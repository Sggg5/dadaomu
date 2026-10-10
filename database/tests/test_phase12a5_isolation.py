from pathlib import Path
import hashlib,json,subprocess,unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
BASE='6f73f20c0866d91838c7f637f2983eb6bc09dcc6'

class PrincipalSampleTests(unittest.TestCase):
    def test_all_production_scripts_scenes_data_and_experiment_geometry_frozen(self):
        paths=subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'scripts','scenes','data','tests/fixtures/phase12a4','tests/support/phase12a4_lab.gd','tests/support/phase12a4_decor.gd'],cwd=ROOT,text=True).splitlines()
        self.assertGreater(len(paths),500)
        for name in paths:
            expected=subprocess.check_output(['git','show',BASE+':'+name],cwd=ROOT)
            current=(ROOT/name).read_bytes()
            if Path(name).suffix in ['.gd','.tscn','.tres','.json','.uid']:
                current=current.replace(b'\r\n',b'\n');expected=expected.replace(b'\r\n',b'\n')
            self.assertEqual(hashlib.sha256(expected).digest(),hashlib.sha256(current).digest(),name)

    def test_native_draft_assets_and_source_alpha(self):
        manifest=json.loads((ROOT/'assets/art/manifest.json').read_text())
        sizes={'a5_principal':(160,148),'a5_offering':(144,60),'a5_gate':(112,28),'a5_masonry':(96,96)}
        for row in manifest['assets']:
            if row['id'] not in sizes:continue
            self.assertEqual('DRAFT',row['status'])
            with Image.open(ROOT/row['path'].removeprefix('res://')) as im:
                self.assertEqual(sizes[row['id']],im.size)
                if row['id']!='a5_masonry':
                    self.assertEqual('RGBA',im.mode);self.assertEqual(0,im.getpixel((0,0))[3])
                    with Image.open(ROOT/row['source'].removeprefix('res://')) as source:
                        self.assertEqual('RGBA',source.mode)
        with Image.open(ROOT/'assets/art/a5_masonry.png') as im:
            for y in range(96):self.assertEqual(im.getpixel((0,y)),im.getpixel((95,y)))
            for x in range(96):self.assertEqual(im.getpixel((x,0)),im.getpixel((x,95)))

    def test_only_explicit_a_visual_sample_no_gameplay_queries(self):
        code=(ROOT/'tests/support/phase12a5_visual.gd').read_text()
        self.assertIn('LAB_V1_PRINCIPAL_BURIAL',code)
        for token in ['RandomNumberGenerator','take_damage','cash','profile_store','CollisionShape2D.new','set_velocity']:
            self.assertNotIn(token,code)
        for folder in ['scripts','scenes','data']:
            for path in (ROOT/folder).rglob('*'):
                if path.suffix in ['.gd','.tscn','.tres','.json']:
                    self.assertNotIn('phase12a5',path.read_text(encoding='utf-8-sig'),str(path))

if __name__=='__main__':unittest.main()
