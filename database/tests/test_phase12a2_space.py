from pathlib import Path
import unittest,re
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
class TombSpaceTests(unittest.TestCase):
 def test_six_native_draft_props(self):
  im=Image.open(ROOT/'assets/art/tomb_props.png')
  self.assertEqual((384,320),im.size);self.assertEqual('RGBA',im.mode)
  for i in range(6):
   cell=im.crop((i%3*128,i//3*160,(i%3+1)*128,(i//3+1)*160))
   self.assertIsNotNone(cell.getbbox());self.assertEqual(0,cell.getpixel((0,0))[3])
 def test_no_physics_or_gameplay_random_in_space(self):
  for name in ['room_visual','tomb_space_piece','tomb_space_floor']:
   text=(ROOT/'scripts/art'/ (name+'.gd')).read_text(encoding='utf-8-sig')
   for forbidden in ['StaticBody2D.new','CollisionShape2D.new','randi(', 'randf(', 'randomize(', 'take_damage(']:
    self.assertNotIn(forbidden,text,name)
   self.assertIsNone(re.search(r"room\.(?:obstacles|geometry|definition)\s*=(?!=)",text),name)
 def test_original_floor_player_preserved(self):
  # Visual wall/prop rework cannot touch body size or seamless floor asset bytes.
  import hashlib,subprocess
  for name in ['player_body_20.png','stone_macro.png']:
   old=subprocess.check_output(['git','show','e4f8cdd:assets/art/'+name],cwd=ROOT)
   self.assertEqual(hashlib.sha256(old).digest(),hashlib.sha256((ROOT/'assets/art'/name).read_bytes()).digest())
