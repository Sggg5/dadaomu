"""Creation, discovery and naming are distinct; both release and planning reuse these checks."""
def reference_time_issues(db, oid, anchor=1933, reviewed=False, acquisition_mode='UNREVIEWED'):
    issues=[]
    cultural=db.execute('SELECT year_start,year_end FROM cultural_heritage WHERE object_id=?',(oid,)).fetchone()
    if cultural:
        if cultural['year_end'] is not None and cultural['year_end']>anchor:
            issues.append('creation_after_or_spanning_world_year:'+oid)
        elif cultural['year_end'] is None and not (reviewed and acquisition_mode=='FICTIONAL_TOMB_ARCHETYPE'):
            issues.append('unknown_creation_date:'+oid)
    fossil=db.execute('SELECT discovery_year,taxon_id FROM fossil_specimens WHERE object_id=?',(oid,)).fetchone()
    if fossil:
        named=db.execute('SELECT named_year FROM taxon_details WHERE taxon_id=?',(fossil['taxon_id'],)).fetchone()
        named_year=named[0] if named else None
        uncertain=fossil['discovery_year'] is None or fossil['discovery_year']>anchor or named_year is None or named_year>anchor
        if uncertain and not (reviewed and acquisition_mode=='FICTIONAL_EXPEDITION'):
            issues.append('fossil_discovery_or_scientific_name_not_known_by_world_year:'+oid)
    return issues

def world_issues(db,game,anchor=1933):
    issues=[]
    if game['available_world_year'] is None or game['available_world_year']>anchor:
        issues.append('game_not_available_in_world_year')
    reviewed=bool(game['world_reviewed'] and game['world_review_note'].strip())
    if game['acquisition_mode']=='UNREVIEWED' or not reviewed:
        issues.append('world_acquisition_not_reviewed')
    for reference in db.execute('SELECT object_id FROM game_object_references WHERE game_id=?',(game['game_id'],)):
        issues.extend(reference_time_issues(db,reference[0],anchor,reviewed,game['acquisition_mode']))
    return issues
