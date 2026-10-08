"""Deterministic standalone HTML; no remote assets or service required."""
import argparse,json
from pathlib import Path
from database.schema.migrate import ROOT,init_db
from database.editorial.terms import load_terms,build_tags
from database.editorial.content import load_articles
from database.editorial.versions import load_refinements,review_details
from database.planning.candidates import load_candidates
from database.rebuild_catalog import rebuild_catalog
from database.exports.curation import load_reviewed_games
from database.media_pipeline.pipeline import active_media
from database.natural_history.audit import build_audits
from database.exhibitions.definitions import load_exhibitions

def prepare_content(db):
    reports=rebuild_catalog(db)
    if any(r['errors'] for r in reports):raise ValueError('Import failed; stop preparation')
    load_terms(db);build_tags(db);load_articles(db);load_refinements(db);load_candidates(db);load_reviewed_games(db);build_audits(db,output=None);load_exhibitions(db)

def preview_payload(db):
    objects=[]
    media_assets=active_media(db)
    for obj in db.execute('SELECT * FROM collection_objects ORDER BY object_id'):
        oid=obj['object_id'];article=db.execute('SELECT * FROM editorial_articles WHERE object_id=?',(oid,)).fetchone()
        sources=[dict(r) for r in db.execute('SELECT source_id,record_id,record_url,license_id FROM source_records WHERE object_id=? ORDER BY source_id,record_id',(oid,))]
        cultural=db.execute('SELECT c.date_label,p.label period FROM cultural_heritage c LEFT JOIN historical_periods p ON p.id=c.historical_period_id WHERE c.object_id=?',(oid,)).fetchone()
        geo=db.execute('SELECT p.label FROM fossil_specimens f LEFT JOIN geological_periods p ON p.id=f.geological_period_id WHERE f.object_id=?',(oid,)).fetchone()
        tags=[dict(r) for r in db.execute('SELECT t.* FROM editorial_terms t JOIN editorial_object_tags x ON x.term_id=t.term_id WHERE x.object_id=? ORDER BY t.term_id',(oid,))]
        cultures=[r['zh_name'] for r in tags if r['domain']=='CULTURE'] or [r[0] for r in db.execute('SELECT t.label FROM cultures t JOIN object_cultures x ON x.term_id=t.id WHERE x.object_id=? ORDER BY t.id',(oid,))]
        technique=[r[0] for r in db.execute('SELECT t.label FROM techniques t JOIN object_techniques x ON x.term_id=t.id WHERE x.object_id=? ORDER BY t.id',(oid,))]
        institution=db.execute('SELECT label FROM institutions WHERE id=?',(obj['museum_id'],)).fetchone()
        def location(id):
            r=db.execute('SELECT label FROM locations WHERE id=?',(id,)).fetchone() if id else None
            return r[0] if r else None
        media=[f"{r['media_kind']} {r['license_id']} / {r['verification_status']} ({r['n']})" for r in db.execute('SELECT media_kind,license_id,verification_status,count(*) n FROM media WHERE object_id=? GROUP BY media_kind,license_id,verification_status ORDER BY media_kind,license_id,verification_status',(oid,))]
        objects.append(dict(object_id=oid,zh_name=article['zh_name'] if article else None,original_name=obj['primary_name'],category=obj['category_id'],cultures=cultures,geological_period=geo[0] if geo else None,era=cultural[0] if cultural else None,institution=institution[0] if institution else None,accession_number=obj['accession_number'],sources=sources,origin=location(obj['origin_location_id']),discovery=location(obj['discovery_location_id']),material='; '.join(technique) or None,body=article['body'] if article else None,confidence=article['confidence'] if article else obj['verification_status'],review_details=review_details(db,article['article_id']) if article else None,status='NORMALIZED',media_summary='; '.join(media) or '无已导入媒体',media_licenses=sorted({x.split(' ')[1] for x in media}),regions=[x for x in [location(obj['origin_location_id']),location(obj['discovery_location_id'])] if x],historical_period=cultural['period'] if cultural else None,images=[r for r in media_assets if r['object_id']==oid]))
    articles=[dict(object_id=r['object_id'],article_id=r['article_id'],zh_name=r['zh_name'],original_name=r['original_name'],body=r['body'],status='EDITORIAL_DRAFT / '+r['review_status']) for r in db.execute('SELECT * FROM editorial_articles ORDER BY article_id')]
    candidates=[json.loads(r[0]) for r in db.execute('SELECT payload_json FROM game_collection_candidates ORDER BY game_id')]
    by_id={o['object_id']:o for o in objects};exhibitions=[]
    for row in db.execute('SELECT payload_json FROM museum_exhibitions ORDER BY exhibition_id'):
        plan=json.loads(row[0]);featured=[by_id[oid] for oid in plan['featured_object_ids']]
        entry=dict(plan,zh_name=plan['title_zh'],original_name=plan['title_en'],body=plan['description'],category='EXHIBITION',cultures=sorted({v for o in featured for v in o['cultures']}),regions=sorted({v for o in featured for v in o['regions']}),historical_period=plan['historical_scope'],geological_period=None,institution='规划专题 / '+str(len(featured))+'件',accession_number='独立策划数据',sources=plan['source_notes'],status=plan['curation_status'],confidence='AI策划草稿，未人工审订',era=plan['historical_scope'],media_licenses=sorted({v for o in featured for v in o['media_licenses']}),images=[],media_summary='专题不自动取得任何媒体许可',featured_objects=[dict(object_id=o['object_id'],zh_name=o['zh_name'],original_name=o['original_name'],sources=o['sources']) for o in featured])
        exhibitions.append(entry)
    return dict(exhibitions=exhibitions,schema_version=1,world_year=1933,objects=objects,articles=articles,candidates=candidates,released_count=db.execute('SELECT count(*) FROM game_collection_definitions WHERE approved=1 AND legacy_resource_path IS NOT NULL').fetchone()[0])

def export_preview(db,output,planning_output=None):
    payload=preview_payload(db);encoded=json.dumps(payload,ensure_ascii=False,sort_keys=True,separators=(',',':')).replace('</','<\\/').replace('\u2028','\\u2028').replace('\u2029','\\u2029')
    template=(ROOT/'preview/template.html').read_text(encoding='utf-8-sig');target=Path(output);target.parent.mkdir(parents=True,exist_ok=True);target.write_text(template.replace('__DATA__',encoded),encoding='utf-8')
    if planning_output:Path(planning_output).write_text(json.dumps(dict(schema_version=1,state='GAME_CANDIDATE',world_year=1933,candidates=payload['candidates']),ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    return payload

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--db',default='database/work/catalog.sqlite');p.add_argument('--output',default='database/previews/index.html');p.add_argument('--planning-output',default='database/previews/planning_preview.json');a=p.parse_args();db=init_db(a.db)
    try:
        prepare_content(db);r=export_preview(db,a.output,a.planning_output);print(json.dumps({k:len(r[k]) for k in ['objects','articles','candidates']}))
    finally:db.close()
