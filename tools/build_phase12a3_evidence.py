"""Assemble real Godot captures; never paint replacements for engine evidence."""
from pathlib import Path
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1] / 'docs/screenshots/phase_12a3'

def gif(name, files, duration):
    frames = [Image.open(ROOT / f).convert('RGB') for f in files]
    assert all(frame.size == (1280, 720) for frame in frames)
    # Shared palette minimizes palette flicker. Original PNGs remain unchanged.
    sample = Image.new('RGB', (1280, 720 * min(8, len(frames))))
    selected = frames if len(frames) <= 8 else frames[::max(1, len(frames) // 8)][:8]
    for i, frame in enumerate(selected):
        sample.paste(frame, (0, i * 720))
    palette = sample.quantize(colors=256, method=Image.Quantize.MEDIANCUT)
    indexed = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    target = ROOT / name
    indexed[0].save(target, save_all=True, append_images=indexed[1:],
                    duration=duration, loop=0, optimize=True, disposal=1)
    with Image.open(target) as result:
        assert result.n_frames == len(frames)
        for i, expected in enumerate(indexed):
            result.seek(i)
            assert ImageChops.difference(result.convert('RGB'), expected.convert('RGB')).getbbox() is None
    print(name, len(frames), target.stat().st_size)

if __name__ == '__main__':
    gif('before_after.gif', ['baseline_basic.png', 'combat_basic.png'], 2500)
    gif('basic_enhanced.gif', ['combat_basic.png', 'combat_enhanced.png'], 2500)
    gif('actual_combat.gif', [p.name for p in sorted(ROOT.glob('motion_*.png'))], 270)
    for name, bounds in {
        'coffin_detail': (240, 200, 405, 370),
        'door_detail': (550, 540, 730, 635),
        'scarab_detail': (295, 270, 505, 325),
    }.items():
        source = 'combat_enhanced.png' if name != 'door_detail' else 'player_door.png'
        image = Image.open(ROOT / source).crop(bounds)
        image.resize((image.width * 3, image.height * 3), Image.Resampling.NEAREST).save(ROOT / (name + '_3x.png'))
