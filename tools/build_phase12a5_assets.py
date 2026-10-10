"""Deterministic native-size normalization; source artwork is never overwritten."""
from pathlib import Path
from PIL import Image
import hashlib,json,shutil,argparse
ROOT=Path(__file__).resolve().parents[1]

def build(source, asset, canvas, box):
    dest=ROOT/'assets/art/sources'/f'{asset}_original.png'
    shutil.copy2(source,dest)
    image=Image.open(dest).convert('RGBA')
    bounds=image.getchannel('A').point(lambda a:255 if a>128 else 0).getbbox()
    assert bounds,asset
    crop=image.crop(bounds)
    crop.thumbnail(box,Image.Resampling.NEAREST)
    # Retain the generated silhouette. Native canvas matches the real footprint.
    output=Image.new('RGBA',canvas)
    output.alpha_composite(crop,((canvas[0]-crop.width)//2,canvas[1]-crop.height))
    output.save(ROOT/'assets/art'/f'{asset}.png')
    return row(asset,canvas,'alpha>128 bounds crop; uniform nearest fit'+str(box)+'; centered feet at canvas bottom, no nonuniform scaling')

def row(asset,size,derivation):
    dest=ROOT/'assets/art'/f'{asset}.png'
    return {'id':asset,'path':f'res://assets/art/{asset}.png','source':f'res://assets/art/sources/{asset}_original.png',
            'author':'OpenAI imagegen / project direction','provenance':'Original AI-generated fictional Chinese tomb sample; not a historical replica; no museum media',
            'license':'AI_GENERATED_ORIGINAL_PENDING_REVIEW','status':'DRAFT','sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),
            'width':size[0],'height':size[1],'format':'PNG','filter':'NEAREST','anchor':'FEET','derivation':derivation}

if __name__=='__main__':
    p=argparse.ArgumentParser()
    for key in ['principal','masonry','offering','gate']:p.add_argument('--'+key,required=True)
    a=p.parse_args(); rows=[]
    rows.append(build(a.principal,'a5_principal',(160,148),(160,148)))
    rows.append(build(a.offering,'a5_offering',(144,60),(144,60)))
    rows.append(build(a.gate,'a5_gate',(112,28),(112,28)))
    raw=ROOT/'assets/art/sources/a5_masonry_original.png';shutil.copy2(a.masonry,raw)
    texture=Image.open(raw).convert('RGB')
    side=min(768,texture.width,texture.height)
    x=(texture.width-side)//2;y=(texture.height-side)//2
    texture=texture.crop((x,y,x+side,y+side)).resize((96,96),Image.Resampling.BOX)
    texture=texture.quantize(colors=32).convert('RGB')
    # Periodic edge averaging makes native clipped strips repeat without hard seams.
    pixels=texture.load()
    for y in range(96):
        edge=tuple((pixels[0,y][c]+pixels[95,y][c])//2 for c in range(3))
        pixels[0,y]=pixels[95,y]=edge
    for x in range(96):
        edge=tuple((pixels[x,0][c]+pixels[x,95][c])//2 for c in range(3))
        pixels[x,0]=pixels[x,95]=edge
    texture.save(ROOT/'assets/art/a5_masonry.png')
    rows.append(row('a5_masonry',(96,96),'central768square crop;BOX downsample96x96;32palette;opposite native boundary pixels averaged; no concept background'))
    manifest=ROOT/'assets/art/manifest.json'; data=json.loads(manifest.read_text(encoding='utf-8'))
    data['assets']=[r for r in data['assets'] if r['id'] not in {s['id'] for s in rows}]+rows
    manifest.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(rows,ensure_ascii=False,indent=2))
