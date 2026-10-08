"""Transactional per-record ingestion; curator fields and game definitions are never overwritten."""
import hashlib
import json
from pathlib import Path
from database.schema.migrate import ROOT, VOCABS, utc_now
from database.normalizers.record import stable_id, text
from database.importers.registry import ADAPTERS
NORMALIZER_VERSION=2

def canonical(value):
    return json.dumps(value,ensure_ascii=False,sort_keys=True,separators=(',',':'))

def load_sources(db):
    for source in json.loads((ROOT/'sources/registry.json').read_text(encoding='utf-8')):
        columns=list(source)
        db.execute(f"INSERT OR IGNORE INTO sources({','.join(columns)}) VALUES({','.join('?' for _ in columns)})",tuple(source.values()))

def term(db,table,label,id=None,parent=None):
    if not label:return None
    if table not in VOCABS:raise ValueError('Unknown vocabulary namespace')
    known=db.execute(f'SELECT id FROM {table} WHERE label=? ORDER BY id LIMIT 1',(str(label),)).fetchone() if id is None else None
    id=id or (known[0] if known else stable_id(table,label))
    db.execute(f'INSERT OR IGNORE INTO {table}(id,label,parent_id) VALUES(?,?,?)',(id,str(label),parent))
    db.execute('INSERT OR IGNORE INTO vocab_names VALUES(?,?,?,?,?)',(table,id,'und','SOURCE',str(label)))
    return id

def location(db,label,region=None):
    if not label:return None
    id=term(db,'locations',label)
    region_id=term(db,'regions',region) if region else None
    db.execute('INSERT OR IGNORE INTO location_details(location_id,region_id) VALUES(?,?)',(id,region_id))
    return id

def occurrence(db,r):
    if not r.occurrence:return None,None,None,None
    data=r.occurrence
    taxon=term(db,'taxa',data.get('scientific_name'),stable_id('taxon',r.source_id+':'+str(data.get('taxon_external_id') or data.get('scientific_name'))))
    if taxon:db.execute('INSERT OR IGNORE INTO taxon_details(taxon_id,scientific_name,rank) VALUES(?,?,?)',(taxon,data['scientific_name'],data.get('rank')))
    formation=term(db,'formations',data.get('formation'))
    label=data.get('geological_period')
    # Source geological labels without numerical ages do not acquire fabricated specimen age bounds.
    existing=db.execute('SELECT id FROM geological_periods WHERE lower(label)=lower(?)',(label,)).fetchone() if label else None
    period=existing[0] if existing else term(db,'geological_periods',label)
    id=str(data['id'])
    locality=location(db,r.discovery,r.region)
    db.execute('INSERT OR IGNORE INTO occurrences VALUES(?,?,?,?,?,?,?,?)',
               (id,r.source_id,r.record_id,taxon,locality,formation,data.get('basis') or 'UNKNOWN',r.record_url))
    return id,taxon,formation,period

