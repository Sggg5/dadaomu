import unittest,json,tempfile
from pathlib import Path
from database.schema.migrate import init_db
from database.preview.__main__ import prepare_content
from database.exports.export_research_catalog import build_catalog,export
class ResearchExportTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.db=init_db(':memory:');prepare_content(cls.db)
 @classmethod
 def tearDownClass(cls):cls.db.close()
 def test_counts_and_scopes(self):
  data,report=build_catalog(self.db);self.assertEqual(len(data['records']),1441);self.assertEqual(len(data['articles']),100);self.assertEqual(report['excluded_records'],0);self.assertNotIn('game_definitions',data);self.assertNotIn('candidates',data)
 def test_identity_and_unknowns(self):
  data,_=build_catalog(self.db);self.assertEqual(len(set(r['object_id'] for r in data['records'])),1441);self.assertTrue(any(r['material'] is None for r in data['records']));self.assertTrue(all(a['review_status']=='DRAFT_PENDING_REVIEW' for a in data['articles']))
 def test_determinism(self):
  with tempfile.TemporaryDirectory() as tmp:
   a=Path(tmp)/'a.json';b=Path(tmp)/'b.json';export(self.db,a,Path(tmp)/'report');export(self.db,b,Path(tmp)/'report');self.assertEqual(a.read_bytes(),b.read_bytes())
if __name__=='__main__':unittest.main()
