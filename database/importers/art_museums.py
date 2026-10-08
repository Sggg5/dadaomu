"""Three independent official museum mappings; no automatic translation."""
from database.normalizers.record import CollectionRecord, inferred_materials, text

def cma(raw):
    r = CollectionRecord('CMA', str(raw['id']), raw['url'], raw, raw.get('title'), museum_id='CMA',
                         accession_number=raw.get('accession_number'), description=raw.get('description'), data_license='CC0')
    r.cultures = raw.get('culture') or []
    r.materials = inferred_materials(raw.get('technique'))
    r.techniques = [raw['technique']] if raw.get('technique') else []
    r.extension = {'year_start': raw.get('creation_date_earliest'), 'year_end': raw.get('creation_date_latest'),
                   'date_label': raw.get('creation_date'), 'calendar': 'source_signed_year_unspecified',
                   'inscriptions': raw.get('inscriptions')}
    if raw.get('type') in ('Painting', 'Paintings', 'Print', 'Prints', 'Calligraphy'): r.category_id = 'ARTWORK'
    r.evidence = {'primary_name': ('title', raw.get('title')), 'cultural.year_start': ('creation_date_earliest', raw.get('creation_date_earliest')),
                  'cultural.year_end': ('creation_date_latest', raw.get('creation_date_latest')), 'materials': ('technique',raw.get('technique'))}
    original = text(raw.get('title_in_original_language'))
    if original and '\ufffd' not in original:
        r.names.append(('und', 'ORIGINAL', original))
    for alias in raw.get('alternate_titles') or []:
        if isinstance(alias, str): r.names.append(('en','ALIAS',alias))
    if raw.get('measurements'): r.measurements.append(('dimensions', None, None, raw['measurements']))
    for kind, img in (raw.get('images') or {}).items():
        if kind == 'web' and img.get('url'):
            allowed = raw.get('share_license_status') == 'CC0'
            r.media.append({'url': img['url'], 'license_id': 'CC0' if allowed else 'UNKNOWN', 'approved': allowed,
                            'copyright': raw.get('copyright') or raw.get('share_license_status') or '', 'kind':'IMAGE'})
    return r

def met(raw):
    r = CollectionRecord('MET', str(raw['objectID']), raw['objectURL'], raw, raw.get('title'), museum_id='MET',
                         accession_number=raw.get('accessionNumber'), data_license='CC0')
    r.cultures = [raw['culture']] if raw.get('culture') else []
    r.origin = text(raw.get('country')); r.region = r.origin
    r.materials = inferred_materials(raw.get('medium'))
    r.techniques = [raw['medium']] if raw.get('medium') else []
    r.extension = {'year_start':raw.get('objectBeginDate'), 'year_end':raw.get('objectEndDate'),
                   'date_label':raw.get('objectDate'), 'calendar':'source_signed_year_unspecified', 'historical_context':None}
    r.evidence = {'primary_name': ('title',raw.get('title')), 'cultural.year_start':('objectBeginDate',raw.get('objectBeginDate')),
                  'cultural.year_end':('objectEndDate',raw.get('objectEndDate')), 'materials':('medium',raw.get('medium'))}
    if raw.get('dimensions'): r.measurements.append(('dimensions',None,None,raw['dimensions']))
    if raw.get('primaryImage'):
        allowed = raw.get('isPublicDomain') is True
        r.media.append({'url':raw['primaryImage'],'license_id':'CC0' if allowed else 'UNKNOWN','approved':allowed,'copyright':raw.get('rightsAndReproduction') or '', 'kind':'IMAGE'})
    return r

def aic(raw):
    r = CollectionRecord('AIC',str(raw['id']),f"https://www.artic.edu/artworks/{raw['id']}",raw,raw.get('title'),museum_id='AIC',
                         accession_number=raw.get('main_reference_number'),description=raw.get('description'),data_license='CC0')
    r.extension = {'year_start':raw.get('date_start'),'year_end':raw.get('date_end'),'date_label':raw.get('date_display'), 'calendar':'source_signed_year_unspecified'}
    r.origin = text(raw.get('place_of_origin')); r.materials = inferred_materials(raw.get('medium_display'))
    r.evidence = {'primary_name':('title',raw.get('title'))}
    if raw.get('dimensions'): r.measurements.append(('dimensions',None,None,raw['dimensions']))
    if raw.get('image_id'):
        allowed = raw.get('is_public_domain') is True
        r.media.append({'url':f"https://www.artic.edu/iiif/2/{raw['image_id']}/full/843,/0/default.jpg",'license_id':'CC0' if allowed else 'UNKNOWN','approved':allowed,'copyright':raw.get('copyright_notice') or '', 'kind':'IMAGE'})
    return r
