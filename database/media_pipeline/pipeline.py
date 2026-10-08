"""Licensed official photographs only; bounded retrieval, signature checks, SHA, no remote preview loads."""
import hashlib,io,json,time,urllib.parse,urllib.request,warnings
from pathlib import Path
from PIL import Image,ImageOps
from database.schema.migrate import ROOT,utc_now
from database.exports.export_godot_catalog import media_allowed,local_asset

ALLOWED_HOSTS=frozenset(['openaccess-api.clevelandart.org','openaccess-cdn.clevelandart.org'])
MAX_BYTES=5_000_000
Image.MAX_IMAGE_PIXELS=20_000_000

def safe_url(url):
    p=urllib.parse.urlsplit(url)
    if p.scheme!='https' or p.hostname not in ALLOWED_HOSTS or p.username or p.password or p.port not in (None,443):raise ValueError('Unapproved official media origin')
    return url

class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,req,fp,code,msg,headers,newurl):
        safe_url(newurl)
        return super().redirect_request(req,fp,code,msg,headers,newurl)

def bounded_get(url,max_bytes=MAX_BYTES):
    safe_url(url);opener=urllib.request.build_opener(SafeRedirect())
    req=urllib.request.Request(url,headers={'User-Agent':'DadaomuMuseumCatalog/0.1 (licensed public media research)'})
    with opener.open(req,timeout=25) as response:
        safe_url(response.url)
        if int(response.headers.get('Content-Length') or 0)>max_bytes:raise ValueError('Image exceeds byte limit')
        data=response.read(max_bytes+1);mime=response.headers.get_content_type()
    if len(data)>max_bytes:raise ValueError('Response exceeds byte limit')
    return data,mime

def checked_image(data,mime):
    if mime not in ('image/jpeg','image/png') or not (data.startswith(b'\xff\xd8\xff') or data.startswith(b'\x89PNG\r\n\x1a\n')):raise ValueError('Not a supported real image; HTML/SVG rejected')
    with warnings.catch_warnings():
        warnings.simplefilter('error',Image.DecompressionBombWarning)
        with Image.open(io.BytesIO(data)) as image:
            if image.format not in ('JPEG','PNG') or min(image.size)<16 or image.width*image.height>Image.MAX_IMAGE_PIXELS:raise ValueError('Invalid image dimensions or signature')
            image.verify()
        with Image.open(io.BytesIO(data)) as image:
            result=ImageOps.exif_transpose(image).convert('RGB');result.load()
    return result

def local_file(path):
    if not path or not path.startswith('database/previews/media/'):return None
    asset=local_asset(path)
    if not asset:return None
    target=(ROOT.parent/path).resolve()
    try:target.relative_to((ROOT/'previews/media').resolve())
    except ValueError:return None
    return target

def file_valid(path,sha):
    p=local_file(path)
    return bool(p and hashlib.sha256(p.read_bytes()).hexdigest()==sha)

def active_media(db,manifest=None):
    manifest=manifest or ROOT/'media_pipeline/manifest.json'
    if not Path(manifest).exists():return []
    result=[]
    for item in json.loads(Path(manifest).read_text(encoding='utf-8'))['images']:
        row=db.execute('SELECT * FROM media WHERE media_id=?',(item['media_id'],)).fetchone()
        if item.get('revoked') or not row or item['object_id']!=row['object_id'] or not media_allowed(row) or row['url']!=item['source_url'] or item['license_id']!=row['license_id']:continue
        if not all(file_valid(item[k+'_repo_path'],item[k+'_sha256']) for k in ['thumb','detail']):continue
        if item['rights_evidence']['share_license_status']!='CC0' or item['rights_evidence']['image_url']!=row['url']:continue
        copy=dict(item)
        for k in ['thumb','detail']:copy[k+'_path']=Path(item[k+'_repo_path']).relative_to(Path('database/previews')).as_posix()
        result.append(copy)
    return result

