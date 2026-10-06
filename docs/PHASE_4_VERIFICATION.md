# Phase 4 验证报告

日期：2026-10-06。基准：94f0bb890e5d321de230066f80d61c93b1408dd2。
分支：codex/phase-4-enemies。Godot 4.6.2 标准版，Windows，Compatibility。

## 实际实现与边界

原创占位尸蟞和盗墓枪手，共享生命/目标/反馈、各自小型状态机；混合敌人统一生成，真实伤害、前摇、死亡缩小、敌方弹丸及清房接通随机地图。玩家、地图生成算法和门系统复用。ANTIQUE 自动清场；BOSS 是普通敌人组合占位。未实现遗物、背包、经济、Boss、复杂导航、击退或正式资产。

EnemyDefinition / RangedEnemyDefinition 为只读 Resource；Enemy 组合已有 Health，Spawner 显式注入唯一 Player 与本房弹丸容器。Enemy 不操作门、RoomState 或 DungeonLayout。RoomDefinition 从单场景 + 多坐标迁移为 Array[EnemySpawnDefinition]，每项有场景、定义、位置；没有双轨生成器。存活集合通过 Health.died 一次性通知，卸载不算死亡。

敌方弹丸继承既有 Projectile 运动/扫掠/消费流程，只覆盖受击对象与图形。开火快照方向、不会追踪，命中或墙体/到期销毁，玩家死亡和房间切换清理。

## 实际参数

| 参数 | 尸蟞 scarab | 盗墓枪手 bandit_shooter |
| --- | --- | --- |
| HP | 50 | 70 |
| 移速 | 150 | 95 |
| 近战伤害 | 10 | 0 |
| 冷却 | 1 秒 | 1.5 秒 |
| 前摇 | 0.22 秒 | 0.4 秒 |
| 恢复 | 0.28 秒 | 0.15 秒 |
| 攻击距离 | 42 | 上限 500 |
| 实际枪手射击距离带 | — | 200～280，目标 240 ±40 |
| 弹丸 | — | 速度 280，伤害 12，寿命 3 秒 |

冷却在攻击提交时启动，实际连续攻击间隔还包含下一次前摇；尸蟞约不低于 1.22 秒，枪手约不低于 1.9 秒。尸蟞前摇后重新判定距离/视线，可躲开；枪手过近撤退、过远靠近，在距离带与视线条件下瞄准。

命中闪白 0.12 秒，死亡白色缩小 0.16 秒后释放；前摇橙色和圆环，枪手还有方向线。敌方弹丸红色菱形、浅色描边。玩家原有 0.35 秒无敌期不变。

## 碰撞和所有权

World 层 1 / 位值 1；Player 层 2 / 2；Targets/Enemies 层 3 / 4；PlayerProjectiles 层 4 / 8；新增 EnemyProjectiles 层 5 / 16。Enemy mask=7；玩家弹丸 mask=5；敌方弹丸 mask=3。敌方弹丸不伤友军。Room 拥有敌人与弹丸；Controller 持有唯一 Player。死亡停止 AI，过房卸载旧 Room。

## 入口公平性修订

用户人工反馈：“有开门杀的嫌疑”。据此加入可配置 entry_grace_time=1.0 秒；生成后 AI 暂停移动/攻击，颜色变浅；之后仍完整执行前摇。五模板每个敌人距四个入口至少 180 像素，避免持键过门直接贴脸。不额外改变玩家无敌期。

组合：center=3 尸蟞，north=5 尸蟞，west=2 枪手，east=3 尸蟞+1 枪手，south=2 尸蟞+2 枪手。

## 自动验证

