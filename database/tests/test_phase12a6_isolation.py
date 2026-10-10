from pathlib import Path
import hashlib,json,subprocess,unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
BASE='c4b0625c0db6461fc026063d69833a35d1dc921d'
class CombatArtTests(unittest.TestCase):
    def test_production_and_principal_architecture_frozen(self):
        paths=subprocess.check_output(['git','ls-tree','-r','--name-only',BASE,'scripts','scenes','data','project.godot','tests/fixtures/phase12a4','tests/support/phase12a5_visual.gd','tests/support/phase12a5_architecture.gd','tests/support/phase12a5_prop.gd'],cwd=ROOT,text=True).splitlines()
        self.assertGreater(len(paths),500)
        for name in paths:
            old=subprocess.check_output(['git','show',BASE+':'+name],cwd=ROOT).replace(b'\r\n',b'\n')
            current=(ROOT/name).read_bytes().replace(b'\r\n',b'\n')
            self.assertEqual(hashlib.sha256(old).digest(),hashlib.sha256(current).digest(),name)
    def test_all_native_direction_poses_draft_and_nonempty(self):
        manifest=json.loads((ROOT/'assets/art/manifest.json').read_text(encoding='utf-8'))
        for kind in ['corpse_dog','scarab']:
            row=next(r for r in manifest['assets'] if r['id']=='a6_'+kind)
            self.assertEqual(row['status'],'DRAFT');self.assertEqual(len(row['selected_source_poses']),16)
            with Image.open(ROOT/row['path'].removeprefix('res://')) as image:
                self.assertEqual(image.size,(512,512));self.assertEqual(image.mode,'RGBA')
                cells=[]
                for i in range(64):
                    cell=image.crop(((i%8)*64,(i//8)*64,(i%8+1)*64,(i//8+1)*64))
                    box=cell.getchannel('A').getbbox()
                    self.assertIsNotNone(box);self.assertLessEqual(box[3],56);self.assertGreater(box[0],0);self.assertLess(box[2],64)
                    cells.append(hashlib.sha256(cell.tobytes()).hexdigest())
                self.assertGreater(len(set(cells)),48,'independently drawn poses, not one rotated sprite')
    def test_no_production_binding_or_gameplay_mutation(self):
        for folder in ['scripts','scenes','data']:
            for path in (ROOT/folder).rglob('*'):
                if path.suffix in ['.gd','.tscn','.tres','.json']:
                    self.assertNotIn('phase12a6',path.read_text(encoding='utf-8-sig'))
        for name in ['enemy_visual','combat_visual','binding']:
            code=(ROOT/f'tests/support/phase12a6_{name}.gd').read_text()
            for token in ['take_damage(', 'health.restore(', 'position = landing', 'RandomNumberGenerator', 'CollisionShape2D.new', 'profile_store', 'definition.max_hp =']:
                self.assertNotIn(token,code)
if __name__=='__main__':unittest.main()
