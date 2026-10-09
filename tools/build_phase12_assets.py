"""Deterministic nearest-neighbour derivatives of saved original AI artwork.
No gameplay data, image network requests, save files or random streams are read.
"""
from pathlib import Path
from PIL import Image
import json, shutil, hashlib, argparse
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'assets/art'
def main():
 p=argparse.ArgumentParser();p.add_argument('--actors',required=True);p.add_argument('--environment',required=True);p.add_argument('--antiques');a=p.parse_args()
 DEST.mkdir(parents=True,exist_ok=True);(DEST/'sources').mkdir(exist_ok=True)
 rows=[]
 def source(path,name):
  target=DEST/'sources'/name;shutil.copyfile(path,target)
  return Image.open(target).convert('RGBA'), 'res://assets/art/sources/'+name
 def save(im,name,src,derivation):
  im.save(DEST/name)
  rows.append(dict(id=name.removesuffix('.png'),path='res://assets/art/'+name,source=src,author='OpenAI imagegen / project direction',provenance='Original AI-generated game artwork; no museum media',license='AI_GENERATED_ORIGINAL_PENDING_REVIEW',status='DRAFT',derivation=derivation,sha256=hashlib.sha256((DEST/name).read_bytes()).hexdigest()))
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
  size=(32,32) if i<4 or name=='parquet' else (128,128)
  save(cell.resize(size,Image.Resampling.NEAREST),name+'.png',src,'equal grid crop; nearest resize '+str(size))
 if a.antiques:
  im,src=source(a.antiques,'antiques_original.png')
  ids=['republic_silver_coin','blue_white_jar','gilt_buddha','han_jade_disc','inlaid_bronze_mirror','tang_sancai_horse','gold_jade_pendant','tomb_beast_fragment']
  for i,name in enumerate(ids):
   x,y=i%4,i//4;cell=im.crop((x*im.width//4,y*im.height//2,(x+1)*im.width//4,(y+1)*im.height//2));box=cell.getbbox()
   if not box:raise ValueError('empty antique')
   cell=cell.crop(box);cell.thumbnail((240,240),Image.Resampling.NEAREST);detail=Image.new('RGBA',(256,256));detail.alpha_composite(cell,((256-cell.width)//2,(256-cell.height)//2))
   save(detail,name+'.png',src,'alpha bounds aspect fit240; centered256; icon/display share identity')
 (DEST/'manifest.json').write_text(json.dumps({'version':1,'approval':'PENDING_USER_REVIEW','assets':rows},ensure_ascii=False,indent=2),encoding='utf-8')
if __name__=='__main__':main()
