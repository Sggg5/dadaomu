"""Context datasets and rights-gated local official exports. No scraping or login bypass."""
from database.normalizers.record import CollectionRecord, license_id

def pbdb(raw):
    id=str(raw.get('oid') or raw['occurrence_no'])
    r=CollectionRecord('PBDB',id,'https://paleobiodb.org/data1.2/occs/single.json?id='+id.replace('occ:',''),raw,
                       raw.get('tna') or raw.get('identified_name'),object_kind='NATURAL_HISTORY',
                       data_license=license_id(raw.get('license')),context_only=True)
    r.occurrence={'id':'PBDB:'+id,'taxon_external_id':raw.get('tid'),'scientific_name':r.primary_name,
                   'rank':raw.get('rank'),'basis':'FOSSIL_OCCURRENCE','formation':raw.get('formation'),
                   'geological_period':raw.get('early_interval')}
    return r

def npm(raw):
    required=('id','title','source_url','data_license')
    if any(not raw.get(k) for k in required):raise ValueError('NPM export needs official id/title/source_url and per-record data_license')
    r=CollectionRecord('NPM',str(raw['id']),raw['source_url'],raw,raw['title'],museum_id='NPM_TAIPEI',
                       accession_number=raw.get('catalog_number'),data_license=license_id(raw['data_license']))
    r.names=[('zh-Hant','ORIGINAL',raw['title'])]
    r.primary_language='zh-Hant'
    r.copyright_notice=raw['title']+' 國立故宮博物院，臺北，CC BY 4.0 @ www.npm.gov.tw'
    r.evidence={'primary_name':('title',raw['title'])}
    return r

def wenwu(raw):
    # Aggregator rights do not supersede the original museum; require explicit provenance.
    if not raw.get('source_url') or not raw.get('data_license') or not raw.get('rights_evidence_url'):
        raise ValueError('Aggregator record lacks original data-rights evidence')
    r=CollectionRecord('WENWU',str(raw.get('relic_id') or raw['id']),raw['source_url'],raw,raw.get('name'),
                       data_license=license_id(raw['data_license']),verification_status='NEEDS_REVIEW')
    return r
