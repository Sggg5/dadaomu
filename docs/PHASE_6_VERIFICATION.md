# Phase 6 验证：晋北大帅尸与层间推进

## 基准与范围

从main `d37fd403fd218c3aa2c6dd2f439e57da47bdf559` 创建 `codex/phase-6-boss-floor-transition`。本阶段按用户新范围实现第一层正式Boss与第二层推进，覆盖旧Phase6古董规划。使用Godot 4.6.2标准版、Windows、Compatibility。不合并main，不实现古董、第二正式Boss或第三层。

## Boss架构与实际数据

`BossDefinition`继承EnemyDefinition，只读Resource；`WarlordBoss`继承Enemy，复用Health、受伤/死亡和scaled_damage。AI只接收Player与局部弹丸容器，不读地图、奖励或库存。`BossEncounter`归Room所有，单独持本体与召唤物；普通EnemySpawner不负责Boss。Room.damage_targets统一提供普通敌人和Boss目标，既有爆炸、墨线、燃烧可自然命中Boss。

| 项目 | 实际值 |
| --- | --- |
| ID / 名称 | jinbei_warlord_corpse / 晋北大帅尸 |
| 基础HP / Tier3实例HP | 650 / 845 |
| 普通移速 | 95px/s |
| INTRO / 决策间隔 / 后摇 | 1.0s / 1.0s / 0.6s |
| 冲锋基础伤害 / Tier3 | 18 / 24.3 |
| 冲锋前摇 / 速度 / 持续 | 0.65s / 650px/s / 0.45s |
| 震荡基础伤害 / Tier3 | 16 / 21.6 |
| 震荡前摇 / 半径 | 0.8s / 180px |
| 半血 / 召唤数量 | 首次HP≤50%且仍存活 / 3只尸蟞 |
| 第二阶段决策间隔 | 1.0×0.8=0.8s；技能前摇不变 |

状态为INTRO→DECIDE→交替CHARGE_WINDUP/CHARGE或SHOCKWAVE_WINDUP/SHOCKWAVE→RECOVERY。冲锋前身体红色与方向线，结束前摇时锁定方向；一次最多伤人一次，碰墙提前停止，横移可以躲开。震荡前地面橙色圆环逐渐扩大，完成时一次180px范围伤害，跑出范围无伤害。不用全局RNG，不无限召怪。

召尸使用正式scarab.tres与相同EncounterDifficulty，位置绕Boss优先、有限安全候选补位；避开玩家100px、障碍及其他生成点。3只只召一次，短暂0.35s激活保护。Boss外形为军帽/披风/深色尸身，体积约普通敌人两倍；均程序几何，无正式美术/音效。

## 房间胜利与出口

第一层BOSS仍复用随机RoomDefinition的地板、障碍和门，忽略其普通spawns；本体活着时ACTIVE且门关闭。Boss死亡只结算一次，停止本体/召唤AI，清余下召唤物和局部弹丸，不伪造召唤物击杀奖励；Room转CLEARED、开门、生成单一FloorExit。已清Boss房离开再回来重新放置出口，不刷Boss。

HUD只在正式Boss房显示名字、当前/最大HP及血条，死亡隐藏；局部存活数包括Boss与召唤物。FloorExit显示“通往更深处的墓道 / [E] 深入墓穴”，64px内、玩家活着且控制可用时E交互一次，只发信号；地图由Session生成。

## Floor、Seed与恢复

Session区分 `_start_new_run` 与 `_enter_next_floor`：

- 新Run：创建新的World、Player与RewardService，floor=1、HP80、Build空、进度零。
- 下一层：捕获RunCarryState，释放旧World，仅保留同一个RewardService，新World/Player恢复当前HP和遗物定义。

第一层`current_floor_seed=run_seed`。第二层候选为`(run_seed XOR (2*104729)) + attempt*7919`，attempt=0..15，选择与第一层空间签名不同的第一个结果；全过程只用Generator独立Seed，不能由N的随机来源或时间影响。有限失败会拒绝切层，默认配置测试未遇到失败。Seed192034的第二层Seed为121872，9房；R再进相同Run可复现完整第二层Layout。

RunCarryState只保存current_hp与只读RelicDefinition引用，恢复时Inventory.add生成新Effect。Health.restore clamp0..max、更新is_dead、仅emit changed，绝不触发damaged/died。保留HP、遗物ID；重置铜镜/洛阳铲计数、纸鸢充能、武器冷却，旧Room燃烧与弹丸不跨层，旧Effect卸载一次、新Effect安装一次。

原RewardService实例、combat_clears、rewards_given、sequence、_seen全部保留。2/4/7为整Run累计，第7次可发生在第二层；发过3件不再发第四件。第二层Context.room_id为`F2:<local_id>`，避免与第一层重复ROOM_001而漏算。START、ANTIQUE、BOSS均不计普通清房。

第一层floor_offset=0，第二层=3；effective_depth=local_distance+offset。第二层第一个普通房本地1→有效4→Tier2，后续进入Tier3，无Tier4。HP倍率1/1.15/1.30、伤害倍率1/1.15/1.35不变；仍只缩放实例HP/伤害，不修改共享Definition或移速/弹速/时序。

