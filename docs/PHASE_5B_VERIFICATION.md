# Phase 5B 验证报告

> 最新平衡修订：奖励2/4/7、两类敌人强化、深度Tier与新模板组成；本文件前半部分保留原版历史，当前结果见末节。

日期：2026-10-06。基准main d7660a1ff198cf1c0a6ce1520db8f315c3766c82。
工作分支 codex/phase-5b-relic-builds。Godot4.6.2标准版 / Windows / Compatibility。

## 实际实现与范围

补强RoomClearContext与AttackStage；独立正式RelicPool/RewardService、E领取底座、指定8件独立效果、3组自然协同。工程test_damage_relic/test_double_shot/test_kill_heal继续用于回归，不进入正式池。没有古董/鉴定/买卖/黑市/永久成长/存档/正式Boss/第三敌人/复杂状态框架。

## RoomClearContext

Controller统一创建room_id、实际room_type、was_combat、enemy_count。只普通COMBAT was_combat=true；START/ANTIQUE=false且count0；BOSS占位有敌人数但was_combat=false，不计普通奖励。Runtime.room_cleared(context)与Controller.room_cleared(context)都转发快照。Room原有一次性CLEARED状态负责去重，奖励Service再按ID防御去重。Phase5A旧测试只改回调类型，未删断言。

## Attack Stage与请求

排序：DAMAGE → COUNT → DIRECTION → PROJECTILE_PROPERTY → FINAL；再按priority升序、最后stable ID。五帝钱COUNT；引魂纸鸢DIRECTION；镇尸钉PROJECTILE_PROPERTY；铜镜FINAL priority0；洛阳铲FINAL priority10。ID不决定主要执行关系。

AttackRequest增加pierce_count、projectile_scale、tags；copy复制所有字段并独立复制tags。ProjectileHitContext增加origin。Projectile只读取通用参数和heavy呈现标签，不检查遗物ID；已命中集合/碰撞例外防重复，墙体始终销毁弹丸。敌方弹丸不经过玩家修改器。

## 正式奖励流程与确定性

DungeonSession拥有当前局RelicRewardService，创建World前注入。Service只负责池、独立RNG、首次COMBAT进度和序列；Runtime仅持有/执行效果。固定Phase2夹具没有注入奖励，生产Session始终注入。

首次COMBAT清场第1、3、5次发reward_available；其他次数没有奖励。START/ANTIQUE/BOSS/重访/重复通知不推进。Controller在当前房创建RelicPedestal，位置避开障碍，显示名称/说明/E提示；玩家64px内按interact(E)安装成功后claimed=true并释放。死亡停止Service并移除未领底座。

版本1；独立RandomNumberGenerator.seed = DungeonSeed XOR (reward_version*7919)。池先按ID排序，再Fisher-Yates洗牌；无放回序列8件唯一。相同Seed/池/版本/引擎产生相同序列；R清空Build与进度并复现序列；N重建新序列，通常不同。没有全局RNG调用，不影响地图。

Seed192034跨进程headless/windows文件完全一致：
ink_line,five_emperor_coins,black_powder,tomb_nail,spirit_kite,luoyang_shovel,copper_mirror,corpse_oil_lamp

## 8件正式遗物实际参数

| ID / 名称 | 稀有度 | 实际参数 |
| --- | --- | --- |
| five_emperor_coins 五帝钱 | COMMON | 每次双弹±5°；每发damage×0.8，默认16；一次冷却 |
| black_powder 黑火药 | UNCOMMON | 每成功hit半径72px，damage×0.5；原目标与周围敌人可受伤 |
| corpse_oil_lamp 尸油灯 | COMMON | 每次3HP、3tick、间隔0.35秒；再命中刷新计数/时间 |
| tomb_nail 镇尸钉 | COMMON | pierce_count+1；墙消耗，同敌人同弹不重伤 |
| copper_mirror 铜镜 | UNCOMMON | 每第3次攻击追加最终批次±20°两组；基础1→3，双弹2→6 |
| ink_line 墨斗 | UNCOMMON | origin到hit的24px宽线段，对其他敌人一次6伤害；反馈0.3秒 |
| luoyang_shovel 洛阳铲 | RARE | 每第5次追加1枚：damage×2.2，speed×1.3，lifetime0.22，scale×1.8；默认44伤害/845速度 |
| spirit_kite 引魂纸鸢 | UNCOMMON | 非致命有效伤害充能，下次攻击追加±15°两发并消耗；充能跨房 |

