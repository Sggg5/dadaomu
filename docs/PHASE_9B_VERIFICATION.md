# Phase 9B 验证记录

基线：`aaefb2e653cdbfa1dd87deb4e46ba5772fdef72c`。开发分支：`codex/phase-9b-multifloor-endurance`。不合并main、不进入后续阶段。

## 实现与职责

- TombDefinition / TombFloorDefinition：多层数据编排与验证，最后一层由数组位置判断，允许一层/三层/其他层数。
- TombFloorGenerator：楼层Seed装配，DungeonGenerator继续只生成单层正交树；RoomController不生成拓扑。
- DungeonLayout：新增terminal_id，boss_id仅Boss层有效；签名也记录终点身份。探索装配/小地图过滤保留terminal_id。
- Room：原场景复用，普通终点真实Spawner战斗后生成出口，Boss终点仍用BossEncounter；重访不重复战斗。
- DungeonSession：任意非最终层都支持F撤离/E深入；cleared_floors与真实Boss计数分离，RunResult不再以Boss数冒充层数。
- RestPoint：本层一次性医疗包，通过Health.heal治疗；满血不消耗、死亡不可使用、重访已领不生成，未用不跨层。
- AntiqueRewardProfile：普通古董来源的只读概率，旧pick保留；高价值祭台和暗室供物继续原RARE/TREASURE池。
- HUD：层数/总层数/层名、通用终点操作、T/B分别表示普通终点/Boss。

新增核心脚本位于scripts/dungeon/{tomb_definition,tomb_floor_definition,tomb_floor_generator}.gd、scripts/dungeon/interactables/rest_point.gd、scripts/antiques/antique_reward_profile.gd。新增default_tomb、五份FloorDefinition/Config/Profile、legacy_two_floor_tomb与phase_9b_*测试。修改Session、Generator、Config、Layout、Room/Controller、Pool/LootService/RiskService、GameFlow、探索复制、小地图/HUD及历史测试夹具注入。源.uid一并提交，logs与测试截图不提交。

## 正式配置

|层|名称|基础房数|最短终点距离|古董最短距离|终点|治疗|C/U/R/T权重|
|---|---|---|---|---|---|---|---|
|1|浅层墓道|4～6|3|1|普通战斗|0|55/30/12/3|
|2|前墓室|5～7|4|2|晋北大帅尸|15|35/35/22/8|
|3|中层墓室|7～9|5|2|普通战斗|0|20/35/30/15|
|4|深层墓室|8～11|6|3|普通战斗|20|10/25/40/25|
|5|主墓室|6～9|5|2|镇墓兽|0|5/15/40/40|

基础范围不计最多两间可选绕路和一间暗室。终点不计普通COMBAT清房奖励/陪葬匣候选；没有动态补发遗物或古董。

## Seed与复现

F1=run_seed。F2=(run_seed XOR (2*104729))+attempt*7919，最多16次，避免与第一层同空间签名，保持历史算法。F3+使用AntiquePool.stable_score(run_seed,floor_number,tomb.id,"FLOOR",1)。所有生成、古董Profile与风险事件各用独立局部RNG。没有时钟参与楼层派生。

正式GameFlow仍由Profile v4的campaign_seed、day、site派生Expedition Seed，9B仅在其下派生Floor Seeds。R重建同Run全部层与空Build/库存；N临时新Run，Campaign/日期安全存档不改。复现固定自动测试Run33使用测试专用forced_night_seed，生产默认0。

|Run33层|Floor Seed|基础房数|
|---|---:|---:|
|1|33|4|
|2|209427|5|
|3|929010088|7|
|4|1678117378|10|
|5|279741021|8|

## 1000 Seed统计（每层1000张地图与1000次Profile抽取）

|层|平均基础房数|平均rarity（0～3）|平均基础估值|
|---|---:|---:|---:|
|1|5.011|0.651|613.56|
|2|6.003|1.018|863.28|
|3|8.006|1.454|1167.69|
|4|9.530|1.823|1422.17|
|5|7.482|2.143|1722.12|

F1～F4平均地图扩大，F5收束；奖励品质/价值总体递增。F5仍抽到COMMON与TREASURE。单Run不保证价值单调递增，仍需要玩家自己判断价值/格和替换取舍。

## 实际程序流程（不是人工手感）

正式GameFlow场景、生产默认五层Tomb、隔离内存存档、测试固定Run33。通过真实情报板E进入夜间，真实Door过房/Weapon/Projectile杀敌、实际清房遗物和古董E拾取；没有F2、inventory.add或HP注入替代这条主流程。程序驾驶会选择安全射击点，不能用其存活率推断难度。

F1普通终点→E深入；F2真大帅尸→医疗包E→E深入；F3普通终点→E；F4普通终点→医疗包E→E；F5真镇墓兽→RunExit E→COMPLETED→结算E回Day2博物馆，携货安全入藏一次。结果reached5/cleared5/bosses2。各次跨层检查旧Player释放、HP/古董/Relic定义保留和8格容量不变。

