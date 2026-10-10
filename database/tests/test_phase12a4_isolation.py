from pathlib import Path
import hashlib,re,subprocess,unittest

ROOT=Path(__file__).resolve().parents[2]
BASE='18dffab07c93ff67df3cde0ded516f2aea1c492c'

class GeometryIsolationTests(unittest.TestCase):
    def test_formal_generation_save_and_pools_canonical_bytes_identical(self):
        paths=['scripts/dungeon/room_geometry_plan.gd','scripts/dungeon/dungeon_generator.gd',
               'scripts/dungeon/tomb_floor_generator.gd','scripts/rooms/room_geometry_validation.gd',
               'scripts/rooms/room_controller.gd','scripts/rooms/enemy_spawner.gd',
               'data/geometries/ordinary_pool.tres','data/tombs/default_tomb.tres',
               'scripts/ui/room_test_hud.gd','scripts/ui/relic_debug_panel.gd']
        paths+= [p.relative_to(ROOT).as_posix() for p in (ROOT/'data/geometries').glob('*.tres')]
        for path in paths:
            baseline=subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)
            # Git stores LF; this Windows checkout may legitimately contain CRLF.
            current=(ROOT/path).read_bytes().replace(b'\r\n',b'\n')
            self.assertEqual(hashlib.sha256(baseline.replace(b'\r\n',b'\n')).digest(),hashlib.sha256(current).digest(),path)

    def test_experimental_resources_never_referenced_by_production(self):
        for folder in ['scripts','scenes','data']:
            for path in (ROOT/folder).rglob('*'):
                if path.is_file() and path.suffix in ['.gd','.tres','.tscn','.json']:
                    self.assertNotIn('tests/fixtures/phase12a4',path.read_text(encoding='utf-8-sig'),str(path))
        for name in ['principal_burial','robbed_burial','side_chamber']:
            text=(ROOT/'tests/fixtures/phase12a4'/f'{name}.tres').read_text()
            self.assertIn('EXPERIMENT_ONLY',text)
            self.assertIn('LAB_VERSION_1',text)
            self.assertEqual(5 if name=='robbed_burial' else 4,len(re.findall(r'Rect2\(',text)))

    def test_no_lab_ui_or_new_gameplay_in_hud_boundary(self):
        text=(ROOT/'scripts/art/player_hud_boundary.gd').read_text()
        self.assertIn('name!=&"GameFlow"',text)
        self.assertIn('set_process_unhandled_input(false)',text)
        for token in ['take_damage(', 'cash', 'profile_store', 'geometry_plan', 'RandomNumberGenerator', 'Button.new']:
            self.assertNotIn(token,text)
