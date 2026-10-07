# Phase 9B.3.2b — Room Geometry Variety & Boss Arena Separation

以下主体记录298bf6a首次空间拆分；文末“2026-10-08顺序复验B补齐”是当前Geometry v2/13种布局/8.4436%结果，旧v1统计仅保留历史对照。

## 基线与边界

基线 `5435e96872f2ff8a2b76d24cfb438406df9df39d`，当前分支codex/phase-9b-multifloor-endurance。9B.3.3此前已提交；本次按最新HEAD和“不要改Boss HP/伤害/Build”保留其数值，只做空间拆分与合法性。没有继续Boss Pressure，没有新Boss/怪/遗物/经济或存档版本，不合并main。

## 架构

- RoomGeometryDefinition持id/obstacles/environments/tags/selection_weight；RoomGeometryPool为只读池。
- RoomDefinition保留Encounter identity、spawns（position仅preferred）、threat_rating、selection_weight、观察期/主题色。生产data/rooms/variety30份资源移除空间字段及旧环境子资源；旧RoomDefinition空间字段仅用于历史普通房夹具，逐步兼容，无生产双路径。
- RoomGeometryPlan在探索附加拓扑装配后创建独立空间计划，不改DungeonLayout/DungeonRoom/Template引用。RoomController只调用计划模块并将选中Geometry注入Room，不写选择算法。
- RoomGetter统一当前空间；Room装墙/绘制/环境，EnemySpawner/BossEncounter/Geometry queries，Pedestal/Cache/RestPoint/风险棺椁全读取该空间。
- BossArenaDefinition/Pool仅Boss，BossArenaPlan按兼容tags筛选独立选择。正式五层显式注入两池，配置缺BossArena池时校验失败。即使历史/独立BOSS没有池，Room也构造空BossArena，绝不继承普通Encounter障碍。
- 专项可显式注入UNIT Arena以验证固定读招/墙碰撞，正式GameFlow不设置override。旧普通房夹具仍按其显式旧布局，无新池参与。

## 确定性与规则

GEOMETRY_VERSION=1；独立RandomNumberGenerator的稳定score输入Run Seed、floor_number、room_id、geometry_pool.id和version。候选按id排序后加权；节点按距离/文本ID稳定遍历，排除已装配邻居Geometry ID。安全房空空间带稳定SAFE_RoomID，Boss的ID为BOSS_*，全部主图邻接ID不会重复。

中央棺weight1，其它weight8；额外每层硬配额floor(COMBAT数/10)，因此不只依赖统计概率。Boss池禁止中央标签和Rect2(500,270,280,200)内实体障碍。

BossArenaPlan ARENA_VERSION=1，独立BOSS_ARENA命名空间，加pool id/floor/room/run；BossRunPlan VERSION1和其选择/32路线保持。相同Seed/配置/引擎/版本R复现，N通常变化；修改资源或版本会改变空间结果。

## 出生与合法空间

EnemySpawnPlacement先解析整波，然后才创建Actor。有限preferred+网格候选，Room边界、四入口至少180px、障碍膨胀24px、敌间48px；没有点返回error，Spawner记录placement_error/_failed并push_error，不生成半波或静默墙内出生。运行时不修改Spawn/Enemy共享Resource。

Room-local→Room.to_global→Spawner.to_local显式转换；偏移Room/Spawner测试验证实际身体仍合法。风险伏兵保留距当前Player180px与0.35秒观察期；父content通过显式Room注入，不能查询错误父节点。

Boss本体/双生、召唤、虫卵共用当前Arena安全点；预警落点和身体推进读Arena，圆/线危险区非法起点重新找合法空间。假身随本体运动持续保持合法位置。地刺/腐液/落石/落点不依赖普通Encounter障碍。所有伤害/警示/持续数值冻结。

离线24px裕量/32px洪泛验证四入口、中心主要活动区域和所有可走格连通，不替代实际Physics扫掠。初版Arena六种，中心开放、掩体小且偏边缘；铜甲有真实可撞静态墙，双生两活动区保持开放。

## 潜地卡房修复

完整Run33 F3在WATER_CHANNEL复现两只潜地尸选同一落点；启用碰撞后位置相互挤压到Y=-220656，仍有38/58HP，HUD剩2、门无法开。对应此前不可见活怪反馈，不是RoomState缺失或需要强制开门。

