# Phase 10B 验收记录

## 10B.1 真实资料批次

基线2336dbd，工作区干净，远端10A同提交；新分支codex/phase-10b-museum-content。不合并main、不改游戏生产数据。

1441个真实馆藏对象，较161新增1280；CMA1160、AIC31、Smithsonian234、GBIF15、MET1。实际新增来自CMA/AIC/Smithsonian；MET官方search端点返回HTTP410，未伪造补齐。快照保留完整原始记录、馆藏号、来源URL与抓取日期，无图片/3D下载。元数据全部CC0，媒体另审，9条媒体未核验。

中国来源culture明确标注的记录涵盖新石器、商周、战国汉、南北朝、隋唐、宋元、明清；未因搜索词或出土地推断文明。夏代、秦代单独实物与菊石/遗迹化石覆盖仍待补齐，不把高阶Chordata称作具体恐龙。世界包括埃及、希腊、罗马、波斯、印度、美洲和两河相关源标签；时代并不都等于古代。

自然记录66化石、13矿物、13陨石、157岩石。古生物部门中140条缺乏地质年代证据的记录排除，部门归属不是化石证据；51新增化石有源geo_age-system或Geologic Age。Normalizer4支持前向重放，原Schema1～3不变。采集时删除重复sourceID，数据库另以机构+馆藏号识别同一实物，重复名称只生成待审核候选，不按名字合并。

统计和缺失字段见phase10b_source_statistics.json；导入清单见samples/phase10b/fetch_manifest.json与additional_manifest.json。未知发现年、精确年龄、鉴定等级仍NULL，66化石保留NEEDS_REVIEW。29项阶段Python校验通过后提交。

后续10B.2～4将在本文件追加；程序来源校验不等于人工学术/策划审核。
