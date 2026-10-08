import copy,json,tempfile,unittest
from pathlib import Path
from database.schema.migrate import init_db,ROOT
from database.preview.__main__ import prepare_content,preview_payload
from database.exhibitions.definitions import load_exhibitions
from database.exports.export_godot_catalog import export_catalog
class ExhibitionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db=init_db(':memory:');prepare_content(cls.db);cls.rows=json.loads((ROOT/'exhibitions/definitions.json').read_text(encoding='utf-8'))
    @classmethod
    def tearDownClass(cls):cls.db.close()
    def test_four_eight_object_proposals(self):
        self.assertEqual(4,len(self.rows))
        for e in self.rows:
            self.assertEqual(8,len(set(e['featured_object_ids'])));self.assertEqual('DRAFT_PENDING_REVIEW',e['curation_status']);self.assertEqual(e['reading_order'],e['featured_object_ids'])
    def test_ids_and_sources_exist(self):
        for e in self.rows:
            for oid in e['featured_object_ids']:self.assertIsNotNone(self.db.execute('SELECT 1 FROM collection_objects WHERE object_id=?',(oid,)).fetchone())
            for aid in e['related_article_ids']:self.assertIsNotNone(self.db.execute('SELECT 1 FROM editorial_articles WHERE article_id=?',(aid,)).fetchone())
    def test_egypt_not_byzantine_or_roman_findspot_only(self):
        e=next(e for e in self.rows if e['exhibition_id']=='ancient_egypt')
        for oid in e['featured_object_ids']:
            raw=json.loads(self.db.execute('SELECT raw_json FROM source_records WHERE object_id=?',(oid,)).fetchone()[0]);culture=';'.join(raw['culture']).lower()
            self.assertIn('egypt',culture);self.assertFalse(any(w in culture for w in ['byzant','coptic','greco-roman','ptolemaic','abbasid','fatimid']))
    def test_no_approval_or_invalid_reference(self):
        for kind in ['status','id']:
            rows=copy.deepcopy(self.rows)
            if kind=='status':rows[0]['curation_status']='REVIEWED'
            else:rows[0]['featured_object_ids'][0]='fake';rows[0]['reading_order'][0]='fake'
            with tempfile.TemporaryDirectory() as tmp:
                p=Path(tmp)/'bad.json';p.write_text(json.dumps(rows),encoding='utf-8')
                with self.assertRaises(ValueError):load_exhibitions(self.db,p)
    def test_preview_and_release_isolation(self):
        self.assertEqual(4,len(preview_payload(self.db)['exhibitions']))
        expected=json.loads((ROOT.parent/'data/catalog/global_catalog.json').read_text(encoding='utf-8'));self.assertEqual(expected,export_catalog(self.db)[0])
        self.assertEqual(1441,self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0])
