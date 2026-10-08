# Phase 11A — 情报地图与古墓远征选择

## 基线与范围

基线 `848740d7615b02605ea71f82eeaceb30519318af`，父提交 `ab314024` 包含多展厅组合展柜；基线自身包含双生尸煞死亡生命周期热修。开始时本地工作区干净，与hotfix远端同步；直接从最新有效HEAD创建 `codex/phase-11a-expedition-map`，无reset、覆盖或main合并。

本阶段把正式情报板直接下固定墓改为地图确认；不增加新地宫、Boss、遗物、掉落或博物馆经济。

## 玩家流程与地图

情报板E → 中国远征调查图 → 鼠标点击晋北/洛阳/关中标记 → 在地区档案中点击具体地点 → 查看时期/背景/危险/机关敌人/可能器物/开放状态 → 确认远征 → 成功保存地面 → 所选TombDefinition进入原DungeonSession。

本地原创 `assets/maps/china_survey_1933.svg`：旧纸色、手绘山地与河道、虚线调查路线、指北针与地区标记。没有网络地图API或外部下载图片；源码离线运行已验证。它是架空游戏方位示意，不是精确1933疆界、导航图或真实考古地点图。地区使用独立可点击画制标记及高亮，不是地名文字按钮集合。

返回地区图清除选中地点；Tab/Esc/关闭按钮恢复地面控制，不开始夜晚。详情可滚动，不隐藏长档案。营业中沿用停止进客/排空游客，随后打开地图而非自动下墓。有待拍品先展示原夜间二选一，选择下墓才打开地图；拍卖与下墓互斥。

## 数据与实际可远征地点

`RegionDefinition`、`SiteDefinition`、`SiteRegistry`、`ExpeditionSelection` 位于 `scripts/expedition/`。数据入口 `data/expedition/sites.json`：三地区、六地点。每个地点显式ID、地区、名称、时期、culture tags、type、risk tier、TombDefinition、loot profile、unlock status、marker，以及背景与情报。无TombDefinition的调查地点不可远征。

| 地区 | 地点ID | 名称 | 状态 |
|---|---|---|---|
| 晋北 | DEFAULT_TOMB | 晋北军阀墓 | AVAILABLE，现有完整五层 |
| 晋北 | JINBEI_STONE | 北岭石椁调查点 | INVESTIGATING |
| 洛阳 | LUOYANG_EAST | 东原封土调查点 | INVESTIGATING |
| 洛阳 | LUOYANG_RIVER | 洛水旧陵线索 | INVESTIGATING |
| 关中 | GUANZHONG_MOUND | 渭北封土调查点 | INVESTIGATING |
| 关中 | GUANZHONG_PASS | 山口石室线索 | INVESTIGATING |

这些是明确标记的虚构调查档案。历史时期文字仅是策划形制参考/未知，不声称核实真实古墓事实。只有晋北原DEFAULT_TOMB可出发，其余按钮禁用且后端也拒绝。

## GameFlow边界与Seed

Museum只发确认site_id。GameFlow再次校验registry、AVAILABLE、完整Tomb验证与已发布loot profile，生成纯选择快照；保存成功后才设NIGHT、冻结玩家控制、排队场景切换。`start_night()`没有显式selection返回false，不恢复默认地点绕过。

确认后GameFlow自己捕获site/region/tomb/loot/seed/campaign/day；地图不持有这份快照。后续地图选择被提交锁阻止，不会改变墓中配置。保存失败留在地面，地图可重试，并回滚原早晨跳过营业时的上一日统计，避免失败操作清空统计。死亡、撤离、通关、once结算与Day+1沿用原逻辑；回馆释放选择并重新实例化可打开的地图。

Seed继续复用 `ExpeditionSeedService.derive(Campaign,Day,Site)` VERSION1，不使用全局RNG。晋北保留旧字符串 `DEFAULT_TOMB`，因此旧派生结果完全兼容。不同Site有独立域；100个Site域确定性/不重复样本通过，两有效测试Site的实际拓扑不同。选择前后BossRunPlan、RelicRewardPlan、Antique结果不变。R重开当前Seed；N重建Seed但保留本次Tomb。正式异常退出回同Day/Site仍复现初始墓穴，不保存墓中战斗进度。

原独立 `dungeon_test.tscn` DEFAULT_TOMB/CLI入口保持；GameFlow旧export tomb仅保留历史测试配置入口，生产读取Site。历史两层测试在隔离fixture中显式把legacy Tomb挂到测试registry并确认，不污染生产sites.json。

## 地区掉落接口与存档

`SiteLootProfile`提供地方类别、历史时期范围、类别权重、跨区域器物、罕见类别及approved pool接口。配置可读取、随确认传入Session的loot_profile_id，但本阶段只允许FORMAL_DEFAULT现有八件池；未来地区池须另行正式批准后实现。没有改八件ID/数值/概率，没有把1441真实资料或500候选变成墓中实物。