def download_samples(db,selection,manifest=ROOT/'media_pipeline/manifest.json'):
    rows=[];failures=[];seen={};before=0
    for index,media_id in enumerate(selection):
        row=db.execute('SELECT * FROM media WHERE media_id=?',(media_id,)).fetchone()
        try:
            if not row or row['media_kind']!='IMAGE' or not media_allowed(row):raise ValueError('Per-media rights not approved')
            source=db.execute('SELECT * FROM source_records WHERE source_id=? AND record_id=?',(row['source_id'],row['record_id'])).fetchone()
            if source['source_id']!='CMA' or not source['record_id'].isdigit():raise ValueError('First implementation only reviewed CMA CDN photographs')
            time.sleep(max(0,.4-(time.monotonic()-before)));before=time.monotonic()
            meta_bytes,_=bounded_get('https://openaccess-api.clevelandart.org/api/artworks/'+source['record_id'],max_bytes=1_000_000)
            raw=json.loads(meta_bytes)['data']
            url=(raw.get('images') or {}).get('web',{}).get('url')
            if raw.get('share_license_status')!='CC0' or url!=row['url']:
                db.execute("UPDATE media SET license_id='UNKNOWN',commercial_allowed=NULL,verification_status='UNVERIFIED' WHERE media_id=?",(media_id,));raise ValueError('Current institution record no longer confirms this image')
            time.sleep(.4);data,mime=bounded_get(url);image=checked_image(data,mime);sha=hashlib.sha256(data).hexdigest()
            duplicate=seen.get(sha);seen.setdefault(sha,media_id)
            folder=ROOT/'previews/media'/('samples' if index<2 else 'cache');folder.mkdir(parents=True,exist_ok=True)
            entry=dict(media_id=media_id,object_id=row['object_id'],original_name=raw['title'],accession_number=raw['accession_number'],source_id='CMA',record_id=source['record_id'],record_url=raw['url'],source_url=url,license_id='CC0',attribution=f"{raw['title']}, {raw['accession_number']}, Cleveland Museum of Art. CC0; resized without cropping.",copyright_notice=raw.get('copyright') or 'CC0 public-domain dedication',terms_url='https://www.clevelandart.org/terms-and-conditions',checked_at=utc_now(),source_sha256=sha,source_mime=mime,source_size=image.size,duplicate_of=duplicate,rights_evidence=dict(share_license_status=raw['share_license_status'],image_url=url,metadata_sha256=hashlib.sha256(meta_bytes).hexdigest()))
            cache=ROOT/'work/media_originals';cache.mkdir(parents=True,exist_ok=True);(cache/(sha+'.jpg')).write_bytes(data)
            for kind,bound in [('thumb',320),('detail',1024)]:
                resized=image.copy();resized.thumbnail((bound,bound),Image.Resampling.LANCZOS);path=folder/(sha[:24]+'_'+kind+'.jpg');resized.save(path,'JPEG',quality=88,optimize=True)
                entry[kind+'_repo_path']=path.relative_to(ROOT.parent).as_posix();entry[kind+'_sha256']=hashlib.sha256(path.read_bytes()).hexdigest();entry[kind+'_size']=resized.size
            rows.append(entry);print('downloaded',len(rows),entry['accession_number'],flush=True)
        except Exception as exc:failures.append(dict(media_id=media_id,error=str(exc)));print('rejected',media_id,str(exc),flush=True)
    report=dict(images=rows,failures=failures,media_scope='LOCAL_PLANNING_PREVIEW_ONLY',pipeline_version=1,pillow_version=Image.__version__)
    Path(manifest).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (ROOT/'media_pipeline/ATTRIBUTION.md').write_text('# 本地样例图片署名\n\n全部逐条核验CMA CC0，未新增游戏资产。仅两对象的四张缩放图提交，其他本地cache可按清单重建。\n\n'+'\n'.join('- '+r['attribution']+' [机构记录]('+r['record_url']+') / [原图片]('+r['source_url']+')' for r in rows),encoding='utf-8')
    return report


def revoke(db,media_id,reason,manifest=ROOT/'media_pipeline/manifest.json'):
    """Explicit revocation survives raw seed replay and preview regeneration; bytes need not be destroyed."""
    db.execute("UPDATE media SET verification_status='DENIED',commercial_allowed=0 WHERE media_id=?",(media_id,))
    payload=json.loads(Path(manifest).read_text(encoding='utf-8'))
    for item in payload['images']:
        if item['media_id']==media_id:item.update(revoked=True,revocation_reason=reason,revoked_at=utc_now())
    Path(manifest).write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def refresh_rights(db,manifest=ROOT/'media_pipeline/manifest.json'):
    report=[]
    for item in json.loads(Path(manifest).read_text(encoding='utf-8'))['images']:
        try:
            time.sleep(.4);data,_=bounded_get('https://openaccess-api.clevelandart.org/api/artworks/'+item['record_id'],1_000_000);raw=json.loads(data)['data']
            if raw.get('share_license_status')!='CC0' or (raw.get('images') or {}).get('web',{}).get('url')!=item['source_url']:
                revoke(db,item['media_id'],'Current official per-image licence/URL no longer confirmed',manifest);report.append(dict(media_id=item['media_id'],status='REVOKED'))
            else:report.append(dict(media_id=item['media_id'],status='CURRENT_CC0'))
        except Exception as exc:
            revoke(db,item['media_id'],'Rights verification unavailable: '+str(exc),manifest);report.append(dict(media_id=item['media_id'],status='UNCONFIRMED_BLOCKED'))
    return report
