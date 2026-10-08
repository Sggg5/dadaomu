"""NHM/Darwin Core and GBIF: taxa, occurrences and catalogued specimens stay distinct."""
import json
from database.normalizers.record import CollectionRecord, license_id, text

def gbif(raw):
    key = str(raw['key'])
    r = CollectionRecord('GBIF', key, 'https://www.gbif.org/occurrence/'+key,raw, raw.get('scientificName'),
                         object_kind='NATURAL_HISTORY',category_id='FOSSIL_SPECIMEN',extension_table='fossil_specimens',
                         accession_number=raw.get('catalogNumber'),data_license=license_id(raw.get('license')),
                         museum_id='NHMUK' if raw.get('institutionCode')=='NHMUK' else None,
                         dataset_url='https://www.gbif.org/dataset/'+raw['datasetKey'])
    basis = raw.get('basisOfRecord')
    r.primary_language='la'
    if basis not in ('FOSSIL_SPECIMEN','PRESERVED_SPECIMEN') or not r.accession_number:
        r.context_only=True # no object created; occurrence/taxon only
    if basis == 'PRESERVED_SPECIMEN': r.category_id='BIOLOGICAL_SPECIMEN'; r.extension_table='biological_specimens'
    dynamic = raw.get('dynamicProperties') or '{}'
    try: dynamic=json.loads(dynamic) if isinstance(dynamic,str) else dynamic
    except ValueError: dynamic={}
    r.description = text(dynamic.get('catalogueDescription'))
    r.discovery = text(raw.get('locality')); r.region = text(raw.get('country'))
    # occurrence eventDate/year is not automatically a fossil discovery year.
    r.extension = {'scientific_name':raw.get('scientificName'), 'taxonomic_rank':raw.get('taxonRank'),
                   'preserved_element':r.description, 'identification_confidence': '; '.join(raw.get('issues') or []) or None}
    r.occurrence = {'id':raw.get('occurrenceID') or 'GBIF:'+key, 'taxon_external_id':str(raw.get('taxonKey') or ''),
                    'scientific_name':raw.get('scientificName'), 'rank':raw.get('taxonRank'), 'basis':basis,
                    'formation':raw.get('formation'), 'geological_period':raw.get('earliestPeriodOrLowestSystem')}
    r.names = [('la','SCIENTIFIC',raw['scientificName'])] if raw.get('scientificName') else []
    if raw.get('issues'): r.verification_status='NEEDS_REVIEW'
    r.evidence = {'primary_name':('scientificName',raw.get('scientificName')), 'accession_number':('catalogNumber',r.accession_number),
                  'fossil.geological_period':('earliestPeriodOrLowestSystem',raw.get('earliestPeriodOrLowestSystem')),
                  'fossil.discovery_year':('eventDate', None)}
    for media in raw.get('media') or []:
        if media.get('identifier'):
            lic=license_id(media.get('license'))
            r.media.append({'url':media['identifier'],'license_id':lic,'approved':lic in ('CC0','CC_BY'),
                            'attribution':media.get('creator') or media.get('rightsHolder'), 'copyright':media.get('rightsHolder') or '', 'kind':'IMAGE'})
    return r

def nhm(raw):
    # Official downloaded Darwin Core row must include its dataset licence, not assumed portal-wide.
    mapped=dict(raw,key=raw.get('_id') or raw.get('occurrenceID'),datasetKey=raw.get('datasetKey') or '7e380070-f762-11e1-a439-00145eb45e9a',
                basisOfRecord=raw.get('basisOfRecord') or 'PRESERVED_SPECIMEN',institutionCode=raw.get('institutionCode') or 'NHMUK')
    r=gbif(mapped); r.source_id='NHM'; r.raw=raw
    r.record_url='https://data.nhm.ac.uk/object/'+str(raw.get('occurrenceID') or raw.get('_id'))
    r.dataset_url='https://data.nhm.ac.uk/dataset/collection-specimens'
    return r