以下命令中的 godot 使用本机完整路径：
C:/Users/atian/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/phase_1_smoke.gd
godot --headless --path . --script res://tests/phase_2_smoke.gd
godot --headless --path . --script res://tests/phase_3_smoke.gd
godot --headless --path . --script res://tests/phase_4_smoke.gd
godot --path . --script res://tests/phase_4_smoke.gd -- --capture
```

最终完整运行结果：导入退出 0，无解析错误；Phase 1：27 checks / 0 failures；Phase 2：204 / 0；Phase 3：103 / 0；Phase 4 无窗口及图形各 80 / 0。所有完整测试退出码 0。日志在忽略的 logs/phase_4_final_0～4.log；无窗口 Phase 4 在 logs/phase_4_smoke.log。

Phase 2 保留原 204 项验收语义，通过固定夹具克隆模板视觉并注入旧 Dummy 数量/位置；仍使用生产 Controller/Spawner。Phase 3 清房测试冻结新 AI、按 HP 计算真实弹丸数量，保留地图、状态、过门和生命周期断言；活跃 AI 完整链由 Phase 4 覆盖。

Phase 4 覆盖请求的 26 项：两敌人生成/读取定义、追击与近战距离、咬击冷却/无敌、瞄准快照/不追踪、子弹一次伤害/撞墙/友军安全、两类被玩家子弹击伤、死亡一次、计数/清房一次、混合房、重访、旧敌人/弹丸释放、唯一玩家、玩家死亡幂等、R/N恢复。额外检查距离行为、前摇/闪白/死亡反馈、弹丸寿命、五模板组合和入口安全。

实际场景执行：Seed 192034 → START 混合房 → 尸蟞真实伤害 → Player 武器击杀 → 活跃枪手射击 → 玩家弹丸击杀 → 清房开门 → WASD + Door 物理过门 → 重访 → R/N。AI 没有在这条主链中冻结；部分单体位置用于固定测试条件，并不等同于人工自由游玩。

新增入口验证：五模板距所有入口 >=180；初次入房半秒内敌人位置不变/速度为零/HP不变；持键穿门后目标房仍有观察期。图形模式截图已查看，玩家可见、前摇橙色圆环可见；截图是程序驱动场景证据。

开发中出现的早期资源替换解析错误已修复，最终运行无该错误。早期带 quit-after 的 Phase 2 运行提前中止，不计为通过；以上结果均等待完整测试摘要。

## 人工试玩状态

启动实际图形窗口并通过原生窗口输入 R 重开。窗口捕获先 FrameArrived 超时，恢复后再次 capture 超时，因此不能声称完成代理人工战斗试玩。

用户给出入口先手风险反馈，已完成上述修订并自动验证。用户明确要求“先交付，人工复验待完成”。修订版人工复验待完成；尸蟞前摇主观清晰度、枪手距离手感、红弹辨识和混合房可躲避性不能以自动断言代替验收。

## 已知限制与下一阶段

轻量墙体切向绕行不等于路径规划，复杂凹形障碍可能卡住；尚无击退、音效或难度曲线。观察期与入口间距是当前公平性保护，长时间试玩和不同入口仍需人工评估。相同 Seed 复现地图拓扑，实时战斗不承诺确定性回放。Phase 5 待单独授权后规划遗物数据、获得与可卸载效果；本任务不进入。

## 文件清单
-  M AGENTS.md
-  M ARCHITECTURE.md
-  M PROJECT_PLAN.md
-  M README.md
-  M data/rooms/test_center.tres
-  M data/rooms/test_east.tres
-  M data/rooms/test_north.tres
-  M data/rooms/test_south.tres
-  M data/rooms/test_west.tres
-  M project.godot
-  M scenes/ui/room_test_hud.tscn
-  M scripts/combat/projectile.gd
-  M scripts/dungeon/dungeon_config.gd
-  M scripts/rooms/enemy_spawner.gd
-  M scripts/rooms/room.gd
-  M scripts/rooms/room_controller.gd
-  M scripts/rooms/room_definition.gd
-  M tests/fixtures/fixed_room_test.gd
-  M tests/phase_2_smoke.gd
-  M tests/phase_3_smoke.gd
- ?? data/enemies/bandit_shooter.tres
- ?? data/enemies/scarab.tres
- ?? scenes/enemies/bandit_shooter.tscn
- ?? scenes/enemies/enemy_projectile.tscn
- ?? scenes/enemies/scarab_enemy.tscn
- ?? scripts/combat/enemy_projectile.gd
- ?? scripts/combat/enemy_projectile.gd.uid
- ?? scripts/enemies/bandit_shooter.gd
- ?? scripts/enemies/bandit_shooter.gd.uid
- ?? scripts/enemies/enemy.gd
- ?? scripts/enemies/enemy.gd.uid
- ?? scripts/enemies/enemy_definition.gd
- ?? scripts/enemies/enemy_definition.gd.uid
- ?? scripts/enemies/ranged_enemy_definition.gd
- ?? scripts/enemies/ranged_enemy_definition.gd.uid
- ?? scripts/enemies/scarab_enemy.gd
- ?? scripts/enemies/scarab_enemy.gd.uid
- ?? scripts/rooms/enemy_spawn_definition.gd
- ?? scripts/rooms/enemy_spawn_definition.gd.uid
- ?? tests/phase_4_enemy_checks.gd
- ?? tests/phase_4_enemy_checks.gd.uid
- ?? tests/phase_4_projectile_checks.gd
- ?? tests/phase_4_projectile_checks.gd.uid
- ?? tests/phase_4_room_checks.gd
- ?? tests/phase_4_room_checks.gd.uid
- ?? tests/phase_4_smoke.gd
- ?? tests/phase_4_smoke.gd.uid
- 新增本报告 docs/PHASE_4_VERIFICATION.md。Godot 生成的源码 .uid 一并跟踪；logs/ 不提交。

新增测试源码 UID：tests/phase_4_enemy_checks.gd.uid、phase_4_projectile_checks.gd.uid、phase_4_room_checks.gd.uid、phase_4_smoke.gd.uid。
