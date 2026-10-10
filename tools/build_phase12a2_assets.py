"""Normalize one original AI DRAFT atlas into native transparent prop cells."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'assets/art/sources/tomb_props_original.png'
image=Image.open(source).convert('RGBA')
out=Image.new('RGBA',(384,320))
for i in range(6):
 x=i%3*512; y=0 if i<3 else 560
 cell=image.crop((x,y,x+512,560 if i<3 else 1024))
 bounds=cell.getchannel('A').point(lambda a:255 if a>128 else 0).getbbox()
 cell=cell.crop(bounds)
 cell.thumbnail((120,150),Image.Resampling.NEAREST)
 out.alpha_composite(cell,(i%3*128+(128-cell.width)//2,i//3*160+154-cell.height))
p=ROOT/'assets/art/tomb_props.png';out.save(p)
manifest=ROOT/'assets/art/manifest.json';data=json.loads(manifest.read_text())
row={'id':'tomb_props','path':'res://assets/art/tomb_props.png','source':'res://assets/art/sources/tomb_props_original.png','sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'status':'DRAFT','author':'OpenAI imagegen / project direction','provenance':'Original AI-generated fictional tomb props; no museum media','license':'AI_GENERATED_ORIGINAL_PENDING_REVIEW','width':384,'height':320,'format':'PNG','filter':'NEAREST','anchor':'CELL_FEET154','derivation':'3x2 alpha bounds; nearest fit120x150 into128x160 cells; no repainting','description':'Original AI six-prop atlas; native128x160 cells; imagegen transparent output, normalized without repainting; not historical replica.'}
data['assets']=[a for a in data['assets'] if a['id']!='tomb_props']+[row]
manifest.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
