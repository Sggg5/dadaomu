# Phase 10A — Global Museum Collection Database 验收

## 基线与Git安全

初始分支codex/phase-9b-multifloor-endurance，HEAD1c3a61423ee968b36446918bc660ffb51401c8c8，工作区干净。git status/branch/rev-parse/log-8及merge-base核验：51909c6、5af5bb1、1c3a614均为当前历史祖先。新分支codex/phase-10a-global-museum-database直接从该HEAD创建；没有reset、强制pull、丢本地提交或合并main。

|阶段|提交|
|---|---|
|10A.1 Global Schema|907d0c0f806ff2d18d9d45c71a496f082c670ab5|
|10A.2 Data Importers|44a2255f20d19a18170f1e336c3f42b6fbb613a9|
|10A.3 Godot Bridge|d138defee16154a3f41964d2896c9158abbe8c41|

## 数据表、关系及边界

SQLite Schema v3，43个主体/FTS表（不计FTS内部辅助表）。CollectionObject→文化遗产/化石/矿物/陨石/岩石/生物/地质扩展；Object↔多语言Names/Materials/Techniques/Cultures；SourceRecord→机构、记录URL、数据权利、日期、原始payload hash/JSON→FieldEvidence；Media独立权利/本地路径；Taxon/Occurrence/Specimen/Formation/Locality明确分离；GameCollectionDefinition→明确审订的参考关系/地区，不能由实物导入自动填充。

Schema001基础、002策划/媒体本地路径、003normalizer_version；迁移SHA锁和事务拒绝篡改/未知版本，Normalizing v3改变时可重放原始记录，保留editor_locked/curator_locked与游戏配置。已应用SQL没有修改。43表字典及FK详见DATA_DICTIONARY.md；设计解释见ARCHITECTURE.md。

历史时间采用独立区域时期（包括中国、埃及、希腊罗马），有符号日期/原文/历法/不确定性；化石地质时间采用固定ICS 2024-12版本、Ma/rank，不宣称这是2026最新图表。源时期明确时建立历史时期关联（包括HAN）；源没有提供的发现年、科学命名年、精确化石年龄、化学组成和晶系保持NULL。

## 数据源及许可

9个独立适配入口，5个官方实际在线获取来源。CMA120、MET1、AIC1、Smithsonian/NMNH24、GBIF/NHMUK15，共161个真实实物身份/馆藏编号记录；全部种子元数据逐条CC0，媒体另查，不下载图片/模型。登记其它4来源不意味着所有内容可商用。

NHM直接datastore查询返回403，没有绕过，使用其公开GBIF CC0发布记录；NHM本地DarwinCore适配器仍可接明确许可的官方导出。PBDB仅上下文Occurrence/Taxon，不把物种或出现点伪装成馆藏。台北故宫当前开放文字/中阶图片CC BY4需署名；聚合wenwu包含非开放来源，不因代码许可批准全部元数据和图片。全部依据与限制见SOURCES_AND_LICENSES.md、sources/registry.json，抓取请求/日期见samples/fetch_manifest.json。

15件化石保留供应者鉴定issues，标记NEEDS_REVIEW而非假称人工物种鉴定通过；10件三叶虫分类记录、5件高阶脊椎/恐龙背景分类记录。不把Chordata当恐龙物种。菊石分类查询多重匹配，未强行择一。生物标本尚无真实种子；Schema与DarwinCore适配接口有覆盖，本阶段不编造以填满类别。

## 统计

|类别|实物数|
|---|---:|
|ARCHAEOLOGICAL_ARTIFACT|117|
|ARTWORK|5|
|FOSSIL_SPECIMEN|15|
|METEORITE|8|
|MINERAL_SPECIMEN|8|
|ROCK_SPECIMEN|8|

