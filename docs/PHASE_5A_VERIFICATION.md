# Phase 5A 验证报告

日期：2026-10-06。仓库 Sggg5/dadaomu。
从最新 origin/main 的 2fd4e932f67720c0b8c11ee385ff7a2786649d41（Merge Phase 4 enemy combat）创建 codex/phase-5a-relic-framework。
Godot 4.6.2 标准版 / Windows / Compatibility，图形验证设备 RTX 2070 SUPER。

## 实现范围与架构

仅底层框架和三个工程测试遗物，非正式内容量。未做 Phase 5B、正式拾取/奖励/选择、掉落、爆炸/燃烧/穿透/反弹、古董、商店、Boss、存档或永久解锁。

RelicDefinition 为只读 Resource，ID/中文名/description/rarity/effect_script/parameters 分离。RelicInventory 由唯一 Player 的 RelicRuntime 持有，只负责唯一遗物持有、查询、添加/移除/clear、创建与卸载效果。具体 RelicEffect 是独立 RefCounted 实例，不使用 Player/Projectile/Controller 遗物 ID 分支或全局 EventBus。

AttackContext 持有请求副本数组；AttackRequest.copy 明确复制位置、方向、伤害、速度和寿命。定义/PlayerStats 均不修改。运行计数和已安装标记属于效果实例，每次安装新建。

## 攻击管线和 Hook

Player → RangedWeapon（一次输入/一次冷却）→ 基础 AttackRequest → 可选 attack_modifier → Runtime.prepare_attack → AttackContext 快照 → Inventory 按 ID 字符串排序应用效果 → attack_prepared → 0..N attack_requested → Controller / CombatTest 创建弹丸 → bind_projectile / projectile_spawned。

没有遗物时数值/方向/速度/冷却与 Phase 4 一致。玩家弹丸成功 take_damage 后发 hit(ProjectileHitContext)，Runtime 转为局部 projectile_hit。敌方弹丸继续独立掩码和 Player 伤害路径，不连接遗物 Runtime，敌人 AI 不修改。

| Hook | 真实来源及规则 |
| --- | --- |
| attack_prepared | 攻击快照修改后，实体生成之前；允许批次扩展 |
| projectile_spawned | 玩家弹丸 setup 后，装配层通知 |
| projectile_hit | 成功伤害后 target/position/快照 damage；墙体与无效伤害不触发 |
| enemy_killed | Spawner 从存活集合删除后一次通知；重复回调、卸载不触发 |
| player_damaged | 非致命已接受伤害；Health 已标记死亡时不触发效果 |
| room_cleared | Room 首次 clear；重访不会重复，包括 START 自动清场 |

节点上下文只供同步处理，不长期保留死亡敌人。没有额外二十种空 Hook 或脚本注册中心。

## 三个工程遗物

| ID / 中文名 | 参数与效果 | 卸载 |
| --- | --- | --- |
| test_damage_relic / 强力火药 | multiplier=1.5；默认伤害20→30；50HP尸蟞3发→2发 | 后续请求恢复20，未修改共享 Stats |
| test_double_shot / 双生铜钱 | spread_degrees=6；请求展开为±6°双弹；一次冷却 | 后续攻击恢复单弹 |
| test_kill_heal / 血契 | heal_amount=5；每敌人首次死亡回复5HP，上限MaxHP | 断开 enemy_killed 连接，停止回血 |

各效果文件独立，无以 ID 选择行为的大管理器。添加顺序不影响本阶段两种攻击修改器组合：按稳定 ID 排序应用；未来非交换效果须另定义顺序，不声称通用协同系统已实现。

## 生命周期

普通遗物唯一，不允许重复 ID；重复 add/install 返回 false。install/uninstall 幂等，保留测试计数检查仅执行一次。卸载不做乘除反向恢复，因为只修改本次攻击副本。旧弹丸保留发射时快照，移除不会追溯改动在飞弹丸。