大部分数值在独立Definition.parameters；效果脚本有同值默认。每件是独立Effect，不在核心Player/Projectile/Controller/Spawner/Runtime用遗物ID特判。

黑火药/墨斗调用CombatGeometry瞬时伤害，CombatPulse只反馈，不发projectile_hit，所以爆炸不会递归。Burn仅轻量Node2D，目标/效果一实例，刷新不叠层；随Room/敌人释放，remove/shutdown取消。未引入复杂StatusEffect框架。

## 三组协同真实结果

- 五帝钱+铜镜：第三次攻击生成6枚实际Projectile；交换获得顺序后方向/伤害/穿透快照一致。额外priority测试故意反转ID，仍正确按priority执行。
- 镇尸钉+黑火药：同弹命中两个200HP靶，各20直击+10爆炸，最终各170；第三靶不伤；该弹产生2次爆炸，无递归或同敌人重复命中。
- 尸油灯+五帝钱：两条轨迹分别命中两个敌人，每个独立Burn；各16直击+9DOT，200→175。没有组合专用脚本。

全部8件同时安装仍正常真实发射。卸载断开连接/取消燃烧；死亡不再DOT、充能或发奖励；R/N释放旧World/Service/效果；跨房不重装。

## 完整一局实际流程

使用生产DungeonSession Seed192034、唯一默认100HP Player。WASD+真实Door过房，活跃AI不冻结；自动测试为固定射击条件将玩家调整到无遮挡100px射击点，用真实Weapon/Projectile逐个击杀，不修改敌人生命完成这条流程。

START → ROOM_001（首次COMBAT）→ 底座墨斗 → 真实E拾取 → ROOM_002 → ANTIQUE ROOM_003 → ROOM_004（第三次COMBAT）→ 底座五帝钱 → E拾取 → ROOM_005 → 返回已清场路径 → ROOM_006（第五次COMBAT）→ 底座黑火药 → E拾取 → 后续未访问COMBAT继续真实战斗。

已取得3件正式遗物，仍同一存活Player；跨房/重访保留，继续战斗后奖励不超过3。全部获取通过Pedestal，不用inventory.add模拟完整局；单体效果/生命周期测试才用add。

## 自动执行命令与结果