|来源文化标签（非互斥，保留原机构范围）|数量|
|---|---:|
|Byzantine Empire (Egypt)|2|
|China, Eastern Zhou dynasty (770–256 BCE)|1|
|China, Erlitou culture (c. 1900–1500 BCE)|1|
|China, Fujian Province, Ming dynasty (1368-1644) - Qing dynasty (1644-1911)|1|
|China, Fujian province, Southern Song dynasty (1127-1279)|1|
|China, Henan Province, Baofeng, Qingliangsi, Northern Song dynasty (960-1127)|1|
|China, Henan province, Eastern Zhou dynasty (770–256 BCE), Warring States period (475–221 BCE)|3|
|China, Henan province, Jincun, Warring States period (475–221 BCE)|1|
|China, Henan province, Northern Dynasties period (386–581 CE)|1|
|China, Henan province, probably Anyang, Shang dynasty (c. 1600–c. 1046 BCE), Anyang phase (c. 1250–1046 BCE)|1|
|China, Inner Mongolia, lower stratum of the Xiajiadian culture (2200–1600 BCE)|1|
|China, Jiangxi Province, Jingdezhen, Qing dynasty (1644–1911), Yongzheng mark and period (1723–35)|1|
|China, Jiangxi Province, Jingdezhen, Qing dynasty, Shunzhi period (1644–61)|1|
|China, Jiangxi Province, Jingdezhen, Yuan dynasty (1271–1368)|1|
|China, Jiangxi Province, Northern Song dynasty (960–1127)|1|
|China, Jiangxi province, Jingdezhen kilns, Qing dynasty (1644–1911), Kangxi mark and reign (1662–1722)|1|
|China, Jiangxi province, Jingdezhen, Ming dynasty (1368-1644), Chenghua mark and period (1465-1487)|2|
|China, Jiangxi province, Jingdezhen, Ming dynasty (1368-1644), Xuande mark and period (1426-1435)|1|
|China, Jin dynasty (1115–1234)|1|
|China, Liao dynasty (916-1125)|1|
|China, Northern Song dynasty (960-1127) - Jin dynasty (1115-1234)|1|
|China, Northern Song dynasty (960–1127)|1|
|China, Northern Wei dynasty (386-534)|1|
|China, Possibly Qing dynasty (1644-1911), Qianlong period (1736-1795)|1|
|China, Qing Dynasty (1644-1911), Kangxi reign (1642-1722)|1|
|China, Qing dynasty (1644-1911)|3|
|China, Qing dynasty (1644-1911), Kangxi reign (1662-1722)|1|
|China, Qing dynasty (1644–1911)|2|
|China, Qing dynasty (1644–1911), Qianlong period (1736–95)|1|
|China, Qing dynasty (1644–1911), Qianlong reign (1736–95)|1|
|China, Shaanxi province, Meixian, Western Zhou dynasty (c. 1046–771 BCE)|1|
|China, Shang dynasty (c. 1600–c. 1046 BCE)|4|
|China, Shang dynasty (c. 1600–c. 1046 BCE), Anyang phase (c. 1250–1046 BCE)|1|
|China, Tang dynasty (618-907)|3|
|China, Warring States period (475–221 BCE)|1|
|China, Western Zhou dynasty (c. 1046–771 BCE)|4|
|China, Xin dynasty (9–23 CE)|1|
|China, probably Shaanxi province, Xi'an, Tang dynasty (618-907)|2|
|China, probably Zhejiang province, Han dynasty (202 BCE–220 CE)|1|
|Egypt|2|
|Egypt and Spain|1|
|Egypt or Syria(?)|2|
|Egypt, Abbasid period|1|
|Egypt, Alexandria, Roman|2|
|Egypt, Antinoë, Byzantine period|1|
|Egypt, Byzantine period|6|
|Egypt, Coptic period|1|
|Egypt, Fatimid period|1|
|Egypt, Roman Empire, Antonine|1|
|Egypt, Roman Empire, late Tiberian|1|
|Greece|15|
|Greece or Italy, Rome (?)|1|
|Greece, Alexandria(?)|1|
|Greece, Archaic period|1|
|Greece, Attic|1|
|Greece, Crete|1|
|Greece, Macedonia(?)|1|
|Italy, Rome|10|
|Italy, Rome, Early Imperial period|3|
|Italy, Rome, Greco-Roman Period|1|
|Italy, Rome, Roman Empire|4|
|Italy, Rome, probably Augustan|1|
|North or Central China, Northern Song (960–1127) or Jin dynasty (1115–1234)|1|
|Northeast China, Liao dynasty (916-1125)|2|
|Northeast China, Neolithic period, probably Hongshan culture (4700–2920 BCE)|1|
|Northern China, Liao dynasty (907-1125)|1|
|Northwest China, Neolithic period to Bronze Age, Qijia culture (2000–1700 BCE)|1|
|Southeast China, Suzhou, Qing dynasty (1644–1911)|1|

|有来源证据的国家/地区|数量|
|---|---:|
|Antarctica|5|
|Australia|2|
|Belgium|1|
|Greenland|1|
|Indonesia|1|
|Morocco|2|
|Namibia|1|
|Tanzania|1|
|Tanzania, United Republic of|3|
|United Kingdom of Great Britain and Northern Ireland|2|
|United States|11|

