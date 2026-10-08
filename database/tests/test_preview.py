import json,re,unittest,tempfile
from pathlib import Path
from database.schema.migrate import ROOT,init_db
from database.preview.__main__ import prepare_content,export_preview,preview_payload
from database.validators.content_quality import content_report
from database.editorial.terms import match_term
class PreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db=init_db(':memory:');prepare_content(cls.db)
    @classmethod
    def tearDownClass(cls):cls.db.close()
    def test_quality_report_not_approval(self):
        r=content_report(self.db);self.assertEqual([],r['errors']);self.assertEqual('NOT_PERFORMED',r['human_review'])
        self.assertEqual(4,r['profile_version']);self.assertEqual(100,r['drafts']);self.assertEqual(500,r['candidates'])
    def test_repeat_deterministic_export(self):
        with tempfile.TemporaryDirectory() as tmp:
            a=Path(tmp)/'a.html';b=Path(tmp)/'b.html';export_preview(self.db,a);prepare_content(self.db);export_preview(self.db,b)
            self.assertEqual(a.read_bytes(),b.read_bytes())
    def test_offline_csp_no_remote_assets(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'index.html';export_preview(self.db,p);s=p.read_text(encoding='utf-8')
            self.assertIn("connect-src 'none'",s);self.assertNotRegex(s,r'<iframe\b|<script[^>]*\bsrc=|<img[^>]*src=[\"\']https?://')
            encoded=re.search(r'<script id="catalog-data" type="application/json">(.*?)</script>',s,re.S)[1]
            data=json.loads(encoded);self.assertEqual(1441,len(data['objects']));self.assertEqual(8,data['released_count'])
    def test_source_script_injection_remains_text(self):
        oid=self.db.execute('SELECT object_id FROM collection_objects LIMIT 1').fetchone()[0]
        self.db.execute('SAVEPOINT malicious_title');self.db.execute('UPDATE collection_objects SET primary_name=? WHERE object_id=?',('</script><script>alert(1)</script>',oid))
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'index.html';export_preview(self.db,p);s=p.read_text(encoding='utf-8');self.assertNotIn('</script><script>alert',s)
        self.db.execute('ROLLBACK TO malicious_title');self.db.execute('RELEASE malicious_title')
    def test_ambiguous_terms_require_scope(self):
        with self.assertRaises(ValueError):match_term(self.db,'gui')
        self.assertEqual('GUI_JADE',match_term(self.db,'gui','JADE_OBJECT')['term_id'])
    def test_layers_and_unique_ids(self):
        p=preview_payload(self.db)
        self.assertTrue(all(o['status']=='NORMALIZED' for o in p['objects']))
        self.assertTrue(all(a['status'].startswith('EDITORIAL_DRAFT') for a in p['articles']))
        self.assertTrue(all(c['status']=='CANDIDATE' for c in p['candidates']))
        self.assertEqual(500,len({c['game_id'] for c in p['candidates']}))
