# Phase 10B 验收记录

## 10B.1 真实资料批次

基线2336dbd，工作区干净，远端10A同提交；新分支codex/phase-10b-museum-content。不合并main、不改游戏生产数据。

1441个真实馆藏对象，较161新增1280；CMA1160、AIC31、Smithsonian234、GBIF15、MET1。实际新增来自CMA/AIC/Smithsonian；MET官方search端点返回HTTP410，未伪造补齐。快照保留完整原始记录、馆藏号、来源URL与抓取日期，无图片/3D下载。元数据全部CC0，媒体另审，9条媒体未核验。

中国来源culture明确标注的记录涵盖新石器、商周、战国汉、南北朝、隋唐、宋元、明清；未因搜索词或出土地推断文明。夏代、秦代单独实物与菊石/遗迹化石覆盖仍待补齐，不把高阶Chordata称作具体恐龙。世界包括埃及、希腊、罗马、波斯、印度、美洲和两河相关源标签；时代并不都等于古代。

自然记录66化石、13矿物、13陨石、157岩石。古生物部门中140条缺乏地质年代证据的记录排除，部门归属不是化石证据；51新增化石有源geo_age-system或Geologic Age。Normalizer4支持前向重放，原Schema1～3不变。采集时删除重复sourceID，数据库另以机构+馆藏号识别同一实物，重复名称只生成待审核候选，不按名字合并。

统计和缺失字段见phase10b_source_statistics.json；导入清单见samples/phase10b/fetch_manifest.json与additional_manifest.json。未知发现年、精确年龄、鉴定等级仍NULL，66化石保留NEEDS_REVIEW。29项阶段Python校验通过后提交。

后续10B.2～4将在本文件追加；程序来源校验不等于人工学术/策划审核。

## 10B.2 中文图鉴草稿与词表

100篇短图鉴，正文169～209字符，45中国金属/玉/陶瓷、20其它中国历史文物、20全球器物、15自然史。全部AI生成、DRAFT_PENDING_REVIEW，不是专家/人工审核通过。推荐中文名与官方原文分离；每篇独立保留器物类型、文化/地质标签、材质、工艺/保存部位、原始来源、可信度和真实相关藏品。自然史专业译名不确定时保留学名。

80条双语受控术语含上下位关系、别名与待审订状态，2754条源字段字面支持的建议标签。标签不是最终学术分类；罗马发现地、印度风格、现藏机构不会互相替代。夏/秦词项存在不代表已有实物覆盖。

追加Schema4/5，不修改已应用1～3。ArticleSources用复合FK指回SourceRecord，正文必须完全来自带证据的claims；新增无引用段落、伪造源字段值和自动REVIEWED导入被阻止。结构验证只证明引用存在、值一致，不能自动证明中文推论正确。具体解释仍需真人逐句审核。

有争议科林斯式头盔、刻诗玉圭、据称出土地与未定属骨片均保留不确定性；近代陨石和牙化石的真实采集年代不能直接进入1933世界。已审核行重建不覆盖。16项词表/图鉴/迁移专项0失败。

## 10B.3 候选提案

500/500完成，300中国、140其它全球文明、60自然史（24化石、10矿物、10陨石、16岩石）。500个不同真实Object引用，无冒充的虚构馆藏。候选身份不是玩家取得该馆实物的承诺；全部CANDIDATE，历史/来源/数值/玩法四审PENDING。

6组初步数值带只为策划一致性，价格不来自博物馆市场估价。255 HAND_CARRY、199 PACKED_CRATE、46 EXPEDITION_TRANSPORT；大于8格必须远征运输，体量未知仍待审订，未开发运输玩法。年代检查复用既有1933校验：480需审核、20具体身份阻断（近代采集/制造）。古植物/脊椎化石保留学名与未定鉴定，未知发现/命名年份不能自动放行。

100件关联自身图鉴，其余关联同类型比较稿并明确TYPE_COMPARISON_DRAFT_NOT_OBJECT_IDENTITY，不能当作该物品自己的百科。未覆盖的专属图鉴后续待写。中文名称有官方原语时保留原语；尚未专门翻译时使用宽中文类型+原文标题并待审订。

Schema6为独立candidate表，不触碰正式GameCollectionDefinition；APPROVED要求四审记录与审核人，程序导入不能批准。正式导出与原data/catalog/global_catalog.json完全一致，仍8件，旧ID/数值、Profile4及发行媒体检查不变。20项候选/发行回归0失败。


## 10B.4 离线预览、最终质量与回归