第二层BOSS仍为模板普通敌人，不再生成晋北大帅尸，清完也无第三层出口。R从第二层回同run_seed第一层，80HP空Build、奖励进度零而序列相同；N新run_seed、第一层、新序列。

## 修改文件

新增（相关GDScript .uid一并提交）：

- scripts/bosses/boss_definition.gd、warlord_boss.gd、boss_encounter.gd
- data/enemies/jinbei_warlord_corpse.tres、scenes/enemies/warlord_boss.tscn
- scripts/dungeon/floor_exit.gd、run_carry_state.gd
- scripts/ui/boss_health_display.gd
- tests/phase_6_boss_checks.gd、phase_6_floor_checks.gd、phase_6_smoke.gd
- docs/PHASE_6_VERIFICATION.md

修改：scripts/combat/health.gd、combat_geometry.gd；scripts/dungeon/dungeon_session.gd；scripts/rooms/room.gd、room_controller.gd；scripts/ui/room_test_hud.gd、scenes/ui/room_test_hud.tscn；tests/phase_3_smoke.gd、phase_5b_run_checks.gd；AGENTS.md、README.md、ARCHITECTURE.md、PROJECT_PLAN.md。

Phase3原BOSS普通刷怪断言换为正式Encounter接入断言，其余94项保留。Phase5B实际深度断言增加floor_offset，第一层原236项回归不变。未修改玩家基础属性、普通敌人数/数据、八件正式遗物或2/4/7规则。

## 自动验证命令与结果

