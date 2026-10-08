"""Versioned AI drafts; preserve human edits even while still pending review."""
import json,difflib
from database.schema.migrate import ROOT
from database.editorial.content import digest,validate_article

def load_refinements(db,path=ROOT/'editorial/refined_articles.json'):
    base={a['article_id']:a for a in json.loads((ROOT/'editorial/articles.json').read_text(encoding='utf-8'))}
    rows=json.loads(path.read_text(encoding='utf-8'));report={'installed':0,'preserved':0}
    for a in rows:
        sha=validate_article(db,a);aid=a['article_id'];old=base[aid]
        if a['base_content_sha256']!=digest(old):raise ValueError('Revision base hash does not match')
        for version,payload in [(1,old),(2,a)]:
            existing=db.execute('SELECT content_sha256 FROM editorial_versions WHERE article_id=? AND version=?',(aid,version)).fetchone()
            if existing and existing[0]!=digest(payload):raise ValueError('Published editorial version is immutable; append a new version')
            db.execute('INSERT OR IGNORE INTO editorial_versions VALUES(?,?,?,?,?,?)',(aid,version,json.dumps(payload,ensure_ascii=False),digest(payload),'AI','DRAFT_PENDING_REVIEW'))
        current=db.execute('SELECT * FROM editorial_articles WHERE article_id=?',(aid,)).fetchone()
        if current['editor_locked'] or current['review_status']!='DRAFT_PENDING_REVIEW' or current['content_sha256'] not in (digest(old),sha):
            report['preserved']+=1;continue
        db.execute('UPDATE editorial_articles SET zh_name=?,body=?,claims_json=?,content_sha256=?,editor_version=2 WHERE article_id=?',(a['zh_name'],a['body'],json.dumps(a['claims'],ensure_ascii=False),sha,aid))
        for index,claim in enumerate(a['claims']):db.execute('INSERT OR IGNORE INTO editorial_article_sources VALUES(?,?,?,?,?)',(aid,index,a['source_id'],a['record_id'],a['source_url']))
        report['installed']+=1
    return report

def review_details(db,aid):
    versions=[json.loads(r[0]) for r in db.execute('SELECT payload_json FROM editorial_versions WHERE article_id=? ORDER BY version',(aid,))]
    if not versions:return None
    new=versions[-1];old=versions[0]
    return dict(version=new['version'],content_sha256=digest(new),name_source=new['name_source'],translation_confidence=new['translation_confidence'],scientific_name=new['scientific_name'],human_confirmation_needed=new['human_confirmation_needed'],claims=new['claims'],source_url=new['source_url'],diff='\n'.join(difflib.unified_diff(old['body'].splitlines(),new['body'].splitlines(),fromfile='10B v1',tofile='10C v2',lineterm='')))
