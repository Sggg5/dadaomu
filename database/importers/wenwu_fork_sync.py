"""Incremental Fork sync into existing schema, with per-source admission and review protection."""
import argparse,collections,hashlib,json,sqlite3,subprocess
from pathlib import Path
from database.schema.migrate import init_db,utc_now
from database.importers.store import load_sources,save_record,canonical,term
from database.importers.wenwu_fork_adapter import project,official_key,SOURCE,REPO,POLICIES

def setup(db):
 load_sources(db)
 term(db,'institutions','Smithsonian National Museum of Asian Art','SMITHSONIAN_NMAA','SMITHSONIAN')
 db.execute("INSERT OR IGNORE INTO sources VALUES(?,?,?,?,?,?,?,?,?)",(SOURCE,None,'wenwu_fork_v1',REPO,REPO+'/blob/master/LICENSE','UNKNOWN','2026-10-09','PER_RECORD','Code MIT is not data/media permission; four verified metadata policies and separate source-only/type records. No image fetches.'))

class Sync:
 def __init__(self,db,sha):
  self.db=db;self.sha=sha;setup(db)
  self.acc=collections.defaultdict(set);self.urls=collections.defaultdict(set);self.other_source=set()
  for row in db.execute('SELECT object_id,museum_id,accession_number FROM collection_objects'):
   if row['museum_id'] and row['accession_number']:self.acc[(row['museum_id'],row['accession_number'])].add(row['object_id'])
  for row in db.execute('SELECT object_id,source_id,record_url FROM source_records WHERE object_id IS NOT NULL'):
   key=official_key(row['record_url'])
   if key:self.urls[key].add(row['object_id'])
   if row['source_id']!=SOURCE:self.other_source.add(row['object_id'])
 def ingest(self,raw):
  data=project(raw,self.sha);r=data['record'];db=self.db
  old=db.execute('SELECT * FROM wenwu_entries WHERE record_id=?',(r.record_id,)).fetchone()
  candidates=set()
  if r.museum_id and r.accession_number:candidates.update(self.acc.get((r.museum_id,r.accession_number),set()))
  candidates.update(self.urls.get(official_key(r.record_url),set()))
  if len(candidates)>1:
   data['issues'].append('AMBIGUOUS_STABLE_IDENTITY');r.context_only=True;data['verdict']='IDENTITY_REVIEW_INDEX_ONLY'
  matched=next(iter(candidates)) if len(candidates)==1 else None
  if data['kind']=='COIN_TYPE':matched=None
  object_before=db.execute('SELECT count(*) FROM collection_objects').fetchone()[0]
  db.execute('BEGIN IMMEDIATE')
  try:
   if r.context_only:
    # Restricted payload remains a factual source index, not a normalized museum object.
    minimal=canonical(data['minimal'])
    db.execute('''INSERT INTO source_records(source_id,record_id,object_id,record_url,dataset_url,license_id,copyright_notice,fetched_at,checked_at,commercial_allowed,payload_sha256,raw_json,normalizer_version)
      VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(source_id,record_id) DO UPDATE SET record_url=excluded.record_url,dataset_url=excluded.dataset_url,license_id=excluded.license_id,copyright_notice=excluded.copyright_notice,checked_at=excluded.checked_at,commercial_allowed=excluded.commercial_allowed,payload_sha256=excluded.payload_sha256,raw_json=excluded.raw_json''',
      (SOURCE,r.record_id,matched,r.record_url,r.dataset_url,'UNKNOWN',r.copyright_notice,raw.get('fetched_at') or utc_now(),utc_now(),None,hashlib.sha256(minimal.encode()).hexdigest(),minimal,5))
   else:
    existing=old['object_id'] if old and old['object_id'] else matched
    protected=bool(existing and (existing in self.other_source or db.execute('SELECT editor_locked FROM collection_objects WHERE object_id=?',(existing,)).fetchone()[0] or db.execute('SELECT 1 FROM object_names WHERE object_id=? AND curator_locked=1',(existing,)).fetchone() or db.execute("SELECT 1 FROM field_evidence WHERE object_id=? AND status='CURATED'",(existing,)).fetchone()))
    protected=protected or bool(old and (old['curator_locked'] or old['review_status']=='HUMAN_REVIEWED'))
    save_record(db,r,raw.get('fetched_at') or utc_now(),identity_object_id=matched,preserve_existing=protected,name_candidates=False)
   object_id=db.execute('SELECT object_id FROM source_records WHERE source_id=? AND record_id=?',(SOURCE,r.record_id)).fetchone()[0]
   columns={'record_id':r.record_id,'museum_code':data['prefix'],'museum_name':data['museum'],'entity_key':data['entity'],'record_kind':data['kind'],'original_name':r.primary_name,'original_dynasty':raw.get('dynasty'),'original_material':r.materials[0] if r.materials else None,'original_inventory':data['inventory'],'accession_number':r.accession_number,'category_label':raw.get('category'),'official_url':r.record_url,'data_license_claim':data['claim'],'effective_data_license':r.data_license,'rights_verdict':data['verdict'],'rights_evidence_url':data['terms'],'media_claims_json':canonical(data['media']),'issues_json':canonical(data['issues']),'upstream_sha':self.sha,'payload_sha256':data['payload_sha'],'projection_sha256':data['projection_sha'],'object_id':object_id,'active':1}
   keys=list(columns);changes=[f'{k}=excluded.{k}' for k in keys if k!='record_id']
   db.execute(f"INSERT INTO wenwu_entries({','.join(keys)}) VALUES({','.join('?' for _ in keys)}) ON CONFLICT(record_id) DO UPDATE SET {','.join(changes)}",tuple(columns.values()))
   db.execute('INSERT OR IGNORE INTO wenwu_versions VALUES(?,?,?,?,?)',(r.record_id,data['payload_sha'],data['projection_sha'],self.sha,canonical(data['minimal'])))
   db.execute('COMMIT')
  except Exception:db.execute('ROLLBACK');raise
  if object_id:
   if r.museum_id and r.accession_number:self.acc[(r.museum_id,r.accession_number)].add(object_id)
   self.urls[official_key(r.record_url)].add(object_id)
  object_after=db.execute('SELECT count(*) FROM collection_objects').fetchone()[0]
  return {'entry':'added' if old is None else 'duplicate' if old['payload_sha256']==data['payload_sha'] and old['projection_sha256']==data['projection_sha'] else 'updated','normalized_added':object_after-object_before,'linked_existing':bool(matched and object_after==object_before),'linked_original_source':bool(matched and matched in self.other_source),'verdict':data['verdict'],'kind':data['kind'],'id':r.record_id}