def save_record(db,r,fetched_at):
    r.validate()
    notice=r.copyright_notice or ('Copyright notice not supplied by source; declared data licence: '+r.data_license+'. Media rights separately checked.')
    raw=canonical(r.raw);digest=hashlib.sha256(raw.encode()).hexdigest()
    old=db.execute('SELECT * FROM source_records WHERE source_id=? AND record_id=?',(r.source_id,r.record_id)).fetchone()
    if old and old['payload_sha256']==digest and old['normalizer_version']==NORMALIZER_VERSION:
        commercial=db.execute('SELECT commercial_allowed FROM licenses WHERE license_id=?',(r.data_license,)).fetchone()[0]
        db.execute('UPDATE source_records SET checked_at=?,copyright_notice=?,license_id=?,commercial_allowed=? WHERE source_id=? AND record_id=?',
                   (utc_now(),notice,r.data_license,commercial,r.source_id,r.record_id))
        return 'duplicate'
    object_id=old['object_id'] if old else None
    if not object_id and not r.context_only:
        # Exact institution + catalogue number is identity evidence; names only generate review candidates.
        matches=db.execute('SELECT object_id FROM collection_objects WHERE museum_id=? AND accession_number=?',
                           (r.museum_id,r.accession_number)).fetchall() if r.museum_id and r.accession_number else []
        object_id=matches[0][0] if len(matches)==1 else stable_id('object',r.source_id+':'+r.record_id)
    lic=db.execute('SELECT commercial_allowed FROM licenses WHERE license_id=?',(r.data_license,)).fetchone()[0]
    if object_id:
        origin=location(db,r.origin,r.region);discovery=location(db,r.discovery,r.region)
        db.execute('''INSERT OR IGNORE INTO collection_objects(object_id,object_kind,category_id,primary_name,description,museum_id,accession_number,origin_location_id,discovery_location_id,license_status,verification_status)
                      VALUES(?,?,?,?,?,?,?,?,?,?,?)''',
                   (object_id,r.object_kind,r.category_id,r.primary_name,text(r.description),r.museum_id,r.accession_number,origin,discovery,r.data_license,r.verification_status))
    db.execute('''INSERT INTO source_records(source_id,record_id,object_id,record_url,dataset_url,license_id,copyright_notice,fetched_at,checked_at,commercial_allowed,payload_sha256,raw_json,normalizer_version)
                  VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(source_id,record_id) DO UPDATE SET
                  payload_sha256=excluded.payload_sha256,raw_json=excluded.raw_json,fetched_at=excluded.fetched_at,
                  checked_at=excluded.checked_at,license_id=excluded.license_id,commercial_allowed=excluded.commercial_allowed,
                  copyright_notice=excluded.copyright_notice,record_url=excluded.record_url,dataset_url=excluded.dataset_url,normalizer_version=excluded.normalizer_version''',
               (r.source_id,r.record_id,object_id,r.record_url,r.dataset_url,r.data_license,notice,fetched_at,utc_now(),lic,digest,raw,NORMALIZER_VERSION))
    occ,taxon,formation,period=occurrence(db,r)
    if not object_id:return 'context'
    locked=db.execute('SELECT editor_locked FROM collection_objects WHERE object_id=?',(object_id,)).fetchone()[0]
    if not locked:
        db.execute('UPDATE collection_objects SET primary_name=?,description=?,verification_status=?,license_status=? WHERE object_id=?',
                   (r.primary_name,text(r.description),r.verification_status,r.data_license,object_id))
        extension=dict(r.extension)
        if r.extension_table=='cultural_heritage' and r.historical_period_label:
            period_id='HAN' if 'han dynasty' in r.historical_period_label.lower() else None
            period_id=term(db,'historical_periods',r.historical_period_label,period_id)
            db.execute('INSERT OR IGNORE INTO human_chronology(period_id,calendar,uncertainty) VALUES(?,?,?)',
                       (period_id,'source_period_unresolved_calendar','Regional source period; numerical bounds not inferred from object dates'))
            extension['historical_period_id']=period_id
        if r.extension_table=='fossil_specimens':
            extension.update(occurrence_id=occ,taxon_id=taxon,formation_id=formation,geological_period_id=period,
                             discovery_location_id=location(db,r.discovery,r.region))
        elif r.extension_table=='biological_specimens':
            extension.update(taxon_id=taxon,collecting_location_id=location(db,r.discovery,r.region))
        elif r.extension_table in ('mineral_specimens','rock_specimens'):
            extension['origin_location_id']=location(db,r.discovery or r.origin,r.region)
        columns={row['name'] for row in db.execute(f'PRAGMA table_info({r.extension_table})')}
        extension={k:(canonical(v) if isinstance(v,(list,dict)) else v) for k,v in extension.items() if k in columns}
        extension['object_id']=object_id
        names=list(extension);update=[k+'=excluded.'+k for k in names if k!='object_id']
        db.execute(f"INSERT INTO {r.extension_table}({','.join(names)}) VALUES({','.join('?' for _ in names)}) ON CONFLICT(object_id) DO "+('UPDATE SET '+','.join(update) if update else 'NOTHING'),tuple(extension.values()))
        for table,values in [('cultures',r.cultures),('materials',r.materials),('techniques',r.techniques)]:
            for value in values:
                tid=term(db,table,value[1],value[0]) if isinstance(value,tuple) else term(db,table,value)
                db.execute(f'INSERT OR IGNORE INTO object_{table} VALUES(?,?)',(object_id,tid))
    # Never replace a curator name or label with a translated guess.
    names=[(r.primary_language,'PRIMARY',r.primary_name)]+r.names
    has_chinese=False
    for lang,kind,value in names:
        if not text(value) or '\ufffd' in value:continue
        has_chinese=has_chinese or lang in ('zh-Hans','zh-Hant')
        db.execute('INSERT OR IGNORE INTO object_names VALUES(?,?,?,?,?,?,?,?)',
                   (object_id,lang,kind,value,'source_available',0,r.source_id,r.record_id))
    if has_chinese:db.execute("UPDATE collection_objects SET translation_status='source_available' WHERE object_id=? AND translation_status='pending'",(object_id,))
    evidence=dict(r.evidence)
    if r.historical_period_label:evidence['cultural.historical_period']=('source_period_or_culture_label',r.historical_period_label)
    for field,value in dict(accession_number=('catalogue_number',r.accession_number),description=('source_description',r.description),
                           discovery_location=('source_locality',r.discovery),data_license=('source_data_license',r.data_license)).items():
        evidence.setdefault(field,value)
    for field,(path,value) in evidence.items():
        db.execute('INSERT OR REPLACE INTO field_evidence VALUES(?,?,?,?,?,?)',
                   (object_id,field,r.source_id,r.record_id,canonical({'source_path':path,'value':value}), 'UNKNOWN' if value is None else 'MATCHED'))
    for dim,value,unit,verbatim in r.measurements:
        db.execute('INSERT OR IGNORE INTO measurements VALUES(?,?,?,?,?,?,?)',(object_id,dim,value,unit,str(verbatim),r.source_id,r.record_id))
    for media in r.media:
        mid=stable_id('media',r.source_id+':'+r.record_id+':'+media['url'])
        media_lic=media['license_id'];requires_by=media_lic=='CC_BY'
        attribution=media.get('attribution')
        approved=media.get('approved') and media_lic in ('CC0','CC_BY') and (not requires_by or attribution)
        db.execute('''INSERT INTO media(media_id,object_id,media_kind,url,license_id,commercial_allowed,verification_status,copyright_notice,attribution,terms_url,checked_at,source_id,record_id)
                      VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(media_id) DO UPDATE SET license_id=excluded.license_id,
                      commercial_allowed=CASE WHEN media.verification_status='DENIED' THEN 0 ELSE excluded.commercial_allowed END,
                      verification_status=CASE WHEN media.verification_status='DENIED' THEN 'DENIED' ELSE excluded.verification_status END,
                      copyright_notice=excluded.copyright_notice,attribution=excluded.attribution,terms_url=excluded.terms_url,checked_at=excluded.checked_at''',
                   (mid,object_id,media.get('kind','IMAGE'),media['url'],media_lic,1 if approved else None,
                    'VERIFIED' if approved else 'UNVERIFIED',media.get('copyright',''),attribution,
                    db.execute('SELECT terms_url FROM sources WHERE source_id=?',(r.source_id,)).fetchone()[0],
                    utc_now() if approved else None,r.source_id,r.record_id))
    for match in db.execute('SELECT object_id FROM collection_objects WHERE primary_name=? AND object_id!=?',(r.primary_name,object_id)):
        a,b=sorted((object_id,match[0]))
        db.execute("INSERT OR IGNORE INTO duplicate_candidates VALUES(?,?,?,'PENDING')",(a,b,'same_name_only'))
    return 'updated' if old else 'success'