地区统计不从“中国文物”直接编造发现地点；无地点字段者保留未知。

|化石源时期|数量|
|---|---:|
|Cambrian|2|
|Cretaceous|1|
|Devonian|1|
|Jurassic|3|
|Ordovician|7|
|Quaternary|1|

|缺失基础字段|比例|
|---|---:|
|accession_number|0.00%|
|description|16.77%|
|discovery_location_id|77.64%|
|museum_id|0.00%|
|origin_location_id|99.38%|

缺少尺寸/测量记录24/161；不是用0补齐。相同来源重放161重复、0新增、0错误；同名不同实物保留，待审核同名候选25对，不自动合并。元数据授权不明0条，鉴定待复核15条；种子媒体未核验0，但无媒体记录不是媒体已获授权。

查询基准：此机161条资料、jade+China条件1000次，median 0.3067ms、P95 0.5678ms。只代表小型种子库，不是已验证十万条性能；Schema索引/FTS及参数化查询为后续扩容基础。检索支持名称/中文子串、文化、地区及子区、时期、地质期、类别、化石分类、材质、机构、出土地、媒体许可和可信度。

## 至少10条实际记录示例

下面名称为机构原文，不伪装成官方中文翻译；每条完整字段来源值/核验状态在field_evidence，原始URL/许可在source_records。