def ordered_files(root,limit=0):
 files=sorted((root/'data/relics').glob('*.json'))
 if not limit:return files
 # Balanced first1000 exercises all museums, rights cases and coin types, not just alphabetical AIC.
 groups=collections.defaultdict(list)
 for path in files:groups[path.name.split('-',1)[0]].append(path)
 result=[];index=0
 while len(result)<min(limit,len(files)):
  for key in sorted(groups):
   if index<len(groups[key]):result.append(groups[key][index])
   if len(result)>=limit:break
  index+=1
 return result

def run(db,root,limit=0,sha=None):
 sha=sha or subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
 if not __import__('re').fullmatch('[0-9a-f]{40}',sha):raise ValueError('Invalid pinned commit')
 sync=Sync(db,sha);counts=collections.Counter();errors=[];museums=collections.Counter();categories=collections.Counter();rights=collections.Counter();kinds=collections.Counter();missing=collections.Counter();digests=collections.Counter()
 files=ordered_files(root,limit)
 for path in files:
  counts['scanned']+=1
  try:
   if not path.resolve().is_relative_to((root/'data/relics').resolve()):raise ValueError('JSON symlink escapes source folder')
   if path.stat().st_size>1_000_000:raise ValueError('Oversized record; no inline image payload admitted')
   raw=json.loads(path.read_text(encoding='utf-8-sig'))
   if raw.get('relic_id')!=path.stem:raise ValueError('Filename/raw ID mismatch')
   outcome=sync.ingest(raw)
   counts[outcome['entry']]+=1;counts['normalized_added']+=outcome['normalized_added'];counts['linked_existing']+=int(outcome['linked_existing']);counts['linked_original_source']+=int(outcome['linked_original_source'])
   museums[raw['relic_id'].split('-',1)[0]]+=1;categories[str(raw.get('category'))]+=1;rights[outcome['verdict']]+=1;kinds[outcome['kind']]+=1
   digests[hashlib.sha256(canonical(raw).encode()).hexdigest()]+=1
   for field in ['name','dynasty','material','year_range']:
    if raw.get(field) in (None,'',[]):missing[field]+=1
  except Exception as exc:counts['rejected']+=1;errors.append({'file':path.name,'reason':str(exc)})
 if not limit and not errors:db.execute('UPDATE wenwu_entries SET active=0 WHERE upstream_sha!=?',(sha,))
 report={'upstream_sha':sha,'complete_scan':not bool(limit),'counts':dict(counts),'museums':dict(museums),'categories':dict(categories),'rights':dict(rights),'record_kinds':dict(kinds),'missing_fields':dict(missing),'identical_payload_duplicates':sum(v-1 for v in digests.values()),'errors':errors,'normalized_total':db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],'source_index_total':db.execute('SELECT count(*) FROM wenwu_entries').fetchone()[0],'same_name_groups':db.execute('SELECT count(*) FROM (SELECT original_name FROM wenwu_entries GROUP BY original_name HAVING count(*)>1)').fetchone()[0],'stable_identity_groups':db.execute('SELECT count(*) FROM (SELECT entity_key FROM wenwu_entries GROUP BY entity_key HAVING count(*)>1)').fetchone()[0],'pending_review':db.execute("SELECT count(*) FROM wenwu_entries WHERE review_status='PENDING'").fetchone()[0]}
 db.execute('INSERT INTO wenwu_sync_runs(upstream_sha,complete_scan,report_json) VALUES(?,?,?)',(sha,not bool(limit),canonical(report)))
 return report

def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--source-root',type=Path,required=True);parser.add_argument('--db',type=Path,default=Path('database/work/phase11c_catalog.sqlite'));parser.add_argument('--limit',type=int,default=0);parser.add_argument('--report',type=Path,required=True)
 args=parser.parse_args();db=init_db(args.db)
 try:
  db.execute('PRAGMA journal_mode=WAL');db.execute('PRAGMA synchronous=NORMAL')
  report=run(db,args.source_root,args.limit);args.report.parent.mkdir(parents=True,exist_ok=True);args.report.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(report['counts']));return 1 if report['errors'] else 0
 finally:db.close()
if __name__=='__main__':raise SystemExit(main())
