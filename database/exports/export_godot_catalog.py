"""Stable approved local JSON only. Never downloads media or rewrites legacy Godot resources."""
import argparse
import json
from pathlib import Path
from database.schema.migrate import init_db
from database.exports.world_policy import world_issues

REPO=Path(__file__).resolve().parents[2]

def local_asset(path,root=REPO):
    if not path:return None
    path=path.removeprefix('res://')
    candidate=Path(path)
    if candidate.is_absolute() or ':' in path:return None
    target=(root/candidate).resolve()
    try:target.relative_to(root.resolve())
    except ValueError:return None
    if not target.is_file():return None
    return 'res://'+target.relative_to(root.resolve()).as_posix()

def media_allowed(row):
    return (row['license_id'] in ('CC0','CC_BY') and row['commercial_allowed']==1 and
            row['verification_status']=='VERIFIED' and bool(row['checked_at']) and
            (row['license_id']!='CC_BY' or bool(row['attribution'])))

def export_catalog(db,anchor=1933,asset_root=REPO):
    items=[];reference_objects={};report={'blocked_games':[],'blocked_media':[],'missing_translations':[],
                                        'missing_images':[],'missing_references':[]}
    for row in db.execute('SELECT * FROM game_collection_definitions WHERE approved=1 ORDER BY game_id'):
        game=dict(row);id=game['game_id'];issues=world_issues(db,game,anchor)
        if not id.strip() or not game['display_name'].strip() or game['rarity'] not in ('COMMON','UNCOMMON','RARE','TREASURE'):
            issues.append('invalid_game_identity_or_rarity')
        for field,minimum in [('base_value',1),('inventory_slots',1),('exhibit_appeal',0)]:
            value=game[field]
            if not isinstance(value,int) or isinstance(value,bool) or value<minimum or value>1000000000:
                issues.append('invalid_game_number:'+field)
        if game['transport_mode']!='HAND_CARRY' or game['inventory_slots']>8:
            issues.append('outside_current_eight_slot_inventory')
        refs=db.execute('''SELECT o.*,r.relation,r.review_note FROM game_object_references r JOIN collection_objects o ON o.object_id=r.object_id
                           WHERE r.game_id=? ORDER BY o.object_id''',(id,)).fetchall()
        for obj in refs:
            rights=db.execute('SELECT license_id,commercial_allowed,copyright_notice FROM source_records WHERE object_id=?',(obj['object_id'],)).fetchall()
            if obj['verification_status'] not in ('SOURCE_VERIFIED','CURATOR_VERIFIED'):
                issues.append('reference_not_reviewed:'+obj['object_id'])
            if not rights or any(r['commercial_allowed']!=1 or r['license_id'] not in ('CC0','CC_BY') or (r['license_id']=='CC_BY' and not r['copyright_notice']) for r in rights):
                issues.append('reference_data_rights_unconfirmed:'+obj['object_id'])
        if issues:
            report['blocked_games'].append({'game_id':id,'reasons':sorted(set(issues))});continue
        item={k:game[k] for k in ('game_id','display_name','description','category','rarity','base_value','inventory_slots','exhibit_appeal','game_asset_id')}
        item['game_asset_id']=local_asset(game['game_asset_id'],asset_root)
        item['unlock_conditions']=json.loads(game['unlock_conditions'])
        item['reference_object_ids']=[r['object_id'] for r in refs]
        item['obtain_region_ids']=[r[0] for r in db.execute('SELECT region_id FROM game_obtain_regions WHERE game_id=? ORDER BY region_id',(id,))]
        item['images']=[]
        if not refs:report['missing_references'].append(id)
        for obj in refs:
            oid=obj['object_id']
            names=[dict(r) for r in db.execute('SELECT language,name_type,value,translation_status FROM object_names WHERE object_id=? ORDER BY language,name_type,value',(oid,))]
            if not any(n['language'] in ('zh-Hans','zh-Hant') for n in names):report['missing_translations'].append(oid)
            sources=[dict(r) for r in db.execute('SELECT source_id,record_id,record_url,license_id,copyright_notice FROM source_records WHERE object_id=? ORDER BY source_id,record_id',(oid,))]
            reference_objects[oid]={'object_id':oid,'primary_name':obj['primary_name'],'object_kind':obj['object_kind'],
                                    'museum_id':obj['museum_id'],'names':names,'sources':sources,
                                    'translation_status':obj['translation_status']}
            for media in db.execute('SELECT * FROM media WHERE object_id=? ORDER BY media_id',(oid,)):
                path=local_asset(media['local_asset_path'],asset_root)
                if not media_allowed(media) or not path:
                    report['blocked_media'].append({'media_id':media['media_id'],'reason':'rights_unverified' if not media_allowed(media) else 'not_locally_packaged'})
                    continue
                item['images'].append({'asset_path':path,'media_kind':media['media_kind'],'license_id':media['license_id'],
                                       'attribution':media['attribution'],'source_url':media['url']})
        if not item['images'] and not item['game_asset_id']:report['missing_images'].append(id)
        items.append(item)
    for key in ('missing_translations','missing_images','missing_references'):report[key]=sorted(set(report[key]))
    catalogue={'schema_version':1,'world_year':anchor,'game_definitions':items,
               'reference_objects':[reference_objects[k] for k in sorted(reference_objects)]}
    return catalogue,report

def write_export(db,output,report_output,anchor=1933,asset_root=REPO):
    catalogue,report=export_catalog(db,anchor,asset_root)
    for target,data in [(output,catalogue),(report_output,report)]:
        p=Path(target);p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(json.dumps(data,ensure_ascii=False,sort_keys=True,indent=2)+'\n',encoding='utf-8')
    return catalogue,report

def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--db',default='database/work/catalog.sqlite')
    p.add_argument('--output',default='database/work/godot_catalog.json');p.add_argument('--report',default='database/work/export_report.json')
    p.add_argument('--world-year',type=int,default=1933);args=p.parse_args(argv)
    db=init_db(args.db)
    try:
        cat,report=write_export(db,args.output,args.report,args.world_year)
        print(json.dumps({'exported':len(cat['game_definitions']),'blocked':report['blocked_games'],'report':args.report},ensure_ascii=False,indent=2))
    finally:db.close()

if __name__=='__main__':main()
