"""Deterministic per-pose extraction; never rotates a single frame into directions."""
from pathlib import Path
from PIL import Image
import json,hashlib,argparse,shutil
ROOT=Path(__file__).resolve().parents[1]

def primary_silhouette(cell):
    # Generated gutters can contain a few clipped pixels from adjacent poses.
    # Keep the largest connected alpha silhouette; never repaint anatomy.
    alpha=cell.getchannel('A');w,h=cell.size
    pixels=alpha.load();remaining={(x,y) for y in range(h) for x in range(w) if pixels[x,y]>48}
    groups=[]
    while remaining:
        seed=remaining.pop();group={seed};queue=[seed]
        while queue:
            x,y=queue.pop()
            for dx in [-1,0,1]:
                for dy in [-1,0,1]:
                    point=(x+dx,y+dy)
                    if point in remaining:remaining.remove(point);group.add(point);queue.append(point)
        groups.append(group)
    if not groups:raise ValueError('empty silhouette')
    keep=max(groups,key=len);mask=Image.new('L',cell.size);mp=mask.load()
    for x,y in keep:mp[x,y]=pixels[x,y]
    cell.putalpha(mask)
    return cell.crop(mask.getbbox())

def build(source,kind,columns):
    raw=ROOT/'assets/art/sources'/f'a6_{kind}_original.png'
    shutil.copy2(source,raw)
    with Image.open(raw) as src:
        im=src.convert('RGBA')
    # Generated sheet actually contains twelve columns, not requested eight.
    # Explicit reviewed pose map selects independent source poses, never duplicates.
    selected=[(0,0),(0,1),(0,2),(0,3),(1,2),(1,3),(0,4),(0,5),(0,6),(0,7),(0,8),(1,8),(0,columns-3),(0,columns-2),(0,columns-1),(1,columns-1)]
    crops=[]
    for direction in range(4):
        for dy,x in selected:
            y=direction*2+dy
            cell=im.crop((round(x*im.width/columns),round(y*im.height/8),round((x+1)*im.width/columns),round((y+1)*im.height/8)))
            crops.append(primary_silhouette(cell))
    scale=min(44/max(p.width for p in crops),44/max(p.height for p in crops)) if kind=='corpse_dog' else min(36/max(p.width for p in crops),36/max(p.height for p in crops))
    atlas=Image.new('RGBA',(512,512))
    for i,pose in enumerate(crops):
        pose=pose.resize((max(1,round(pose.width*scale)),max(1,round(pose.height*scale))),Image.Resampling.NEAREST)
        # Shared species scale; all feet line56, fixed canvas and origin.
        atlas.alpha_composite(pose,((i%8)*64+(64-pose.width)//2,(i//8)*64+56-pose.height))
    out=ROOT/'assets/art'/f'a6_{kind}.png';atlas.save(out)
    return {'id':f'a6_{kind}','path':f'res://assets/art/a6_{kind}.png','source':f'res://assets/art/sources/a6_{kind}_original.png','status':'DRAFT','license':'AI_GENERATED_ORIGINAL_PENDING_REVIEW','author':'OpenAI imagegen / project direction','provenance':'Original fictional tomb enemy, not museum media','width':512,'height':512,'filter':'NEAREST','frame_size':[64,64],'directions':['SOUTH','WEST','EAST','NORTH'],'poses':['idle']*2+['walk']*4+['windup']*2+['attack']*2+['hurt']*2+['death']*4,'source_columns':columns,'source_rows':8,'selected_source_poses':selected,'derivation':'largest connected alpha48 silhouette removes gutter fragments; common uniform species scale; NEAREST; feet56; no rotations or nonuniform stretch','sha256':hashlib.sha256(out.read_bytes()).hexdigest()}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--dog',required=True);p.add_argument('--scarab',required=True);p.add_argument('--dog-columns',type=int,default=12);p.add_argument('--scarab-columns',type=int,default=11);a=p.parse_args()
    rows=[build(a.dog,'corpse_dog',a.dog_columns),build(a.scarab,'scarab',a.scarab_columns)]
    path=ROOT/'assets/art/manifest.json';manifest=json.loads(path.read_text(encoding='utf-8'));manifest['assets']=[r for r in manifest['assets'] if r['id'] not in [s['id'] for s in rows]]+rows
    path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
