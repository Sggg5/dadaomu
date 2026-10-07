# Phase 9B.3 验证：敌人威胁、组合战斗与Build随机性

## 范围与状态

基准 a10ceb39517321cabad2d6a509a9eeb9f1b129e3；当前 codex/phase-9b-multifloor-endurance。代码、自动/图形验证通过，三局人工结果已记录，潜地穿墙修复后的人工复验待完成；不合并main，不进入后续阶段。9B.2乐趣反馈保留，但普通怪威胁不足，因此不能把旧阶段或自动驾驶封为最终手感验收。

## 敌人与Encounter

保留原六类AI和数值，新六类：

| 类型 | 行为/前摇 | 主要应对 |
|---|---|---|
| 潜地尸 | 地下0.6s，预测位置+速度×0.45，合法落点0.8s预警；出土后3s可攻击追击 | 读落点移动；地下暂时无敌，死亡取消落点 |
| 胀爆尸 | 接近后0.8s膨胀爆；被击杀0.6s延迟爆，单次 | 留距离，不能通过击杀取消全部爆炸风险 |
| 分裂尸 | 复用可读咬击；死亡生成两个20HP、6伤害快速碎尸，不再分裂 | 先解决子体，子体计清房 |
| 墓穴弩手 | 0.8s固定锁线，760速度重箭，发射前检查世界LOS | 横移，不会追踪或隔墙锁定 |
| 腐尸 | 慢近战；死后52px污水4s，每0.75s判定低伤害，最多4池 | 远离污染区 |
| 悬棺尸 | 固定位置，合法落点圆圈1s，再落击 | 读圈移动，优先击杀 |

Role位标记独立于AI：PURSUER/RANGED/DIVER/TANK/SPAWNER/ZONER/AMBUSHER/PRIORITY。三精英使用独立Resource/脚本：尸犬冲刺结束左右各一短波，纸人死亡0.4s预警后8枚慢环弹，母体召唤间隔3.5s且死后两虫。不是大幅HP/伤害倍增。

30个模板按10普通、10混合、6高压、4特殊设计，五层各六种独立加权池。模板数与房间抽样频率分开统计，普通/混合/高压/特殊权重倾向约50/30/15/5，第一层没有高压/特殊，深层仍有普通。四种环境：周期地刺、静态石棺、预警箭孔、纯减速积水；并非每房带机关。

所有初始Spawn距四入口≥180px、障碍膨胀24px内无出生点、两点间距≥48px；entry grace仍0.35s。EnemySpawner负责动态死亡记录/pending/living，RoomController不新增AI-ID分支。Room退出/死亡停止Hazards和弹丸；不依赖异步Timer。

## Build扩充与分配

新增16件：

- CORE：归弹珠（反弹）、引魂罗盘（温和转向且降单伤）、雷罐（每四命中邻近短雷）、护身盘（短环绕后切线飞出）。
- SYNERGY：残墨（后续穿透命中）、灰种（已有燃烧目标小爆）、回声骨（有限弱回声弹）、猎印（击杀后一次蓄力）。
- UTILITY：远灯（射程寿命）、风靴（受伤0.8s短加速）、风钉（短减速）、护钱（清房后一次减伤）。
- TRADEOFF：鬼鼓（快攻低伤）、魂砖（单枚大慢重弹）、血契（低血增伤不加HP）、倒镜（减主伤增背弹）。

总池36件，角色数量CORE11/SYNERGY10/UTILITY6/TRADEOFF9。每件独立脚本，原二十件行为保持；不添加组合ID硬判。AttackRequest通用反弹/短环绕/冷却倍率，命中Context通用tags/序号/方向。追加伤害不重新发送命中Hook，回声tags避免递归，临时减速使用弱引用与有限节点。

RelicRewardPlan VERSION3：Run结构Seed决定六种轻微archetype之一，结构倾向目标抽样18/47/28/7；这些不是宣称实战已经分成弱/普通/强/神。每个固定source独立stable_score Seed，先按来源Role权重再温和核心倾向、主题×1.35，候选按ID排序无放回。最低两核心，仅剩槽位时最低保护；没有核心硬上限，没有玩家DPS反馈，也不查询Museum。

ITEM40/35/15/10、BOSS10/45/35/10、MILESTONE10/30/30/30为基础权重。实际结果会受无放回、主题与软核心倾向影响；不是保证精确比例。五ITEM+五BOSS+三里程碑=13，实际所得依探索/清房/拾取而变；不强迫每局13件。20%二选一只预留choices API，当前没有启用生产二选一。R相同计划、N不同计划、漏房不改变后面计划。

1000 Seed遗物统计：1000不同完整计划，覆盖全部36件。核心数量2:203、3:274、4:283、5:170、6:50、7:14、8:6；98%在2～6。power_band总和proxy min24/P10=28/median31/P90=34/max39。这个proxy没有计算协同、代价和实际DPS，不能替代人工强弱验收。

