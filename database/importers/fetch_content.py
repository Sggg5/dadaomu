"""Bounded, resumable official metadata batches; no image or arbitrary URL fetching."""
import argparse
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path
from database.schema.migrate import ROOT, utc_now

AGENT = 'DadaomuMuseumCatalog/0.1 (public metadata research; no images)'
MAX_BYTES = 20_000_000

def request_json(url):
    for attempt in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': AGENT}), timeout=35) as response:
                data = response.read(MAX_BYTES + 1)
            if len(data) > MAX_BYTES:
                raise ValueError('Metadata batch exceeds 20 MB')
            return json.loads(data)
        except Exception:
            if attempt == 2:
                raise
            time.sleep(1 + attempt)

def acquire_cma(query, limit=100, skip=0):
    if not 1 <= limit <= 100 or not 0 <= skip <= 2000:
        raise ValueError('Bounded pagination required')
    url = 'https://openaccess-api.clevelandart.org/api/artworks/?' + urllib.parse.urlencode(dict(q=query, limit=limit, skip=skip, cc0=1))
    data = request_json(url)
    return url, data['data']

def acquire_smithsonian(unit='nmnhminsci', shard='00', limit=200):
    if unit not in ('nmnhminsci', 'nmnhpaleo') or len(shard) != 2 or any(c not in '0123456789abcdef' for c in shard) or not 1 <= limit <= 250:
        raise ValueError('Unapproved public unit or batch size')
    url = f'https://smithsonian-open-access.s3-us-west-2.amazonaws.com/metadata/edan/{unit}/{shard}.txt'
    rows = []; size = 0
    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': AGENT}), timeout=35) as response:
        for _ in range(limit):
            line = response.readline(MAX_BYTES + 1); size += len(line)
            if size > MAX_BYTES:
                raise ValueError('Metadata batch exceeds 20 MB')
            if not line:
                break
            rows.append(json.loads(line))
    return url, rows

def acquire_gbif(taxon_key, limit=100):
    if not str(taxon_key).isdigit() or not 1 <= limit <= 100:
        raise ValueError('Numeric taxon and bounded batch required')
    url = 'https://api.gbif.org/v1/occurrence/search?' + urllib.parse.urlencode(dict(datasetKey='7e380070-f762-11e1-a439-00145eb45e9a', basisOfRecord='FOSSIL_SPECIMEN', taxonKey=taxon_key, limit=limit))
    return url, request_json(url)['results']

def save_batch(source, rows, url, path):
    from database.importers.registry import ADAPTERS
    valid = []; rejected = []
    for raw in rows:
        try:
            r = ADAPTERS[source](raw); r.validate()
            if r.context_only or r.data_license not in ('CC0', 'CC_BY') or not r.accession_number:
                raise ValueError('Not a licensed catalogued physical object')
            valid.append(raw)
        except Exception as exc:
            rejected.append(str(exc))
    when = utc_now(); target = Path(path); target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(''.join(json.dumps({'fetched_at': when, 'record': r}, ensure_ascii=False, sort_keys=True) + '\n' for r in valid), encoding='utf-8')
    return dict(source=source, url=url, fetched_at=when, file=str(target.resolve().relative_to(ROOT)), records=len(valid), rejected=len(rejected), rejection_reasons=sorted(set(rejected)), media_downloaded=0)

if __name__ == '__main__':
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('query'); p.add_argument('output'); p.add_argument('--skip', type=int, default=0)
    a = p.parse_args(); url, rows = acquire_cma(a.query, skip=a.skip)
    print(json.dumps(save_batch('CMA', rows, url, a.output), ensure_ascii=False, indent=2))

