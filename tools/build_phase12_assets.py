"""Deterministic nearest-neighbour derivatives of saved original AI artwork.
No gameplay data, image network requests, save files or random streams are read.
"""
from pathlib import Path
from PIL import Image, ImageEnhance
import json, shutil, hashlib, argparse
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'assets/art'
def main():
 p=argparse.ArgumentParser();p.add_argument('--actors',required=True);p.add_argument('--environment',required=True);p.add_argument('--antiques');p.add_argument('--npcs');p.add_argument('--furniture');a=p.parse_args()
 DEST.mkdir(parents=True,exist_ok=True);(DEST/'sources').mkdir(exist_ok=True)
 rows=[]
 def source(path,name):
  target=DEST/'sources'/name;shutil.copyfile(path,target)
  return Image.open(target).convert('RGBA'), 'res://assets/art/sources/'+name
 def save(im,name,src,derivation):
  im.save(DEST/name)
  rows.append(dict(width=im.width,height=im.height,format='PNG',filter='NEAREST',anchor='FEET62' if name in ['actors.png','museum_npcs.png'] else 'CENTER',id=name.removesuffix('.png'),path='res://assets/art/'+name,source=src,author='OpenAI imagegen / project direction',provenance='Original AI-generated game artwork; no museum media',license='AI_GENERATED_ORIGINAL_PENDING_REVIEW',status='DRAFT',derivation=derivation,sha256=hashlib.sha256((DEST/name).read_bytes()).hexdigest()))
 im,src=source(a.actors,'actors_original.png')
 atlas=Image.new('RGBA',(48*6,64*6))
 for y in range(6):
  for x in range(6):
   cell=im.crop((x*im.width//6,y*im.height//6,(x+1)*im.width//6,(y+1)*im.height//6))
   box=cell.getbbox()
   if not box:raise ValueError('empty actor cell')
   cell=cell.crop(box);cell.thumbnail((46,58),Image.Resampling.NEAREST)
   atlas.alpha_composite(cell,(x*48+(48-cell.width)//2,y*64+62-cell.height))
 save(atlas,'actors.png',src,'6x6 alpha-bounds crop; preserve aspect; nearest fit46x58; feet baseline62')
 im,src=source(a.environment,'environment_original.png')
 names=['stone_0','stone_1','stone_2','stone_3','wall','coffin','parquet','showcase']
 for i,name in enumerate(names):
  x,y=i%4,i//4;cell=im.crop((x*im.width//4,y*im.height//2,(x+1)*im.width//4,(y+1)*im.height//2))
  size=(32,32) if i<4 else (128,128)
  if i<4:
   cell=cell.resize(size,Image.Resampling.BOX).convert('RGB').quantize(colors=16).convert('RGBA')
   cell=ImageEnhance.Brightness(ImageEnhance.Contrast(cell).enhance(.65)).enhance(.60)
  elif name=='parquet':
   cell=ImageEnhance.Brightness(ImageEnhance.Contrast(cell.resize(size,Image.Resampling.BOX)).enhance(.70)).enhance(.70)
  else:cell=cell.resize(size,Image.Resampling.NEAREST)
  save(cell,name+'.png',src,'equal grid crop; floor box16palette/contrast0.65/brightness0.60; parquet128contrast0.70/brightness0.70; props nearest')
 if a.antiques:
  im,src=source(a.antiques,'antiques_original.png')
  ids=['republic_silver_coin','blue_white_jar','gilt_buddha','han_jade_disc','inlaid_bronze_mirror','tang_sancai_horse','gold_thread_jade','guardian_fragment']
  for i,name in enumerate(ids):
   x,y=i%4,i//4;cell=im.crop((x*im.width//4,y*im.height//2,(x+1)*im.width//4,(y+1)*im.height//2));box=cell.getbbox()
   if not box:raise ValueError('empty antique')
   cell=cell.crop(box);cell.thumbnail((240,240),Image.Resampling.NEAREST);detail=Image.new('RGBA',(256,256));detail.alpha_composite(cell,((256-cell.width)//2,(256-cell.height)//2))
   save(detail,name+'.png',src,'alpha bounds aspect fit240; centered256; icon/display share identity')
 if a.npcs:
  im,src=source(a.npcs,'museum_npcs_original.png');atlas=Image.new('RGBA',(288,128))
  for y in range(2):
   for x in range(6):
    cell=im.crop((x*im.width//6,y*im.height//2,(x+1)*im.width//6,(y+1)*im.height//2))
    cell.putalpha(cell.getchannel('A').point(lambda value:255 if value>=128 else 0))
    cell=cell.crop(cell.getbbox());cell.thumbnail((46,58),Image.Resampling.NEAREST)
    atlas.alpha_composite(cell,(x*48+(48-cell.width)//2,y*64+62-cell.height))
  save(atlas,'museum_npcs.png',src,'6x2 grid; binary alpha128; aspect fit46x58; feet62')
 if a.furniture:
  im,src=source(a.furniture,'furniture_original.png')
  for i,name in enumerate(['office','construction','appraisal','restoration','research','board','ticket','dealer']):
   x,y=i%4,i//4;cell=im.crop((x*im.width//4,y*im.height//2,(x+1)*im.width//4,(y+1)*im.height//2))
   cell.putalpha(cell.getchannel('A').point(lambda value:255 if value>=128 else 0))
   cell=cell.crop(cell.getbbox());cell.thumbnail((124,92),Image.Resampling.NEAREST)
   out=Image.new('RGBA',(128,96));out.alpha_composite(cell,((128-cell.width)//2,94-cell.height))
   save(out,name+'.png',src,'equal grid alpha128; aspect fit124x92; feet94')
 (DEST/'manifest.json').write_text(json.dumps({'version':1,'approval':'PENDING_USER_REVIEW','assets':rows},ensure_ascii=False,indent=2),encoding='utf-8')
if __name__=='__main__':main()

