"""Read-only exhibition proposals; no ticket modifiers, game unlocks or visitor behavior."""
from dataclasses import dataclass
import json
from database.schema.migrate import ROOT
from database.editorial.content import digest

@dataclass(frozen=True)
class MuseumExhibitionDefinition:
    exhibition_id:str
    title_zh:str
    title_en:str
    description:str
    theme_tags:list
    featured_object_ids:list
    related_article_ids:list
    historical_scope:str
    display_requirements:dict
    curation_status:str
    review_notes:list

def load_exhibitions(db,path=ROOT/'exhibitions/definitions.json'):
    rows=json.loads(path.read_text(encoding='utf-8'))
    if len({r['exhibition_id'] for r in rows})!=len(rows):raise ValueError('Duplicate exhibition ID')
    for r in rows:
        MuseumExhibitionDefinition(**{k:r[k] for k in MuseumExhibitionDefinition.__dataclass_fields__})
        if r['curation_status']!='DRAFT_PENDING_REVIEW':raise ValueError('AI exhibition proposals cannot approve themselves')
        if len(set(r['featured_object_ids']))!=len(r['featured_object_ids']):raise ValueError('Repeated exhibit is not another real object')
        if r['reading_order']!=r['featured_object_ids']:raise ValueError('Reading order must reference actual selected objects')
        for oid in r['featured_object_ids']:
            if not db.execute('SELECT 1 FROM collection_objects WHERE object_id=?',(oid,)).fetchone():raise ValueError('Exhibition references nonexistent object')
        for aid in r['related_article_ids']:
            if not db.execute('SELECT 1 FROM editorial_articles WHERE article_id=?',(aid,)).fetchone():raise ValueError('Exhibition references nonexistent article')
        for relation in r['object_relationships']:
            if relation['from'] not in r['featured_object_ids'] or relation['to'] not in r['featured_object_ids']:raise ValueError('Invalid exhibit relationship')
    db.execute('SAVEPOINT exhibition_import')
    try:
        for r in rows:
            db.execute('INSERT OR IGNORE INTO museum_exhibitions VALUES(?,?,?,?,?,?)',(r['exhibition_id'],r['title_zh'],r['title_en'],json.dumps(r,ensure_ascii=False),digest(r),r['curation_status']))
            for i,oid in enumerate(r['reading_order']):db.execute('INSERT OR IGNORE INTO exhibition_objects VALUES(?,?,?)',(r['exhibition_id'],oid,i))
            for aid in r['related_article_ids']:db.execute('INSERT OR IGNORE INTO exhibition_articles VALUES(?,?)',(r['exhibition_id'],aid))
        db.execute('RELEASE exhibition_import')
    except Exception:db.execute('ROLLBACK TO exhibition_import');db.execute('RELEASE exhibition_import');raise
    return len(rows)
