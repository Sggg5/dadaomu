"""Idempotent seed replay. Never deletes an existing DB or curator edits."""
import argparse
import json
from database.schema.migrate import ROOT, init_db
from database.importers.store import import_rows
from database.query import build_index

SAMPLES={'CMA':'cma_seed.jsonl','GBIF':'gbif_nhm_fossil_seed.jsonl','SMITHSONIAN':'smithsonian_natural_seed.jsonl','MET':'met_seed.jsonl','AIC':'aic_seed.jsonl'}
def rebuild_catalog(db):
    reports=[]
    for source,file in SAMPLES.items():
        rows=[json.loads(line) for line in (ROOT/'samples'/file).read_text(encoding='utf-8').splitlines() if line.strip()]
        reports.append(import_rows(db,source,rows))
    build_index(db)
    return reports

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--db',default='database/work/catalog.sqlite')
    args=p.parse_args();db=init_db(args.db)
    try:
        reports=rebuild_catalog(db);print(json.dumps(reports,indent=2))
        raise SystemExit(1 if any(r['errors'] for r in reports) else 0)
    finally:db.close()
