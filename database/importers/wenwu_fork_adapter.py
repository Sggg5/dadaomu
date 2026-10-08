"""Read-only Fork projection. No network requests, image fetches or game/candidate writes."""
import hashlib,json,re,unicodedata
from urllib.parse import urlsplit,urlunsplit,parse_qsl,urlencode
from database.normalizers.record import CollectionRecord,text
from database.importers.store import canonical
VERSION=2
SOURCE='WENWU_FORK'
REPO='https://github.com/Sggg5/wenwu-database'
POLICIES={
 'MET':('MET','metmuseum.org','CC0','https://www.metmuseum.org/hubs/open-access'),
 'CLE':('CMA','clevelandart.org','CC0','https://www.clevelandart.org/open-access'),
 'AIC':('AIC','artic.edu','CC0','https://api.artic.edu/docs/#copyright'),
 'SMI':('SMITHSONIAN_NMAA','si.edu','CC0','https://www.si.edu/openaccess/faq'),
 'NPM':('NPM_TAIPEI','npm.gov.tw','CC_BY','https://theme.npm.edu.tw/opendata/%E6%95%85%E5%AE%AEOpen%20Data%E5%B0%88%E5%8D%80%E5%9C%96%E5%83%8F%E8%88%87%E6%96%87%E5%AD%97%E6%8E%88%E6%AC%8A%E8%A6%8F%E7%AF%84.pdf'),
 'GPM':(None,'dpm.org.cn','UNKNOWN','https://digicol.dpm.org.cn/'),
 'NMC':(None,'chnmuseum.cn','UNKNOWN','https://www.chnmuseum.cn/'),
 'SXHM':(None,'sxhm.com','UNKNOWN','https://www.sxhm.com/'),
 'HN':(None,'chnmus.net','UNKNOWN','https://www.chnmus.net/'),
 'HAM':(None,'harvardartmuseums.org','UNKNOWN','https://harvardartmuseums.org/'),
 'VA':(None,'vam.ac.uk','UNKNOWN','https://developers.vam.ac.uk/')}

def http_url(value):
 if not isinstance(value,str):return None
 try:
  p=urlsplit(value)
  if p.scheme not in ('https','http') or not p.hostname or p.username or p.password:return None
  if any(ord(c)<32 for c in value):return None
  return value
 except ValueError:return None

def canonical_url(value):
 if not http_url(value):return None
 p=urlsplit(value);host=p.hostname.lower().removeprefix('www.')
 query=sorted((k,v) for k,v in parse_qsl(p.query,keep_blank_values=True) if not k.lower().startswith('utm_') and k not in ('mode','lang'))
 return urlunsplit(('https',host,p.path.rstrip('/'),urlencode(query),''))

def official_key(url):
 value=canonical_url(url)
 if not value:return None
 p=urlsplit(value)
 # AIC native API IDs are not main_reference_number accession numbers.
 if p.hostname in ('artic.edu','api.artic.edu'):
  match=re.search(r'/(?:artworks|api/v1/artworks)/(\d+)',p.path)
  return 'AIC_API:'+match[1] if match else None
 if p.hostname in ('metmuseum.org','collectionapi.metmuseum.org'):
  match=re.search(r'/(?:search|objects)/(\d+)',p.path)
  return 'MET_API:'+match[1] if match else None
 if p.path in ('','/','/collection','/collections','/art/collection/search'):return None
 if p.hostname.endswith('clevelandart.org') and not re.search(r'/art/[^/]+$',p.path):return None
 if p.hostname.endswith('si.edu') and '/object/' not in p.path:return None
 if p.hostname.endswith('si.edu'):
  from urllib.parse import unquote
  match=re.search(r'/object/(?:fsg_)?(F[^/:]+)',unquote(p.path))
  if match:return 'NMAA_ACC:'+match[1]
 return value

def identifier(value):
 value=text(value)
 if value and value.lower() not in ('unknown','none','n/a','无','未知','未提供','0','-'):return unicodedata.normalize('NFC',value)
 return None