实际Role分配（CORE/SYNERGY/UTILITY/TRADEOFF）：ITEM2532/1455/598/415；BOSS727/2141/1662/470；MILESTONE397/899/815/889。最常出现风靴536/1000，无一件接近所有计划必出。正式奖励上限和来源未删改。

## 1000 Seed × 五层地图统计

Combat只统计主图普通战斗节点，精英是每房至多一例，环境含静态石棺。Threat频率为1/2/3/4/5百分比。

| 层 | Combat总数 | 初始敌均数 | Threat % | 精英房 % | 环境房 % | 类型覆盖 |
|---|---:|---:|---|---:|---:|---|
| F1 | 5011 | 5.018 | 36.52/38.89/24.59/0.00/0.00 | 0.00% | 19.48% | corpse_dog, bandit_shooter, scarab, splitting_corpse |
| F2 | 7003 | 5.615 | 0.00/54.09/34.91/11.00/0.00 | 11.00% | 49.42% | scarab, bandit_shooter, corpse_dog, splitting_corpse, exploding_corpse, armored_corpse |
| F3 | 9006 | 6.147 | 0.00/51.93/29.42/14.69/3.95 | 14.69% | 59.68% | bandit_shooter, corpse_dog, tomb_crossbow, armored_corpse, scarab, paper_spirit, burrowing_corpse, exploding_corpse |
| F4 | 11530 | 7.036 | 0.00/51.27/30.20/14.95/3.57 | 14.95% | 48.73% | rotting_corpse, bandit_shooter, splitting_corpse, corpse_dog, brood_mother, scarab, tomb_crossbow, paper_spirit, armored_corpse, hanging_corpse, burrowing_corpse, exploding_corpse |
| F5 | 9482 | 7.338 | 0.00/46.40/26.83/19.76/7.00 | 19.76% | 53.60% | scarab, bandit_shooter, paper_spirit, armored_corpse, hanging_corpse, tomb_crossbow, brood_mother, exploding_corpse, corpse_dog, rotting_corpse, burrowing_corpse, splitting_corpse |

保持每层1古董房+1Cache，深层古董价值来自原RewardProfile；1000Seed既有rarity/value单调回归继续通过，未改9A风险。

## 实际流程与边界验证

以下表格保留960a362首次验证的历史驾驶记录；本次修复后重跑数据见文末。真实GameFlow、内存隔离Profile、Campaign52/Run33：博物馆情报板E→五层。每层真实Door、活跃AI、Player武器、E领取遗物房/清房/Boss底座，真实古董E和满包Tab/Delete换货；击败五Boss，第一/第二层Boss间F2+15、第四层+20规则原样，最终出口E→结算→E回Day2。

| 层 | 含可选房实际房数 | HP | 遗物 | 累计Combat | 背包估值 |
|---|---:|---:|---:|---:|---:|
| F1 | 8 | 80 | 3 | 4 | 1800 |
| F2 | 10 | 80 | 5 | 10 | 3300 |
| F3 | 14 | 17.9 | 8 | 18 | 4500 |
| F4 | 18 | 37.9 | 11 | 30 | 4400 |
| F5 | 17 | 37.9 | 13 | 40 | 5520 |

自动驾驶会直接选择安全射击坐标，但不加血、不停AI、不直接伤害敌人、不通过inventory.add替代奖励。第三层潜地/尸犬/精英纸人组合真实造成伤害，自动驾驶为功能连接验证，不能作为真人压力或Boss耗时证明。

另外三组真实Tier3高压Room（模板18/23/29）使用12件构造Build单元夹具：真实Weapon清掉母体召唤/分裂子体，开门且卸载无危险残留；完整GameFlow不使用此构造捷径。

新敌人逐类实际预警/攻击/受伤/死亡/释放，潜地下无敌与死亡取消、死亡爆延迟且只伤一次、子体两虫不递归并计清房、弩手横移和LOS、悬棺预警可躲、污水间隔/4池/4s，精英三种行为、积水只有减速、卸载取消均通过。36Effect逐件安装、命中/击杀/清房/受伤Hook、卸载取消，四组Seed的5/8/12/13件Build攻击48与Room256上限通过。R/N真实键重建计划/空Build，choices不消费未来来源通过。

## 回归真实结果

旧9B.2测试显式使用pre_threat_tomb与pre_variation_relic_pool/build_uniform，原断言保留。Phase1～9A继续legacy夹具；新专项验证当前生产配置，没有删旧覆盖。

| Phase | 检查数 | 失败 |
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
| 8a | 482 | 0 |
| 8b | 305 | 0 |
| 8c | 297 | 0 |
| 8d | 2153 | 0 |
| 9a | 10510 | 0 |
| 9b | 30753 | 0 |
| 9b2 | 4842 | 0 |
| 9b3 | 29072 | 0 |

总计 **80,507项，0失败**。9B.3 graphical **29,072项，0失败**，截图已检查（潜地/弩手/悬棺预警、组合和五层Build），无Script Error/ERROR。导入与正式入口隔离Profile启动退出0。Profile VERSION4，没有正式用户存档写入。

PowerShell复现（$godot为本机Godot4.6.2 console路径）：

