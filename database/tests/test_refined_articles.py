import json,unittest
from database.schema.migrate import init_db,ROOT
from database.preview.__main__ import prepare_content
from database.editorial.content import load_articles,validate_article
from database.editorial.versions import load_refinements,review_details
class RefinedTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db=init_db(':memory:');prepare_content(cls.db);cls.rows=json.loads((ROOT/'editorial/refined_articles.json').read_text(encoding='utf-8'))
    @classmethod
    def tearDownClass(cls):cls.db.close()
    def test_thirty_distinct_versioned_drafts(self):
        self.assertEqual(30,len(self.rows));self.assertEqual(60,self.db.execute('SELECT count(*) FROM editorial_versions').fetchone()[0])
        for a in self.rows:
            self.assertTrue(200<=len(a['body'])<=350);validate_article(self.db,a)
            r=self.db.execute('SELECT * FROM editorial_articles WHERE article_id=?',(a['article_id'],)).fetchone();self.assertEqual(2,r['editor_version']);self.assertEqual('DRAFT_PENDING_REVIEW',r['review_status'])
    def test_original_not_overwritten(self):
        for a in self.rows:self.assertEqual(a['original_name'],self.db.execute('SELECT primary_name FROM collection_objects WHERE object_id=?',(a['object_id'],)).fetchone()[0])
    def test_claims_diffs_and_names_traceable(self):
        for a in self.rows:
            detail=review_details(self.db,a['article_id']);self.assertTrue(detail['diff']);self.assertEqual(3,len(detail['claims']));self.assertTrue(detail['content_sha256']);self.assertEqual(a['source_url'],detail['name_source']['source_url'])
    def test_pending_human_lock_survives_seed_import(self):
        aid=self.rows[0]['article_id'];self.db.execute('SAVEPOINT human_editor')
        self.db.execute('UPDATE editorial_articles SET editor_locked=1,body=?,content_sha256=? WHERE article_id=?',('Human edit','human_hash',aid))
        load_articles(self.db);load_refinements(self.db)
        self.assertEqual('Human edit',self.db.execute('SELECT body FROM editorial_articles WHERE article_id=?',(aid,)).fetchone()[0])
        self.db.execute('ROLLBACK TO human_editor');self.db.execute('RELEASE human_editor')
    def test_base_import_does_not_revert_v2(self):
        before=[tuple(r) for r in self.db.execute('SELECT article_id,body,editor_version FROM editorial_articles ORDER BY article_id')]
        load_articles(self.db);load_refinements(self.db)
        self.assertEqual(before,[tuple(r) for r in self.db.execute('SELECT article_id,body,editor_version FROM editorial_articles ORDER BY article_id')])
