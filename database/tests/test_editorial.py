import copy,json,unittest
from database.schema.migrate import init_db,ROOT
from database.rebuild_catalog import rebuild_catalog
from database.editorial.content import load_articles,validate_article
from database.editorial.terms import load_terms,match_term,build_tags
class EditorialTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db=init_db(':memory:');rebuild_catalog(cls.db);load_terms(cls.db);build_tags(cls.db);load_articles(cls.db)
        cls.articles=json.loads((ROOT/'editorial/articles.json').read_text(encoding='utf-8'))
    @classmethod
    def tearDownClass(cls):cls.db.close()
    def test_one_hundred_traceable_ai_drafts(self):
        self.assertEqual(100,len(self.articles));self.assertEqual(100,self.db.execute('SELECT count(*) FROM editorial_articles').fetchone()[0])
        self.assertEqual(100,self.db.execute('SELECT count(*) FROM editorial_article_sources').fetchone()[0])
        for a in self.articles:
            validate_article(self.db,a);self.assertEqual('DRAFT_PENDING_REVIEW',a['review_status'])
    def test_no_source_or_untraced_text_blocked(self):
        for change in ['url','body','value','empty']:
            a=copy.deepcopy(self.articles[0])
            if change=='url':a['source_url']='https://example.test/invented'
            elif change=='body':a['body']+='某皇帝亲手制造。'
            elif change=='value':a['claims'][0]['evidence'][0]['value']='invented inscription'
            else:a['claims'][0]['evidence']=[]
            with self.assertRaises(ValueError):validate_article(self.db,a)
    def test_ai_draft_cannot_import_as_approved(self):
        a=copy.deepcopy(self.articles[0]);a['review_status']='REVIEWED'
        with self.assertRaises(ValueError):validate_article(self.db,a)
    def test_original_names_unmodified(self):
        for a in self.articles:self.assertEqual(a['original_name'],self.db.execute('SELECT primary_name FROM collection_objects WHERE object_id=?',(a['object_id'],)).fetchone()[0])
        self.assertEqual(0,self.db.execute("SELECT count(*) FROM object_names WHERE translation_status='AI_APPROVED'").fetchone()[0])
    def test_term_parents_and_aliases(self):
        self.assertEqual('BRONZE_VESSEL',match_term(self.db,'鼎')['parent_id'])
        self.assertEqual('CERAMIC_OBJECT',match_term(self.db,'Ding ware')['parent_id'])
        self.assertEqual('CRETACEOUS',match_term(self.db,'白垩纪')['term_id'])
        self.assertIsNone(match_term(self.db,'invented species'))
    def test_editorial_replay_preserves_reviewed_rows(self):
        a=self.articles[0];aid=a['article_id']
        self.db.execute("UPDATE editorial_articles SET review_status='REVIEWED',reviewer='fixture',review_note='Explicit test review',zh_name='Human locked' WHERE article_id=?",(aid,))
        load_articles(self.db)
        self.assertEqual('Human locked',self.db.execute('SELECT zh_name FROM editorial_articles WHERE article_id=?',(aid,)).fetchone()[0])
        self.db.execute("UPDATE editorial_articles SET review_status='DRAFT_PENDING_REVIEW',zh_name=? WHERE article_id=?",(a['zh_name'],aid))
    def test_fossils_preserve_unknown_and_controversy(self):
        for i in [70,85,86,88,90,96]:
            a=self.articles[i];self.assertIn(a['confidence'],('IDENTIFICATION_PENDING','UNCERTAIN_SOURCE_ATTRIBUTION'))
        self.assertIn('具体物种',self.articles[86]['body'])