本机godot路径：C:/Users/atian/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10
godot --headless --path . --script res://tests/phase_1_smoke.gd
godot --headless --path . --script res://tests/phase_2_smoke.gd
godot --headless --path . --script res://tests/phase_3_smoke.gd
godot --headless --path . --script res://tests/phase_4_smoke.gd
godot --headless --path . --script res://tests/phase_5a_smoke.gd
godot --headless --path . --script res://tests/phase_5b_smoke.gd
godot --path . --script res://tests/phase_5b_smoke.gd -- --capture
```

| 检查 | 最终真实结果 |
| --- | --- |
| 导入解析 / 默认启动 | exit0，无解析错误，安全START |
| Phase1 | 27 checks / 0 failures / exit0 |
| Phase2 | 204 / 0 / exit0 |
| Phase3 | 86 / 0 / exit0 |
| Phase4 | 95 / 0 / exit0 |
| Phase5A | 61 / 0 / exit0 |
| Phase5B headless | 126 / 0 / exit0 |
| Phase5B图形 | 126 / 0 / exit0 |

最终logs/phase_5b_import/startup/smoke/graphical/regression_1～5a.log无ERROR/FAIL/WARNING；git diff --check通过，所有脚本<300行。日志/截图/.godot不提交。

58项要求覆盖：数据测试1～22（真实自动清场Context、池/RNG/奖励去重/阶段/copy）；完整局测试23～27（真实E一次领取、跨房、R/N）；命中/燃烧/阶段专项28～45（8单件、范围非递归、刷新、穿透、镜像/铲风次数、墨线、防无限充能）；协同46～50（3自然组合、逆序、多件实际射击）；卸载/死亡/跨房/R/N及未修改的旧回归51～58。帮助模块都有completed终点断言，避免脚本异常当通过。

早期静态Resource迭代触发Godot类型推断解析错误，已用明确Pool实例引用修复；开发UI改用Callable.bind。初次解析/部分输出不计通过。最终完整重跑全部通过。

## 图形与人工验收

图形模式完整运行126项，检查reward_1/2/3、mirror_six、explosion、dual_burn、ink_line、heavy_wind等截图。底座有名称/说明/E提示；六弹展开、爆炸圆环、独立燃烧火点、深色墨线、浅蓝大铲风可见。截图属于程序驱动图形证据，不等于自由试玩。

已打开实际游戏Seed192034供用户试玩，并说明F2正式调试面板。用户答复：“先交付，人工验收待完成”。本阶段没有取得正式手感反馈；底座可读性/E顺畅度、视觉混乱、爆炸强度与三件后趣味性人工验收均待完成。

## 已知限制 / Phase6准备

- 离房未领取底座奖励丢失，重访不补；死亡后不领取。调试提前持有同ID会使底座add失败，正常无放回流程不会遇到。
- 爆炸/墨线仅几何范围，不做额外墙体遮挡；未做最终数值平衡。
- 铜镜的明确规则是左右各复制一组；洛阳铲在其后追加单枚重弹，不是近战武器。
- 卸载停止活动DOT/反馈，已飞行弹丸保留发射快照；无保存/拾取回溯。
- 仍无击杀归因、复杂导航、正式美术/音效；人工验收待完成。

Phase6只准备独立古董Definition/背包容量/价值/携带生命周期，不能混入战斗RelicInventory；本任务不实现古董内容。

## 文件清单
-  M AGENTS.md
-  M ARCHITECTURE.md
-  M PROJECT_PLAN.md
-  M README.md
-  M project.godot
-  M scenes/ui/room_test_hud.tscn
-  M scripts/combat/attack_request.gd
-  M scripts/combat/projectile.gd
-  M scripts/combat/projectile_hit_context.gd
-  M scripts/dungeon/dungeon_session.gd
-  M scripts/relics/effects/double_shot_effect.gd
-  M scripts/relics/relic_effect.gd
-  M scripts/relics/relic_inventory.gd
-  M scripts/relics/relic_runtime.gd
-  M scripts/rooms/room_controller.gd
-  M scripts/ui/relic_debug_panel.gd
-  M tests/phase_5a_room_checks.gd
- ?? data/relics/black_powder.tres
- ?? data/relics/copper_mirror.tres
- ?? data/relics/corpse_oil_lamp.tres
- ?? data/relics/five_emperor_coins.tres
- ?? data/relics/formal_pool.tres
- ?? data/relics/ink_line.tres
- ?? data/relics/luoyang_shovel.tres
- ?? data/relics/spirit_kite.tres
- ?? data/relics/tomb_nail.tres
- ?? scripts/combat/burn.gd
- ?? scripts/combat/burn.gd.uid
- ?? scripts/combat/combat_geometry.gd
- ?? scripts/combat/combat_geometry.gd.uid
- ?? scripts/combat/combat_pulse.gd
- ?? scripts/combat/combat_pulse.gd.uid
- ?? scripts/relics/effects/black_powder_effect.gd
- ?? scripts/relics/effects/black_powder_effect.gd.uid
- ?? scripts/relics/effects/copper_mirror_effect.gd
- ?? scripts/relics/effects/copper_mirror_effect.gd.uid
- ?? scripts/relics/effects/corpse_oil_lamp_effect.gd
- ?? scripts/relics/effects/corpse_oil_lamp_effect.gd.uid
- ?? scripts/relics/effects/five_emperor_coins_effect.gd
- ?? scripts/relics/effects/five_emperor_coins_effect.gd.uid
- ?? scripts/relics/effects/ink_line_effect.gd
- ?? scripts/relics/effects/ink_line_effect.gd.uid
- ?? scripts/relics/effects/luoyang_shovel_effect.gd
- ?? scripts/relics/effects/luoyang_shovel_effect.gd.uid
- ?? scripts/relics/effects/spirit_kite_effect.gd
- ?? scripts/relics/effects/spirit_kite_effect.gd.uid
- ?? scripts/relics/effects/tomb_nail_effect.gd
- ?? scripts/relics/effects/tomb_nail_effect.gd.uid
- ?? scripts/relics/hit_relic_effect.gd
- ?? scripts/relics/hit_relic_effect.gd.uid
- ?? scripts/relics/relic_pedestal.gd
- ?? scripts/relics/relic_pedestal.gd.uid
- ?? scripts/relics/relic_pool.gd
- ?? scripts/relics/relic_pool.gd.uid
- ?? scripts/relics/relic_reward_service.gd
- ?? scripts/relics/relic_reward_service.gd.uid
- ?? scripts/rooms/room_clear_context.gd
- ?? scripts/rooms/room_clear_context.gd.uid
- ?? tests/phase_5b_burn_checks.gd
- ?? tests/phase_5b_burn_checks.gd.uid
- ?? tests/phase_5b_data_checks.gd
- ?? tests/phase_5b_data_checks.gd.uid
- ?? tests/phase_5b_hit_checks.gd
- ?? tests/phase_5b_hit_checks.gd.uid
- ?? tests/phase_5b_run_checks.gd
- ?? tests/phase_5b_run_checks.gd.uid
- ?? tests/phase_5b_smoke.gd
- ?? tests/phase_5b_smoke.gd.uid
- 新增本报告 docs/PHASE_5B_VERIFICATION.md；源码.uid一并跟踪。

## 2026-10-06 平衡修订：成长节奏与战斗压力

基准6b286e7ac154d5e60efba0c1b07dd086954d954d，仍在codex/phase-5b-relic-builds。用户反馈原版奖励过快、整体无挑战；底座靠近+E体验没有问题。E/底座规则不改，不增敌人种类/遗物/Boss/词缀/经济/Phase6。

### 当前奖励

THRESHOLDS=[2,4,7]。普通COMBAT首次ID统计不变，START/ANTIQUE/BOSS/重访/重复clear不统计。第1/3/5/6无奖励，第2/4/7各一件。5～6个COMBAT的短局只得2件，不动态补发。独立RNG/版本/池不变，无放回序列不变，R复现序列，N重建。

### 当前敌人和模板

尸蟞基础HP65、move_speed165、contact_damage12、attack_cooldown0.9、windup0.25；恢复0.28、距离42和咬击前距离/LOS重判保持。枪手HP90、move_speed105、projectile_damage14、projectile_speed340、cooldown1.35、windup0.4；原距离带/非追踪保持。

center=4尸蟞；north=6尸蟞；west=3枪手；east=4尸蟞+1枪手；south=3尸蟞+2枪手。各新增坐标：center(360,368)、north(360,368)、west(980,260)、east(900,400)、south(1000,240)。保留0.35s观察期。

所有点（含新增）自动检查：四入口距离≥180px、半径16障碍安全、房间边界内、其他敌人间距≥40px；五模板均通过。

### EncounterDifficulty

Controller从DungeonRoom.distance_from_start解析上下文，经Room/EnemySpawner传给Enemy.configure_spawn。Enemy._ready只初始化本实例Health，scaled_damage只计算本实例伤害；EnemyDefinition及RangedEnemyDefinition资源不变，AI不查询Layout，Spawner不做BFS。

| 深度 | Tier | HP | 伤害 |
| --- | --- | --- | --- |
| 1～2 | 1 | ×1.00 | ×1.00 |
| 3～4 | 2 | ×1.15 | ×1.10 |
| ≥5 | 3 | ×1.30 | ×1.20 |

尸蟞实例HP65/74.75/84.5，咬击12/13.2/14.4；枪手HP90/103.5/117，弹伤14/15.4/16.8。不缩放前摇/冷却/弹速/移速。BOSS普通组合仍可使用其地图深度，奖励依然不计数。HUD新增深度/Tier开发标签。R重新解析新上下文，重访CLEARED无敌人。

### 完整验证

使用原报告命令并新增encounter_balance_checks帮助模块（由phase_5b_smoke执行）。新版日志为logs/balance_import.log、balance_1～5b.log、balance_graphical.log。最终导入exit0无解析错误；git diff --check通过。

| 测试 | 最终结果 |
| --- | --- |
| Phase1 | 27 checks / 0 failures / exit0 |
| Phase2 | 204 / 0 / exit0 |
| Phase3 | 94 / 0 / exit0 |
| Phase4 | 105 / 0 / exit0 |
| Phase5A | 61 / 0 / exit0 |
| Phase5B无窗口 | 232 / 0 / exit0 |
| Phase5B图形 | 232 / 0 / exit0 |

旧测试保留验收语义：Phase4按新伤害/HP/组合调整期望；Phase5A伤害增幅测试由65HP的4发变3发，真实击杀需要补一轮双弹；Phase3按实际HP计算射击数所以断言数增加。没有删除断言让回归通过。早期枪手HP断言替换成88的笔误已改为90并完整复跑。

新增检查覆盖本次30项：奖励阈值与1～7每次发放、短局5/6仅2件、非COMBAT/去重/R规则；官方资源精确参数；五模板组成/新点几何；深度1/2/3/4/5/8映射；真实实例HP、定时咬击、真实枪手弹伤/速度；资源不变；实际Controller深度注入；R无倍率累计；CLEARED重访无强化敌人；三组协同全部保留并通过。

实际无F2正常自动局Seed192034：前两COMBAT用普通武器，第二次ROOM_002领取墨斗，第四次ROOM_005领取五帝钱，第七次ROOM_008领取黑火药，再继续第八个COMBAT。通过真实Weapon/Projectile、Door和E获得奖励，活跃AI没有冻结，也没有修改玩家HP用于这条正式流程。测试为固定射击条件会将玩家调整至无遮挡射击点，不能作为人类操作难度结论。

图形截图第七次领取时玩家24/100HP，HUD深度4/Tier2；深层Tier3行为由实际咬击/枪弹与房间流程断言验证。底座/E原人工反馈已确认无问题。

### 人工复验与限制

已打开新版Seed192034，提出“不用F2打一局”复验，关注前两房压力、中段成长、深层威胁。用户回复“先交付，人工平衡复验待完成”，因此标为待复验；自动流程不等同于挑战性平衡通过。

保留旧版限制：轻量避障可能在复杂障碍卡住；范围/墨线无墙体遮挡；未领取底座离房丢失；未做最终平衡曲线。短局仅2件是本次明确规则。Phase6仍未开始。

修改：两类敌人资源、五模板、Enemy/两AI、Spawner/Room/Controller、HUD、奖励阈值、旧测试期望及Phase5B帮助；新增encounter_difficulty.gd和encounter_balance_checks.gd及UID；同步四份项目文档。本任务提交并push当前分支，不合并main。
## 2026-10-06 致死性修订（基准0e71de3）

用户反馈“虽然会受伤，但是没有死亡风险”。本次只提高失误代价，不增加HP、数量、种类、遗物或难度选项。

玩家默认资源max_hp=80、hurt_invulnerability=0.25；其余移动/攻击资源值不动。0.25只在有效伤害后生效，拒绝同帧/短间隔伤害；红闪绘制保持，已查看受伤截图79/80HP与红色玩家。

尸蟞：HP65、速度175、伤害14、冷却0.8、前摇0.25；距离/LOS重判与非接触持续伤害不变。
枪手：HP90、速度105、弹伤16、弹速380、冷却1.20、前摇0.4；原距离带/非追踪保持。

HP倍率1.00/1.15/1.30不变，伤害倍率改1.00/1.15/1.35。Tier1/2/3实际咬击14/16.1/18.9；枪弹16/18.4/21.6。80HP分别6/5/5次咬击或5/5/4次枪弹可致死，不是一两下秒杀。没有额外缩放移速、弹速、前摇或冷却；共享定义未被实例倍率修改。

五模板数量与出生坐标完全不变，入口安全/0.35s观察期保持。正式奖励2/4/7及无放回、R/N规则不变。三组协同全通过。

### 验证结果

沿用本报告导入/Phase1～5B命令，日志为logs/lethality_import.log、lethality_1～5b.log、lethality_graphical.log；最终无ERROR/FAIL/WARNING，导入exit0，git diff --check通过。

| 测试 | 真实结果 |
| --- | --- |
| Phase1 | 27 / 0 failures / exit0 |
| Phase2 | 204 / 0 / exit0 |
| Phase3 | 94 / 0 / exit0 |
| Phase4 | 105 / 0 / exit0 |
| Phase5A | 61 / 0 / exit0 |
| Phase5B无窗口 | 236 / 0 / exit0 |
| Phase5B图形 | 236 / 0 / exit0 |

encounter_balance_checks检查玩家80/0.25及其他基础值保持；真实有效伤害与红闪、0.25内拒绝重复、期满允许再次伤害；全部新敌人参数、深度1/2/3/4/5/8实例HP/实际咬击/枪弹伤害与固定速度；定义保持、R不累计、清场重访不刷、奖励2/4/7、三组协同覆盖保留。旧HP期望按80调整，不删功能断言。

首轮原100px自动射击路线在ROOM_008死亡，导致后续领奖/过门检查连锁失败。这是新参数下实际伤害结算，不通过回调数值规避。测试驾驶改为从180px无遮挡候选中主动远离其他敌人及预测弹道；不加HP/回血、不停AI、不用F2，仍真实Weapon/Door/E走完整奖励局。保留活跃AI清场、生存、三次领取、过门/R/N等断言，完整重跑通过。自动驾驶会为固定条件调整位置，不等同于人类自由移动，也不能验证趣味性。

### 人工验收

实际打开新版Seed192034，并要求不使用F2复验早期容错、中段躲枪、深层死亡风险。用户答复：“稍微有点压力，但还可以，就这吧”。按此反馈接受当前数值，不继续加压；并未收集分Tier的统计死亡率，不声称最终平衡已完成。

本次修改默认玩家/两类敌人资源、EncounterDifficulty伤害倍率、测试期望/驾驶及无敌期检查；更新README/ARCHITECTURE/PROJECT_PLAN/AGENTS与本报告。无新游戏系统或内容。既有避障、范围无墙体遮挡、奖励离房丢失限制保持。若以后仍需挑战，应评估攻击模式而非堆HP；当前任务不实施，停止于Phase5B。
图形计时测试修正：PNG保存会造成物理时钟追帧，截图不放在0.25秒断言区间内；使用实际invulnerability_remaining和物理频率推导期满等待，再保存红闪截图。此前受截图耗时影响的失败不计通过，最终完整重跑结果见上表。
