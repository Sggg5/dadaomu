"""Rendering authorization never exempts gameplay functions or game data."""
from pathlib import Path
import hashlib,json,re,unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def digest(text):return hashlib.sha256(text.encode()).hexdigest()
def functions(text):
 return dict(re.findall(r'(?m)^func ([^\n]+)\n([\s\S]*?)(?=^func |\Z)',text))
def normalize(body):return '\n'.join(line for line in body.splitlines() if line.strip() and not line.startswith('var art_visual:'))
class VisualTests(unittest.TestCase):
 def test_exact_visual_hash_allowlist(self):
  updates=json.loads((ROOT/'database/samples/phase12_visual_authorized_hashes.json').read_text())
  self.assertEqual(set(updates),{'scripts/antiques/antique_pedestal.gd','scripts/enemies/enemy.gd','scripts/player/player.gd','scripts/rooms/room.gd','scripts/ui/antique_inventory_panel.gd','scripts/ui/museum_work_panel.gd'})
  for path,expected in updates.items():self.assertEqual(expected,digest((ROOT/path).read_text(encoding='utf-8-sig')),path)
 def test_game_data_and_nonvisual_scripts_frozen(self):
  snapshot=json.loads((ROOT/'tests/fixtures/phase12_gameplay_freeze.json').read_text())
  self.assertGreater(len(snapshot['files']),500)
  for path,expected in snapshot['files'].items():
   self.assertEqual(expected,digest((ROOT/path).read_text(encoding='utf-8-sig')),path)
 def test_existing_gameplay_functions_frozen(self):
  snapshot=json.loads((ROOT/'tests/fixtures/phase12_gameplay_freeze.json').read_text())
  for path,expected in snapshot['functions'].items():
   actual=functions((ROOT/path).read_text(encoding='utf-8-sig'))
   for signature,value in expected.items():self.assertEqual(value,digest(normalize(actual[signature])),path+' '+signature)
 def test_provenance_and_draft_status(self):
  manifest=json.loads((ROOT/'assets/art/manifest.json').read_text())
  self.assertEqual('PENDING_USER_REVIEW',manifest['approval'])
  ids=[]
  for row in manifest['assets']:
   ids.append(row['id']);self.assertEqual('DRAFT',row['status'])
   path=ROOT/row['path'].removeprefix('res://');self.assertTrue(path.is_file())
   self.assertEqual(row['sha256'],hashlib.sha256(path.read_bytes()).hexdigest())
   self.assertTrue((ROOT/row['source'].removeprefix('res://')).is_file())
  self.assertEqual(len(ids),len(set(ids)))
 def test_transparency_and_canonical_frames(self):
  actor=Image.open(ROOT/'assets/art/actors.png');self.assertEqual((288,384),actor.size)
  for y in range(6):
   for x in range(6):
    cell=actor.crop((x*48,y*64,(x+1)*48,(y+1)*64));self.assertIsNotNone(cell.getbbox());self.assertLessEqual(cell.getbbox()[3],62)
  for name in ['museum_npcs','republic_silver_coin','blue_white_jar','gilt_buddha','han_jade_disc','inlaid_bronze_mirror','tang_sancai_horse','gold_thread_jade','guardian_fragment']:
   image=Image.open(ROOT/'assets/art'/ (name+'.png'));self.assertEqual('RGBA',image.mode);self.assertEqual(0,image.getpixel((0,0))[3])
