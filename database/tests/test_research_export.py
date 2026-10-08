import unittest,json,tempfile
from pathlib import Path
from database.schema.migrate import init_db
from database.preview.__main__ import prepare_content
from database.exports.export_research_catalog import build_catalog,export,export_exhibitions
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
 def test_media_is_verified_portable_subset(self):
  data,_=build_catalog(self.db);self.assertEqual(len(data['media']),2)
  for media in data['media']:
   self.assertEqual(media['license_id'],'CC0');self.assertTrue(media['asset_path'].startswith('res://assets/catalog/'));self.assertTrue(media['attribution']);self.assertEqual(len(media['sha256']),64)
 def test_exhibitions_reuse_existing_definitions(self):
  with tempfile.TemporaryDirectory() as tmp:
   data=export_exhibitions(self.db,Path(tmp)/'plans.json');self.assertEqual(len(data['exhibitions']),4)
   official=json.loads(Path('database/exhibitions/definitions.json').read_text(encoding='utf-8'))
   self.assertEqual(sorted(data['exhibitions'],key=lambda r:r['exhibition_id']),sorted(official,key=lambda r:r['exhibition_id']))
 def test_determinism(self):
  with tempfile.TemporaryDirectory() as tmp:
   a=Path(tmp)/'a.json';b=Path(tmp)/'b.json';export(self.db,a,Path(tmp)/'report');export(self.db,b,Path(tmp)/'report');self.assertEqual(a.read_bytes(),b.read_bytes())
if __name__=='__main__':unittest.main()