```powershell
& $godot --headless --path . --editor --quit
foreach ($phase in @('1','2','3','4','5a','5b','6','6_5','7a','7b','8a','8b','8c','8d','9a','9b','9b2','9b3')) {
    & $godot --headless --fixed-fps 60 --quit-after 180000 --path . --script "tests/phase_${phase}_smoke.gd"
}
& $godot --path . --disable-vsync --fixed-fps 60 --quit-after 180000 --script tests/phase_9b3_smoke.gd -- --capture
& $godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase_9b3/startup.json --seed52
```

## 文件与架构

新增六普通+三精英脚本/场景/Definition、分裂碎尸资源、30个variety RoomDefinition、四个Encounter模块、16Effect/Definition、BriefSlow、RewardProfile及三个权重资源，phase_9b3五组专项与threat驾驶。修改Enemy基础数据接口、Spawner死亡记录、Room挂Hazards、Generator权重模板选择、AttackRequest/Projectile/Player/Runtime、RewardPlan/Service、Session/GameFlow装配、开发tooltip、生产五层模板池。BossEncounter只增加Room引用注入，不改BossAI。更新四份主文档和本验收文档，旧测试只改明确历史夹具选择。

## 已知限制与修复后人工待复验

几何占位美术，静态棺椁不可破坏；没有新Boss、词缀、难度选择或永久战斗成长。役割和power_band只读开发元数据；没有DPS动态调怪。二选一只预留API。新敌人/组合/Build实际强弱、五层疲劳和两次回血是否足够，自动测试无法决定。

三局人工反馈已记录：Run1高Build按住攻击清屏并通五层；Run2到F4主动撤离；Run3死亡且古董全部丢失。已出现完整通关、撤离、死亡三种结果，本次没有证据要求整体平衡调整。正式GUI使用隔离人工档，修复后只需重点复验中央棺椁/实体墙的潜地落点与开放空间预测；不合并main，不进入下一阶段。

## 人工试玩后Bug修正：潜地落点可达性

基准960a3628706ec084ce60598623592a2316aa67fe，继续当前9B分支。只改潜地尸和独立几何查询；不改RewardPlan VERSION3、36遗物/CORE/profile/13来源、敌人总体数量、其他敌人、三精英、30模板、四环境、五Boss、RestPoint、80HP、F2+15/F4+20、8格及古董经济。

**原因**：safe_point仅验证落点边界、障碍clearance和玩家距离，随后直接position=landing；合法落点不等于从当前潜地区域可达，因此会从棺椁/隔离墙一侧跳到另一侧。

**修复**：新增EncounterGeometry.safe_reachable_point。仍按离预测点最近排序有限候选（首选+原32px网格），先验证原合法性，再将Room-local origin/candidate分别to_global，用layer1实体PhysicsRay验证，允许排除自身RID。被挡继续搜索替代点；只有全部失败才返回INF。潜地尸将Player世界位置+velocity×0.45转换到Room-local，origin也由自身global_position转换，0.8s圈按Room-local保存，出土使用Room.to_global写global_position。父节点偏移不再泄露到物理射线/落点。原2s初始表面、0.6s潜地、0.8s预警、3s表面追击及伤害均保留；地下仍仅8px土包，不画完整实体。

**新增23断言**：真实中央Rect2(604,312,72,112)挡首选而替代点ray无碰撞/保留72px clearance；Room与Spawner偏移重复验证；完整竖墙Rect2(604,144,72,448)只能同侧出土；开放空间移动预测精确、前进超过300px、0.8s预警和表面碰撞恢复；无合法点回退SURFACE、重置2s且可受伤；地下及预警期间死亡不再生成/保留marker；实际RoomController切房不留marker/actor/延迟伤害。原死亡/卸载断言继续保留。

完整流程初轮旧自动驾驶在第三层死亡，57个后续断言连带失败；已修正测试驾驶跳过已潜地/即将潜地目标，增加最多0.3s移动提前量。只修改测试瞄准，不改攻击数值、AI或血量，不删除断言，不直接杀怪，不注入奖励。修复后真实Museum→五层→五Boss→全部E奖励→最终出口→Day2回馆再通过；本次自动驾驶F1～F5各80HP，遗物3/5/8/11/13，不能据此推断真人难度。上文17.9HP表为旧版本真实历史记录。

**最终结果**：Phase1～9B.3 80,507项0失败；9B.3 headless与graphical各29,072项0失败；独立障碍图形23项0失败。中央障碍、完整墙、开放预测截图已检查；全日志无Script Error/ERROR/泄漏报告。导入与正式入口隔离档启动退出0。日志/PNG/测试入口脚本位于ignored logs，不提交用户存档或临时文件。

本次文件：scripts/rooms/encounter_geometry.gd、scripts/enemies/burrowing_corpse.gd；新增tests/phase_9b3_burrow_reachability_checks.gd及uid，修改phase_9b3_smoke.gd注册与threat_fight_driver.gd测试驾驶；更新本验收文档。当前分支commit/push后重开正式入口，等待穿墙修复人工复验，停止。
