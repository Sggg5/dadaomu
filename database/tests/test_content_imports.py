import unittest
import json
from database.schema.migrate import init_db,ROOT
from database.rebuild_catalog import rebuild_catalog
from database.importers.store import import_rows
from database.importers.registry import ADAPTERS
from database.validators.quality import validate_db

class ContentImportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db=init_db(':memory:');cls.reports=rebuild_catalog(cls.db)
    @classmethod
    def tearDownClass(cls):cls.db.close()
    def test_actual_expansion_and_rights(self):
        self.assertGreaterEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],1000)
        self.assertTrue(all(r['errors']==0 and r['unknown_license']==0 for r in self.reports))
        self.assertEqual([],validate_db(self.db)['errors'])
        for r in self.db.execute('SELECT record_url,payload_sha256,license_id FROM source_records'):
            self.assertTrue(r['record_url'].startswith(('http://','https://')))
            self.assertTrue(r['payload_sha256']);self.assertIn(r['license_id'],('CC0','CC_BY'))
    def test_idempotence(self):
        before=self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0]
        reports=rebuild_catalog(self.db)
        self.assertTrue(all(r['succeeded']==0 and r['errors']==0 for r in reports))
        self.assertEqual(before,self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0])
    def test_paleobiology_is_not_automatically_fossil(self):
        raw=json.loads((ROOT/'samples/phase10b/smithsonian_nmnhpaleo.jsonl').read_text(encoding='utf-8').splitlines()[0])['record']
        indexed=raw['content']['indexedStructured'];indexed.pop('geo_age-system',None)
        free=raw['content']['freetext'];free['notes']=[r for r in free.get('notes',[]) if r.get('label')!='Geologic Age']
        with self.assertRaisesRegex(ValueError,'alone'):ADAPTERS['SMITHSONIAN'](raw)
    def test_fossil_unknown_discovery_not_collection_date(self):
        self.assertEqual(0,self.db.execute('SELECT count(*) FROM fossil_specimens WHERE discovery_year IS NOT NULL').fetchone()[0])
        self.assertGreater(self.db.execute('SELECT count(*) FROM fossil_specimens WHERE geological_period_id IS NOT NULL').fetchone()[0],0)
    def test_names_remain_distinct_identities(self):
        names=self.db.execute('SELECT primary_name FROM collection_objects GROUP BY primary_name HAVING count(*)>1').fetchall()
        self.assertGreater(len(names),0)
        # Same text never licenses an identity merge across institutions.
        rows=self.db.execute('SELECT museum_id,accession_number FROM collection_objects WHERE primary_name=?',(names[0][0],)).fetchall()
        self.assertGreater(len(rows),1)