def project(raw,sha):
 rid=raw.get('relic_id');name=raw.get('name');url=http_url(raw.get('source_url'))
 if not isinstance(rid,str) or not re.fullmatch(r'[A-Z]+-[^/\\\x00-\x1f]{1,180}',rid) or not isinstance(name,str) or not name.strip() or not url:raise ValueError('Missing/invalid raw ID, name or official URL')
 prefix=rid.split('-',1)[0]
 if prefix not in POLICIES:raise ValueError('Unregistered museum prefix')
 museum,domain,policy,terms=POLICIES[prefix];host=urlsplit(url).hostname.lower()
 if not (host==domain or host.endswith('.'+domain)):raise ValueError('Museum prefix / official host mismatch')
 collection=raw.get('collection') or {}
 if not isinstance(collection,dict):raise ValueError('Invalid collection payload')
 inventory=identifier(collection.get('inventory_no'))
 issues=[];kind='MUSEUM_RECORD'
 if prefix=='SXHM' and raw.get('category')=='钱币' and ('汇总记录' in str(raw.get('summary','')) or '.xlsx' in str(raw.get('raw_ref',''))):kind='COIN_TYPE';issues.append('AGGREGATED_TYPE_NOT_INDIVIDUAL_SPECIMEN')
 if str(raw.get('record_type','')).upper() in ('COIN_TYPE','TYPE'):kind='COIN_TYPE'
 accession=inventory
 if prefix in ('AIC','HN'):accession=None;issues.append('API_ID_NOT_ACCESSION')
 claim=str(raw.get('license') or 'UNKNOWN')
 licensed=(policy=='CC0' and claim.upper()=='CC0') or (policy=='CC_BY' and ('CC BY 4' in claim.upper() or 'CC-BY-4' in claim.upper()))
 if prefix=='NPM' and not licensed:issues.append('CC0_CLAIM_VS_CURRENT_CC_BY4_SCOPE_UNRESOLVED')
 verdict='OPEN_METADATA' if licensed else ('RIGHTS_CONFLICT_INDEX_ONLY' if prefix=='NPM' else 'INDEX_ONLY')
 effective=policy if licensed else 'UNKNOWN'
 if kind=='COIN_TYPE':verdict='TYPE_INDEX_ONLY';licensed=False;effective='UNKNOWN'
 if not text(raw.get('material')):issues.append('UNKNOWN_MATERIAL')
 if not text(raw.get('dynasty')):issues.append('UNKNOWN_DYNASTY')
 years=raw.get('year_range');valid_years=isinstance(years,list) and len(years)==2 and all(type(v) is int for v in years) and years[0]<=years[1]
 if years is not None and not valid_years:issues.append('INVALID_OR_AMBIGUOUS_YEAR_RANGE')
 if raw.get('dynasty_confidence')!='high':issues.append('PERIOD_CLASSIFICATION_PENDING_REVIEW')
 media=[]
 for item in raw.get('images') or []:
  if not isinstance(item,dict) or not http_url(item.get('url')):issues.append('INVALID_MEDIA_URL');continue
  media.append({'url':item['url'],'declared_license':item.get('license','UNKNOWN'),'credit':item.get('credit',''),'effective_license':'UNKNOWN','verification_status':'UNVERIFIED','download_allowed':False})
 minimal={k:raw.get(k) for k in ['relic_id','name','aliases','dynasty','dynasty_confidence','year_range','category','material','dimensions','collection','source_url','license','fetched_at','updated_at','raw_ref']}
 minimal['mapping']={'museum_id':museum,'accession':accession,'category_id':'NUMISMATIC_OBJECT' if raw.get('category')=='钱币' else 'ARTWORK' if raw.get('category') in ('书画','碑帖拓本','历史影像') else 'HISTORICAL_OBJECT' if valid_years and years[0]>=1500 else 'ARCHAEOLOGICAL_ARTIFACT'}
 minimal['images']=media;minimal['adapter_version']=VERSION;minimal['effective_data_license']=effective;minimal['rights_verdict']=verdict;minimal['issues']=issues
 # No restricted summaries, history, interpretation or image bytes enter our DB/export.
 digest=hashlib.sha256(canonical(raw).encode()).hexdigest()
 projection=hashlib.sha256(canonical(minimal).encode()).hexdigest()
 key=official_key(url)
 if not accession and not key:issues.append('NO_STRONG_PHYSICAL_IDENTITY')
 entity=('TYPE:'+prefix+':'+rid) if kind=='COIN_TYPE' else (prefix+':ACC:'+accession if accession else prefix+':URL:'+key if key else prefix+':RID:'+rid)
 record=CollectionRecord(SOURCE,rid,url,minimal,name.strip(),museum_id=museum,accession_number=accession,data_license=effective,verification_status='NEEDS_REVIEW',context_only=not licensed)
 record.primary_language='zh-Hant' if prefix=='NPM' else 'zh-Hans' if re.search(r'[\u3400-\u9fff]',name) else 'en'
 record.copyright_notice=f"{collection.get('museum','')} | data {effective} | raw claim {claim} | image rights unverified | via {REPO}"
 record.dataset_url=f'{REPO}/tree/{sha}/data/relics'
 record.category_id='NUMISMATIC_OBJECT' if raw.get('category')=='钱币' else 'ARTWORK' if raw.get('category') in ('书画','碑帖拓本','历史影像') else 'HISTORICAL_OBJECT' if valid_years and years[0]>=1500 else 'ARCHAEOLOGICAL_ARTIFACT'
 record.historical_period_label=text(raw.get('dynasty'))
 record.materials=[raw['material']] if isinstance(raw.get('material'),str) and raw['material'].strip() else []
 record.extension={'date_label':text(raw.get('dynasty')),'calendar':'source_aggregator_signed_year_unspecified'}
 if valid_years:record.extension.update(year_start=years[0],year_end=years[1])
 record.evidence={k:(k,raw.get(k)) for k in ['relic_id','name','dynasty','year_range','material','collection','source_url','license']}
 record.names=[(record.primary_language,'ALIAS',x) for x in raw.get('aliases') or [] if isinstance(x,str) and x.strip()]
 record.media=[{'url':m['url'],'license_id':'UNKNOWN','approved':False,'copyright':m['declared_license'],'attribution':m['credit']} for m in media]
 return dict(record=record,rid=rid,prefix=prefix,museum=collection.get('museum'),inventory=inventory,entity=entity,kind=kind,claim=claim,verdict=verdict,effective=effective,terms=terms,media=media,issues=issues,minimal=minimal,payload_sha=digest,projection_sha=projection)