MuseumProfileStore VERSION5与v1–4→v5迁移未修改；现有实例、展位、现金、日期、待拍锁照旧。选择是本次Run上下文，不新增存档版本或地区进度字段。

## 实测与回归方法

`tests/phase_11a_smoke.gd`：真实WASD到情报板、E开图、Viewport鼠标事件点击地区/ItemList/确认按钮，调查中拒绝、Esc退出、保存失败/营业统计、正式五层配置、默认Seed、R/N、死亡回Day2、再开地图；完整版本复用真实武器/敌人/门/Boss/古董/遗物驾驶，原五层通关回Day2。隔离替代Site单元测试不会发布第二个生产墓穴。

完整Run33实测：五层、五Boss、13件遗物、携货5520估值，正常返回Day2。自动战斗驾驶证明装配与生命周期，不声称真人难度或美术验收。

历史8A–9A与hotfix测试适配新增确认步骤，没有删除原死亡/撤离/拍卖/Seed/战斗断言。8A新增确认前不进Night断言。数据库保护测试最初失败：旧10A哈希要求热修前Twin代码；已为获准848740d热修和本次GameFlow/Session三处变更登记精确替代哈希，仍逐文件检查全部其它冻结代码，未删除保护断言。SQLite迁移/数据/正式目录均未变。

```powershell
Godot_v4.6.2-stable_win64_console.exe --headless --editor --path . --import
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/phase_11a_smoke.gd --fixed-fps 60 --quit-after 180000
Godot_v4.6.2-stable_win64_console.exe --path . --script res://tests/phase_11a_smoke.gd --fixed-fps 60 --quit-after 15000 -- --capture --ui-only
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/phase_twin_death_hotfix_smoke.gd --fixed-fps 60 --quit-after 50000
python -m unittest discover -s database/tests -v
Godot_v4.6.2-stable_win64.exe --path . --script res://tests/phase_11a_playtest.gd -- --capture
```

图形专项实际147基础检查加营业统计边界共148项（不重复五层长Run）；完整headless为717项。截图均真实Godot Viewport，ignored logs：`11a_region_map.png`、`11a_investigation_archive.png`、`11a_jinbei_confirmation.png`、`11a_real_jinbei_start.png`。正式GameFlow图形启动另用隔离profile-path验证。

## 修改文件与限制

新增：六个expedition模型/标记脚本及UID、ExpeditionMapPanel及UID、sites.json、本地SVG与来源说明、map fixture、专项与隔离playtest及UID、本报告。生产改动仅GameFlow/Museum装配与Session的loot元数据；旧测试增加地图确认；数据库单项保护哈希精准更新；AGENTS/README/ARCHITECTURE/PROJECT_PLAN补充当前章节。

Boss、Player、Enemy、Relic、八古董、正式Catalog、ProfileStore及SQL迁移相对基线diff为空。所有脚本远小于1000行；日志/截图/存档/生成物不提交。

限制：只有晋北可以玩；其它地点没有地宫、不伪装开放。尚无永久地区解锁、地图探索历史存档或新的地方掉落。地图是第一版示意美术；没有验收Windows发行二进制包。发行导出需包括 `data/expedition/sites.json`、本地SVG导入纹理与既有JSON配置。人工地图体验仍待用户验收。

Git：独立Phase11A提交/push，不合并main，不进入下一阶段。包含本报告的最终SHA见交付消息或 `git log -1 --format=%H`。最终隔离试玩是正式GameFlow的in_memory存档，Day1/空馆藏/零现金，无赠送；停在已通过真实E打开的地图，玩家可以亲自确认晋北并下墓。

## 最终自动结果

历史28组：**293860项，0失败**；11A完整专项：**717项，0失败**；11A图形UI专项：**148项，0失败**；双生尸煞专项：**47项，0失败**；数据库：**92 tests，0失败**。导入与正式入口图形启动通过，无SCRIPT ERROR/ERROR。坏档夹具WARNING为预期。

| suite | checks | failures |
|---|---:|---:|
| 1 | 27 | 0 |
| 2 | 204 | 0 |
| 3 | 94 | 0 |
| 4 | 105 | 0 |
| 5a | 61 | 0 |
| 5b | 236 | 0 |
| 6 | 164 | 0 |
| 6_5 | 174 | 0 |
| 7a | 306 | 0 |
| 7b | 722 | 0 |
| 8a | 486 | 0 |
| 8b | 305 | 0 |
| 8c | 297 | 0 |
| 8d | 2153 | 0 |
| 9a | 10513 | 0 |
| 9b | 30758 | 0 |
| 9b2 | 4843 | 0 |
| 9b3 | 29133 | 0 |
| 9b32 | 1734 | 0 |
| 9b33 | 2702 | 0 |
| geometry | 206885 | 0 |
| softlock | 1030 | 0 |
| baseline | 728 | 0 |
| 10a | 49 | 0 |
| 10d_bridge | 9 | 0 |
| 10d_media | 11 | 0 |
| 10d | 40 | 0 |
| 10d6 | 91 | 0 |
