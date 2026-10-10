"""Lossless arrangement / verified GIF compression of real Godot evidence."""
from pathlib import Path
from PIL import Image
import build_phase12a3_evidence as shared

ROOT=Path(__file__).resolve().parents[1]/'docs/screenshots/phase_12a4'

if __name__=='__main__':
    shared.ROOT=ROOT
    shared.gif('four_layouts.gif',[f'{i}_static_enhanced.png' for i in range(4)],2500)
    sheet=Image.new('RGB',(2560,1440))
    for i in range(4):
        source=Image.open(ROOT/f'{i}_static_enhanced.png').convert('RGB')
        assert source.size==(1280,720)
        sheet.paste(source,((i%2)*1280,(i//2)*720))
        frames=[p.name for p in sorted(ROOT.glob(f'{i}_motion_*.png'))]
        assert len(frames)==24
        shared.gif(f'{i}_combat.gif',frames,200)
    sheet.save(ROOT/'four_layouts_contact_sheet.png')
