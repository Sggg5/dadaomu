"""Content quality report; hard errors and human-review gaps are explicitly separate."""
import json,hashlib
from database.schema.migrate import ROOT
from database.validators.quality import statistics,validate_db
from database.planning.candidates import validate_candidate
from database.editorial.content import validate_article

def content_report(db):
    errors=list(validate_db(db)['errors']);stats=statistics(db)
    articles=json.loads((ROOT/'editorial/articles.json').read_text(encoding='utf-8'))
    candidates=[json.loads(r[0]) for r in db.execute('SELECT payload_json FROM game_collection_candidates ORDER BY game_id')]
    for a in articles:
        try:validate_article(db,a)
        except Exception as exc:errors.append(a['article_id']+': '+str(exc))
    for c in candidates:
        try:validate_candidate(db,c)
        except Exception as exc:errors.append(c['game_id']+': '+str(exc))
    if db.execute('SELECT count(*) FROM game_collection_definitions').fetchone()[0]!=8:errors.append('Released game definitions changed')
    count=lambda table,col:[dict(r) for r in db.execute(f'SELECT {col},count(*) count FROM {table} GROUP BY {col} ORDER BY {col}')]
    return dict(errors=errors,statistics=stats,source_counts=count('source_records','source_id'),article_states=count('editorial_articles','review_status'),candidate_states=count('game_collection_candidates','status'),candidate_cohorts=count('game_collection_candidates','cohort'),drafts=len(articles),candidates=len(candidates),terms=db.execute('SELECT count(*) FROM editorial_terms').fetchone()[0],unknown_fossil_fields={f:db.execute('SELECT count(*) FROM fossil_specimens WHERE '+f+' IS NULL').fetchone()[0] for f in ['scientific_name','taxonomic_rank','age_min_ma','age_max_ma','discovery_year','preserved_element']},missing_dedicated_articles=sum(c['article_relation']!='SAME_OBJECT' for c in candidates),blocked_specific_1933_identities=sum(c['world_1933']['status']=='BLOCKED_SPECIFIC_IDENTITY' for c in candidates),media_downloaded=0,profile_version=4,release_catalog_sha256=hashlib.sha256((ROOT.parent/'data/catalog/global_catalog.json').read_bytes()).hexdigest(),human_review='NOT_PERFORMED',semantic_assertion_review='Citations validated structurally; translation correctness and historical interpretation still require humans')
