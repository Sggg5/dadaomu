"""Explicit proposals only: deterministic values are not economic balance or human approval."""
import json
from database.schema.migrate import ROOT
from database.editorial.content import digest

TRANSPORTS={'HAND_CARRY','PACKED_CRATE','EXPEDITION_TRANSPORT'}
RARITIES={'COMMON','UNCOMMON','RARE','TREASURE'}

def validate_candidate(db,c):
    if c['status']!='CANDIDATE' or any(c['reviews'][k]!='PENDING' for k in ('history','source','numbers','gameplay')):
        raise ValueError('Proposal import cannot approve a candidate')
    if not c['game_id'].startswith('candidate_'):
        raise ValueError('Candidate namespace must be distinct from released IDs')
    if db.execute('SELECT 1 FROM game_collection_definitions WHERE game_id=?',(c['game_id'],)).fetchone():
        raise ValueError('Candidate overlaps a released game definition')
    ref=db.execute('SELECT * FROM source_records WHERE object_id=? AND source_id=? AND record_id=?',(c['object_id'],c['source_id'],c['record_id'])).fetchone()
    if not ref or c['source_url']!=ref['record_url']:
        raise ValueError('Candidate requires a traceable source')
    if c['basis_kind'] not in ('REAL_OBJECT_REFERENCE','FICTIONAL_ARCHETYPE') or not c['basis_note']:
        raise ValueError('Real source reference and fictional identity must be distinguished')
    if c['transport_mode'] not in TRANSPORTS:raise ValueError('Unknown transport mode')
    slots=c['suggested_slots']
    if not isinstance(slots,int) or isinstance(slots,bool) or slots<1:raise ValueError('Invalid candidate size')
    if slots>8 and c['transport_mode']!='EXPEDITION_TRANSPORT':raise ValueError('Large specimen cannot enter 8-slot backpack')
    for key in ('suggested_value','suggested_appeal'):
        if type(c[key]) is not int or c[key]<1:raise ValueError('Invalid proposal value')
    if c['suggested_rarity'] not in RARITIES:raise ValueError('Invalid rarity')
    if not c['obtain_regions'] or not c['region_note'] or not c['world_1933']['issues']:
        raise ValueError('Unknown geography and chronology must stay explicitly pending')
    if c['article_id'] and not db.execute('SELECT 1 FROM editorial_articles WHERE article_id=?',(c['article_id'],)).fetchone():
        raise ValueError('Dangling encyclopedia link')
    bands=json.loads((ROOT/'planning/value_bands.json').read_text(encoding='utf-8'))
    band=bands[c['value_band']]
    if not band['value'][0]<=c['suggested_value']<=band['value'][1] or not band['appeal'][0]<=c['suggested_appeal']<=band['appeal'][1]:
        raise ValueError('Candidate outside proposal consistency band')
    return digest(c)

def load_candidates(db,path=ROOT/'planning/candidates.json'):
    rows=json.loads(path.read_text(encoding='utf-8'))
    if len({r['game_id'] for r in rows})!=len(rows):raise ValueError('Duplicate game candidate ID')
    hashes=[validate_candidate(db,r) for r in rows]
    db.execute('BEGIN IMMEDIATE')
    try:
        for c,sha in zip(rows,hashes):
            db.execute('''INSERT INTO game_collection_candidates(game_id,object_id,article_id,zh_name,cohort,category,basis_kind,payload_json,content_sha256)
                          VALUES(?,?,?,?,?,?,?,?,?) ON CONFLICT(game_id) DO UPDATE SET payload_json=excluded.payload_json,
                          content_sha256=excluded.content_sha256,zh_name=excluded.zh_name,article_id=excluded.article_id,category=excluded.category WHERE game_collection_candidates.status='CANDIDATE' ''',
                       (c['game_id'],c['object_id'],c['article_id'],c['zh_name'],c['cohort'],c['category'],c['basis_kind'],json.dumps(c,ensure_ascii=False,sort_keys=True),sha))
        db.execute('COMMIT')
    except Exception:db.execute('ROLLBACK');raise
    return len(rows)
