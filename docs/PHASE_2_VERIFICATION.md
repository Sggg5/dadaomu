# Phase 2 验证记录

日期：2026-10-06（Asia/Shanghai）。Godot 4.6.2.stable.official.71f334935 标准版；Windows，Compatibility / OpenGL 3.3，NVIDIA RTX 2070 SUPER。

## 实现范围

共享 Room、Door、EnemySpawner、RoomController、RoomState；固定十字形五房：中心前室、北侧石柱厅、西侧横廊、东侧侧殿、南侧沉沙室。五份 Resource 配置分别使用 3/4/2/4/5 个 Dummy 和不同障碍/地面布局，没有复制战斗脚本。

首次进入 UNVISITED → ACTIVE，先关门再生成；全部敌人死亡后 ACTIVE → CLEARED 并开门。走过门槛进入相邻房间。重访 CLEARED 保持开门，不重新生成。玩家与生命跨房间保留；旧 Room 的敌人/弹丸/门/墙释放；R 重开整张地图。

古董、商人、机关、秘密、Boss 房仅预留类型标识。没有随机地图、真实敌人 AI 或其他下一阶段内容。

## 验证结果

本机引擎：`C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`。

| 检查 | 参数 | 结果 |
| --- | --- | --- |
| 导入解析 | `--headless --path . --editor --quit` | 退出码 0，最终无解析错误 |
| 默认入口，无窗口 | `--headless --path . --quit-after 120` | 退出码 0，Phase 2 就绪，无运行错误 |
| 五房行为 | `--headless --path . --script res://tests/phase_2_smoke.gd` | 204 次断言，0 失败，退出码 0 |
| 五房图形与截图 | `--path . --script res://tests/phase_2_smoke.gd -- --capture` | 204 次断言，0 失败，退出码 0 |
| Phase 1 玩家回归 | `--headless --path . --script res://tests/phase_1_smoke.gd` | 27 次断言，0 失败，退出码 0 |
| 默认入口，图形 | `--path . --quit-after 120` | 退出码 0，主场景和 Compatibility 初始化成功 |

行为验证使用实际弹丸、物理帧和 WASD 输入穿过门区，没有直接把房间设为 CLEARED。弹丸击杀部分由测试指定发射起点与方向；人工瞄准手感仍需试玩。覆盖：

- 三态顺序及重复激活/清场保护；五房生成点不与墙/障碍重叠。
- 首次进入各房间全部锁门，剩余敌人未归零前不提前开门，最后死亡仅清场一次。
- 重复 enter 不重复生成；物理锁门阻挡；已站在门区域时开门后可继续走出。
- 固定十字邻接、非相邻方向拒绝、四个方向的实际过门及正确返回。
- 唯一玩家和 75 HP 保留，旧房间和长寿弹丸释放，不出现入口反弹或连续切换。
- 重访中心与叶房均不重新刷怪；五房各自状态持久到重开。
- 同帧重复切换请求仅接受第一个；空战斗房能完成；运行时配置副本不改共享资源。
- 死亡禁止切房，R 重建全图、恢复生命、重置状态与敌人数。

早期导入发现 Door.Side 与 Godot 全局 Side 名称冲突，以及几何计算的一处类型推断错误；已改为 Door.Direction 并明确 Vector2 类型。最终导入与运行检查没有这些错误。布局检查发现横廊一个生成点距障碍过近，已调整并通过五房边界断言。

图形模式保存并检查了各房间 ACTIVE/CLEARED、全图清场和死亡截图，路径为忽略的 `logs/phase_2_*.png`。确认布局差异、门状态、中文 HUD、小地图和死亡提示正常。不是人工长时间试玩或跨显卡验收。

## 文件清单

新增：

- `scripts/rooms/room_state.gd`、`room_definition.gd`、`enemy_spawner.gd`、`door.gd`、`room.gd`、`room_controller.gd`。
- `scripts/ui/room_minimap.gd`、`room_test_hud.gd`。
- `scenes/rooms/door.tscn`、`room.tscn`、`scenes/ui/room_test_hud.tscn`、`scenes/main/room_test.tscn`。
- `data/rooms/test_center.tres`、`test_north.tres`、`test_west.tres`、`test_east.tres`、`test_south.tres`。
- `tests/phase_2_smoke.gd`、本记录，以及 Godot 生成的脚本 `.uid`。

修改：`scripts/player/player.gd`（输入冻结接口）、`project.godot`（默认入口与阶段描述）、`README.md`、`ARCHITECTURE.md`、`PROJECT_PLAN.md`、`AGENTS.md`。

## 已知限制

- 敌人仍是无攻击 Dummy；全部房间为普通战斗房。
- 房间尺寸、门宽、入口偏移为本阶段固定值；内容布局数据化。连接图固定，尚未接入随机生成。
- 房间状态仅在本次运行中保留，没有存档；R 会全部重置。
- 无正式美术/音效/切房动画；切换为即时替换。
- 未发现未解决的解析或运行错误。手感、长时间游玩和多设备兼容性仍需后续测试。

Phase 2 完成后停止。Phase 3 与 Phase 4 未开始，Git 未提交或推送。
