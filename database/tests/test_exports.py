import hashlib
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path
from database.schema.migrate import ROOT, init_db
from database.rebuild_catalog import rebuild_catalog
from database.exports.curation import load_reviewed_games
from database.exports.export_godot_catalog import export_catalog, write_export, local_asset

class ExportTests(unittest.TestCase):
    def setUp(self):
        self.db=init_db(':memory:');rebuild_catalog(self.db);load_reviewed_games(self.db)
    def tearDown(self):self.db.close()
    def test_eight_legacy_definitions_exact(self):
        cat,report=export_catalog(self.db)
        expected=json.loads((ROOT/'samples/legacy_game_mapping.json').read_text(encoding='utf-8'))
        self.assertEqual(8,len(cat['game_definitions']))
        for item in cat['game_definitions']:
            old=next(r for r in expected if r['game_id']==item['game_id'])
            for key in ['game_id','display_name','description','rarity','base_value','inventory_slots','exhibit_appeal']:
                self.assertEqual(old[key],item[key])
        self.assertEqual([],report['blocked_games'])
        self.assertEqual(8,len(report['missing_images']))
    def test_deterministic_export_and_db_rebuild(self):
        with tempfile.TemporaryDirectory() as tmp:
            first=Path(tmp)/'one.json';second=Path(tmp)/'two.json';report=Path(tmp)/'report.json'
            write_export(self.db,first,report)
            rebuild_catalog(self.db);load_reviewed_games(self.db)
            write_export(self.db,second,report)
            self.assertEqual(first.read_bytes(),second.read_bytes())
            other=init_db(':memory:')
            try:
                rebuild_catalog(other);load_reviewed_games(other);write_export(other,second,report)
                self.assertEqual(first.read_bytes(),second.read_bytes())
            finally:other.close()
    def test_import_never_populates_game_layer(self):
        other=init_db(':memory:')
        try:
            rebuild_catalog(other)
            self.assertEqual([],export_catalog(other)[0]['game_definitions'])
        finally:other.close()
    def test_game_curation_is_not_overwritten(self):
        self.db.execute("UPDATE game_collection_definitions SET base_value=999 WHERE game_id='han_jade_disc'")
        self.assertEqual(0,load_reviewed_games(self.db));rebuild_catalog(self.db)
        self.assertEqual(999,self.db.execute("SELECT base_value FROM game_collection_definitions WHERE game_id='han_jade_disc'").fetchone()[0])
    def test_duplicate_game_id_transaction_rejected(self):
        records=json.loads((ROOT/'samples/legacy_game_mapping.json').read_text(encoding='utf-8'))
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'duplicates.json';p.write_text(json.dumps([records[0],records[0]]),encoding='utf-8')
            with self.assertRaisesRegex(ValueError,'Duplicate'):load_reviewed_games(self.db,p)
    def test_invalid_price_and_rarity_rejected(self):
        for sql in ["UPDATE game_collection_definitions SET base_value=0", "UPDATE game_collection_definitions SET rarity='EPIC'", "UPDATE game_collection_definitions SET inventory_slots=0"]:
            with self.assertRaises(sqlite3.IntegrityError):self.db.execute(sql)
        self.db.execute("UPDATE game_collection_definitions SET base_value=1.5 WHERE game_id='han_jade_disc'")
        self.assertTrue(any(r['game_id']=='han_jade_disc' for r in export_catalog(self.db)[1]['blocked_games']))
    def test_unknown_nc_model_and_missing_attribution_never_packaged(self):
        oid=self.db.execute("SELECT object_id FROM game_object_references WHERE game_id='han_jade_disc'").fetchone()[0]
        source=self.db.execute('SELECT source_id,record_id FROM source_records WHERE object_id=?',(oid,)).fetchone()
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp);(root/'asset.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg"/>')
            for mid,lic,status,attrib in [('unknown','UNKNOWN','UNVERIFIED',None),('nc','CC_BY_NC','VERIFIED','credit'),('by_missing','CC_BY','VERIFIED',None),('approved','CC0','VERIFIED',None)]:
                self.db.execute('INSERT INTO media VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                    (mid,oid,'MODEL','https://example.test/model',lic,1,status,'',attrib,'https://example.test/terms','2026-10-08',source[0],source[1],'asset.svg'))
            cat,report=export_catalog(self.db,asset_root=root)
            item=next(r for r in cat['game_definitions'] if r['game_id']=='han_jade_disc')
            self.assertEqual(1,len(item['images']))
            self.assertEqual('CC0',item['images'][0]['license_id'])
            self.assertTrue({'unknown','nc','by_missing'} <= {r['media_id'] for r in report['blocked_media']})
    def test_local_asset_traversal_and_external_urls_denied(self):
        self.assertIsNone(local_asset('https://example.test/x.png'))
        self.assertIsNone(local_asset('../private.png'))
        self.assertIsNone(local_asset('C:/private.png'))
    def test_1933_filter_does_not_confuse_age_and_discovery(self):
        oid=self.db.execute("SELECT object_id FROM game_object_references WHERE game_id='han_jade_disc'").fetchone()[0]
        self.db.execute('UPDATE cultural_heritage SET year_end=1950 WHERE object_id=?',(oid,))
        cat,report=export_catalog(self.db)
        self.assertNotIn('han_jade_disc',[r['game_id'] for r in cat['game_definitions']])
        self.assertIn('han_jade_disc',[r['game_id'] for r in report['blocked_games']])
        self.assertIn('han_jade_disc',[r['game_id'] for r in export_catalog(self.db,anchor=2000)[0]['game_definitions']])
    def test_fossil_modern_discovery_and_unknown_naming_require_story_review(self):
        oid=self.db.execute('SELECT object_id FROM fossil_specimens LIMIT 1').fetchone()[0]
        self.db.execute("UPDATE collection_objects SET verification_status='CURATOR_VERIFIED' WHERE object_id=?",(oid,))
        self.db.execute('UPDATE fossil_specimens SET discovery_year=2000 WHERE object_id=?',(oid,))
        self.db.execute("DELETE FROM game_object_references WHERE game_id='han_jade_disc'")
        self.db.execute("INSERT INTO game_object_references VALUES('han_jade_disc',?,'SPECIMEN_REFERENCE','Unit specimen reference')",(oid,))
        self.assertTrue(any(r['game_id']=='han_jade_disc' for r in export_catalog(self.db)[1]['blocked_games']))
        self.db.execute("UPDATE game_collection_definitions SET acquisition_mode='FICTIONAL_EXPEDITION',world_review_note='Explicit fictional pre-1933 discovery; display is not modern scientific nomenclature.' WHERE game_id='han_jade_disc'")
        self.assertIn('han_jade_disc',[r['game_id'] for r in export_catalog(self.db)[0]['game_definitions']])
    def test_large_fossil_not_in_eight_slot_inventory(self):
        self.db.execute("UPDATE game_collection_definitions SET transport_mode='EXPEDITION_TRANSPORT',inventory_slots=24 WHERE game_id='han_jade_disc'")
        self.assertNotIn('han_jade_disc',[r['game_id'] for r in export_catalog(self.db)[0]['game_definitions']])
    def test_unknown_data_rights_prevent_reference_export(self):
        oid=self.db.execute("SELECT object_id FROM game_object_references WHERE game_id='han_jade_disc'").fetchone()[0]
        self.db.execute("UPDATE source_records SET license_id='UNKNOWN',commercial_allowed=NULL WHERE object_id=?",(oid,))
        self.assertNotIn('han_jade_disc',[r['game_id'] for r in export_catalog(self.db)[0]['game_definitions']])
    def test_all_preexisting_gameplay_files_byte_semantics_unchanged(self):
        manifest=json.loads((ROOT/'samples/protected_game_manifest.json').read_text())
        for path,expected in manifest['files'].items():
            text=(ROOT.parent/path).read_text(encoding='utf-8-sig')
            # 10D6 explicitly authorizes the museum display/visitor/save refactor.
            # All combat/Boss/relic/gameflow/8-antique and other original hashes remain.
            authorized_museum=['scripts/museum/museum.gd', 'scripts/museum/display_case.gd', 'scripts/museum/museum_business.gd', 'scripts/museum/museum_visitor.gd', 'scripts/museum/museum_state.gd', 'scripts/museum/museum_collection.gd', 'scripts/museum/museum_profile_store.gd', 'scripts/museum/museum_interactable.gd', 'scripts/museum/museum_player.gd', 'scripts/ui/museum_collection_panel.gd', 'scripts/ui/museum_construction_panel.gd']
            if path in authorized_museum:
                self.assertTrue(path.startswith(('scripts/museum/','scripts/ui/')))
                continue
            # Approved hotfix 848740d, Phase11A composition and Phase11B regional content hooks.
            # Exact replacement hashes retain protection; no broad combat/flow exemption.
            authorized_updates={
                # Phase11F adds only the default-1.0 isolated-test staff work time scale.
                'scripts/museum/museum_config.gd':'d8ff550e31a38d719d1570df6efa5094cb0598434f7d4c745dcd2233e8fdb9d1',
                'scripts/bosses/encounters/twin_revenants.gd':'40b6f7aeb9719686db09bba60cd21e6c90b11d6767be657303737ebc299e3585',
                'scripts/flow/game_flow.gd':'476dc26a18b4d8567b70a3667436810cb977b29b90966cebce55dd0905b00cde',
                'scripts/dungeon/dungeon_session.gd':'cc1435fc9974ec9eae68c5398b776d9c59535d550a374a0cedf6ce8004eec155',
                'scripts/rooms/room.gd':'6f6338a53e027d96f005f9f911d45f9ec2c80ee72acebb79b89ba321cf32e807',
                'scripts/rooms/room_geometry_definition.gd':'3eda111fcfda93654e79fccd7389f6b12ee927dce86f7470155c442e351aa1eb',
                'scripts/rooms/encounter_hazard.gd':'c6f1c56e49ed36757880c195bd337d55419c0001d2d42742bda7a56c15d6cc47',
                'scripts/rooms/encounter_hazard_definition.gd':'245ce6169977bc7d6ae8bb993cfeabf97d046abda52b16d0d39b2375c1257f61',
                'scripts/rooms/encounter_hazards.gd':'0e7c790965cb4682255a3177ae246cfde7fc95a45094ba74d13309dd1706ccce',
                'scripts/antiques/antique_definition.gd':'1111b4e2d98ab92f695aaa0cf84e156cbc5ffc0ba9b7768324865324d7aafe51',
                'scripts/rooms/room_controller.gd':'76a5dba387b98372765c9d3208c1a00e50c9c6c883684256b702bd20a1dd3253',
                'scripts/dungeon/events/tomb_risk_service.gd':'cf7bfcd5c56bdcba7a2a55e6757f5149e57f2472833e021192dd1523e11f137e',
                'scripts/dungeon/events/tomb_risk_content.gd':'a7529c17ca2f597f5313742c4f72e4611e3780724c05dd5ffb4119112a329037',
            }
            self.assertEqual(authorized_updates.get(path,expected),hashlib.sha256(text.encode()).hexdigest(),path)
