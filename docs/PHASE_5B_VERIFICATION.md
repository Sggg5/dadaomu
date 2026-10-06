# Phase 5B 验证报告

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
