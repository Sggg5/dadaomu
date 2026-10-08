# Phase 10D — Museum Codex & Exhibition Integration 验收

基线 `62ed174b36febf174c10a9ed99537af46f1f4207`，分支 `codex/phase-10d-museum-codex`。2026-10-08。代码、自动及图形检查完成；**人工体验待验收**。仅提交/push，不合并main。

## 实现与身份边界

- 独立研究JSON加载1441真实对象，100中文图鉴（30 v2）、4专题各8实物引用。稳定object_id/article_id/exhibition_id与OwnedAntique.instance_id分离；研究目录不写game_definitions，不改变正式8件。
- Museum(900,190)研究台复用MuseumInteractable/MuseumPlayer E交互；四分类、中文/英文及自然史类别搜索、40条分页、原文/推荐名、来源链接可选择复制、正文滚动、统一照片占位、审核状态。
- 我的馆藏逐instance_id显示definition_id/获得日期/鉴定状态/展柜；重复古董不合并。未鉴定不泄露condition/经济结果。只显示游戏原型自身描述，不把真实博物馆实物变成玩家持有物。
- 研究目录明确RESEARCH_REFERENCE_NOT_1933_DISCOVERY；现代发现/命名可作为研究资料阅读，**没有放宽正式1933过滤**。500候选未导出；400同类型比较关联稿不会冒充某实物专属图鉴。
- 100文章与4专题均DRAFT_PENDING_REVIEW；SOURCE_VERIFIED不是专家批准。自然史学术状态/unknown/待核实问题保留，陨石同号子样冲突仍待人工核对。
- 打开冻结角色并归零速度；Tab/E关闭恢复合法控制。搜索框内E作为英文输入、Tab始终关闭；下拉窗口关闭时清理，避免残留。重复打开拒绝，别的面板占用控制时拒绝打开；夜晚不恢复非法控制，卸载释放节点/纹理。
- 不调用identify/repair/assign/sell，不发state.changed、不触发正式保存；营业OPEN期间可读，游客与经营照常。没有增加票价/吸引力/收益/展柜/存档字段。

## 数据桥接与媒体

复用Schema9现有SQLite与10C定义，未新增或改写SQL迁移。导出器只用既有快照，不重新抓取；原API payload不进入JSON。JSON稳定ID排序，重复导出字节一致，NULL保留。Godot只读本地JSON/JPEG，不访问Python/SQLite/网络。

本地研究目录1441条，排除记录0；无中文名/文章1341，描述未知378，材质未知983，历史时期NULL688，地质年代NULL1396。这里包括不适用字段，不把NULL统一视为错误；缺口报告见phase10d_export_report.json。没有合法本地图片的1439条显示占位。

只将两件Git样例（CMA 1926.248、1926.249）复制为assets/catalog JPEG。媒体映射含object/media ID、CC0、署名、原始机构链接、SHA256、审核/撤权状态；不从database/.gdignore引用运行资产。导出检查active_media的DB许可、rights证据、对象关联、原URL、本地SHA与真实解码；运行时再查本地路径边界、格式、尺寸、SHA、对象关联、许可及撤权。UNKNOWN/DENIED/CC BY-NC不显示；CC BY缺署名不显示。图像保持比例，按选中项加载，非全量高分辨率预载。

其余18照片仍为可重建策划cache，不自动进入游戏。离线无法发现未来机构撤权；需10C显式refresh-rights，再重导出。已标记撤权不会在运行界面显示。四专题无授权封面时用明确的文字占位封面，不伪造馆藏照片。

## 正式GameFlow真实主流程

`tests/phase_10d_smoke.gd -- --flow`实例化正式game_flow.tscn：新档Day1空馆藏 → 实际WASD到研究台 → E打开 → 研究/化石/照片/专题 → Tab/E关闭恢复控制 → 情报板E真实下墓 → 实际ANTIQUE E拾取 → 武器/弹丸击败第一Boss → F撤离 → E回Day2 → 新OwnedAntique在重新装配的图鉴显示 → 鉴定/布展唯一真实藏品 → E开馆/游客观看/门票/闭馆。

主流程不使用collection.add注入夜间带回物品。夜间采用已有legacy_two_floor_tomb及固定Seed192034快速隔离夹具；不声称这个UI专项是正式五层完整平衡验收，生产五层仍由原9B回归覆盖。另一个明确单位夹具构造两件唐三彩马，分别未鉴定41/已鉴定87品相，验证独立身份和隐藏字段。真实售票E开馆、再走到研究台E阅读，验证营业运行与票款只由游客产生。

所有流程使用in-memory Profile，启动冒烟用user://tests/phase10d/startup.json；不读取或写正式用户Profile。

## 自动检查真实结果

Python全部92测试、0失败：10A/10B/10C及6个10D导出测试。包含幂等/重复身份/术语/草稿锁/年代/授权/候选隔离/旧8件/Profile冻结/确定性导出/媒体拒绝/专题源定义等价。

10A原文件哈希保护仅调整Museum.gd的明确装配插入例外：扣除两行声明及五行研究台装配后仍与原hash比对，其余受保护文件继续完整hash断言；没有删除保护或重写全部基线hash。

既有24套Godot共293691项，0失败。8B/8C/8D/9A的坏存档夹具产生预期WARNING；无SCRIPT ERROR/ERROR。

|旧阶段|检查数|失败|
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
|softlock|1030|0|
|baseline|727|0|
|10a|49|0|

|10D专项|检查数|失败|
|---|---:|---:|
|bridge|9|0|
|media|11|0|
|GameFlow|114|0|
|graphical_GameFlow|114|0|
|graphical_UI1280|40|0|
|graphical_UI1600|40|0|
|graphical_UI960|40|0|

