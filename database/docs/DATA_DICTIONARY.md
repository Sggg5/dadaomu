# Data Dictionary

Schema v3. FK关系/类型/默认与非空约束由版本化SQL定义；NULL代表未知，不用0或猜测填充。

## biological_specimens

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|no|1|NULL|
|scientific_name|TEXT|no|0|NULL|
|taxon_id|TEXT|no|0|NULL|
|collecting_location_id|TEXT|no|0|NULL|
|collecting_date|TEXT|no|0|NULL|

外键：collecting_location_id → locations.id; taxon_id → taxa.id; object_id → collection_objects.object_id。

## catalogue_fts

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id||no|0|NULL|
|names||no|0|NULL|
|description||no|0|NULL|

## collection_objects

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|no|1|NULL|
|object_kind|TEXT|yes|0|NULL|
|category_id|TEXT|yes|0|NULL|
|primary_name|TEXT|yes|0|NULL|
|description|TEXT|no|0|NULL|
|museum_id|TEXT|no|0|NULL|
|accession_number|TEXT|no|0|NULL|
|origin_location_id|TEXT|no|0|NULL|
|discovery_location_id|TEXT|no|0|NULL|
|license_status|TEXT|yes|0|NULL|
|verification_status|TEXT|yes|0|NULL|
|translation_status|TEXT|yes|0|'pending'|
|editor_locked|INTEGER|yes|0|0|

外键：license_status → licenses.license_id; discovery_location_id → locations.id; origin_location_id → locations.id; museum_id → institutions.id; category_id → object_categories.id。

## cultural_heritage

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|no|1|NULL|
|historical_period_id|TEXT|no|0|NULL|
|year_start|INTEGER|no|0|NULL|
|year_end|INTEGER|no|0|NULL|
|date_label|TEXT|no|0|NULL|
|calendar|TEXT|no|0|'astronomical_proleptic_gregorian'|
|date_uncertainty|TEXT|no|0|NULL|
|creation_place_id|TEXT|no|0|NULL|
|findspot_id|TEXT|no|0|NULL|
|artifact_type_id|TEXT|no|0|NULL|
|inscriptions|TEXT|no|0|NULL|
|historical_context|TEXT|no|0|NULL|
|interpretation|TEXT|no|0|NULL|

外键：artifact_type_id → object_categories.id; findspot_id → locations.id; creation_place_id → locations.id; historical_period_id → historical_periods.id; object_id → collection_objects.object_id。

## cultures

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → cultures.id。

## duplicate_candidates

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|first_object_id|TEXT|yes|1|NULL|
|second_object_id|TEXT|yes|2|NULL|
|reason|TEXT|yes|3|NULL|
|status|TEXT|yes|0|'PENDING'|

外键：second_object_id → collection_objects.object_id; first_object_id → collection_objects.object_id。

## field_evidence

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|yes|1|NULL|
|field_path|TEXT|yes|2|NULL|
|source_id|TEXT|yes|3|NULL|
|record_id|TEXT|yes|4|NULL|
|source_value|TEXT|no|0|NULL|
|status|TEXT|yes|0|NULL|

外键：source_id → source_records.source_id; record_id → source_records.record_id; object_id → collection_objects.object_id。

## formations

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → formations.id。

## fossil_specimens

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|no|1|NULL|
|scientific_name|TEXT|no|0|NULL|
|taxon_id|TEXT|no|0|NULL|
|taxonomic_rank|TEXT|no|0|NULL|
|geological_period_id|TEXT|no|0|NULL|
|formation_id|TEXT|no|0|NULL|
|age_min_ma|REAL|no|0|NULL|
|age_max_ma|REAL|no|0|NULL|
|preserved_element|TEXT|no|0|NULL|
|preservation_type|TEXT|no|0|NULL|
|completeness|TEXT|no|0|NULL|
|identification_confidence|TEXT|no|0|NULL|
|discovery_location_id|TEXT|no|0|NULL|
|discovery_year|INTEGER|no|0|NULL|
|occurrence_id|TEXT|no|0|NULL|

外键：occurrence_id → occurrences.occurrence_id; discovery_location_id → locations.id; formation_id → formations.id; geological_period_id → geological_periods.id; taxon_id → taxa.id; object_id → collection_objects.object_id。