以下godot代表本机 `C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`。在项目根目录运行：

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10
godot --headless --path . --script res://tests/phase_1_smoke.gd
godot --headless --path . --script res://tests/phase_2_smoke.gd
godot --headless --path . --script res://tests/phase_3_smoke.gd
godot --headless --path . --script res://tests/phase_4_smoke.gd
godot --headless --path . --script res://tests/phase_5a_smoke.gd
godot --headless --path . --script res://tests/phase_5b_smoke.gd
godot --headless --path . --script res://tests/phase_6_smoke.gd
godot --path . --script res://tests/phase_6_smoke.gd -- --capture
```

| 检查 | 真实结果 |
| --- | --- |
| Godot导入解析、项目启动 | 均退出0，无解析/运行错误 |
| Phase1 | 27检查，0失败，退出0 |
| Phase2 | 204检查，0失败，退出0 |
| Phase3 | 94检查，0失败，退出0；原100 Seed与联通覆盖保留 |
| Phase4 | 105检查，0失败，退出0 |
| Phase5A | 61检查，0失败，退出0 |
| Phase5B | 236检查，0失败，退出0；三组遗物协同通过 |
| Phase6无窗口 | 163检查，0失败，退出0（边界修订后，固定60fps步进） |
| Phase6实际图形 | 153检查，0失败，退出0 |

Phase6 Boss专项覆盖用户条目1～28：最深叶、忽略spawns、单Boss/数据/实例HP、锁门/INTRO、冲锋前摇/锁向/一次伤害/横移/撞墙、震荡前摇/范围内外一次结算、半血3尸蟞/一次/安全位置/同Tier、死亡一次/清召唤物/清场开门/HUD隐藏、单出口与E一次。额外覆盖ACTIVE重复enter不重复Boss、已清Boss重访恢复出口。

Floor专项覆盖29～60：初始层Seed、胜利前/距离外不能过层、真实E第二层、派生Seed/同Run重复Layout/空间不同、唯一Player/旧World释放、HP/ID集合/Effect安装卸载、Burn/纸鸢/计数/武器冷却清理、同Service全状态延续、全局第7次第三奖励、有效深度/Tier/共享资源、第二层普通Boss/无第三层、R回第一层HP80空Build同序列、N新局。额外覆盖Health.restore上下界与仅changed、不发第四件奖励。

最终无窗口自动行为使用`--fixed-fps 60`固定物理步进，所有阶段仍按真实节点/输入/弹丸执行；普通实时无窗口及实际窗口已另跑通过。图形153项之后新增一项ACTIVE重复enter断言，无窗口最终154项通过。

本地日志在忽略的logs/phase_6_final_*.log、phase_6_graphical.log；检查最终汇总和ERROR/SCRIPT ERROR，不只依赖进程退出码。初次迭代发现测试夹具冲锋落点被障碍挡住、已释放对象的typed lambda，以及卸载后definition清空；修正夹具/引用后重跑通过，没有删除行为断言。

## 实际图形闭环

Seed192034：从安全START，以活跃AI、真实Weapon/Projectile逐个清六个COMBAT，按E从底座获得墨斗/五帝钱，真实WASD和Door到达BOSS。Boss实际执行冲锋、震荡、半血3尸蟞，真实弹丸击杀，清掉剩余召唤物并产生墓道；近身真实E到第二层安全START，再清至少一个真实COMBAT（累计第7个，正常E拾取黑火药），确认第二层普通Boss占位可清且无第三层入口。

程序驾驶在普通房和Boss战会直接选择安全射击位置，Boss只在DECIDE/RECOVERY窗口射击；不冻结AI，不改玩家HP通过战斗，不用F2，不直接清Boss HP。Boss实战前只持正常拾取的两件遗物。该驾驶不是人工手感验收，完美位移降低受伤概率，战斗耗时约15.3s，不能据此宣称普通玩家已达到20～40秒。

完整真实击杀结束后，另设Runtime边界夹具：给铜镜/洛阳铲/纸鸢并设置非零计数、受5伤充能，挂旧Room临时Burn；验证进入第二层后HP75仍75，原有与夹具遗物ID都保留，效果替换/计数充能清零、Burn释放。这部分是生命周期单项，不把这些额外遗物算作正常奖励获取或Boss通关Build。

截图已实际查看：Boss本体/血条、震荡圆环、半血三尸蟞、胜利墓道、第二层START与75HP。HUD不遮挡房间，小地图/层数/有效深度和存活数正常；截图位于忽略的logs/phase_6_*.png。

## 人工试玩与限制

已打开可玩游戏Seed192034，并请求不使用F2试玩冲锋/震荡、半血压力、战斗时长、出口与跨层。当前人工反馈待完成；自动图形流程通过不等于主观验收通过。Boss正常玩家20～40秒、半血压力及第二层危险感仍需人工确认。

已知限制：几何占位与无正式音效；简单切向绕障而非完整寻路；程序驾驶完美射击约15秒；第二层无正式Boss/第三层/结束结算；古董/撤离/经济/存档均未实现。跨层主动重置临时效果计数和充能；奖励离房未领仍丢失，不补发。后续阶段须另获授权，本任务完成后停止。

## Phase 6 边界修订：冲锋遮挡与玩家死亡HUD

基准提交为6583f996a4fb434e76216bb955e9d4ca1c0c09bc，仍在codex/phase-6-boss-floor-transition。本次仅修改warlord_boss.gd、room_controller.gd、phase_6_boss_checks.gd与本报告。

CHARGE先处理move_and_collide结果：碰撞Player才结算一次伤害；碰撞墙/障碍立即RECOVERY，不进入proximity分支。无碰撞时保留50px近距一次命中，并使用现有has_line_to_target确认没有World遮挡，避免尚未接触薄墙时也隔墙伤人。方向锁定、0.65s前摇、650速度、0.45s持续及全部伤害/HP参数不变。

新增Boss→薄障碍→Player夹具：World障碍1×96px，中心(600,544)；Boss由(550,544)向右冲锋，Player在(617,544)。Boss停止后双方仍在障碍两侧且中心距<50px，断言RECOVERY、Player HP80不变、_charge_hit未标记。薄障碍专门满足“隔着障碍但中心距仍小于旧阈值”的边界，不改变正式模板。原真实冲锋一次伤害、横移躲避、撞墙停止仍保留；另验证直接碰撞Player提前停止，以及仅夹具排除玩家物理碰撞时，无遮挡近距仍只伤一次。

RoomController._on_player_died新增hud.hide_boss()，并继续执行原停止战斗/清理底座/show_death逻辑。新Run进入活Boss房，死亡前HUD可见；真实Health死亡信号后同步断言Boss血条已隐藏、Death标签正常、Boss AI停止。普通房死亡由Phase1～5B原回归继续覆盖。

先只加入回归夹具、运行旧代码：160检查中恰好2项失败（隔墙伤害、死亡血条），证明测试确实复现问题。应用修复、补全直接碰撞/无碰撞分支覆盖后完整重跑：

| 套件 | 检查 / 失败 / 退出码 |
| --- | --- |
| Phase1 | 27 / 0 / 0 |
| Phase2 | 204 / 0 / 0 |
| Phase3 | 94 / 0 / 0 |
| Phase4 | 105 / 0 / 0 |
| Phase5A | 61 / 0 / 0 |
| Phase5B | 236 / 0 / 0 |
| Phase6 | 163 / 0 / 0 |
| 导入解析、启动 | 均退出0，无Godot错误 |

复现命令为`godot --headless --fixed-fps 60 --path . --script res://tests/phase_<阶段>_smoke.gd`，阶段依次1、2、3、4、5a、5b、6；导入用`--headless --path . --editor --quit`，启动用`--headless --path . --quit-after 10`。本机完整Godot路径见上文。新日志为忽略的logs/phase_6_boundary_<阶段>.log、phase_6_boundary_import.log、phase_6_boundary_startup.log；旧代码复现失败保存在phase_6_boundary_before.log。

163项包含原完整真实Weapon/Projectile击杀Boss→E进入第二层→继续COMBAT流程。本次未重跑图形截图，图形153项为前次阶段验收记录；主观人工试玩状态仍未确认。未修改第二层、遗物、RewardService、Floor Seed、玩家资源或Boss数据/技能时序；不合并main，完成push后停止。