headless旧阶段+bridge/media/GameFlow合计293825项，0失败。图形完整GameFlow114项，最终1280/1600/960 UI各40项，共234项，0失败。导入与正式入口独立启动均exit0，无解析/运行错误。一次PowerShell命令宿主报Stack overflow，改用Python subprocess调用同一官方Godot后导入/启动/桥接/媒体均正常；未修改Godot引擎或放宽断言。

早期验证抓到类型推断解析错误、自然史关键词、哈希保护对授权装配的误报、截图早于布局更新和面板透出背景文字，均已修正后重跑；不把失败尝试计为成功。

## 真实Godot图形证据

全部为官方Godot 4.6.2真实Viewport渲染PNG，不是HTML/AI合成。截图保存SHA、尺寸与隔离Profile说明于phase10d_graphical_report.json。检查1280×720、1600×900，并增加960×540小窗口；文字正常、长正文可滚动、图片比例保持、列表分页及按钮可操作。截图文件位于ignored logs，不提交二进制截图。

- [研究台位置](../../logs/phase10d/1280x720/research_desk.png)
- [我的馆藏（两件同定义不同实例）](../../logs/phase10d/1280x720/owned_instances.png)
- [空馆藏](../../logs/phase10d/1280x720/empty_owned.png)
- [全球研究目录](../../logs/phase10d/1280x720/global_directory.png)
- [中国文物详情 / 真实照片](../../logs/phase10d/1280x720/photo_detail.png)
- [化石资料详情](../../logs/phase10d/1280x720/fossil_detail.png)
- [另一件真实照片](../../logs/phase10d/1280x720/photo_0.png)
- [无图片占位](../../logs/phase10d/1280x720/placeholder.png)
- [中文正文与来源滚动](../../logs/phase10d/1280x720/article_sources.png)
- [古埃及专题](../../logs/phase10d/1280x720/exhibition_ancient_egypt.png)
- [真实Day2带回藏品](../../logs/phase10d/1280x720/day2_codex.png)
- [实际营业期间研究阅读](../../logs/phase10d/1280x720/open_reading.png)

- [1600×900真实照片](../../logs/phase10d/1600x900/photo_detail.png)
- [1600×900专题](../../logs/phase10d/1600x900/exhibition_ancient_egypt.png)
- [960×540小窗口](../../logs/phase10d/960x540/owned_instances.png)

## 执行命令

```powershell
python -m database.exports.export_research_catalog --db database/work/10d_rebuild.sqlite
python -m unittest discover -s database/tests -v
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase10d/startup.json --seed=192034
godot --headless --path . --script tests/phase_10d_bridge.gd
godot --headless --path . --script tests/phase_10d_media.gd
godot --headless --fixed-fps 60 --path . --script tests/phase_10d_smoke.gd -- --flow
godot --path . --resolution 1280x720 --fixed-fps 60 --script tests/phase_10d_smoke.gd -- --capture --flow
godot --path . --resolution 1600x900 --fixed-fps 60 --script tests/phase_10d_smoke.gd -- --capture
godot --path . --resolution 960x540 --fixed-fps 60 --script tests/phase_10d_smoke.gd -- --capture
godot --path . --script tests/phase_10d_handoff.gd
```

旧回归脚本tests/phase_1,2,3,4,5a,5b,6,6_5,7a,7b,8a,8b,8c,8d,9a,9b,9b2,9b3,9b32,9b33,geometry,10a_smoke.gd；另phase_softlock_smoke.gd与phase_player_baseline_smoke.gd。实际绝对exe路径为本机Downloads官方4.6.2 console版本；本机Python缓存运行时/Pillow12.3.0，没有新增Godot插件或重型服务。

## 文件与职责

新增Research/Exhibition导出JSON、export_research_catalog.py及6个Python测试；MuseumResearchCatalog本地数据/检索/媒体安全、MuseumExhibitionCatalog引用校验、MuseumCodexText纯文本格式、MuseumCodexPanel原生Control生命周期；2 JPEG与ATTRIBUTION.json；bridge/media/UI/GameFlow/手动handoff测试及.uid；质量/截图/排除报告。

修改Museum.gd仅装配研究台；test_exports.py保留原hash保护并精确允许装配新增；根README/PLAN/ARCHITECTURE/AGENTS及database README。没有改GameFlow、战斗、Boss、遗物、8古董数值/概率、Profile4、正式global_catalog.json或已有SQL迁移。

## 限制与人工交付

100图鉴/4专题仍待真人专业审核，部分译名/年代/标本鉴定不确定，122自然史审查问题不在本阶段重新裁决。只2件图像，专题封面为文字占位。500候选不提供运行时预览；未开发经营收益、真实运输、图鉴解锁或新的经济规则。未制作发行包，打包时需包含本地JSON与用于SHA检查的assets/catalog JPEG原字节。

手动handoff脚本启动正式GameFlow，默认空馆藏，走到研究台附近停留；使用隔离内存Profile，试玩不会覆盖原存档。人工体验状态仍PENDING，不以程序驾驶冒称真人通过。

## 五阶段提交

|阶段|SHA|
|---|---|
|10D.1|1a5fed93faf7504e5181fc0682bcdb3fff4b3451|
|10D.2|59de4a38c9314a4578291fe6dcaffdbfb8a3e379|
|10D.3|3b9db0032b8e20d5928a634f66b2ca3f876c9ee3|
|10D.4|afa417b1014f4372e6e08680dff336bd54961974|
|10D.5|本文件所在最终提交；完整SHA以最终交付报告/git rev-parse HEAD为准|

避免在commit内部自引用自身hash。五阶段提交前对应验证均通过；最终push核对本地与远端HEAD一致、upstream 0/0和干净工作区。不合并main、不进入下一阶段，等待人工体验。
