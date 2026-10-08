"""Bounded local media rebuilding; no dependency in Godot runtime."""
import argparse,json
from database.schema.migrate import ROOT,init_db
from database.preview.__main__ import prepare_content
from database.media_pipeline.pipeline import download_samples,refresh_rights
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('command',choices=['download','refresh-rights']);p.add_argument('--db',default='database/work/catalog.sqlite');a=p.parse_args();db=init_db(a.db)
    try:
        prepare_content(db)
        result=download_samples(db,json.loads((ROOT/'media_pipeline/selection.json').read_text(encoding='utf-8'))) if a.command=='download' else refresh_rights(db)
        print(json.dumps(result,ensure_ascii=False,indent=2))
    finally:db.close()