离线单HTML：`database/previews/index.html`，独立候选提案：`database/previews/planning_preview.json`。可按文明、器物类别、地质时代与状态筛选，查看中英文名称、原件简介、机构/馆藏号、来源链接与数据/媒体许可。无运行服务依赖；CSP禁止网络连接与图片，源文本通过textContent输出，转义JSON脚本结束符。真实馆藏、图鉴草稿、候选为三视图；原文名称不被中文稿替换。

浏览器工具安全策略拒绝file://，未绕过，因此外观人工验收未完成。17项最小DOM单元检查覆盖筛选、搜索、分页、详情、来源与CSP；这是代码逻辑校验，不称为浏览器截图或用户验收。用户可本地直接打开HTML；图鉴正文与候选预览不依赖联网，点击原始来源才需要网络。

最终Normalizer5补充CMA Drawing/Photograph为ARTWORK、Coins为NUMISMATIC_OBJECT，书籍/服装/家具与1500年后工艺品为HISTORICAL_OBJECT，不再把现代书籍都用考古器物兜底。Source type/date证据保留、人工锁不覆盖；宽分类仍不代替最终专业类型审订。SQLite追加迁移到6，既有1～3及应用过的4～6均未改写。

最终1441对象、1447 SourceRecord（6条额外源记录按同机构/馆藏号连回同一实物）；1027同名重复候选未擅自删除/合并。各机构对象：CMA1160、AIC31、Smithsonian234、GBIF15、MET1；SourceRecord中Smithsonian240，其他数量相同。源元数据1447条CC0；媒体1218 CC0/VERIFIED、5 CC_BY/VERIFIED（含署名）、9 UNKNOWN/UNVERIFIED。仅登记媒体链接，图片/3D下载与发行新资产均0。

66化石中24学名未知、51分类rank未知、66精确年龄范围未知、66实际发现年未知、26保存部位未知。未知保留NULL，不从Collection Date推发现年，不从Chordata/项目名/未定属推物种。存在寒武、奥陶、泥盆、侏罗、白垩、古近、新近、第四纪和宾夕法尼亚亚纪源标签；21条尚无规范地质period。全部66保持NEEDS_REVIEW。

100篇图鉴全待审，500候选全CANDIDATE；400只有同类型比较图鉴。20具体实物身份被1933阻断，480仍需人工历史与获取审核；体量、译名、真伪、断代疑问和运输合法性见CONTENT_REVIEW_WORKFLOW.md与phase10b_quality_report.json。没有专家批准、经济平衡结论或新发行藏品。

正式池隔离证据：重新导出与提交的data/catalog/global_catalog.json逐结构一致；原8件ID/价值/占格/稀有度/吸引力断言全部保留；442冻结游戏文件SHA验证通过，git diff相对2336dbd不涉及scripts/scenes/data/project.godot。Profile VERSION4及既有读写/迁移回归通过，地宫随机流和掉落概率未改。

Python完整63测试0失败；Godot完整Phase1～9B.3.3+Geometry 291885项、Softlock1030、Player/Boss baseline727、10A49，共293691项0失败；10A graphical49项0失败。导入与正式入口隔离Profile启动正常，无SCRIPT ERROR/ERROR。旧8B/8C/8D/9A故意非法Profile的预期WARNING存在，保留原断言。早先补充套件命令拼错路径导致未启动，已用真实脚本名重新执行并通过，未当成代码修复或删测试。

```powershell
python -m unittest discover -s database/tests -v
python -m database.preview --db database/work/catalog.sqlite
node database/tests/preview_dom_test.cjs
python -m database.cli validate_db --db database/work/catalog.sqlite
python -m database.cli export_godot_catalog --db database/work/catalog.sqlite --output database/work/release_check.json --report database/work/release_check_report.json

godot --headless --fixed-fps 60 --path . --script tests/phase_<phase>_smoke.gd
godot --headless --fixed-fps 60 --path . --script tests/phase_softlock_smoke.gd
godot --headless --fixed-fps 60 --path . --script tests/phase_player_baseline_smoke.gd
godot --path . --script tests/phase_10a_smoke.gd
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase10b/startup.json --seed=33
```

phase序列：1/2/3/4/5a/5b/6/6_5/7a/7b/8a/8b/8c/8d/9a/9b/9b2/9b3/9b32/9b33/geometry/10a。运行日志仅ignored logs，SQLite/用户存档/缓存不提交。

### 新增真实馆藏样例

下列22件均为相对10A新增的真实馆藏记录；原文名与馆藏号保留，中文命名不在这里冒称已审定。原始标签和身份可通过链接/本地raw_json核对。

