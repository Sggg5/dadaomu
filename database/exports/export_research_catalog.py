"""Offline research bridge. Never changes released game definitions."""
import argparse,json,hashlib,shutil
from database.media_pipeline.pipeline import active_media,checked_image
from pathlib import Path
from database.schema.migrate import init_db,ROOT
from database.preview.__main__ import prepare_content,preview_payload

def build_catalog(db):
    preview=preview_payload(db);records=[];missing={}
    for o in preview['objects']:
        raw=db.execute('SELECT * FROM collection_objects WHERE object_id=?',(o['object_id'],)).fetchone()
        article=db.execute('SELECT * FROM editorial_articles WHERE object_id=?',(o['object_id'],)).fetchone()
        materials=[r[0] for r in db.execute('SELECT m.label FROM materials m JOIN object_materials x ON x.term_id=m.id WHERE x.object_id=? ORDER BY m.id',(o['object_id'],))]
        row=dict(object_id=o['object_id'],original_name=o['original_name'],recommended_zh_name=o['zh_name'],object_kind=raw['object_kind'],category=o['category'],culture=o['cultures'],historical_period=o['historical_period'],date_label=o['era'],geological_period=o['geological_period'],material=materials or None,description=raw['description'],museum_name=o['institution'],accession_number=o['accession_number'],source_urls=[s['record_url'] for s in o['sources']],source_licenses=[s['license_id'] for s in o['sources']],article_id=article['article_id'] if article else None,article_status=article['review_status'] if article else None,media_asset_id=None,verification_status=raw['verification_status'],world_scope='RESEARCH_REFERENCE_NOT_1933_DISCOVERY')
        audit=db.execute('SELECT fields_json,issues_json,academic_review FROM natural_history_audits WHERE object_id=?',(o['object_id'],)).fetchone()
        row['natural_history']=dict(fields=json.loads(audit[0]),issues=json.loads(audit[1]),academic_review=audit[2]) if audit else None
        for key in ['recommended_zh_name','historical_period','geological_period','material','description','article_id']:
            if row[key] is None:missing[key]=missing.get(key,0)+1
        records.append(row)
    articles=[dict(r) for r in db.execute('SELECT article_id,object_id,zh_name,original_name,object_type,civilization_or_geology,material,technique_or_preservation,body,confidence,review_status,editor_version FROM editorial_articles ORDER BY article_id')]
    return dict(schema_version=1,scope='RESEARCH_REFERENCE_NOT_1933_DISCOVERY',records=records,articles=articles,media=research_media(db)),dict(records=len(records),articles=len(articles),missing_fields=missing,excluded_records=0,candidates_not_exported=500,media_policy='Only tracked, verified samples promoted in 10D.3')

def research_media(db):
    result=[]
    for image in active_media(db):
        if not image['detail_repo_path'].startswith('database/previews/media/samples/'):continue
        path=ROOT.parent/image['detail_repo_path'];checked_image(path.read_bytes(),'image/jpeg')
        result.append(dict(media_id=image['media_id'],object_id=image['object_id'],asset_path='res://assets/catalog/'+path.name,sha256=image['detail_sha256'],license_id=image['license_id'],attribution=image['attribution'],copyright_notice=image['copyright_notice'],record_url=image['record_url'],verification_status='SOURCE_VERIFIED',revoked=False))
    return sorted(result,key=lambda r:r['media_id'])

def promote_media(db):
    target=ROOT.parent/'assets/catalog';target.mkdir(parents=True,exist_ok=True)
    for image in research_media(db):
        source=ROOT/'previews/media/samples'/Path(image['asset_path']).name
        shutil.copyfile(source,target/ source.name)
    (target/'ATTRIBUTION.json').write_text(json.dumps(research_media(db),ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')

def export(db,output,report):
    payload,quality=build_catalog(db)
    mapping={m['object_id']:m['media_id'] for m in payload['media']}
    for row in payload['records']:row['media_asset_id']=mapping.get(row['object_id'])
    quality['local_images']=len(payload['media'])
    quality['missing_images']=len(payload['records'])-len(payload['media'])
    for path,data in [(output,payload),(report,quality)]:
        Path(path).parent.mkdir(parents=True,exist_ok=True);Path(path).write_text(json.dumps(data,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    return payload

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--db',default='database/work/catalog.sqlite');a=p.parse_args();db=init_db(a.db)
    try:
        prepare_content(db);promote_media(db);r=export(db,'data/catalog/museum_research_catalog.json','database/docs/phase10d_export_report.json');print(len(r['records']),len(r['articles']))
    finally:db.close()
