"""Bilingual controlled draft terms and source-literal suggested tags."""
import json
import re
from database.schema.migrate import ROOT
from database.editorial.content import value_at

TYPE_TAGS={'Jade':'JADE_OBJECT','Ceramic':'CERAMIC_OBJECT','Painting':'ART','Print':'ART','Calligraphy':'ART','Sculpture':'SCULPTURE','Garment':'TEXTILE','Embroidery':'TEXTILE','Tapestry':'TEXTILE','Furniture and woodwork':'FURNITURE'}
NATURAL_TAGS={'FOSSIL_SPECIMEN':'FOSSIL','MINERAL_SPECIMEN':'MINERAL','METEORITE':'METEORITE','ROCK_SPECIMEN':'ROCK'}

def load_terms(db,path=ROOT/'editorial/terms.json'):
    rows=json.loads(path.read_text(encoding='utf-8'))
    if len({r['term_id'] for r in rows})!=len(rows):raise ValueError('Duplicate controlled term ID')
    db.execute('BEGIN IMMEDIATE')
    try:
        for r in rows:
            if r['review_status']!='DRAFT_PENDING_REVIEW':raise ValueError('Term imports cannot claim human approval')
            db.execute('''INSERT OR IGNORE INTO editorial_terms VALUES(?,?,?,?,?,?,?,?)''',
                       (r['term_id'],r['parent_id'],r['domain'],r['zh_name'],r['en_name'],json.dumps(r['aliases'],ensure_ascii=False),r['authority_url'],r['review_status']))
        db.execute('COMMIT')
    except Exception:db.execute('ROLLBACK');raise
    return len(rows)

def match_term(db,alias,parent=None):
    """Ambiguous gui requires parent scope; never selects the first translation silently."""
    matches=[]
    for r in db.execute('SELECT * FROM editorial_terms ORDER BY term_id'):
        names=[r['term_id'],r['zh_name'],r['en_name']]+json.loads(r['aliases_json'])
        if any(alias.casefold()==n.casefold() for n in names) and (parent is None or r['parent_id']==parent):matches.append(dict(r))
    if len(matches)>1:raise ValueError('Ambiguous term; specify upper category')
    return matches[0] if matches else None

def source_tags(obj,raw):
    if obj['source_id']!='CMA':
        if obj['category_id'] in NATURAL_TAGS:yield NATURAL_TAGS[obj['category_id']],None,None
        if obj['source_id']=='SMITHSONIAN':
            for system in raw['content'].get('indexedStructured',{}).get('geo_age-system',[]):
                if system.upper() in {'CAMBRIAN','ORDOVICIAN','SILURIAN','DEVONIAN','CARBONIFEROUS','PERMIAN','TRIASSIC','JURASSIC','CRETACEOUS','PALEOGENE','NEOGENE','QUATERNARY'}:
                    yield system.upper(),'content.indexedStructured.geo_age-system',raw['content']['indexedStructured']['geo_age-system']
        return
    typ=raw.get('type');tech=raw.get('technique') or '';title=raw.get('title','')
    if typ in TYPE_TAGS:yield TYPE_TAGS[typ],'type',typ
    if re.search(r'\bbronze\b',tech,re.I):yield 'BRONZE_VESSEL','technique',tech
    for token,tid in [('(Ding)','DING'),('(Jue)','JUE'),('(Zun)','ZUN'),('(Hu)','HU'),('(Bi)','BI'),('(Gui)','GUI_JADE'),('(Cong)','CONG')]:
        if token.lower() in title.lower():yield tid,'title',title
    for token,tid in [('Ding ware','DING_WARE'),('Jian ware','JIAN_WARE'),('Jun ware','JUN_WARE'),('Qingbai','QINGBAI'),('Fahua','FAHUA'),('susancai','SUSANCAI'),('blue and white','BLUE_WHITE'),('celadon','CELADON')]:
        if token.lower() in tech.lower():yield tid,'technique',tech
    for culture in raw.get('culture') or []:
        for token,tid in [('China','CHINA'),('Egypt','EGYPT'),('Greece','GREECE'),('Rome','ROME'),('Persia','PERSIA'),('Mesopotamia','MESOPOTAMIA'),('India','SOUTH_ASIA'),('Mesoamerica','MESOAMERICA')]:
            if token.lower() in culture.lower():yield tid,'culture',raw['culture']
        for token,tid in [('Neolithic','H_NEOLITHIC'),('Shang dynasty','H_SHANG'),('Zhou dynasty','H_ZHOU'),('Warring States','H_WARRING_STATES'),('Han dynasty','H_HAN'),('Northern Dynasties','H_WEIJIN'),('Southern Dynasties','H_WEIJIN'),('Sui dynasty','H_SUI'),('Tang dynasty','H_TANG'),('Song dynasty','H_SONG'),('Yuan dynasty','H_YUAN'),('Ming dynasty','H_MING'),('Qing dynasty','H_QING')]:
            if token.lower() in culture.lower() and any('china' in x.lower() for x in raw['culture']):yield tid,'culture',raw['culture']

def build_tags(db):
    for r in db.execute('SELECT o.*,s.source_id,s.record_id,s.raw_json FROM collection_objects o JOIN source_records s ON s.object_id=o.object_id ORDER BY s.source_id,s.record_id').fetchall():
        raw=json.loads(r['raw_json'])
        for tid,path,value in source_tags(r,raw):
            # Natural kind is an internal normalization; cite the entire source, not an invented source path.
            if path is None:path='';value=raw
            db.execute('INSERT OR IGNORE INTO editorial_object_tags VALUES(?,?,?,?,?,?,?)',
                       (r['object_id'],tid,r['source_id'],r['record_id'],path,json.dumps(value,ensure_ascii=False),'DRAFT_PENDING_REVIEW'))
    return db.execute('SELECT count(*) FROM editorial_object_tags').fetchone()[0]