|类型/文化|原文名称|原馆藏编号|原始记录链接|
|---|---|---|---|
|ARCHAEOLOGICAL_ARTIFACT|Adoring Monk|1962.213|[原始记录](https://clevelandart.org/art/1962.213)|
|ARCHAEOLOGICAL_ARTIFACT|Peaches and Bats|2006.141|[原始记录](https://clevelandart.org/art/2006.141)|
|ARCHAEOLOGICAL_ARTIFACT|Dish with Bird on Fruit Tree Branch|1964.213.1|[原始记录](https://clevelandart.org/art/1964.213.1)|
|ARCHAEOLOGICAL_ARTIFACT|Roundel with Amazons, from a tunic|1952.104|[原始记录](https://clevelandart.org/art/1952.104)|
|ARCHAEOLOGICAL_ARTIFACT|Aphrodite|1927.489|[原始记录](https://clevelandart.org/art/1927.489)|
|ARCHAEOLOGICAL_ARTIFACT|Barbarian|1987.64|[原始记录](https://clevelandart.org/art/1987.64)|
|FOSSIL_SPECIMEN|Cambropallas Geyer, 1993|PI It 29147 b|[原始记录](https://www.gbif.org/occurrence/6132187845)|
|MINERAL_SPECIMEN|Chondrodite|NMNH 172885-00|[原始记录](http://n2t.net/ark:/65665/3e1d934a9-7f1c-4524-bb18-1042fa84827a)|
|METEORITE|CMS 04013,3|USNM 7648|[原始记录](http://n2t.net/ark:/65665/3f5180027-7b33-4909-9193-fd13a321dfb0)|
|ROCK_SPECIMEN|Zirconiferous sandstone|NMNH 87788-3|[原始记录](http://n2t.net/ark:/65665/3b2043ed0-373a-4bdb-a5df-62366d54a82a)|
|ARTWORK|Wheat Field with Cypresses|1993.132|[原始记录](https://www.metmuseum.org/art/collection/search/436535)|
|ARTWORK|A Sunday on La Grande Jatte — 1884|1926.224|[原始记录](https://www.artic.edu/artworks/27992)|

## 游戏导出/1933/兼容

旧8件ID/name/description/price/rarity/slots/appeal逐字段快照保留（samples/legacy_game_mapping.json）；442个既有scripts/data/scenes/project配置语义hash不变。新GlobalMuseumCatalog只读取审核后本地JSON，无HTTP/SQLite，没有autoload或掉落池装配。本阶段不改Museum经营、战斗、Boss、遗物、随机流、OwnedAntique.instance_id、MuseumProfileStore VERSION4，零正式存档迁移。

策划层明确单独审核，不把161件全部作为游戏掉落。2个FORM_REFERENCE注明只是器物形制参考（战国Bi不是汉代制造日期证据，普通源jar不等于游戏小罐）；其余6件未强凑真实对应，导出报告列缺口。玩家虚构古董不表示拿走馆藏原件。8件都无新增媒体/游戏美术，中文游戏名来自原项目，资料缺中文则pending。

1933可配置anchor分别检查制造（跨界日期保守阻止）、发现、命名和虚构获取方式；现代/未知发现化石默认阻止，需要明确审订FICTIONAL_EXPEDITION故事说明。Ma不参与公元年比较。大型EXPEDITION_TRANSPORT/超过8格定义排除，无运输/发掘玩法。

媒体仅许可CC0/CC BY、商业许可、核验完成、CC BY署名齐全且合法本地路径存在才导出；UNKNOWN/CONFIRM/CC BY-NC与外部路径拒绝。上游图片撤回许可后重新导入不会沿用旧CC0，人工DENIED也不被自动复活。没有通过远程URL让运行时下载。

实际导出data/catalog/global_catalog.json：8件GameCollectionDefinition、2条精简参考资料；缺失资料中文2、图像8、真实参考6；2个合法图片链接因未本地打包排除，输出images为空。导出无抓取时间，稳定排序；不同数据库重建与重复导出字节完全一致。export_report.sample.json保留缺口报告，不修改任何旧.tres。

导出例（节选）：

```json
{
  "base_value": 350,
  "category": "ARCHAEOLOGICAL_ARTIFACT",
  "description": "绘着卷草纹的小罐，釉色尚存。",
  "display_name": "青花小罐",
  "exhibit_appeal": 12,
  "game_asset_id": null,
  "game_id": "blue_white_jar",
  "images": [],
  "inventory_slots": 2,
  "obtain_region_ids": [],
  "rarity": "COMMON",
  "reference_object_ids": [
    "object:33858b3c60109c37df3218fc"
  ],
  "unlock_conditions": []
}
```

## 自动测试与执行命令

37项Python测试，0失败；迁移篡改/失败回滚、全球时间、同名不同馆藏、幂等、旧Normalizer重放与人工锁、来源/媒体撤权、合法/不合法发行、原有8件、442个冻结文件、1933规则、大型化石、确定性重建导出均有覆盖。Godot10A headless49项、graphical49项，0失败。

既有Phase1～9B.3.3+Geometry 291885项、Softlock1030项、Player/Boss baseline727项，加10A共293691项，0失败。导入/正式GameFlow隔离Profile启动正常，无SCRIPT ERROR/ERROR。8B/8C/8D/9A的故意损坏Profile夹具预期WARNING保留，未删除原断言。

|Godot套件|项数|失败|
|---|---:|---:|
|1|27|0|
|2|204|0|
|3|94|0|
|4|105|0|
|5a|61|0|
|5b|236|0|
|6|164|0|
|6_5|174|0|
|7a|306|0|
|7b|722|0|
|8a|482|0|
|8b|305|0|
|8c|297|0|
|8d|2153|0|
|9a|10510|0|
|9b|30753|0|
|9b2|4842|0|
|9b3|29132|0|
|9b32|1733|0|
|9b33|2701|0|
|geometry|206884|0|

```powershell
python -m unittest discover -s database/tests -v
python -m database.rebuild_catalog --db database/work/release_catalog.sqlite
python -m database.exports.curation --db database/work/release_catalog.sqlite
python -m database.cli search_catalog --db database/work/release_catalog.sqlite --material JADE
python -m database.cli export_godot_catalog --db database/work/release_catalog.sqlite --output data/catalog/global_catalog.json --report database/work/export_report.json --world-year 1933
godot --headless --path . --script tests/phase_10a_smoke.gd
godot --headless --fixed-fps 60 --path . --script tests/phase_<阶段>_smoke.gd
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase10a/startup.json --seed=33
```

## 已知限制与停止边界

首批161资料为底座样本，不声称已导入十万条。只有5来源实际获取，另外4适配入口是本地审订清单/上下文入口，不声称所有供应者原生批量API都已自动接通。缺失位置/描述/尺寸、词表别名和科学鉴定仍需长期策划；菊石多重分类匹配、生物实物种子等缺口明确保留。无图片/3D下载，无正式图鉴UI、经营改版或新玩法。完成三独立commit后只尝试push新分支，失败保留本地，不force、不合并main，停止等待下一阶段。

最终示例抽查追加小修：MET/AIC油画由官方classification/artwork_type_title明确映射ARTWORK（不再用默认考古器物）；新增实际种子断言，Normalizer v3允许原库安全重放分类且保留人工锁。三个阶段提交不改写，追加一个分类修正提交；37项Python测试0失败，导出字节及冻结游戏代码不变。