def import_rows(db,source_id,rows,fetched_at=None):
    load_sources(db)
    if source_id not in ADAPTERS:raise ValueError('Unknown source adapter')
    db.execute('INSERT INTO import_runs(source_id,started_at) VALUES(?,?)',(source_id,utc_now()))
    run_id=db.execute('SELECT last_insert_rowid()').fetchone()[0]
    counts={'succeeded':0,'skipped':0,'duplicates':0,'errors':0,'unknown_license':0}
    for envelope in rows:
        raw=envelope.get('record',envelope);when=envelope.get('fetched_at',fetched_at or utc_now())
        db.execute('BEGIN IMMEDIATE')
        try:
            record=ADAPTERS[source_id](raw)
            if record.data_license in ('UNKNOWN','CONFIRM'):counts['unknown_license']+=1
            result=save_record(db,record,when)
            db.execute('COMMIT')
            counts['duplicates' if result=='duplicate' else 'skipped' if result=='context' else 'succeeded']+=1
        except Exception as exc:
            db.execute('ROLLBACK');counts['errors']+=1
            db.execute('INSERT INTO import_errors VALUES(?,?,?)',(run_id,str(raw.get('id',raw.get('key',''))),str(exc)))
    db.execute('UPDATE import_runs SET finished_at=?,succeeded=?,skipped=?,duplicates=?,errors=?,unknown_license=? WHERE run_id=?',
               (utc_now(),*counts.values(),run_id))
    return dict(run_id=run_id,source=source_id,**counts)
