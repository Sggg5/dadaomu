"""Assemble native Godot frames/crops. Never rescale a full viewport capture."""
from pathlib import Path
from PIL import Image
import build_phase12a3_evidence as shared
ROOT=Path(__file__).resolve().parents[1]/'docs/screenshots/phase_12a5'
if __name__=='__main__':
    shared.ROOT=ROOT
    for prefix in ['before','after']:
        for mode in ['basic','enhanced']:
            assert Image.open(ROOT/f'{prefix}_1_static_{mode}.png').size==(1280,720)
    shared.gif('before_after.gif',['before_1_static_enhanced.png','after_1_static_enhanced.png'],2500)
    shared.gif('basic_enhanced.gif',['after_1_static_basic.png','after_1_static_enhanced.png'],2500)
    route=[p.name for p in sorted(ROOT.glob('after_1_route_*.png'))]
    combat=[p.name for p in sorted(ROOT.glob('after_1_motion_*.png'))]
    assert route and len(combat)==24
    shared.gif('walk_around_coffin.gif',route,200)
    shared.gif('actual_combat.gif',combat,200)
    shared.gif('walk_then_combat.gif',route+combat,200)
    for prefix in ['before','after']:
        image=Image.open(ROOT/f'{prefix}_1_static_enhanced.png')
        for name,box in {'principal':(536,256,744,424),'door':(550,563,730,636),
                         'wall':(112,88,400,160),'player':(608,464,676,551)}.items():
            # Native pixels, no filtering, retouch or added shadows.
            image.crop(box).save(ROOT/f'{prefix}_{name}_native.png')
    sheet=Image.new('RGB',(2560,720))
    for x,name in [(0,'before_1_static_enhanced.png'),(1280,'after_1_static_enhanced.png')]:
        sheet.paste(Image.open(ROOT/name),(x,0))
    sheet.save(ROOT/'before_after_native_pair.png')
