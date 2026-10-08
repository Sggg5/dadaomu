"""Traceable Chinese drafts; structural validation cannot certify historical translation."""
import hashlib
import json
from database.schema.migrate import ROOT

STATUS = 'DRAFT_PENDING_REVIEW'

def value_at(raw, path):
    current = raw
    for part in path.split('.'):
        current = current[int(part)] if isinstance(current, list) else current[part]
    return current

def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode('utf-8')).hexdigest()

def validate_article(db, article):
    source = db.execute('SELECT * FROM source_records WHERE object_id=? AND source_id=? AND record_id=?',
                        (article['object_id'], article['source_id'], article['record_id'])).fetchone()
    if source is None:
        raise ValueError('Article requires an actual object/source identity')
    if source['record_url'] != article['source_url']:
        raise ValueError('Source URL does not match the imported record')
    raw = json.loads(source['raw_json']); claims = article['claims']
    if not claims or article['body'] != ''.join(c['text'] for c in claims):
        raise ValueError('Every narrative paragraph must have a cited claim; untraced text blocked')
    for claim in claims:
        if claim['kind'] not in ('SOURCE_SUMMARY', 'CAUTIOUS_INTERPRETATION', 'UNKNOWN_NOTICE'):
            raise ValueError('Unknown claim kind')
        if not claim.get('text') or not claim.get('evidence'):
            raise ValueError('Unsourced historical assertion blocked')
        for evidence in claim['evidence']:
            if value_at(raw, evidence['path']) != evidence['value']:
                raise ValueError('Evidence does not match source field')
        if claim['kind'] == 'CAUTIOUS_INTERPRETATION' and not claim.get('uncertainty_note'):
            raise ValueError('Interpretation requires explicit uncertainty')
    if article['review_status'] != STATUS or article.get('ai_generated') is not True:
        raise ValueError('AI imports remain drafts; human review is a separate audited action')
    if not 150 <= len(article['body']) <= 360:
        raise ValueError('Draft is outside the short encyclopedia range')
    obj = db.execute('SELECT primary_name FROM collection_objects WHERE object_id=?',(article['object_id'],)).fetchone()
    if article['original_name'] != obj[0]:
        raise ValueError('Official original name must be retained')
    for oid in article['related_object_ids']:
        if not db.execute('SELECT 1 FROM collection_objects WHERE object_id=?',(oid,)).fetchone():
            raise ValueError('Untraceable related object')
    return digest(article)

def load_articles(db, path=ROOT/'editorial/articles.json'):
    articles = json.loads(path.read_text(encoding='utf-8'))
    # Validate entire batch before a transaction; reviewed rows are never overwritten by a rebuild.
    hashes = [validate_article(db, a) for a in articles]
    if len({a['article_id'] for a in articles}) != len(articles):
        raise ValueError('Duplicate editorial article ID')
    db.execute('SAVEPOINT editorial_import')
    try:
        for a, sha in zip(articles, hashes):
            db.execute('''INSERT INTO editorial_articles(article_id,object_id,zh_name,original_name,object_type,civilization_or_geology,material,technique_or_preservation,body,claims_json,related_object_ids,confidence,review_status,ai_generated,reviewer,review_note,content_sha256) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                          ON CONFLICT(article_id) DO UPDATE SET zh_name=excluded.zh_name, body=excluded.body,
                          claims_json=excluded.claims_json, content_sha256=excluded.content_sha256
                          WHERE editorial_articles.review_status='DRAFT_PENDING_REVIEW' AND editorial_articles.editor_locked=0 AND editorial_articles.editor_version=1 ''',
                       (a['article_id'], a['object_id'], a['zh_name'], a['original_name'], a['object_type'],
                        a['civilization_or_geology'], a['material'], a['technique_or_preservation'], a['body'],
                        json.dumps(a['claims'],ensure_ascii=False), json.dumps(a['related_object_ids']),
                        a['confidence'], STATUS, 1, None, None, sha))
            for index, claim in enumerate(a['claims']):
                db.execute('INSERT OR IGNORE INTO editorial_article_sources VALUES(?,?,?,?,?)',
                           (a['article_id'], index, a['source_id'], a['record_id'], a['source_url']))
        db.execute('RELEASE editorial_import')
    except Exception:
        db.execute('ROLLBACK TO editorial_import'); db.execute('RELEASE editorial_import'); raise
    return len(articles)
