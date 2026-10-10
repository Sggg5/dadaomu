"""Native Godot evidence, no scene painting or post-capture enhancement."""
from pathlib import Path
from PIL import Image,ImageChops
import json,shutil
import build_phase12a3_evidence as shared
ROOT=Path(__file__).resolve().parents[1]/'docs/screenshots/phase_12a6'
def gif_native(name,files,duration):
    frames=[]
    for path in files:
        with Image.open(path) as im:frames.append(im.convert('RGB'))
    assert frames and all(f.size==frames[0].size for f in frames)
    w,h=frames[0].size
    sample=Image.new('RGB',(w,h*min(8,len(frames))))
    for i,f in enumerate(frames[::max(1,len(frames)//8)][:8]):sample.paste(f,(0,i*h))
    palette=sample.quantize(colors=256,method=Image.Quantize.MEDIANCUT)
    indexed=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
    target=ROOT/name
    indexed[0].save(target,save_all=True,append_images=indexed[1:],duration=duration,loop=0,optimize=True,disposal=1)
    with Image.open(target) as result:
        # GIF may merge consecutive identical crops; total playback duration remains.
        total=0
        for i in range(result.n_frames):result.seek(i);total+=result.info['duration']
        assert total==len(frames)*duration
    return {'file':name,'source_frames':len(frames),'frame_size':[w,h],'duration_ms':len(frames)*duration}
if __name__=='__main__':
    shared.ROOT=ROOT
    shared.gif('before_after.gif',['old_static_enhanced.png','new_static_enhanced.png'],2500)
    shared.gif('basic_enhanced.gif',['new_static_basic.png','new_static_enhanced.png'],2500)
    rows=[]
    for prefix in ['new','probe']:
        files=sorted(ROOT.glob(prefix+'_battle_*.png'))
        assert files
        if prefix=='new':files.append(ROOT/'new_cleared_open_doors.png')
        rows.append(gif_native(prefix+'_full_combat.gif',files,100))
    for kind in ['corpse_dog','scarab']:
        # Both generated from the same real near-melee AI/weapon test, not pose units.
        files=sorted(ROOT.glob('probe_'+kind+'_*.png'));assert files
        rows.append(gif_native(kind+'_actual_ai.gif',files,100))
        source=ROOT.parents[2]/'assets/art'/('a6_'+kind+'.png')
        shutil.copy2(source,ROOT/(kind+'_all_64_frames.png'))
    route=sorted(ROOT.glob('new_route_*.png'));assert route
    rows.append(gif_native('real_walk_around_coffin.gif',route,200))
    for prefix in ['old','new']:
        with Image.open(ROOT/(prefix+'_static_enhanced.png')) as im:
            assert im.size==(1280,720)
            for kind,box in {'scarab':(288,198,376,286),'corpse_dog':(788,198,876,286)}.items():
                im.crop(box).save(ROOT/(prefix+'_'+kind+'_native.png'))
    for kind in ['scarab','corpse_dog']:
        sheet=Image.new('RGB',(176,88))
        for i,prefix in enumerate(['old','new']):
            with Image.open(ROOT/(prefix+'_'+kind+'_native.png')) as im:sheet.paste(im,(i*88,0))
        sheet.save(ROOT/(kind+'_before_after_native.png'))
    for prefix in ['new','probe']:
        path=ROOT/('new_runtime_states.json' if prefix=='new' else 'probe_states.json')
        data=json.loads(path.read_text())
        valid=[f for f in data.get('frame_metrics',[]) if f['alive']>=3 and f['projectiles']>0 and f['enemy_warnings']+f['environment_warnings']>0]
        assert valid,'must prove simultaneous real enemies/projectiles/warnings'
        frame=max(valid,key=lambda f:f['alive']*10+f['projectiles']+f['enemy_warnings']*2)
        shutil.copy2(ROOT/(prefix+f"_battle_{frame['frame']:03}.png"),ROOT/(prefix+'_dense_warning.png'))
        frame['source']=prefix;rows.append({'dense_frame':frame})
    (ROOT/'gif_provenance.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
