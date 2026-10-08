"""Bounded official public metadata acquisition; never follows auth bypasses or downloads images."""
import argparse
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path
from database.schema.migrate import utc_now

MAX_BYTES=20_000_000
ENDPOINTS={'CMA':'https://openaccess-api.clevelandart.org/api/artworks/',
           'MET':'https://collectionapi.metmuseum.org/public/collection/v1/objects/',
           'AIC':'https://api.artic.edu/api/v1/artworks/',
           'GBIF':'https://api.gbif.org/v1/occurrence/search'}

def fetch_source(source,output,record_id=None,query=None,limit=20,shard='00',unit='nmnhminsci'):
    limit=min(max(int(limit),1),100)
    if source in ('MET','AIC'):
        if not record_id or not str(record_id).isdigit():raise ValueError('Numeric official object id required')
        url=ENDPOINTS[source]+str(record_id)
    elif source=='CMA':url=ENDPOINTS[source]+'?'+urllib.parse.urlencode(dict(q=query or '',limit=limit,cc0=1))
    elif source=='GBIF':url=ENDPOINTS[source]+'?'+urllib.parse.urlencode(dict(basisOfRecord='FOSSIL_SPECIMEN',limit=limit))
    elif source=='SMITHSONIAN':
        if unit not in ('nmnhminsci','nmnhpaleo') or len(shard)!=2 or any(c not in '0123456789abcdef' for c in shard):
            raise ValueError('Only approved public natural-history unit shards allowed')
        url=f'https://smithsonian-open-access.s3-us-west-2.amazonaws.com/metadata/edan/{unit}/{shard}.txt'
    else:raise ValueError('This source uses a licensed local official export or a separately reviewed context download; no automatic scraping')
    request=urllib.request.Request(url,headers={'User-Agent':'DadaomuMuseumCatalog/0.1 (public metadata research; no images)'})
    with urllib.request.urlopen(request,timeout=30) as response:
        data=response.read(MAX_BYTES+1)
    if len(data)>MAX_BYTES:raise ValueError('Response exceeds bounded metadata limit')
    if source=='SMITHSONIAN':rows=[json.loads(line) for line in data.splitlines()[:limit]]
    else:
        payload=json.loads(data)
        rows=payload['data'] if source=='CMA' else payload['results'] if source=='GBIF' else [payload['data']] if source=='AIC' else [payload]
    target=Path(output);target.parent.mkdir(parents=True,exist_ok=True)
    when=utc_now()
    target.write_text(''.join(json.dumps({'fetched_at':when,'record':row},ensure_ascii=False,sort_keys=True)+'\n' for row in rows),encoding='utf-8')
    return {'source':source,'url':url,'fetched_at':when,'records':len(rows),'media_downloaded':0}

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('source',choices=list(ENDPOINTS)+['SMITHSONIAN']);p.add_argument('output')
    p.add_argument('--id',dest='record_id');p.add_argument('--query');p.add_argument('--limit',type=int,default=20)
    p.add_argument('--shard',default='00');p.add_argument('--unit',default='nmnhminsci')
    args=p.parse_args()
    print(json.dumps(fetch_source(args.source,args.output,args.record_id,args.query,args.limit,args.shard,args.unit),indent=2))