|原文名称|馆藏号|规范宽分类|原始来源|
|---|---|---|---|
|Sciaenops sp|PAL284144|FOSSIL_SPECIMEN|[机构记录](http://n2t.net/ark:/65665/3fd10c263-1aa7-4fa5-aecb-9f7786521b53)|
|Priconodon crassus Marsh, 1888|PAL540735|FOSSIL_SPECIMEN|[机构记录](http://n2t.net/ark:/65665/346fc51bc-cacb-4ba1-a999-9da8481f6ddd)|
|Mammut americanum (Kerr)|V3045|FOSSIL_SPECIMEN|[机构记录](http://n2t.net/ark:/65665/31afd82c3-c5e2-40ad-b982-b05d8a7ef178)|
|Sphoeroides hyperostosus Tyler et al., 1992|PAL283930|FOSSIL_SPECIMEN|[机构记录](http://n2t.net/ark:/65665/31e37dda0-a0a5-49dc-a8bd-8e4d6ec56373)|
|Quartz|NMNH G11370-00|MINERAL_SPECIMEN|[机构记录](http://n2t.net/ark:/65665/3cd6867d7-543a-4e85-aa61-1ced0ff3c5e9)|
|Rhodonite|NMNH 174734-00|MINERAL_SPECIMEN|[机构记录](http://n2t.net/ark:/65665/376e4b233-5b16-4643-94c6-b1941cee34c1)|
|ALH 84233,1|USNM 6531|METEORITE|[机构记录](http://n2t.net/ark:/65665/3cc7a9582-c1b1-4719-832e-4f5c516ae420)|
|QUE 97256,0|USNM 7308|METEORITE|[机构记录](http://n2t.net/ark:/65665/3b3debf72-3ef7-4c30-b8c2-48f611a6297b)|
|Amphibolite|NMNH 117784-54|ROCK_SPECIMEN|[机构记录](http://n2t.net/ark:/65665/381f02c97-ce33-4958-a058-b9c8de371aab)|
|Lead ore|NMNH 76779|ROCK_SPECIMEN|[机构记录](http://n2t.net/ark:/65665/3d423100e-5284-4588-afb0-1c2974946311)|
|The Repose in Egypt|1959.99.15|ARTWORK|[机构记录](https://clevelandart.org/art/1959.99.15)|
|Zhi and Xu's Pure Conversation|1970.128|ARTWORK|[机构记录](https://clevelandart.org/art/1970.128)|
|Birds Gather under the Spring Willow|1974.31|ARTWORK|[机构记录](https://clevelandart.org/art/1974.31)|
|Wine Cup|1957.71|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1957.71)|
|Water and Moon (Potala) Guanyin|1984.7|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1984.7)|
|Footed Plate with Floral Medallion|1989.268|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1989.268)|
|Eleven-Headed Guanyin|1981.53|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1981.53)|
|Textile Ornament(?): Phoenix|1942.1083.1|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1942.1083.1)|
|Necklace Bead in the Form of a Fish|1973.39.i|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1973.39.i)|
|Eleven-Headed Guanyin|1959.129|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1959.129)|
|Decorated Jar with Boat Scenes|1914.639|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1914.639)|
|Lobed Mirror with Paired Phoenixes and Floral Displays|1995.348|ARCHAEOLOGICAL_ARTIFACT|[机构记录](https://clevelandart.org/art/1995.348)|

最终分类统计：ARCHAEOLOGICAL_ARTIFACT=673, ARTWORK=271, FOSSIL_SPECIMEN=66, HISTORICAL_OBJECT=227, METEORITE=13, MINERAL_SPECIMEN=13, NUMISMATIC_OBJECT=21, ROCK_SPECIMEN=157。
正式目录SHA256：`dad2b7d7ea3a5849750bf6a93837d1ebbe77f30d9d84510890754e8c957c3b0f`。

### 四次提交与交付

|阶段|commit|
|---|---|
|10B.1|41844b6cb87d3ce578c0ca91a04c41f64b801b7f|
|10B.2|f185b4f16c658775222d444360a68afaa12c0662|
|10B.3|6b298d323782256a223e463b6be3a38e01a9d143|
|10B.4|本验收文件所在最终提交；完整SHA在最终交付报告和git log中|

本文件随10B.4提交，因此不能在自身提交内容内嵌尚未生成的自身hash；用`git log -4 --format="%H %s"`可获取四个完整SHA，最终交付报告逐一给出。push当前codex/phase-10b-museum-content后核对远端HEAD；未合并main、不继续下一阶段。
