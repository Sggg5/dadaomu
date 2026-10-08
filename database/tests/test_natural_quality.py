import json,unittest
from collections import Counter
from database.schema.migrate import init_db
from database.rebuild_catalog import rebuild_catalog
from database.natural_history.audit import build_audits
from database.editorial.content import value_at
class NaturalQualityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db=init_db(':memory:');rebuild_catalog(cls.db);cls.rows=build_audits(cls.db,output=None)
    @classmethod
    def tearDownClass(cls):cls.db.close()
    def test_all_required_real_objects(self):
        self.assertEqual({'FOSSIL_SPECIMEN':66,'MINERAL_SPECIMEN':13,'METEORITE':13,'ROCK_SPECIMEN':30},dict(Counter(a['category'] for a in self.rows)))
        self.assertEqual(1441,self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0])
    def test_literal_field_evidence(self):
        for a in self.rows:
            for field,values in a['fields'].items():
                for v in values:
                    if not v.get('source_id'):continue
                    raw=json.loads(self.db.execute('SELECT raw_json FROM source_records WHERE source_id=? AND record_id=?',(v['source_id'],v['record_id'])).fetchone()[0])
                    if v['source_path'].startswith('dynamicProperties.') and isinstance(raw.get('dynamicProperties'),str):raw['dynamicProperties']=json.loads(raw['dynamicProperties'])
                    self.assertEqual(v['value'],value_at(raw,v['source_path']))
    def test_no_expert_approval_or_inferred_discovery(self):
        self.assertTrue(all(a['academic_review']=='NEEDS_REVIEW' for a in self.rows))
        self.assertTrue(all('discovery_year' in a['missing'] and 'named_year' in a['missing'] for a in self.rows if a['category']=='FOSSIL_SPECIMEN'))
        self.assertEqual(0,self.db.execute('SELECT count(*) FROM fossil_specimens WHERE discovery_year IS NOT NULL OR age_min_ma IS NOT NULL').fetchone()[0])
    def test_shared_meteorite_catalogue_conflicts(self):
        conflicts=[a for a in self.rows if 'SHARED_CATALOGUE_NUMBER_CONFLICTING_NAMES_OR_SUBSAMPLES' in a['issues']]
        self.assertGreaterEqual(len(conflicts),1)
        for a in conflicts:self.assertIn('CONFLICTING_SUBSAMPLE_MASSES_NOT_ONE_OBJECT_MEASUREMENT',a['issues'])
    def test_general_formula_not_specimen_measurement(self):
        self.assertEqual(2,self.db.execute('SELECT count(*) FROM natural_knowledge').fetchone()[0])
        self.assertEqual(0,self.db.execute('SELECT count(*) FROM mineral_specimens WHERE chemical_composition IS NOT NULL').fetchone()[0])
    def test_reimport_idempotent(self):
        rebuild_catalog(self.db);second=build_audits(self.db,output=None)
        self.assertEqual(self.rows,second)
