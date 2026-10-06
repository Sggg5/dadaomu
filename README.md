# 大盗墓时代

原创独立 2D 俯视角房间式 Roguelite。背景为 1920～1940 年代架空中国：盗墓者探索古墓，收集古董与遗物，选择继续深入或带着收益撤离。

## 当前状态

当前 **Phase 4 敌人战斗原型**。默认 Seed 为 `192034`，每图 8～12 个房间，独立 RNG 可重现正交树状布局。START 固定在 (0,0)，Boss 是距离至少 5 的最远叶子，ANTIQUE 距离至少 2。

随机节点决定位置/连接/类型，五份原有普通房配置作为共享模板池。玩家、战斗、门和房间生命周期继续复用：首次进入锁门，击杀后开门，过门保留生命，重访已清场房不刷怪。

START 和 BOSS 使用普通敌人战斗占位；ANTIQUE 自动清场，没有古董内容（Phase 6）或 Boss 战斗（Phase 7）。已实现尸蟞追击咬击、盗墓枪手保持距离与射击。入房有 0.35 秒观察期，敌人暂停行动；橙色表示攻击前摇，红色菱形是敌方弹丸。修订版人工手感复验仍待反馈。

## 开发环境与运行

- Godot 4.6.2 标准版（GDScript），Windows 为主要开发平台。
- 渲染器：Compatibility；逻辑画布：1280 × 720，canvas_items 缩放。
- 使用 Godot 项目管理器导入根目录 `project.godot`，打开后按 F6 运行当前场景，或 F5 运行项目。
- WASD 移动，鼠标瞄准，按住鼠标左键连续射击。
- F1 或“测试伤害”按钮造成 25 点伤害；受伤后有 0.35 秒无敌期。默认 100 HP，间隔受伤四次死亡。
- 清场后走入绿色门过房；橙色门锁定。小地图显示未探索、战斗中、已清场和当前位置。
- R 或“同图重开”使用当前 Seed 重建完整地图、恢复 HP 并重置状态。N 或“新图”选择新 Seed，生成不同拓扑。
- HUD 显示当前 Seed；动态小地图以 S/B/A 标记出生/Boss/古董占位房。Esc 或“退出”关闭窗口。
- 命令行：`godot --path . --editor`；Godot 不在 PATH 时使用安装位置的完整路径。
- 导入/解析检查：`godot --headless --path . --editor --quit`。
- 启动冒烟检查：`godot --headless --path . --quit-after 10`。
- Phase 1 行为检查：`godot --headless --path . --script res://tests/phase_1_smoke.gd`。
- 图形/鼠标检查：`godot --path . --script res://tests/phase_1_smoke.gd -- --capture`，截图保存在忽略的 `logs/`。
- Phase 2 五房完整检查：`godot --headless --path . --script res://tests/phase_2_smoke.gd`。
- Phase 2 图形检查：`godot --path . --script res://tests/phase_2_smoke.gd -- --capture`，保存各房间、清场和死亡截图。
- Phase 3 完整检查：`godot --headless --path . --script res://tests/phase_3_smoke.gd`。
- Phase 3 图形检查：`godot --path . --script res://tests/phase_3_smoke.gd -- --capture`。

复现指定 Seed：

```powershell
godot --path . -- --seed=192034
```

也可修改 `dungeon_test.tscn` 根节点 Inspector 的 `seed_value`。不传参数时从默认 Seed 开始；选到新 Seed 后 R 重复该 Seed。关闭程序不会保存所选 Seed，请记录 HUD 值或用命令行再次指定。

相同引擎（当前验证为 Godot 4.6.2）、生成版本、配置与模板池顺序下，相同 Seed 重现完整拓扑与模板选择。不同 Seed 不保证每次都得到不同图，所以 N 最多尝试 16 个候选，失败保留当前图并提示警告。无窗口与图形测试还会在 `logs/phase_3_digest_*.txt` 保存 100 Seed 的结果摘要供跨进程比较。

调参：编辑 `data/definitions/default_player_stats.tres`，修改 MaxHP、MoveSpeed、AttackDamage、AttackSpeed（每秒次数）、ProjectileSpeed、加减速、弹丸寿命和无敌期。CurrentHP 属于每个玩家的 Health 实例，不能写回共享初始资源。Dummy 的初始 HP 可在 `dummy.tscn` Inspector 调整，测试伤害可在测试场景 Inspector 调整。

房间内容：编辑 `data/rooms/test_*.tres` 的敌人场景、生成点、障碍、名称和颜色。生成配置位于 `data/tombs/default_dungeon_config.tres`，可调整房数、最低深度和模板池。地图状态属于运行实例，不能写回模板；模板的历史 `room_id` 是模板 ID，`map_position` 仅供 Phase 2 旧夹具使用，随机节点不读取该坐标。

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

尚未实现的目录由 `.gitkeep` 保留。当前运行入口为 `scenes/main/dungeon_test.tscn`；`room_test.tscn` 是需注入布局的控制器装配场景，不直接 F6 运行。Phase 0/1 独立入口保留；Phase 2 原始十字图位于 `tests/fixtures/fixed_room_test.tscn`，原来的 204 个断言全部保留。

## 文档与 Git

- `PROJECT_PLAN.md`：逐阶段范围和验收。
- `ARCHITECTURE.md`：系统边界、数据与依赖约定。
- `GAME_DESIGN.md`：核心玩法与首个 Demo 范围。
- `AGENTS.md`：所有后续开发任务必须遵守的项目规则。
- `docs/PHASE_3_VERIFICATION.md`：实际验收、命令、逐项结果及限制。
- 跟踪源码、场景、Resource、源资产和 Godot `.uid`；不提交 `.godot/`、构建输出和本地日志。
- 开始任务前检查 `git status`；功能分支默认使用 `codex/` 前缀。提交需有明确阶段与范围，不自动推送。

## Phase 4 敌人与验证

五模板组合为 3 尸蟞、5 尸蟞、2 枪手、3 尸蟞 + 1 枪手、2 尸蟞 + 2 枪手。编辑 data/enemies/*.tres 调整生命、速度、伤害、冷却和前摇；编辑 RoomDefinition.spawns 的每项场景/数据/位置，entry_grace_time 调整入房观察期。每个生成点与四入口至少相距 180 像素。

```powershell
godot --headless --path . --script res://tests/phase_4_smoke.gd
godot --path . --script res://tests/phase_4_smoke.gd -- --capture
```

完整结果、人工反馈与限制见 docs/PHASE_4_VERIFICATION.md。未实现完整寻路、正式美术、音效、遗物或 Boss；不进入 Phase 5。