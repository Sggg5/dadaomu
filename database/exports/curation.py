"""Explicit reviewed game prototypes; ingestion cannot auto-populate this layer."""
import json
from pathlib import Path
from database.schema.migrate import ROOT

def load_reviewed_games(db,path=ROOT/'samples/legacy_game_mapping.json'):
    definitions=json.loads(Path(path).read_text(encoding='utf-8'))
    seen=set();inserted=0
    db.execute('BEGIN IMMEDIATE')
    try:
        for data in definitions:
            id=data['game_id']
            if id in seen:raise ValueError('Duplicate game id: '+id)
            seen.add(id)
            # Re-running mapping never rewrites a curator's stored game configuration.
            if db.execute('SELECT 1 FROM game_collection_definitions WHERE game_id=?',(id,)).fetchone():continue
            cols=[r['name'] for r in db.execute('PRAGMA table_info(game_collection_definitions)') if r['name'] in data]
            db.execute(f"INSERT INTO game_collection_definitions({','.join(cols)}) VALUES({','.join('?' for _ in cols)})",tuple(data[c] for c in cols))
            for oid in data.get('reference_object_ids',[]):
                note=data.get('reference_reviews',{}).get(oid)
                if not note:raise ValueError('Real-object reference requires relationship review')
                db.execute('INSERT INTO game_object_references VALUES(?,?,?,?)',(id,oid,'FORM_REFERENCE',note))
            for region in data.get('obtain_region_ids',[]):db.execute('INSERT INTO game_obtain_regions VALUES(?,?)',(id,region))
            inserted+=1
        db.execute('COMMIT')
    except Exception:
        db.execute('ROLLBACK');raise
    return inserted

if __name__=='__main__':
    import argparse
    from database.schema.migrate import init_db
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--db',default='database/work/catalog.sqlite');p.add_argument('--file',type=Path,default=ROOT/'samples/legacy_game_mapping.json')
    args=p.parse_args();db=init_db(args.db)
    try:print(json.dumps({'inserted':load_reviewed_games(db,args.file)}))
    finally:db.close()
