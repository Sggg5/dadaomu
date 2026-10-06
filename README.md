# 大盗墓时代

原创独立 2D 俯视角房间式 Roguelite。背景为 1920～1940 年代架空中国：盗墓者探索古墓，收集古董与遗物，选择继续深入或带着收益撤离。

## 当前状态

已完成 **Phase 2 房间系统**。默认启动固定十字形五房地图：首次进入锁门并生成敌人，击杀全部敌人后开门，走入门口切换相邻房间；已清场房间重访不刷怪。玩家生命跨房间保留，R 重开整张测试地图。Phase 3 尚未开始。

```text
          石柱厅
             |
横廊 —— 前室 —— 侧殿
             |
          沉沙室
```

五房分别配置不同敌人生成点、数量（3/4/2/4/5）、石柱/障碍布局与地面颜色，均复用同一 Room 场景和控制逻辑。敌人仍为 Phase 1 的无攻击 Dummy，真正敌人 AI 留在 Phase 4。

## 开发环境与运行

- Godot 4.6.2 标准版（GDScript），Windows 为主要开发平台。
- 渲染器：Compatibility；逻辑画布：1280 × 720，canvas_items 缩放。
- 使用 Godot 项目管理器导入根目录 `project.godot`，打开后按 F6 运行当前场景，或 F5 运行项目。
- WASD 移动，鼠标瞄准，按住鼠标左键连续射击。
- F1 或“测试伤害”按钮造成 25 点伤害；受伤后有 0.35 秒无敌期。默认 100 HP，间隔受伤四次死亡。
- 清场后走入绿色门过房；橙色门锁定。小地图显示未探索、战斗中、已清场和当前位置。
- R 或“重新开始”按钮重置玩家、所有房间状态、敌人和弹丸；Esc 或“退出”按钮关闭窗口。
- 命令行：`godot --path . --editor`；Godot 不在 PATH 时使用安装位置的完整路径。
- 导入/解析检查：`godot --headless --path . --editor --quit`。
- 启动冒烟检查：`godot --headless --path . --quit-after 10`。
- Phase 1 行为检查：`godot --headless --path . --script res://tests/phase_1_smoke.gd`。
- 图形/鼠标检查：`godot --path . --script res://tests/phase_1_smoke.gd -- --capture`，截图保存在忽略的 `logs/`。
- Phase 2 五房完整检查：`godot --headless --path . --script res://tests/phase_2_smoke.gd`。
- Phase 2 图形检查：`godot --path . --script res://tests/phase_2_smoke.gd -- --capture`，保存各房间、清场和死亡截图。

调参：编辑 `data/definitions/default_player_stats.tres`，修改 MaxHP、MoveSpeed、AttackDamage、AttackSpeed（每秒次数）、ProjectileSpeed、加减速、弹丸寿命和无敌期。CurrentHP 属于每个玩家的 Health 实例，不能写回共享初始资源。Dummy 的初始 HP 可在 `dummy.tscn` Inspector 调整，测试伤害可在测试场景 Inspector 调整。

房间内容：编辑 `data/rooms/test_*.tres` 的敌人场景、生成点、障碍矩形、名称和颜色；固定地图邻接表位于 `scripts/rooms/room_controller.gd`，本阶段没有随机生成。房间状态属于本次测试，不能写回配置资源。非战斗房类型仅预留标识，尚不可使用。

尚未配置发行导出预设；需要发布时再安装对应版本导出模板。不同 Godot 4.x 版本升级前应重新执行导入和启动检查。

## 目录

| 路径 | 用途 |
| --- | --- |
| scenes/ | 主入口及后续玩家、房间、敌人、UI 场景 |
| scripts/ | 按职责划分的 GDScript |
| data/ | 后续 Resource 数据定义及实例 |
| assets/ | 原创美术、音频、字体 |
| tests/ | 后续核心行为验证场景与脚本 |
| docs/ | 后续设计记录和验证报告 |

尚未实现的目录由 `.gitkeep` 保留。Phase 0 占位主场景保留在 `scenes/main/main.tscn`，Phase 1 独立测试场景保留在 `scenes/main/combat_test.tscn`；当前入口为 `scenes/main/room_test.tscn`。复用的 `scenes/rooms/room.tscn` 需由控制器注入配置，不作为独立入口运行。

## 文档与 Git

- `PROJECT_PLAN.md`：逐阶段范围和验收。
- `ARCHITECTURE.md`：系统边界、数据与依赖约定。
- `GAME_DESIGN.md`：核心玩法与首个 Demo 范围。
- `AGENTS.md`：所有后续开发任务必须遵守的项目规则。
- 跟踪源码、场景、Resource、源资产和 Godot `.uid`；不提交 `.godot/`、构建输出和本地日志。
- 开始任务前检查 `git status`；功能分支默认使用 `codex/` 前缀。提交需有明确阶段与范围，不自动推送。
