"""Inspect every required natural specimen; never infer discovery, rank, mass or expert approval."""
import json
from collections import Counter
from pathlib import Path
from database.schema.migrate import ROOT

MINERAL_NAMES={'Quartz':'石英','Calcite':'方解石','Rhodonite':'蔷薇辉石','Siderite':'菱铁矿','Forsterite':'镁橄榄石','Franklinite':'锌铁尖晶石','Corundum (var. ruby)':'刚玉（红宝石变种）','Beryl':'绿柱石','Dravite':'Dravite（专业中文名待审）','Chondrodite':'Chondrodite（专业中文名待审）','Elbaite':'Elbaite（专业中文名待审）','Unakite':'Unakite（复合岩石/宝石材料分类待审）'}
FOSSIL_FIELDS=['scientific_name','rank','group','geological_period','formation','locality','specimen_number','institution','preserved_element','discovery_year','named_year','identification_confidence']
MINERAL_FIELDS=['recommended_zh_name','english_name','formula','crystal_system','locality','color','crystal_habit','specimen_number','institution']
METEOR_FIELDS=['official_name','classification','fall_or_find','locality','mass','dimensions','specimen_number','institution']

def raw_fields(source,raw):
    found={}
    def put(field,path,value):
        if value not in (None,[],{},''):found.setdefault(field,[]).append(dict(source_path=path,value=value))
    if source=='GBIF':
        for field,key in [('scientific_name','scientificName'),('rank','taxonRank'),('geological_period','earliestPeriodOrLowestSystem'),('formation','formation'),('locality','locality'),('specimen_number','catalogNumber'),('institution','institutionCode'),('group','phylum'),('identification_confidence','issues')]:put(field,key,raw.get(key))
        dynamic=raw.get('dynamicProperties') or '{}'
        try:dynamic=json.loads(dynamic) if isinstance(dynamic,str) else dynamic
        except ValueError:dynamic={}
        put('preserved_element','dynamicProperties.catalogueDescription',dynamic.get('catalogueDescription'))
    else:
        c=raw['content'];idx=c.get('indexedStructured',{});free=c.get('freetext',{});d=c['descriptiveNonRepeating']
        put('official_name','content.descriptiveNonRepeating.title.content',d.get('title',{}).get('content'));put('english_name','content.descriptiveNonRepeating.title.content',d.get('title',{}).get('content'))
        for field,key in [('scientific_name','scientific_name'),('geological_period','geo_age-system'),('formation','strat_formation'),('group','tax_phylum')]:put(field,'content.indexedStructured.'+key,idx.get(key))
        put('institution','content.freetext.dataSource',free.get('dataSource'))
        for key,label,field in [('identifier','USNM Number','specimen_number'),('place','Place','locality'),('notes','Skeletal Morphology','preserved_element'),('notes','Geologic Age','geological_age_verbatim'),('objectType','Type Status','type_status'),('physicalDescription','Color','color'),('physicalDescription','Crystal System','crystal_system'),('physicalDescription','Chemical Formula','formula'),('physicalDescription','Crystal Habit','crystal_habit'),('physicalDescription','Weight','mass'),('physicalDescription','Dimensions','dimensions'),('physicalDescription','Classification','classification')]:
            for i,row in enumerate(free.get(key,[])):
                if row.get('label')==label:put(field,f'content.freetext.{key}.{i}.content',row.get('content'))
        # Collection Date is recorded separately; never discovery year or fall date.
        for i,row in enumerate(free.get('date',[])):
            if row.get('label')=='Collection Date':put('collection_date',f'content.freetext.date.{i}.content',row.get('content'))
    return found