新增Enemy.reserved_world_position空间接口，潜地WARNING预留落点；可达查询同时避开其他实体/预留点48px和Player身体40px，仍优先预测位置、同侧替代、layer1真实Ray。出土前再校验，失败回SURFACE；不改变60基础HP/115移速/0.6地下/0.8预警/3秒地面时间或伤害。

专项两只独立Health/登记敌人同步潜地，预留点分离、20次30帧持续边界检查、真实武器清场。旧中央障碍/隔离墙/开放预测/无合法点/死亡/卸载覆盖保留。原反馈Seed735291385 F3自动99项0失败，截图Seed522269330 F5自动81项0失败；旧现场进程不会热更新，人工复验待。

## 1000Seed统计

每Seed五层，总42,032普通房；中央棺231，占0.5496%。12种全部覆盖；Boss中央大柱=0，十Boss各两个兼容Arena全部覆盖。验证347个实际Encounter/Geometry组合的整波位置及边界/间距/入口。

|Geometry ID|出现次数|
|---|---:|
|BROKEN_HORIZONTAL_WALL|3773|
|BROKEN_VERTICAL_WALL|3801|
|CENTRAL_COFFIN|231|
|DIAGONAL_PILLARS|3832|
|DOUBLE_LANE|3915|
|FOUR_CORNER_COFFINS|3711|
|OFFSET_COFFIN|3845|
|OPEN|3703|
|SCATTERED_SMALL_COVER|3815|
|SIDE_COFFINS|3846|
|SIDE_CRYPTS|3727|
|WATER_CHANNEL|3833|

|Boss|兼容Arena及出现次数|
|---|---|
|bronze_king|BOSS_EDGE_COVER: 255, BOSS_SIDE_WALLS: 268|
|centipede_mother|BOSS_OPEN: 253, BOSS_WIDE_HALL: 259|
|chain_zombie|BOSS_OPEN: 235, BOSS_WIDE_HALL: 254|
|coffin_old_corpse|BOSS_OPEN: 265, BOSS_SIDE_WALLS: 250|
|jinbei_warlord_corpse|BOSS_OPEN: 245, BOSS_SIDE_WALLS: 266|
|paper_general|BOSS_CORNER_COVER: 234, BOSS_OPEN: 254|
|scarab_nest|BOSS_EDGE_COVER: 230, BOSS_OPEN: 255|
|tomb_guardian_beast|BOSS_OPEN: 257, BOSS_WIDE_HALL: 255|
|tomb_master|BOSS_EDGE_COVER: 259, BOSS_OPEN: 229|
|twin_revenants|BOSS_CORNER_COVER: 218, BOSS_DUAL_OPEN: 259|


每种Encounter跨Run可配多个Geometry；主图signature、legacy/profiled Antique、Cache选源、RelicPlan和BossRunPlan前后不变。真实R/N界面也通过。

## 实际与图形流程

12种普通布局逐一实例化真实EnemySpawner，Weapon/Projectile清场→连接Door打开→真实Door返回START；六Arena实例化兼容Boss/召唤/卵及实际危险区域，故意污染普通模板中央棺仍不影响Boss空间。五层正式GameFlow通过真实Door、E、战斗、遗物/古董、五Boss、出口，返回真实Day2 Museum。

普通12张：logs/geometry_OPEN.png、OFFSET_COFFIN、SIDE_COFFINS、DIAGONAL_PILLARS、BROKEN_HORIZONTAL_WALL、BROKEN_VERTICAL_WALL、FOUR_CORNER_COFFINS、DOUBLE_LANE、SIDE_CRYPTS、SCATTERED_SMALL_COVER、WATER_CHANNEL、CENTRAL_COFFIN（均geometry_前缀/.png）。

Boss九张含六Arena与指定组合：

```text
geometry_BOSS_OPEN_scarab_nest.png
geometry_BOSS_EDGE_COVER_scarab_nest.png
geometry_BOSS_SIDE_WALLS_coffin_old_corpse.png
geometry_BOSS_CORNER_COVER_paper_general.png
geometry_BOSS_DUAL_OPEN_twin_revenants.png
geometry_BOSS_WIDE_HALL_chain_zombie.png
geometry_BOSS_SIDE_WALLS_bronze_king.png
geometry_BOSS_OPEN_tomb_guardian_beast.png
geometry_BOSS_EDGE_COVER_tomb_master.png
```

