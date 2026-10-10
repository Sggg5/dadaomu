from pathlib import Path
import unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
class ReworkTests(unittest.TestCase):
 def test_floor_periodic_edges(self):
  im=Image.open(ROOT/'assets/art/stone_macro.png')
  self.assertEqual((96,96),im.size)
  for i in range(96):
   self.assertEqual(im.getpixel((0,i)),im.getpixel((95,i)))
   self.assertEqual(im.getpixel((i,0)),im.getpixel((i,95)))
 def test_fixed_native_body_anchors(self):
  original=Image.open(ROOT/'assets/art/actors.png')
  bounds=[original.crop((0,row*64,48,(row+1)*64)).getbbox() for row in [0,3]]
  reference=sum(box[3]-box[1] for box in bounds)/2
  self.assertEqual(50.5,reference) # Guard against mistaking the58px fit limit for body height.
  for percent,height in [(15,58),(20,61),(25,63)]:
   self.assertAlmostEqual(height/reference-1,percent/100,delta=.01)
   im=Image.open(ROOT/('assets/art/player_body_'+str(percent)+'.png'))
   self.assertEqual((256,320),im.size)
   for row in range(4):
    for col in range(3):
     cell=im.crop((col*64,row*80,(col+1)*64,(row+1)*80))
     box=cell.getbbox();self.assertIsNotNone(box)
     self.assertEqual(76,box[3]);self.assertEqual(height,box[3]-box[1])
     self.assertLess(box[2],64);self.assertGreater(box[0],0)
 def test_independent_weapon_does_not_modify_gameplay(self):
  text=(ROOT/'scripts/art/player_visual.gd').read_text(encoding='utf-8-sig')
  for forbidden in ['actor.position =','actor.velocity =','actor.aim_direction =','actor.stats.','try_attack(','take_damage(']:
   self.assertNotIn(forbidden,text)
  self.assertIn('actor.weapon.attack_requested.connect',text)
