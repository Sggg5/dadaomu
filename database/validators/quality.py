"""Cross-table and rights validation; NULL is unknown, not a failed invented fact."""
import json
from database.schema.migrate import VOCABS

def validate_db(db):
    errors=[]
    errors += ['Foreign key violation: '+str(tuple(r)) for r in db.execute('PRAGMA foreign_key_check')]
    if db.execute('PRAGMA integrity_check').fetchone()[0]!='ok':errors.append('SQLite integrity check failed')
    for row in db.execute('SELECT * FROM collection_objects'):
        count=db.execute('SELECT count(*) FROM source_records WHERE object_id=?',(row['object_id'],)).fetchone()[0]
        if not count:errors.append('Object lacks source: '+row['object_id'])
        if row['object_kind']=='CULTURAL_HERITAGE' and db.execute('SELECT 1 FROM fossil_specimens WHERE object_id=?',(row['object_id'],)).fetchone():
            errors.append('Fossil/cultural kind mismatch: '+row['object_id'])
    for row in db.execute('SELECT * FROM vocab_names'):
        if row['vocab'] not in VOCABS or not db.execute(f"SELECT 1 FROM {row['vocab']} WHERE id=?",(row['term_id'],)).fetchone():
            errors.append('Dangling vocabulary name: '+row['term_id'])
    # Review flags are retained separately from hard failures.
    return {'errors':errors,'objects':db.execute('SELECT count(*) FROM collection_objects').fetchone()[0],
            'needs_review':db.execute("SELECT count(*) FROM collection_objects WHERE verification_status='NEEDS_REVIEW'").fetchone()[0],
            'unknown_data_license':db.execute("SELECT count(*) FROM source_records WHERE license_id IN('UNKNOWN','CONFIRM')").fetchone()[0],
            'unverified_media':db.execute("SELECT count(*) FROM media WHERE verification_status!='VERIFIED'").fetchone()[0]}

def report_licenses(db):
    return {'data':[dict(r) for r in db.execute('SELECT license_id,count(*) AS records FROM source_records GROUP BY license_id ORDER BY license_id')],
            'media':[dict(r) for r in db.execute('SELECT license_id,verification_status,count(*) AS records FROM media GROUP BY license_id,verification_status ORDER BY license_id,verification_status')]}

def statistics(db):
    fields=['description','museum_id','accession_number','origin_location_id','discovery_location_id']
    n=db.execute('SELECT count(*) FROM collection_objects').fetchone()[0]
    return {'objects':n,'by_category':[dict(r) for r in db.execute('SELECT category_id,count(*) AS count FROM collection_objects GROUP BY category_id ORDER BY category_id')],
            'by_culture':[dict(r) for r in db.execute('SELECT t.label,count(*) AS count FROM object_cultures c JOIN cultures t ON c.term_id=t.id GROUP BY t.id ORDER BY t.label')],
            'by_institution':[dict(r) for r in db.execute('SELECT museum_id,count(*) AS count FROM collection_objects GROUP BY museum_id ORDER BY museum_id')],
            'by_region':[dict(r) for r in db.execute('SELECT t.label,count(DISTINCT o.object_id) AS count FROM collection_objects o JOIN location_details l ON l.location_id=coalesce(o.discovery_location_id,o.origin_location_id) JOIN regions t ON t.id=l.region_id GROUP BY t.id ORDER BY t.label')],
            'fossil_periods':[dict(r) for r in db.execute('SELECT p.label,count(*) AS count FROM fossil_specimens f LEFT JOIN geological_periods p ON p.id=f.geological_period_id GROUP BY p.id ORDER BY p.label')],
            'missing':{field:db.execute(f'SELECT count(*) FROM collection_objects WHERE {field} IS NULL').fetchone()[0]/max(n,1) for field in fields},
            'duplicate_candidates':db.execute('SELECT count(*) FROM duplicate_candidates').fetchone()[0],
            'licenses':report_licenses(db)}
