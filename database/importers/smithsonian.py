"""EDAN unit records; stable record_ID, not temporary ld serialization ID."""
from database.normalizers.record import CollectionRecord, license_id, text

def values(freetext, key, label=None):
    return [row['content'] for row in freetext.get(key,[]) if row.get('content') and (label is None or row.get('label')==label)]

def smithsonian(raw):
    content=raw['content']; descriptive=content['descriptiveNonRepeating']; free=content.get('freetext',{})
    record_id=descriptive['record_ID']
    r=CollectionRecord('SMITHSONIAN',record_id,descriptive['record_link'],raw,descriptive.get('title',{}).get('content'),
                       museum_id='SMITHSONIAN',data_license=license_id(descriptive.get('metadata_usage',{}).get('access')))
    r.accession_number=next(iter(values(free,'identifier','USNM Number') or values(free,'identifier','Accession Number')),None)
    unit=descriptive.get('unit_code',raw.get('unitCode',''))
    r.description='; '.join(values(free,'notes','Description')) or None
    r.discovery='; '.join(values(free,'place','Place')) or None
    geo=content.get('indexedStructured',{}).get('geoLocation',[])
    if geo:r.region=text(geo[0].get('L2',{}).get('content'))
    r.evidence={'primary_name':('content.descriptiveNonRepeating.title.content',r.primary_name),
                'accession_number':('content.freetext.identifier',r.accession_number)}
    if unit=='NMNHMINSCI':
        r.object_kind='NATURAL_HISTORY'
        collections=' '.join(values(free,'setName')).lower()
        if 'meteorite' in collections:
            r.category_id='METEORITE';r.extension_table='meteorite_specimens'
            r.extension={'official_name':r.primary_name,'classification':'; '.join(values(free,'physicalDescription','Classification')) or None}
        elif 'rock' in collections or 'petrology' in collections:
            r.category_id='ROCK_SPECIMEN';r.extension_table='rock_specimens'
            r.extension={'lithology':r.primary_name}
        else:
            r.category_id='MINERAL_SPECIMEN';r.extension_table='mineral_specimens'
            r.extension={'mineral_name':r.primary_name,'classification': '; '.join(values(free,'physicalDescription','Classification')) or None,
                         'chemical_composition':'; '.join(values(free,'physicalDescription','Chemical Formula')) or None,
                         'crystal_system':'; '.join(values(free,'physicalDescription','Crystal System')) or None}
    elif unit=='NMNHPALEO':
        r.object_kind='NATURAL_HISTORY';r.category_id='FOSSIL_SPECIMEN';r.extension_table='fossil_specimens'
        names=content.get('indexedStructured',{}).get('scientific_name',[])
        indexed = content.get('indexedStructured', {})
        systems = indexed.get('geo_age-system', [])
        age_notes = values(free, 'notes', 'Geologic Age')
        if not systems and not age_notes:
            raise ValueError('Paleobiology collection membership alone does not establish a fossil')
        scientific = names[0] if names else None
        r.extension = {'scientific_name': scientific,
                       'preserved_element': '; '.join(values(free, 'notes', 'Skeletal Morphology')) or None}
        r.occurrence = {'id': 'SMITHSONIAN:' + record_id, 'taxon_external_id': scientific,
                        'scientific_name': scientific, 'rank': None, 'basis': 'FOSSIL_SPECIMEN',
                        'formation': next(iter(indexed.get('strat_formation', [])), None),
                        'geological_period': systems[0] if systems else None}
        r.evidence['fossil.geological_period'] = ('content.indexedStructured.geo_age-system', systems[0] if systems else None)
        r.evidence['fossil.geological_age_label'] = ('content.freetext.notes.Geologic Age', age_notes or None)
        r.evidence['fossil.discovery_year'] = ('Collection Date is not discovery date', None)
        r.verification_status = 'NEEDS_REVIEW' # source classification is not expert specimen identification

    for item in free.get('physicalDescription',[]):
        if item.get('content'):r.measurements.append((item.get('label','verbatim'),None,None,item['content']))
    online=descriptive.get('online_media',{}).get('media',[])
    for media in online:
        if not media.get('content'):continue
        lic=license_id(media.get('usage',{}).get('access'))
        r.media.append({'url':media['content'],'license_id':lic,'approved':lic=='CC0',
                        'copyright':media.get('usage',{}).get('text',''),'kind':'MODEL' if media.get('type')=='3d' else 'IMAGE'})
    return r
