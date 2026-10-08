import copy,json,sqlite3,unittest
from database.schema.migrate import init_db,ROOT
from database.rebuild_catalog import rebuild_catalog
from database.editorial.content import load_articles
from database.editorial.terms import load_terms,build_tags
from database.planning.candidates import load_candidates,validate_candidate
from database.exports.curation import load_reviewed_games
from database.exports.export_godot_catalog import export_catalog
from database.exports.world_policy import reference_time_issues
class CandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.db=init_db(':memory:');rebuild_catalog(cls.db);load_terms(cls.db);build_tags(cls.db);load_articles(cls.db);load_reviewed_games(cls.db)
        cls.before=export_catalog(cls.db)[0];load_candidates(cls.db)
        cls.rows=json.loads((ROOT/'planning/candidates.json').read_text(encoding='utf-8'))
    @classmethod
    def tearDownClass(cls):cls.db.close()
    def test_five_hundred_actual_proposals(self):
        self.assertEqual(500,len(self.rows));self.assertEqual(500,len({r['object_id'] for r in self.rows}))
        self.assertEqual({'CHINA':300,'WORLD':140,'NATURAL':60},{k:sum(r['cohort']==k for r in self.rows) for k in ['CHINA','WORLD','NATURAL']})
        for r in self.rows:validate_candidate(self.db,r)
    def test_candidate_release_isolation(self):
        self.assertEqual(self.before,export_catalog(self.db)[0])
        expected=json.loads((ROOT.parent/'data/catalog/global_catalog.json').read_text(encoding='utf-8'))
        self.assertEqual(expected,export_catalog(self.db)[0])
        self.assertEqual(8,self.db.execute('SELECT count(*) FROM game_collection_definitions').fetchone()[0])
    def test_ai_and_numeric_validation_cannot_approve(self):
        c=copy.deepcopy(self.rows[0]);c['status']='APPROVED'
        with self.assertRaises(ValueError):validate_candidate(self.db,c)
        c=copy.deepcopy(self.rows[0]);c['reviews']['history']='PASSED'
        with self.assertRaises(ValueError):validate_candidate(self.db,c)
        with self.assertRaises(sqlite3.IntegrityError):self.db.execute("UPDATE game_collection_candidates SET status='APPROVED'")
    def test_large_transport_not_hand_carry(self):
        large=[r for r in self.rows if r['suggested_slots']>8]
        self.assertGreater(len(large),0)
        for r in large:self.assertEqual('EXPEDITION_TRANSPORT',r['transport_mode'])
        c=copy.deepcopy(large[0]);c['transport_mode']='HAND_CARRY'
        with self.assertRaises(ValueError):validate_candidate(self.db,c)
    def test_unknown_scientific_identification_remains_pending(self):
        fossil=[r for r in self.rows if r['category']=='FOSSIL_SPECIMEN']
        self.assertGreaterEqual(len(fossil),20)
        for r in fossil:
            self.assertEqual('CANDIDATE',r['status'])
            self.assertTrue(any('scientific_name_not_known' in x for x in r['world_1933']['issues']))
    def test_1933_filters_real_specific_specimens(self):
        late=[r for r in self.rows if 'specific_specimen_collected_after_1933' in r['world_1933']['issues']]
        self.assertGreater(len(late),0)
        for r in late:self.assertEqual('BLOCKED_SPECIFIC_IDENTITY',r['world_1933']['status'])
        oid=self.rows[0]['object_id'];self.db.execute('SAVEPOINT chronology_fixture');self.db.execute('INSERT OR REPLACE INTO cultural_heritage(object_id,year_start,year_end) VALUES(?,?,?)',(oid,1950,1951))
        self.assertTrue(any('creation_after' in x for x in reference_time_issues(self.db,oid)))
        self.db.execute('ROLLBACK TO chronology_fixture');self.db.execute('RELEASE chronology_fixture')
    def test_bad_values_unknown_regions_and_unlicensed_media_are_not_released(self):
        c=copy.deepcopy(self.rows[0]);c['suggested_value']=10**8
        with self.assertRaises(ValueError):validate_candidate(self.db,c)
        c=copy.deepcopy(self.rows[0]);c['obtain_regions']=[]
        with self.assertRaises(ValueError):validate_candidate(self.db,c)
        self.assertTrue(all(not r['media_assets'] for r in self.rows))
