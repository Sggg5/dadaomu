"""Visual-only boundary tests; no assertions removed from older suites."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]

class VisualRefinementTests(unittest.TestCase):
    def test_static_cache_and_dynamic_warning_registration(self):
        text = (ROOT / 'scripts/art/room_visual.gd').read_text(encoding='utf-8-sig')
        process = text.split('func _process', 1)[1].split('func _draw', 1)[0]
        self.assertNotIn('_prioritize_warnings(room)', process)
        self.assertIn('node_added.connect(_warning_added)', text)
        self.assertIn('if changed:', process)
        self.assertIn('warning.z_index = 1100', process)

    def test_visual_files_do_not_mutate_combat_or_random_streams(self):
        for name in ['room_visual', 'tomb_space_piece', 'tomb_space_floor', 'enemy_visual']:
            text = (ROOT / 'scripts/art' / (name + '.gd')).read_text(encoding='utf-8-sig')
            for forbidden in ['take_damage(', 'health.current_hp =', 'velocity =',
                              'collision_layer =', 'randi(', 'randf(', 'randomize(']:
                self.assertNotIn(forbidden, text, name)