## game_collection_definitions

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|game_id|TEXT|no|1|NULL|
|display_name|TEXT|yes|0|NULL|
|description|TEXT|yes|0|NULL|
|category|TEXT|yes|0|NULL|
|rarity|TEXT|yes|0|NULL|
|base_value|INTEGER|yes|0|NULL|
|inventory_slots|INTEGER|yes|0|NULL|
|exhibit_appeal|INTEGER|yes|0|NULL|
|unlock_conditions|TEXT|yes|0|'[]'|
|game_asset_id|TEXT|no|0|NULL|
|approved|INTEGER|yes|0|0|
|available_world_year|INTEGER|no|0|NULL|
|acquisition_mode|TEXT|yes|0|'UNREVIEWED'|
|world_reviewed|INTEGER|yes|0|0|
|world_review_note|TEXT|yes|0|''|
|transport_mode|TEXT|yes|0|'HAND_CARRY'|
|legacy_resource_path|TEXT|no|0|NULL|
|curator_locked|INTEGER|yes|0|1|

外键：category → object_categories.id。

## game_object_references

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|game_id|TEXT|yes|1|NULL|
|object_id|TEXT|yes|2|NULL|
|relation|TEXT|yes|0|NULL|
|review_note|TEXT|yes|0|NULL|

外键：object_id → collection_objects.object_id; game_id → game_collection_definitions.game_id。

## game_obtain_regions

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|game_id|TEXT|yes|1|NULL|
|region_id|TEXT|yes|2|NULL|

外键：region_id → regions.id; game_id → game_collection_definitions.game_id。

## geological_periods

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → geological_periods.id。

## geological_specimens

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|no|1|NULL|
|geological_period_id|TEXT|no|0|NULL|
|formation_id|TEXT|no|0|NULL|

外键：formation_id → formations.id; geological_period_id → geological_periods.id; object_id → collection_objects.object_id。

## geological_timescale

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|period_id|TEXT|no|1|NULL|
|rank|TEXT|yes|0|NULL|
|age_min_ma|REAL|no|0|NULL|
|age_max_ma|REAL|no|0|NULL|
|scale_version|TEXT|yes|0|NULL|

外键：period_id → geological_periods.id。

## historical_periods

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → historical_periods.id。

## human_chronology

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|period_id|TEXT|no|1|NULL|
|year_start|INTEGER|no|0|NULL|
|year_end|INTEGER|no|0|NULL|
|calendar|TEXT|yes|0|'astronomical_proleptic_gregorian'|
|uncertainty|TEXT|no|0|NULL|

外键：period_id → historical_periods.id。

## import_errors

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|run_id|INTEGER|yes|0|NULL|
|record_id|TEXT|no|0|NULL|
|message|TEXT|yes|0|NULL|

外键：run_id → import_runs.run_id。

## import_runs

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|run_id|INTEGER|no|1|NULL|
|source_id|TEXT|no|0|NULL|
|started_at|TEXT|yes|0|NULL|
|finished_at|TEXT|no|0|NULL|
|succeeded|INTEGER|no|0|0|
|skipped|INTEGER|no|0|0|
|duplicates|INTEGER|no|0|0|
|errors|INTEGER|no|0|0|
|unknown_license|INTEGER|no|0|0|

外键：source_id → sources.source_id。

## institutions

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → institutions.id。

## licenses

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|license_id|TEXT|no|1|NULL|
|label|TEXT|yes|0|NULL|
|url|TEXT|no|0|NULL|
|commercial_allowed|INTEGER|no|0|NULL|
|attribution_required|INTEGER|yes|0|0|

## location_details

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|location_id|TEXT|no|1|NULL|
|region_id|TEXT|no|0|NULL|
|latitude|REAL|no|0|NULL|
|longitude|REAL|no|0|NULL|

外键：region_id → regions.id; location_id → locations.id。

## locations

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → locations.id。

## materials

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → materials.id。

## measurements

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|yes|1|NULL|
|dimension|TEXT|yes|2|NULL|
|value|REAL|no|0|NULL|
|unit|TEXT|no|0|NULL|
|verbatim|TEXT|yes|3|NULL|
|source_id|TEXT|no|0|NULL|
|record_id|TEXT|no|0|NULL|

外键：source_id → source_records.source_id; record_id → source_records.record_id; object_id → collection_objects.object_id。

## media

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|media_id|TEXT|no|1|NULL|
|object_id|TEXT|yes|0|NULL|
|media_kind|TEXT|yes|0|NULL|
|url|TEXT|yes|0|NULL|
|license_id|TEXT|yes|0|NULL|
|commercial_allowed|INTEGER|no|0|NULL|
|verification_status|TEXT|yes|0|NULL|
|copyright_notice|TEXT|yes|0|NULL|
|attribution|TEXT|no|0|NULL|
|terms_url|TEXT|yes|0|NULL|
|checked_at|TEXT|no|0|NULL|
|source_id|TEXT|yes|0|NULL|
|record_id|TEXT|yes|0|NULL|
|local_asset_path|TEXT|no|0|NULL|

外键：source_id → source_records.source_id; record_id → source_records.record_id; license_id → licenses.license_id; object_id → collection_objects.object_id。

