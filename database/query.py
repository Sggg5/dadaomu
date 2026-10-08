"""Offline parameterized filters; FTS for words, LIKE fallback for CJK substrings."""
def build_index(db):
    db.execute('BEGIN IMMEDIATE')
    try:
        db.execute('DELETE FROM catalogue_fts')
        db.execute('''INSERT INTO catalogue_fts(object_id,names,description)
                      SELECT o.object_id,coalesce(group_concat(n.value,' '),o.primary_name),coalesce(o.description,'')
                      FROM collection_objects o LEFT JOIN object_names n ON n.object_id=o.object_id GROUP BY o.object_id''')
        db.execute('COMMIT')
    except Exception:
        db.execute('ROLLBACK');raise

FILTERS={
 'kind':('o.object_kind=?',None), 'category':('o.category_id=?',None), 'institution':('o.museum_id=?',None),
 'confidence':('o.verification_status=?',None), 'license':('o.license_status=?',None),
 'culture':('o.object_id IN(SELECT c.object_id FROM object_cultures c JOIN cultures t ON t.id=c.term_id WHERE t.id=? OR t.label LIKE ?)', 'term'),
 'material':('o.object_id IN(SELECT c.object_id FROM object_materials c JOIN materials t ON t.id=c.term_id WHERE t.id=? OR t.label LIKE ?)', 'term'),
 'historical_period':('o.object_id IN(SELECT object_id FROM cultural_heritage WHERE historical_period_id=?)',None),
 'geological_period':('o.object_id IN(SELECT object_id FROM fossil_specimens WHERE geological_period_id=?)',None),
 'taxon':('o.object_id IN(SELECT f.object_id FROM fossil_specimens f JOIN taxa t ON t.id=f.taxon_id WHERE t.id=? OR t.label LIKE ?)', 'term'),
 'findspot':('o.discovery_location_id IN(SELECT id FROM locations WHERE id=? OR label LIKE ?)', 'term'),
 'region':('''coalesce(o.discovery_location_id,o.origin_location_id) IN(SELECT location_id FROM location_details WHERE region_id IN(
              WITH RECURSIVE descendants(id) AS (SELECT id FROM regions WHERE id=? OR label LIKE ?
              UNION SELECT r.id FROM regions r JOIN descendants d ON r.parent_id=d.id) SELECT id FROM descendants))''', 'term'),
 'media_license':('o.object_id IN(SELECT object_id FROM media WHERE license_id=?)',None)}

def search_catalog(db,keyword='',limit=50,**filters):
    clauses=[];params=[]
    if keyword:
        query='"'+keyword.replace('"','""')+'"'
        clauses.append('''(o.object_id IN(SELECT object_id FROM catalogue_fts WHERE catalogue_fts MATCH ?)
                          OR o.object_id IN(SELECT object_id FROM object_names WHERE value LIKE ?))''')
        params.extend((query,'%'+keyword+'%'))
    for key,value in filters.items():
        if value is None:continue
        if key not in FILTERS:raise ValueError('Unsupported search filter: '+key)
        sql,kind=FILTERS[key];clauses.append(sql);params.append(value)
        if kind=='term':params.append('%'+value+'%')
    where=' WHERE '+' AND '.join(clauses) if clauses else ''
    params.append(min(max(int(limit),1),1000))
    return [dict(r) for r in db.execute('SELECT o.* FROM collection_objects o'+where+' ORDER BY o.object_id LIMIT ?',params)]
