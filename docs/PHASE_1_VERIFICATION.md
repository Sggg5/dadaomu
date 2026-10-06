# Phase 1 验证记录

日期：2026-10-06（Asia/Shanghai）。Godot 4.6.2.stable.official.71f334935 标准版；Windows，Compatibility / OpenGL 3.3，NVIDIA RTX 2070 SUPER。

## 范围

最小玩家战斗原型：WASD 加减速移动、鼠标方向、按住左键基础远程弹丸、生命、受伤无敌期、死亡、重开；固定矩形测试空间与三个无攻击 Dummy。没有 Phase 2 的门、清场开门、房间切换或其他后续系统。

## 验证方法与结果

使用本机引擎：`C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`。

| 检查 | 参数 | 结果 |
| --- | --- | --- |
| 导入 / 解析 | `--headless --path . --editor --quit` | 退出码 0，无解析错误 |
| 默认入口启动 | `--headless --path . --quit-after 120` | 退出码 0，Phase 1 就绪，无运行错误 |
| 核心行为 | `--headless --path . --script res://tests/phase_1_smoke.gd` | 27 项通过，0 失败 |
| 图形模式 / 鼠标 / 按钮 | `--path . --script res://tests/phase_1_smoke.gd -- --capture` | 30 项通过，0 失败，无 Godot 运行错误 |
| 图形入口启动 | `--path . --quit-after 60` | 退出码 0，Compatibility 初始化和主场景启动成功 |

行为检查覆盖：加速、达到配置速度、减速停止、斜向速度、墙体阻挡、首次射击、冷却、单次伤害、命中回收、击杀三靶、高速扫掠撞墙、寿命回收、负伤害拒绝、F1 输入、无敌期、死亡只触发一次、死亡后停用移动/攻击、按钮禁用、重复重开清理、R 输入。图形模式额外通过视口事件验证鼠标瞄准、左键发射命中、点击伤害按钮不射击。

鼠标验证初版依赖系统光标 warp，受 Windows 焦点/光标状态影响出现失败。最终实现把鼠标事件采样与物理步分离，每帧将视口坐标转为世界坐标；验证经 Godot 视口分发运动事件和鼠标按钮事件，避免依赖系统光标 warp。最终结果如上。

截图保存在忽略的 `logs/phase_1_initial.png`、`logs/phase_1_death.png`；检查初始 HUD、中文、边界、三靶与死亡提示布局。此为实际引擎渲染和自动化输入检查，没有人工长时间手感试玩；加减速参数仍需用户试玩调整。

## 文件清单

新增：

- `scripts/player/player_stats.gd`、`player.gd`。
- `scripts/combat/health.gd`、`attack_request.gd`、`ranged_weapon.gd`、`projectile.gd`。
- `scripts/enemies/dummy.gd`、`scripts/main/combat_test.gd`。
- `data/definitions/default_player_stats.tres`。
- `scenes/player/player.tscn`、`projectile.tscn`、`scenes/enemies/dummy.tscn`、`scenes/main/combat_test.tscn`。
- `tests/phase_1_smoke.gd`、本记录，以及引擎生成的脚本 `.uid`。

修改：`project.godot`（默认场景、输入、碰撞层、描述）、`README.md`、`ARCHITECTURE.md`、`PROJECT_PLAN.md`、`AGENTS.md`。

## 已知限制

- 占位几何、固定地图和无 AI 靶子；没有音效、正式美术或复杂攻击效果。
- 默认受伤后 0.35 秒无敌，过快连续按 F1 的伤害会被拒绝，这是预期行为。
- CurrentHP 保存在 Health 实例中；Stats 为共享只读初始配置。改变资源后重开/重新运行查看效果。
- 后续武器可沿攻击请求/执行对象/伤害接口扩展；共同武器接口将在需要第二种武器时抽取，当前未创建未使用框架。
- 当前没有已发现且未解决的解析或运行错误。不同设备、窗口缩放和长期操作手感未作完整兼容性验收。

Phase 1 完成后停止；Phase 2 未开始。未提交或推送 Git。
