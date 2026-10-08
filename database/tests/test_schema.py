import sqlite3
import tempfile
import unittest
from pathlib import Path
from database.schema.migrate import ROOT, init_db, migrate, seed_vocab

class SchemaTests(unittest.TestCase):
    def setUp(self):
        self.db = init_db(':memory:')
    def tearDown(self):
        self.db.close()
    def object(self, id, kind='CULTURAL_HERITAGE', category='ARTWORK'):
        self.db.execute('INSERT INTO collection_objects(object_id,object_kind,category_id,primary_name,license_status,verification_status) VALUES(?,?,?,?,?,?)',
                        (id, kind, category, 'Same name', 'CC0', 'SOURCE_VERIFIED'))
    def test_global_separate_time(self):
        self.assertGreaterEqual(self.db.execute('SELECT count(*) FROM cultures').fetchone()[0], 4)
        self.assertEqual(self.db.execute("SELECT year_start FROM human_chronology WHERE period_id='HAN'").fetchone()[0], -205)
        self.assertEqual(self.db.execute("SELECT age_max_ma FROM geological_timescale WHERE period_id='JURASSIC'").fetchone()[0], 201.4)
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO human_chronology(period_id) VALUES('JURASSIC')")
    def test_same_name_distinct_objects_and_nulls(self):
        self.object('one'); self.object('two')
        self.assertEqual(self.db.execute('SELECT count(*) FROM collection_objects').fetchone()[0], 2)
        self.assertIsNone(self.db.execute('SELECT museum_id FROM collection_objects LIMIT 1').fetchone()[0])
    def test_natural_extensions_are_not_artifacts(self):
        self.object('fossil', 'NATURAL_HISTORY', 'FOSSIL_SPECIMEN')
        self.db.execute("INSERT INTO fossil_specimens(object_id) VALUES('fossil')")
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO cultural_heritage(object_id) VALUES('fossil')")
    def test_checks_reject_invalid_ranges_and_foreign_keys(self):
        self.object('a')
        for query in ["INSERT INTO cultural_heritage(object_id,year_start,year_end) VALUES('a',2000,1000)",
                      "INSERT INTO object_materials VALUES('a','MISSING')",
                      "INSERT INTO geological_timescale VALUES('JURASSIC','PERIOD',200,100,'test')"]:
            with self.assertRaises(sqlite3.IntegrityError): self.db.execute(query)
    def test_repeat_migration_and_vocab_is_idempotent(self):
        before = self.db.execute('SELECT count(*) FROM vocab_names').fetchone()[0]
        migrate(self.db); seed_vocab(self.db)
        self.assertEqual(before, self.db.execute('SELECT count(*) FROM vocab_names').fetchone()[0])
        self.assertEqual(1, self.db.execute('SELECT count(*) FROM schema_migrations').fetchone()[0])
    def test_migration_tampering_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / '001_global_schema.sql'
            p.write_text((ROOT / 'schema/001_global_schema.sql').read_text() + '\n-- changed\n')
            with self.assertRaisesRegex(ValueError, 'modified'): migrate(self.db, tmp)
    def test_failed_migration_rolls_back(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = ROOT / 'schema/001_global_schema.sql'
            (Path(tmp) / source.name).write_bytes(source.read_bytes())
            (Path(tmp) / '002_broken.sql').write_text('CREATE TABLE should_rollback(a);\nINVALID SQL;\n')
            with self.assertRaises(sqlite3.OperationalError): migrate(self.db, tmp)
        self.assertIsNone(self.db.execute("SELECT name FROM sqlite_master WHERE name='should_rollback'").fetchone())
    def test_all_specializations_and_fts_available(self):
        tables = {r[0] for r in self.db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        for name in ('mineral_specimens','meteorite_specimens','rock_specimens','biological_specimens','occurrences','field_evidence','media','catalogue_fts'):
            self.assertIn(name, tables)
    def test_media_explicit_unknown_license(self):
        row = self.db.execute("SELECT commercial_allowed FROM licenses WHERE license_id='UNKNOWN'").fetchone()
        self.assertIsNone(row[0])
        self.assertEqual(0, self.db.execute("SELECT commercial_allowed FROM licenses WHERE license_id='CC_BY_NC'").fetchone()[0])