截图为明确指定Arena的空间夹具，含手工追加召唤/卵/危险区，不表示各Boss正式技能或自然楼层；正式实际战斗另由完整Run与回归覆盖。已目检普通断墙/侧棺、铜甲侧墙、双生开放两区，HUD/入口/障碍可见。

## 自动回归

|阶段|断言|失败|
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
|9b3|29077|0|
|9b32|1733|0|
|9b33|2701|0|
|geometry|199526|0|


合计284,472项，0失败。Geometry graphical 199,526项、0失败；导入/正式入口启动无解析/脚本错误。8B～9A负向存档夹具的预期WARNING保留，不将其误报为回归失败。

旧测试只适配空间访问、明确UNIT Arena、整波preferred语义；完全堵死房的潜地回退夹具先合法出生再堵空间，保留回退/可伤害断言，同时新测试独立验证墙内出生被拒绝。没有删断言让测试通过。Boss基础data/bosses字段与基线逐字比较，除compatible_arena_tags外完全一致；数据遗物/敌人/经济/版本未改。

## 命令

使用Godot4.6.2 console，目录为项目根：

```powershell
Godot_v4.6.2-stable_win64_console.exe --headless --path . --editor --quit
Godot_v4.6.2-stable_win64_console.exe --headless --fixed-fps 60 --quit-after 180000 --path . --script tests/phase_geometry_smoke.gd
Godot_v4.6.2-stable_win64_console.exe --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 180000 --script tests/phase_geometry_smoke.gd -- --capture
Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit-after 10 -- --profile-path=user://tests/geometry/startup.json --seed=33
```

完整回归同headless参数逐一运行Phase1～9B.3.3及geometry smoke（含所有A/B/C/D分支历史阶段）。生成日志/截图/统计/临时驱动放ignored logs，不提交用户存档。

## 文件与人工边界

新增：8个Geometry/Arena/Plan/Placement/Validation脚本、对应UID；20份Geometry/Arena/Pool资源；4份Geometry测试与UID；本报告。修改：生产30 Encounter、五Floor配置、十Boss兼容tags；Session/RoomController/Room/Spawner、危险/拾取/风险/Rest空间访问；潜地占位与Boss区域/假身空间检查；旧测试适配及AGENTS/README/ARCHITECTURE/PROJECT_PLAN。

没有新增场景复制、插件、Boss/怪/遗物或存档版本。固定Room矩形和当前简单AI保持；离线格子校验不是全尺寸导航证明，有限自动驾驶也无法证明不存在所有绕掩体策略。中央稳定圆柱路径已删除，但“同组合不同打法、连续5～10房空间变化、Boss无永久安全绕柱点”必须人工试玩，当前未标人工通过。

正式GameFlow试玩使用隔离测试profile；不使用F2加物。交付后停止，不合并main、不再调Boss Pressure，等待人工验收。

## 9B.3.2a-c 顺序复验：B补齐（2026-10-08）

A提交51909c6之后继续现有架构，新增WIDE_OPEN：生产普通池13种（OPEN/WIDE_OPEN都无实体障碍，WIDE标签预留弹幕/高速空间语义，不扩房尺寸）。四角Boss掩体现在是真实四角小棺，中心仍开放。大帅兼容OPEN/WIDE_HALL。RoomGeometryPlan升级GEOMETRY_VERSION2：中央weight12，其它8，每层ceil(COMBAT/10)有限配额，允许小层偶发中央布局；整体占比由1000Seed统计断言<=10%保护。

1000Seed五层共42032战斗房，中央3549（8.4436%，低于硬上限，略高于建议5～8%）；13种均覆盖，邻接重复0，Boss中央柱0，十Boss所有兼容Arena覆盖。390种Encounter/Geometry配对验证全波出生无墙内/入口封堵；四入口与活动区洪泛连通。新增风险拓扑/events/secret/fork独立随机流比较；地图/Boss/Relic/Antique/cache原断言继续保留。

图形专项206582项0失败：13普通Geometry、6Arena与铜甲SIDE_WALLS/双生DUAL_OPEN/镇兽OPEN/墓主人EDGE_COVER截图均生成于ignored logs；目检四角Arena与真实Boss/召唤。R稳定、N变化、实际清房过门、五层回馆通过。Softlock1030项0失败。自动驾驶位置选择不是人工难度结论，空间打法与永久绕掩体问题仍需最终人工验收。
B全回归21套291528项、0失败；加Softlock共292558项、0失败。导入/隔离Profile正式入口启动正常。
