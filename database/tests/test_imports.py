import copy
import json
import sqlite3
import unittest
from database.schema.migrate import ROOT, init_db
from database.importers.store import import_rows, load_sources
from database.importers.registry import ADAPTERS
from database.query import build_index, search_catalog
from database.validators.quality import validate_db

FILES={'CMA':'cma_seed.jsonl','GBIF':'gbif_nhm_fossil_seed.jsonl','SMITHSONIAN':'smithsonian_natural_seed.jsonl','MET':'met_seed.jsonl','AIC':'aic_seed.jsonl'}
def seed_rows(source):
    return [json.loads(line) for line in (ROOT/'samples'/FILES[source]).read_text(encoding='utf-8').splitlines()]

def rebuild(db):
    reports=[import_rows(db,key,seed_rows(key)) for key in FILES]
    build_index(db)
    return reports

class ImportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalogue=init_db(':memory:');cls.reports=rebuild(cls.catalogue)
    @classmethod
    def tearDownClass(cls):cls.catalogue.close()
    def setUp(self):self.db=init_db(':memory:');load_sources(self.db)
    def tearDown(self):self.db.close()
    def test_real_verified_seed_count_and_sources(self):
        self.assertEqual(161,self.catalogue.execute('SELECT count(*) FROM collection_objects').fetchone()[0])
        self.assertTrue(all(r['errors']==0 and r['unknown_license']==0 for r in self.reports))
        for row in self.catalogue.execute('SELECT * FROM source_records'):
            self.assertTrue(row['record_url'].startswith(('https://','http://')))
            self.assertEqual(row['license_id'],'CC0')
            self.assertTrue(row['payload_sha256'] and row['checked_at'] and row['fetched_at'])
        self.assertEqual([],validate_db(self.catalogue)['errors'])
    def test_repeat_import_no_duplicates(self):
        rows=seed_rows('CMA')[:2]
        self.assertEqual(2,import_rows(self.db,'CMA',rows)['succeeded'])
        self.assertEqual(2,import_rows(self.db,'CMA',rows)['duplicates'])
        self.assertEqual(2,self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0])
    def test_changed_media_rights_are_not_grandfathered(self):
        raw=copy.deepcopy(seed_rows('CMA')[0]['record'])
        raw['images']={'web':{'url':'https://example.test/cma-image'}};raw['share_license_status']='CC0'
        import_rows(self.db,'CMA',[raw])
        self.assertEqual('VERIFIED',self.db.execute('SELECT verification_status FROM media').fetchone()[0])
        raw['share_license_status']='Copyrighted'
        import_rows(self.db,'CMA',[raw])
        self.assertEqual(('UNKNOWN','UNVERIFIED'),tuple(self.db.execute('SELECT license_id,verification_status FROM media').fetchone()))
    def test_old_normalizer_replays_without_reset_or_losing_curator(self):
        rows=seed_rows('CMA')[:1];import_rows(self.db,'CMA',rows)
        self.db.execute('UPDATE source_records SET normalizer_version=0')
        self.db.execute("UPDATE collection_objects SET editor_locked=1,description='Keep curator' ")
        self.assertEqual(1,import_rows(self.db,'CMA',rows)['succeeded'])
        self.assertEqual('Keep curator',self.db.execute('SELECT description FROM collection_objects').fetchone()[0])
        self.assertEqual(2,self.db.execute('SELECT normalizer_version FROM source_records').fetchone()[0])
    def test_names_are_not_identity_and_exact_accession_links(self):
        raw=copy.deepcopy(seed_rows('CMA')[0]['record']);raw['title']='Same name';raw['id']=1000001;raw['accession_number']='unit.a'
        second=dict(raw,id=1000002,accession_number='unit.b')
        third=dict(raw,id=1000003)
        self.assertEqual(3,import_rows(self.db,'CMA',[raw,second,third])['succeeded'])
        self.assertEqual(2,self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0])
        self.assertEqual(1,self.db.execute('SELECT count(*) FROM duplicate_candidates').fetchone()[0])
        self.assertEqual(3,self.db.execute('SELECT count(*) FROM source_records').fetchone()[0])
    def test_curator_fields_never_overwritten(self):
        raw=copy.deepcopy(seed_rows('CMA')[0]['record']);import_rows(self.db,'CMA',[raw])
        oid=self.db.execute('SELECT object_id FROM collection_objects').fetchone()[0]
        self.db.execute("UPDATE collection_objects SET description='Curator text',primary_name='审订名称',editor_locked=1 WHERE object_id=?",(oid,))
        self.db.execute("INSERT INTO object_names VALUES(?,'zh-Hans','PRIMARY','玉璧','curated',1,NULL,NULL)",(oid,))
        raw['description']='Changed provider description';raw['title']='Changed provider name'
        import_rows(self.db,'CMA',[raw]);build_index(self.db)
        self.assertEqual(('审订名称','Curator text'),tuple(self.db.execute('SELECT primary_name,description FROM collection_objects').fetchone()))
        self.assertEqual(1,len(search_catalog(self.db,'玉璧')))
        self.assertEqual(1,len(search_catalog(self.db,'审订')))
        self.assertEqual(1,self.db.execute("SELECT curator_locked FROM object_names WHERE language='zh-Hans'").fetchone()[0])
    def test_same_taxon_is_multiple_real_specimens(self):
        rows=seed_rows('GBIF')[:2]
        import_rows(self.db,'GBIF',rows)
        self.assertEqual(2,self.db.execute('SELECT count(*) FROM fossil_specimens').fetchone()[0])
        self.assertEqual(2,self.db.execute('SELECT count(*) FROM occurrences').fetchone()[0])
    def test_occurrence_and_taxon_do_not_create_collection_object(self):
        record={'oid':'occ:unit','tid':'txn:1','tna':'Unit taxon','license':'CC0'}
        report=import_rows(self.db,'PBDB',[record])
        self.assertEqual(1,report['skipped']);self.assertEqual(0,report['errors'])
        self.assertEqual(0,self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0])
        self.assertEqual(1,self.db.execute('SELECT count(*) FROM occurrences').fetchone()[0])
    def test_invalid_row_rolls_back_and_reports(self):
        report=import_rows(self.db,'CMA',[{'id':1}])
        self.assertEqual(1,report['errors'])
        self.assertEqual(0,self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0])
        self.assertEqual(1,self.db.execute('SELECT count(*) FROM import_errors').fetchone()[0])
    def test_no_invented_fossil_discovery_dates(self):
        row=seed_rows('GBIF')[0]
        import_rows(self.db,'GBIF',[row])
        self.assertIsNone(self.db.execute('SELECT discovery_year FROM fossil_specimens').fetchone()[0])
        self.assertIsNone(self.db.execute('SELECT age_min_ma FROM fossil_specimens').fetchone()[0])
    def test_search_filters_and_safe_inputs(self):
        b=self.catalogue
        for filt in ({'kind':'NATURAL_HISTORY'},{'category':'METEORITE'},{'culture':'China'},{'material':'JADE'},
                     {'geological_period':'JURASSIC'},{'historical_period':'HAN'},{'institution':'MET'},{'license':'CC0'},{'region':'United States'},
                     {'media_license':'CC0'}):self.assertGreater(len(search_catalog(b,**filt)),0,filt)
        self.assertEqual([],search_catalog(b,"' OR 1=1 --"))
        with self.assertRaises(ValueError):search_catalog(b,invalid_column='x')
    def test_independent_adapters_registered(self):
        self.assertEqual(9,len(ADAPTERS))
        for key in FILES:
            normalized=ADAPTERS[key](seed_rows(key)[0]['record']);normalized.validate()
        with self.assertRaises(ValueError):ADAPTERS['WENWU']({'id':'unlicensed'})
    def test_traditional_names_keep_source_language(self):
        row={'id':'unit','title':'傳統名稱','source_url':'https://digitalarchive.npm.gov.tw/unit','data_license':'CC-BY-4.0'}
        self.assertEqual(1,import_rows(self.db,'NPM',[row])['succeeded'])
        self.assertEqual(0,self.db.execute("SELECT count(*) FROM object_names WHERE language='en'").fetchone()[0])
        self.assertEqual(2,self.db.execute("SELECT count(*) FROM object_names WHERE language='zh-Hant'").fetchone()[0])
    def test_rebuild_logical_data_identical(self):
        rebuild(self.db)
        for table in ('collection_objects','cultural_heritage','fossil_specimens','mineral_specimens','meteorite_specimens','rock_specimens'):
            self.assertEqual([tuple(r) for r in self.catalogue.execute('SELECT * FROM '+table+' ORDER BY object_id')],
                             [tuple(r) for r in self.db.execute('SELECT * FROM '+table+' ORDER BY object_id')])
