"""Explicit Phase13A authorization preserves every unrelated gameplay freeze assertion."""
from pathlib import Path
import hashlib,json,subprocess,unittest
from phase13_authorization import AUTH
ROOT=Path(__file__).resolve().parents[2]
EXPECTED={'scripts/antiques/antique_inventory.gd','scripts/combat/enemy_projectile.gd','scripts/dungeon/dungeon_session.gd','scripts/dungeon/events/tomb_risk_content.gd','scripts/dungeon/interactables/wall_mark.gd','scripts/dungeon/run_carry_state.gd','scripts/expedition/expedition_selection.gd','scripts/flow/game_flow.gd','scripts/player/player.gd','scripts/rooms/encounter_hazard.gd','scripts/rooms/room_controller.gd','scripts/ui/expedition_map_panel.gd'}
class ProfessionTests(unittest.TestCase):
 def test_exact_reviewable_authorization(self):
  self.assertEqual(set(AUTH),EXPECTED)
  for path,row in AUTH.items():
   old=subprocess.check_output(['git','show','c3bd02bb1c9fee6a90e9f031a34e04364fa44571:'+path]).decode('utf-8-sig').replace('\r\n','\n')
   self.assertEqual(row['baseline'],hashlib.sha256(old.encode()).hexdigest())
   self.assertEqual(row['current'],hashlib.sha256((ROOT/path).read_text(encoding='utf-8-sig').encode()).hexdigest())
 def test_old_data_and_profile_bytes_unchanged(self):
  paths=subprocess.check_output(['git','ls-tree','-r','--name-only','c3bd02bb1c9fee6a90e9f031a34e04364fa44571','data','scripts/museum/museum_profile_store.gd'],text=True).splitlines()
  for path in paths:
   old=subprocess.check_output(['git','show','c3bd02bb1c9fee6a90e9f031a34e04364fa44571:'+path])
   self.assertEqual(old.replace(b'\r\n',b'\n'),(ROOT/path).read_bytes().replace(b'\r\n',b'\n'),path)
 def test_independent_rng_and_small_scripts(self):
  p=ROOT/'scripts/professions/profession_corpse_plan.gd'
  s=p.read_text(encoding='utf-8-sig');self.assertIn('RandomNumberGenerator.new()',s)
  self.assertNotIn('.shuffle()',s);self.assertNotIn('randomize()',s)
  for p in (ROOT/'scripts/professions').glob('*.gd'):self.assertLess(len(p.read_text(encoding='utf-8-sig').splitlines()),1000)
 def test_draft_abilities_have_finite_budgets(self):
  data=json.loads((ROOT/'data/professions/draft_professions.json').read_text(encoding='utf-8-sig'))
  self.assertIn('DRAFT',str(data))
  self.assertEqual({row['id'] for row in data['definitions']},{'MOJIN','FAQIU','BANSHAN','XIELING'})
  for row in data['definitions']:self.assertLessEqual(row['uses'],1)

 def test_aligned_rules_and_separate_corpse_config(self):
  data=json.loads((ROOT/'data/professions/draft_professions.json').read_text(encoding='utf-8-sig'))
  rows={r['id']:r for r in data['definitions']}
  self.assertEqual(rows['MOJIN']['ability'],'MOJIN:CLUE')
  self.assertEqual(rows['FAQIU']['first_damage_multiplier'],.7)
  self.assertEqual(rows['BANSHAN']['movement_multiplier'],1.08)
  self.assertEqual(rows['BANSHAN']['hits_required'],4)
  self.assertEqual(rows['BANSHAN']['empower_multiplier'],1.25)
  self.assertEqual(rows['XIELING']['token'],'卸岭旗')
  self.assertEqual(rows['XIELING']['extra_slots'],2)
  self.assertEqual(rows['XIELING']['loaded_multiplier'],.95)
  self.assertEqual(rows['XIELING']['overload_multiplier'],.8)
  corpse=json.loads((ROOT/'data/professions/corpse_distribution.json').read_text())
  self.assertEqual(corpse['max_per_floor'],1)
  self.assertEqual(corpse['later_floor_chance'],.5)
  code=(ROOT/'scripts/professions/profession_runtime.gd').read_text(encoding='utf-8-sig')
  self.assertIn('request.set_meta(ATTACK_KEY,id)',code)
  self.assertNotIn('request.tags.append',code)