F2/F4在真实敌人攻击后再治疗，分别有效+15/+20：63.9→78.9、57.3→77.3。其余层没有免费回血。单位边界另验证34+15=49、72+15=80、满血不消费、死亡不能治疗、离开终点再受伤回来可用、已用重访不生成、未用随World释放。

|完整程序Run离层|HP|背包槽位|携货估值|真实Boss累计|
|---|---:|---:|---:|---:|
|1|80|2|240|0|
|2|78.9|7|2940|1|
|3|78.9|8|5500|1|
|4|77.3|7|5400|1|
|5|77.3|7|6800|2|

F3开始发生真实满包E失败→Tab/Delete→E换货。例如丢弃银元120换玉璧900；深层仍保持8格，不自动替换，不把掉落直接塞包。程序驾驶的选择不一定经济最优。

另从真实GameFlow分别重跑前缀，在F1/F2/F3/F4真实终点F撤离；结果均EXTRACTED/reached当前层/cleared当前层，Boss计数0/1/1/1，实际E回馆并安全入藏。死亡统计单项独立构造已清层账本：F4尚未清终点死亡=reached4/cleared3/boss1；它属于边界测试，不冒充完整无注入死亡主流程。一层普通终点墓也通过真实战斗和RunExit完成，0Boss；三层数据生成有效且第四层拒绝。

## 历史兼容与冻结边界

保留default_dungeon_config，新增tests/fixtures/legacy_two_floor_tomb，历史Phase1～9A Session/GameFlow夹具显式注入旧两层墓，未删除核心断言。legacy Profile为空继续旧pick语义，生产五层每层使用Profile。

玩家80HP/8格、敌人和Boss数据、前摇/伤害/移动/冷却、Tier3上限、遗物2/4/7以及9A棺椁35/25/20/20、20HP机关、25HP祭台、暗室35%/绕路45%/普通棺椁0～1均保持。Museum/Profile/市场代码无经济新功能，无永久战斗成长、药品库存、存档v5或墓内续存。Museum不传现金/等级/拍卖参数给治疗和奖励Profile。

## 验证命令与结果

使用Godot 4.6.2 stable Windows console：

```powershell
godot --headless --path . --editor --quit
godot --headless --fixed-fps 60 --quit-after 150000 --path . --script tests/phase_9b_smoke.gd
godot --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 150000 --script tests/phase_9b_smoke.gd -- --capture
godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase_9b/startup.json --seed=52
# Phase1～9A同参数逐套跑phase_<name>_smoke.gd。
```

最终完整回归：Phase1～9B **41,508项、0失败**；其中旧Phase1～9A **15,840项、0失败**，9B headless **25,668项、0失败**。9B graphical **25,668项、0失败**。导入与隔离正式入口启动返回0，错误/失败扫描为空。检查并实际查看了终点、层名/出口提示、Boss预警和背包截图。

|套件|断言数|失败|
|---|---:|---:|
|1|27|0|
|2|204|0|
|3|94|0|
|4|105|0|
|5A|61|0|
|5B|236|0|
|6|164|0|
|6.5|174|0|
|7A|306|0|
|7B|722|0|
|8A|482|0|
|8B|305|0|
|8C|297|0|
|8D|2153|0|
|9A|10510|0|
|9B|25668|0|

日志：logs/phase_9b_regression_*.log、phase_9b_graphical.log、phase_9b_import.log、phase_9b_startup.log，均忽略不提交。错误/失败扫描与实际返回码同时检查。

## 人工试玩

待用户实际试玩与反馈，不能将自动驾驶数据作为人工验收。已打开正式GameFlow隔离测试档`user://tests/phase_9b/manual_playtest.json`（Campaign初始化52），窗口实际存在；不需要强制通五层。关注F1短、F3/F4扩大、F5收束、休整能否保留压力、F2～F4撤离犹豫、深层换货及总Run长度。

|层|进入HP|离开HP|背包|估值|是否深入|
|---|---|---|---|---|---|
|1|待反馈|待反馈|待反馈|待反馈|待反馈|
|2|待反馈|待反馈|待反馈|待反馈|待反馈|
|3|待反馈|待反馈|待反馈|待反馈|待反馈|
|4|待反馈|待反馈|待反馈|待反馈|待反馈|
|5|待反馈|待反馈|待反馈|待反馈|待反馈|

## 已知限制

占位美术/开发HUD；仅原有两Boss与八种古董，稀有度曲线非最终经济平衡。固定Pool/profile/config/生成版本与引擎版本影响复现；没有跨版本地图承诺。RNG确定性与程序集成通过不能证明五层时长与风险手感合格。风险事件密度冻结，等人工五层反馈再评估；不在本阶段继续调伤害或事件概率。不合并main、不进入后续阶段。