跨房：Player 持有 Runtime/Inventory，Room 卸载不触及库存；新 Room 在 enter 前接通击杀/清场来源。
死亡：Health.is_dead 立即使 is_active=false，阻止晚到受伤/击杀/命中；shutdown 卸载全部效果并清空库存。
R/N/场景离树：_exit_tree 调用 shutdown，卸载效果、断开 Health 连接/武器修改器与库存回指；新 Player 创建空库存。定义资源可共用，效果实例/计数不共用。

开发 UI：1/2/3 添加三个测试遗物，Backspace 全部卸载；底部工程遗物列表仅展示本局库存，不是正式拾取界面。R/N 重置，死亡后拒绝添加。

## 自动命令和结果

本机 godot 完整路径：
C:/Users/atian/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10
godot --headless --path . --script res://tests/phase_1_smoke.gd
godot --headless --path . --script res://tests/phase_2_smoke.gd
godot --headless --path . --script res://tests/phase_3_smoke.gd
godot --headless --path . --script res://tests/phase_4_smoke.gd
godot --headless --path . --script res://tests/phase_5a_smoke.gd
godot --path . --script res://tests/phase_5a_smoke.gd -- --capture
```

| 验证 | 最终真实结果 |
| --- | --- |
| 导入/解析 | exit 0，无解析错误 |
| 默认Seed192034启动 | exit 0，安全START、11房 |
| Phase 1 | 27 checks / 0 failures / exit 0 |
| Phase 2 | 204 / 0 / exit 0 |
| Phase 3 | 86 / 0 / exit 0 |
| Phase 4 | 95 / 0 / exit 0 |
| Phase 5A headless | 61 / 0 / exit 0 |
| Phase 5A 图形模式 | 61 / 0 / exit 0 |

旧 Phase 1～4 测试未修改，敌方弹丸/活跃 AI/入口保护/安全 START 的验收保持。最终日志位于忽略的 logs/phase_5a_import.log、phase_5a_startup.log、phase_5a_regression_1～4.log、phase_5a_smoke.log、phase_5a_graphical.log，无 ERROR/FAIL/WARNING。git diff --check 通过。所有脚本仍低于300行。

Phase 5A 场景驱动检查对应请求的30项：

- 1～10：基础请求、三定义、库存添加/去重/移除、生命周期计数、伤害1.5倍、卸载恢复、Stats/参数不变。
- 11～16：真实武器双弹、方向差、两个独立目标扫掠命中/消费、恢复单弹、组合与逆序安装一致。
- 17～19：真实混合房玩家双弹击杀一次；重复死亡回调不重复回血；满血限制。
- 20～22：WASD+真实Door跨房库存保留，清场/重访仍输出双弹30伤害，install_count不变。
- 23～25：R同Seed、N新Seed清库存/卸载旧效果；死亡清空且晚到击杀无法回血/复活/重复命中。
- 26～27：5次安装/移除，连接精确加1/减1；每次局部Hook只回血5，移除后通知不再响应。
- 28～30：地宫中Player唯一；独立额外Player单体测试不共享Build；旧Phase1～4原断言全通过。

额外验证50HP尸蟞实际由3发变2发；测试帮助模块都有completed最终标记，避免协程脚本异常被误计为通过。单体攻击场景临时冻结AI、分开双弹靶点；房间流程部分使用Health加速清场，真实第一击杀通过Player武器。活跃AI/红弹完整链由未修改的Phase4回归覆盖。

开发中首轮帮助测试读取已释放的尸蟞导致协程异常，已改为检查有效性并测试Spawner死亡去重；不把首轮部分摘要当通过。一次图形运行受到桌面额外射击输入干扰，之后测试入口逐物理帧释放attack，只从真实Weapon发射，完整重跑通过；生产输入逻辑未修改。

## 图形与人工验证

程序驱动图形模式执行基础单弹→强力火药更快击杀→双弹→组合→清房跨房→保留→移除→普通单弹，并保存/检查截图。截图：phase_5a_baseline_single、damage_only、double_shot、combined_hit、build_after_traversal、removed_single、death_empty.png（logs/不提交）。双弹几何可见，列表/按键提示不遮战斗区，移除后显示无并恢复单弹。

实际游戏窗口已启动Seed1供用户测试。computer-use 原生捕获出现 FrameArrived timed out；重新选择窗口恢复时报告 user input was detected in this window，因此停止自动窗口操作，未宣称代理完成自由试玩。

用户实际反馈：“双弹清晰，跨房保留”。这两项人工确认。移除恢复、火药击杀速度、血契体验未收到人工确认；相应行为已自动验证，但主观验收仍待反馈，不以测试通过替代手感结论。

## 已知限制与 Phase 5B 准备

- 工程遗物仅三个；没有正式获得方式或正式内容量。
- enemy_killed当前是房间首次死亡事件，未实现伤害来源/击杀归因；测试伤害同样算死亡事件。
- 请求排序按ID，后续非交换效果需明确顺序；扩展请求字段须维护copy。
- 修改只影响之后攻击，在飞弹丸保留原快照；不实现效果热重写弹丸。
- HitContext节点仅同步有效；未来延迟反应需使用可验证的弱引用/数值快照。
- 仍无复杂寻路、正式音效/资产；人工验收部分完成。

Phase5B仅准备：选择少量原创规则变化遗物、获得方式与可卸载协同测试；必须单独授权后再实施。不合并main，本任务提交并push当前Phase5A分支后停止。

## 文件清单
-  M AGENTS.md
-  M ARCHITECTURE.md
-  M PROJECT_PLAN.md
-  M README.md
-  M project.godot
-  M scenes/player/player.tscn
-  M scenes/ui/room_test_hud.tscn
-  M scripts/combat/attack_request.gd
-  M scripts/combat/health.gd
-  M scripts/combat/projectile.gd
-  M scripts/combat/ranged_weapon.gd
-  M scripts/main/combat_test.gd
-  M scripts/player/player.gd
-  M scripts/rooms/enemy_spawner.gd
-  M scripts/rooms/room_controller.gd
- ?? data/relics/test_damage_relic.tres
- ?? data/relics/test_double_shot.tres
- ?? data/relics/test_kill_heal.tres
- ?? scripts/combat/attack_context.gd
- ?? scripts/combat/attack_context.gd.uid
- ?? scripts/combat/projectile_hit_context.gd
- ?? scripts/combat/projectile_hit_context.gd.uid
- 新增 scripts/relics/effects/damage_relic_effect.gd
- 新增 scripts/relics/effects/damage_relic_effect.gd.uid
- 新增 scripts/relics/effects/double_shot_effect.gd
- 新增 scripts/relics/effects/double_shot_effect.gd.uid
- 新增 scripts/relics/effects/kill_heal_effect.gd
- 新增 scripts/relics/effects/kill_heal_effect.gd.uid
- ?? scripts/relics/relic_definition.gd
- ?? scripts/relics/relic_definition.gd.uid
- ?? scripts/relics/relic_effect.gd
- ?? scripts/relics/relic_effect.gd.uid
- ?? scripts/relics/relic_inventory.gd
- ?? scripts/relics/relic_inventory.gd.uid
- ?? scripts/relics/relic_runtime.gd
- ?? scripts/relics/relic_runtime.gd.uid
- ?? scripts/ui/relic_debug_panel.gd
- ?? scripts/ui/relic_debug_panel.gd.uid
- ?? tests/phase_5a_attack_checks.gd
- ?? tests/phase_5a_attack_checks.gd.uid
- ?? tests/phase_5a_room_checks.gd
- ?? tests/phase_5a_room_checks.gd.uid
- ?? tests/phase_5a_smoke.gd
- ?? tests/phase_5a_smoke.gd.uid
- 新增 docs/PHASE_5A_VERIFICATION.md；Godot生成的源码UID一起提交，logs/与.godot/不提交。