## meteorite_specimens

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|no|1|NULL|
|official_name|TEXT|no|0|NULL|
|classification|TEXT|no|0|NULL|
|fall_date|TEXT|no|0|NULL|
|discovery_date|TEXT|no|0|NULL|
|discovery_location_id|TEXT|no|0|NULL|
|specimen_type|TEXT|no|0|NULL|

外键：discovery_location_id → locations.id; object_id → collection_objects.object_id。

## mineral_specimens

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|no|1|NULL|
|mineral_name|TEXT|no|0|NULL|
|classification|TEXT|no|0|NULL|
|chemical_composition|TEXT|no|0|NULL|
|crystal_system|TEXT|no|0|NULL|
|origin_location_id|TEXT|no|0|NULL|
|crystal_habit|TEXT|no|0|NULL|

外键：origin_location_id → locations.id; object_id → collection_objects.object_id。

## object_categories

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → object_categories.id。

## object_cultures

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|yes|1|NULL|
|term_id|TEXT|yes|2|NULL|

外键：term_id → cultures.id; object_id → collection_objects.object_id。

## object_materials

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|yes|1|NULL|
|term_id|TEXT|yes|2|NULL|

外键：term_id → materials.id; object_id → collection_objects.object_id。

## object_names

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|yes|1|NULL|
|language|TEXT|yes|2|NULL|
|name_type|TEXT|yes|3|NULL|
|value|TEXT|yes|4|NULL|
|translation_status|TEXT|yes|0|NULL|
|curator_locked|INTEGER|yes|0|0|
|source_id|TEXT|no|0|NULL|
|record_id|TEXT|no|0|NULL|

外键：source_id → source_records.source_id; record_id → source_records.record_id; object_id → collection_objects.object_id。

## object_techniques

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|yes|1|NULL|
|term_id|TEXT|yes|2|NULL|

外键：term_id → techniques.id; object_id → collection_objects.object_id。

## occurrences

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|occurrence_id|TEXT|no|1|NULL|
|source_id|TEXT|yes|0|NULL|
|source_record_id|TEXT|yes|0|NULL|
|taxon_id|TEXT|no|0|NULL|
|locality_id|TEXT|no|0|NULL|
|formation_id|TEXT|no|0|NULL|
|basis_of_record|TEXT|yes|0|NULL|
|record_url|TEXT|yes|0|NULL|

外键：formation_id → formations.id; locality_id → locations.id; taxon_id → taxa.id; source_id → sources.source_id。

## regions

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → regions.id。

## rock_specimens

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|object_id|TEXT|no|1|NULL|
|lithology|TEXT|no|0|NULL|
|geological_setting|TEXT|no|0|NULL|
|origin_location_id|TEXT|no|0|NULL|

外键：origin_location_id → locations.id; object_id → collection_objects.object_id。

## schema_migrations

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|version|INTEGER|no|1|NULL|
|name|TEXT|yes|0|NULL|
|sha256|TEXT|yes|0|NULL|
|applied_at|TEXT|yes|0|NULL|

## source_records

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|source_id|TEXT|yes|1|NULL|
|record_id|TEXT|yes|2|NULL|
|object_id|TEXT|no|0|NULL|
|record_url|TEXT|yes|0|NULL|
|dataset_url|TEXT|no|0|NULL|
|license_id|TEXT|yes|0|NULL|
|copyright_notice|TEXT|yes|0|NULL|
|fetched_at|TEXT|yes|0|NULL|
|checked_at|TEXT|yes|0|NULL|
|commercial_allowed|INTEGER|no|0|NULL|
|payload_sha256|TEXT|yes|0|NULL|
|raw_json|TEXT|yes|0|NULL|
|normalizer_version|INTEGER|yes|0|0|

外键：license_id → licenses.license_id; object_id → collection_objects.object_id; source_id → sources.source_id。

## sources

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|source_id|TEXT|no|1|NULL|
|institution_id|TEXT|no|0|NULL|
|adapter|TEXT|yes|0|NULL|
|base_url|TEXT|yes|0|NULL|
|terms_url|TEXT|yes|0|NULL|
|license_id|TEXT|no|0|NULL|
|last_checked|TEXT|yes|0|NULL|
|status|TEXT|yes|0|NULL|
|notes|TEXT|yes|0|NULL|

外键：license_id → licenses.license_id; institution_id → institutions.id。

## taxa

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → taxa.id。

## taxon_details

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|taxon_id|TEXT|no|1|NULL|
|scientific_name|TEXT|yes|0|NULL|
|rank|TEXT|no|0|NULL|
|named_year|INTEGER|no|0|NULL|
|identification_notes|TEXT|no|0|NULL|