def build_audits(db,output=ROOT/'natural_history/audit_records.json'):
    objects=db.execute("SELECT * FROM collection_objects WHERE category_id IN('FOSSIL_SPECIMEN','MINERAL_SPECIMEN','METEORITE') OR object_id IN(SELECT object_id FROM collection_objects WHERE category_id='ROCK_SPECIMEN' ORDER BY object_id LIMIT 30) ORDER BY category_id,object_id").fetchall();audits=[]
    for obj in objects:
        sources=db.execute('SELECT * FROM source_records WHERE object_id=? ORDER BY source_id,record_id',(obj['object_id'],)).fetchall();fields={};issues=[]
        for source in sources:
            raw=json.loads(source['raw_json'])
            for name,values in raw_fields(source['source_id'],raw).items():
                fields.setdefault(name,[]).extend(dict(**v,source_id=source['source_id'],record_id=source['record_id'],record_url=source['record_url']) for v in values)
        names={json.dumps(v['value'],ensure_ascii=False,sort_keys=True) for v in fields.get('official_name',[])}
        if len(names)>1:issues.append('SHARED_CATALOGUE_NUMBER_CONFLICTING_NAMES_OR_SUBSAMPLES')
        if len({json.dumps(v['value'],sort_keys=True) for v in fields.get('mass',[])})>1:issues.append('CONFLICTING_SUBSAMPLE_MASSES_NOT_ONE_OBJECT_MEASUREMENT')
        category=obj['category_id'];required=FOSSIL_FIELDS if category=='FOSSIL_SPECIMEN' else MINERAL_FIELDS if category=='MINERAL_SPECIMEN' else METEOR_FIELDS if category=='METEORITE' else ['english_name','locality','specimen_number','institution']
        name=obj['primary_name']
        if category=='MINERAL_SPECIMEN':fields['recommended_zh_name']=[dict(value=MINERAL_NAMES.get(name,name+'（中文待审）'),source_path='EDITORIAL_TRANSLATION_NOT_OFFICIAL',status='DRAFT_PENDING_REVIEW',basis='Official English mineral name',record_url=sources[0]['record_url'])]
        if category=='FOSSIL_SPECIMEN':
            flat=str([v['value'] for v in fields.get('scientific_name',[])])
            if not fields.get('scientific_name') or 'Genus sp' in flat or 'Chordata' in flat:issues.append('UNRESOLVED_OR_HIGHER_TAXON_NOT_SPECIES')
            if not fields.get('geological_period'):issues.append('GEOLOGICAL_PERIOD_UNRESOLVED_OR_ERA_ONLY')
        if category=='MINERAL_SPECIMEN' and name=='Unakite':issues.append('AGGREGATE_ROCK_OR_GEM_MATERIAL_NOT_CONFIRMED_SINGLE_MINERAL')
        audits.append(dict(object_id=obj['object_id'],original_name=name,category=category,academic_review='NEEDS_REVIEW',fields=fields,missing=[f for f in required if not fields.get(f)],issues=issues,source_hashes=[dict(source_id=s['source_id'],record_id=s['record_id'],sha256=s['payload_sha256']) for s in sources],source_urls=[s['record_url'] for s in sources]))
        db.execute('''INSERT INTO natural_history_audits(object_id,audit_version,source_hashes_json,fields_json,issues_json) VALUES(?,?,?,?,?) ON CONFLICT(object_id) DO UPDATE SET source_hashes_json=excluded.source_hashes_json,fields_json=excluded.fields_json,issues_json=excluded.issues_json WHERE natural_history_audits.academic_review='NEEDS_REVIEW' ''',(obj['object_id'],1,json.dumps(audits[-1]['source_hashes']),json.dumps(fields,ensure_ascii=False),json.dumps(issues)))
        for field,values in fields.items():
            for v in values:
                if not v.get('source_id'):continue
                db.execute('INSERT OR REPLACE INTO field_evidence VALUES(?,?,?,?,?,?)',(obj['object_id'],'natural_audit.'+field,v['source_id'],v['record_id'],json.dumps(dict(source_path=v['source_path'],value=v['value']),ensure_ascii=False),'MATCHED'))
    knowledge=json.loads((ROOT/'natural_history/knowledge.json').read_text(encoding='utf-8-sig'))
    for k in knowledge:db.execute('INSERT OR IGNORE INTO natural_knowledge VALUES(?,?,?,?,?,?,?,?)',(k['knowledge_id'],k['subject_name'],k['field_name'],json.dumps(k['value']),k['scope'],k['authority_url'],k['checked_at'],k['review_status']))
    if output:Path(output).write_text(json.dumps(audits,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    return audits

def write_report(audits,path=ROOT/'docs/NATURAL_HISTORY_QUALITY.md'):
    counts=Counter(a['category'] for a in audits);missing=Counter(f for a in audits for f in a['missing']);evidence=sum(len(values) for a in audits for key,values in a['fields'].items() if key!='recommended_zh_name')
    text='# 自然历史逐条质量核查\n\n检查122对象：66化石、13矿物、13陨石及按object_id稳定抽查30岩石。所有源记录分别核对，同USNM多分样不会把质量合成整石质量。\n\n'+str(dict(counts))+'\n\n新增可追溯字段核查证据 '+str(evidence)+' 条（不是新增实测数据）。源学名、类群、地层、地质标签、保存部位、矿物颜色/切磨、陨石分样重量/采集时间有则逐字段保留。原库的发现年、命名年、精确Ma仍NULL，不从采集日期或题名推断。学术审核全部NEEDS_REVIEW。\n\n缺失字段统计：\n\n'
    text+='\n'.join('- '+k+'：'+str(v) for k,v in sorted(missing.items()))
    text+='\n\n方解石通用CaCO3与三方晶系知识来自Museum Wales，独立natural_knowledge保存；不写入某一实物化学检测或晶型。机构页面图片版权未授权，不下载。专业中文名仅待审译名，不覆盖官方名称。\n\n## 存疑记录与原始来源\n\n'
    for a in audits:
        if a['issues']:text+='- '+a['original_name']+' (`'+a['object_id']+'`)：'+', '.join(a['issues'])+'。 '+ ' / '.join('[原始记录]('+u+')' for u in a['source_urls'])+'\n'
    text+='\n## 处理边界\n\n部分陨石共用USNM号却有不同题名/重量，10B身份关联存在分样混合风险。本次保留1441身份，不悄然拆分或删记录；冲突组必须人工解析后才能作为特定样本内容或尺寸来源。Unakite当前矿物宽分类也待复核。Taxon/Occurrence/Specimen保持独立，字段核验不等于物种鉴定。所有记录详细字段与hash见natural_history/audit_records.json。\n'
    Path(path).write_text(text,encoding='utf-8');return dict(checked=len(audits),evidence=evidence,issues=sum(bool(a['issues']) for a in audits),missing=dict(missing))
