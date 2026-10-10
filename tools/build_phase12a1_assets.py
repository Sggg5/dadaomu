"""Reproducible atlas packing and repeat-boundary preparation of DRAFT sources.
Pixel preparation is limited to atlas slicing/alignment/palette/seam treatment.
No gameplay data or RNG is read or written.
"""
from pathlib import Path
from PIL import Image,ImageEnhance
import argparse,json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[1];DEST=ROOT/'assets/art'
def principal_bounds(cell):
 """Ignore fragments leaking from adjacent generated grid rows.
 Use largest 8-connected alpha component for its bounds; preserve every pixel
 inside those bounds so small detached pixel-art details are not erased.
 """
 alpha=cell.getchannel('A');pixels=alpha.load();seen=set();best=[]
 for y in range(cell.height):
  for x in range(cell.width):
   if pixels[x,y]==0 or (x,y) in seen:continue
   pending=[(x,y)];seen.add((x,y));component=[]
   while pending:
    px,py=pending.pop();component.append((px,py))
    for ny in range(max(0,py-1),min(cell.height,py+2)):
     for nx in range(max(0,px-1),min(cell.width,px+2)):
      if pixels[nx,ny] and (nx,ny) not in seen:seen.add((nx,ny));pending.append((nx,ny))
   if len(component)>len(best):best=component
 if not best:raise ValueError('No connected body')
 return min(x for x,y in best),min(y for x,y in best),max(x for x,y in best)+1,max(y for x,y in best)+1
def main():
 p=argparse.ArgumentParser();p.add_argument('--body');p.add_argument('--floor');a=p.parse_args()
 m=json.loads((DEST/'manifest.json').read_text());rows=m['assets']
 def source(path,name):
  target=DEST/'sources'/name
  if Path(path).resolve()!=target.resolve():shutil.copyfile(path,target)
  return Image.open(target).convert('RGBA'),'res://assets/art/sources/'+name
 def save(im,name,src,note,anchor):
  path=DEST/(name+'.png');im.save(path)
  rows[:]=[r for r in rows if r['id']!=name]
  rows.append(dict(id=name,path='res://assets/art/'+path.name,source=src,width=im.width,height=im.height,format='PNG',filter='NEAREST',anchor=anchor,status='DRAFT',author='OpenAI imagegen / project direction',license='AI_GENERATED_ORIGINAL_PENDING_REVIEW',provenance='Original generated explorer/stone draft, no external IP or museum media',derivation=note,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
 if a.body:
  image,src=source(a.body,'player_rework_original.png');cells=[]
  for row in [0,2,1,3]: # Source profile views are swapped; output S/W/E/N.
   frames=[]
   for col in range(4):
    cell=image.crop((col*image.width//4,row*image.height//4,(col+1)*image.width//4,(row+1)*image.height//4))
    cell.putalpha(cell.getchannel('A').point(lambda v:255 if v>=128 else 0))
    box=principal_bounds(cell)
    if not box:raise ValueError('Empty body frame')
    frames.append(cell.crop(box))
   cells.append(frames)
  for percent in [15,20,25]:
   # Measured original S/N idle bounds:49/52px, not the58px fit limit.
   height=round(50.5*(1+percent/100));atlas=Image.new('RGBA',(256,320))
   for row,frames in enumerate(cells):
    for col,cell in enumerate(frames):
     # Fixed standing height and groundline across frames, aspect preserved.
     factor=height/cell.height if col<3 else min(60/cell.width,35/cell.height)
     size=(max(1,round(cell.width*factor)),max(1,round(cell.height*factor)))
     if size[0]>62:raise ValueError('Body exceeds frame width')
     cell=cell.resize(size,Image.Resampling.NEAREST)
     atlas.alpha_composite(cell,(col*64+(64-cell.width)//2,row*80+76-cell.height))
   save(atlas,'player_body_'+str(percent),src,'4x4 S/W/E/N; largest alpha component bounds removes neighbor-row fragments; profile rows corrected; native64x80; aspect preserved; standing height'+str(height)+'; binaryalpha128; fixedfeet76','FEET76')
 if a.floor:
  image,src=source(a.floor,'stone_rework_original.png')
  image=image.resize((96,96),Image.Resampling.BOX).convert('RGB').quantize(colors=16).convert('RGB')
  image=ImageEnhance.Brightness(ImageEnhance.Contrast(image).enhance(.45)).enhance(.57)
  # Blend opposing edge pairs, never add a light rectangular border.
  # Horizontal then vertical pairing keeps all four edge pixels periodic.
  pixels=image.load()
  for axis in [0,1]:
   original=image.copy()
   for offset in range(4):
    weight=.5*(1-offset/4)
    for step in range(96):
     left=(offset,step) if axis==0 else (step,offset)
     right=(95-offset,step) if axis==0 else (step,95-offset)
     a0=original.getpixel(left);b0=original.getpixel(right)
     pixels[left]=tuple(round(a0[c]*(1-weight)+b0[c]*weight) for c in range(3))
     pixels[right]=tuple(round(b0[c]*(1-weight)+a0[c]*weight) for c in range(3))
  save(image.convert('RGBA'),'stone_macro',src,'96px 3x3 contiguous macro atlas; box16palette; contrast.45 brightness.57; opposing edge blend4 without border; sparse separate dust runtime','CENTER')
 (DEST/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
if __name__=='__main__':main()