外键：taxon_id → taxa.id。

## techniques

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|id|TEXT|no|1|NULL|
|parent_id|TEXT|no|0|NULL|
|label|TEXT|yes|0|NULL|
|external_id|TEXT|no|0|NULL|
|authority_url|TEXT|no|0|NULL|

外键：parent_id → techniques.id。

## vocab_names

|字段|SQLite类型|必填|主键|默认|
|---|---|---|---|---|
|vocab|TEXT|yes|1|NULL|
|term_id|TEXT|yes|2|NULL|
|language|TEXT|yes|3|NULL|
|name_type|TEXT|yes|4|NULL|
|value|TEXT|yes|5|NULL|

## 语义及审核

- object_id: 来源/馆藏号证据对应的实物身份，不等于物种、游戏原型或OwnedAntique.instance_id。
- year_start/year_end: 人文日期有符号年范围；适配器保存source_signed_year_unspecified及原文，不擅自推定外馆API是否使用天文年0。human_chronology明确采用天文年编号。
- age_min_ma/age_max_ma: 距今百万年，下限≤上限；词表ICS版本固定，标本精确年龄不由时期名称自动补写。
- scientific_name/taxon_id: 原机构/GBIF报告的名称/分类单位，带issues的鉴定NEEDS_REVIEW；同一分类多馆藏编号保持多Specimen。
- eventDate: 采集/出现记录日期，不自动用作化石发现日期。
- primary_language/object_names.language: BCP47（zh-Hans/zh-Hant/en/und/la），原文/学名/别名/旧称独立name_type。translation_status不把自动译名当官方译名。
- editor_locked/curator_locked: 人工审订锁；重新导入保留人工名称、描述和游戏配置，刷新来源原始资料。
- field_evidence: canonical字段、源路径/源值、MATCHED/UNKNOWN/CONFLICT/CURATED，不把UNKNOWN写成核验完成。
- media: 每图片/模型自己的许可、出处、版权、署名、核验和local_asset_path；只有核验CC0/CC BY、商业允许、署名齐全且本地路径合法才能发行。
- game_object_references: FORM_REFERENCE等明确关系，仅资料参考，不能宣称玩家拿走现实馆藏或年代等同。
- available_world_year/acquisition_mode/world_review_note: 策划时间审查，与制造/发现/命名分别处理；现代发现化石需明确虚构考察设计，不默认1933已知。
- transport_mode: 当前仅HAND_CARRY且slots≤8；大骨架EXPEDITION_TRANSPORT排除，本阶段无运输玩法。

## Phase10B 前向扩展（Schema6）

|表|关键字段|职责|
|---|---|---|
|editorial_terms|term_id,parent_id,domain,zh_name,en_name,aliases_json,authority_url,review_status|双语受控草稿术语，父子FK|
|editorial_object_tags|object_id,term_id,source_id,record_id,source_path,source_value_json,status|建议标签逐条保留源字面证据|
|editorial_articles|article_id,object_id,zh_name,original_name,object_type,civilization_or_geology,material,technique_or_preservation,body,claims_json,related_object_ids,confidence,review_status,ai_generated,reviewer,review_note,content_sha256|独立中文稿；不修改官方ObjectNames|
|editorial_article_sources|article_id,claim_index,source_id,record_id,record_url|每段引用对应真实SourceRecord复合FK|
|game_collection_candidates|game_id,object_id,article_id,zh_name,cohort,category,basis_kind,payload_json,content_sha256,status,history_review,source_review,numeric_review,gameplay_review,reviewer,review_note|独立提案，未自动转换正式定义；APPROVED需四审通过|
|content_review_log|review_id,entity_kind,entity_id,from_status,to_status,reviewer,note,content_sha256,reviewed_at|真人内容版本审核日志；本阶段无实际人工批准|

payload_json保存时代、地区、稀有度/价值/槽位/吸引力建议、三种transport_mode、1933待审/阻断原因、图鉴关系与源引用。大于8格必须EXPEDITION_TRANSPORT。未知体量不是HAND_CARRY的发行批准，所有提案仍CANDIDATE。现有正式game_collection_definitions transport字段不被新策划分类改写。


## Phase10C Schema7～9

- natural_history_audits：每对象raw source hash、逐字段证据、疑问；academic_review与字段校验独立。
- natural_knowledge：通用类型知识、authority_url、字段值、来源日期与待审状态，禁止充作实物实测。
- editorial_articles追加editor_locked/editor_version；editorial_versions保存article/version/payload/hash/author_type/status，不修改既有迁移。
- museum_exhibitions保存独立提案及hash；exhibition_objects、exhibition_articles以FK绑定真实Object/Article，reading_order记录策展顺序。全部DRAFT_PENDING_REVIEW。
