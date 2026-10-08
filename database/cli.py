"""Run from repository root: python -m database.cli COMMAND --db database/work/catalog.sqlite."""
import argparse
import json
from pathlib import Path
from database.schema.migrate import init_db
from database.importers.store import import_rows, load_sources
from database.query import build_index, search_catalog, FILTERS
from database.validators.quality import validate_db, report_licenses, statistics

def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command',choices=['init_db','import_source','validate_db','build_index','search_catalog','report_licenses','statistics','export_godot_catalog'])
    parser.add_argument('--db',default='database/work/catalog.sqlite')
    parser.add_argument('--source');parser.add_argument('--file',type=Path);parser.add_argument('--keyword',default='');parser.add_argument('--limit',type=int,default=50)
    parser.add_argument('--output',default='database/work/godot_catalog.json');parser.add_argument('--report',default='database/work/export_report.json');parser.add_argument('--world-year',type=int,default=1933)
    for name in FILTERS:parser.add_argument('--'+name.replace('_','-'),dest=name)
    args=parser.parse_args(argv)
    db=init_db(args.db)
    try:
        load_sources(db)
        if args.command=='init_db':result={'schema_version':db.execute('SELECT max(version) FROM schema_migrations').fetchone()[0]}
        elif args.command=='import_source':
            if not args.source or not args.file:parser.error('import_source requires --source and --file')
            rows=[json.loads(line) for line in args.file.read_text(encoding='utf-8-sig').splitlines() if line.strip()]
            result=import_rows(db,args.source,rows);build_index(db)
        elif args.command=='export_godot_catalog':
            from database.exports.export_godot_catalog import write_export
            cat,report=write_export(db,args.output,args.report,args.world_year)
            result={'exported':len(cat['game_definitions']),'blocked':report['blocked_games']}
        elif args.command=='build_index':build_index(db);result={'indexed':db.execute('SELECT count(*) FROM catalogue_fts').fetchone()[0]}
        elif args.command=='validate_db':result=validate_db(db)
        elif args.command=='report_licenses':result=report_licenses(db)
        elif args.command=='statistics':result=statistics(db)
        else:result=search_catalog(db,args.keyword,args.limit,**{name:getattr(args,name) for name in FILTERS})
        print(json.dumps(result,ensure_ascii=False,indent=2))
        return 1 if isinstance(result,dict) and result.get('errors') else 0
    finally:db.close()

if __name__=='__main__':raise SystemExit(main())
