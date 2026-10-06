# 大盗墓时代

原创独立 2D 俯视角房间式 Roguelite。背景为 1920～1940 年代架空中国：盗墓者探索古墓，收集古董与遗物，选择继续深入或带着收益撤离。

## 当前状态

当前 **Phase 5B 正式遗物奖励与 Build 协同**。默认 Seed 为 `192034`，每图 8～12 个房间，独立 RNG 可重现正交树状布局。START 固定在 (0,0)，Boss 是距离至少 5 的最远叶子，ANTIQUE 距离至少 2。

随机节点决定位置/连接/类型，五份原有普通房配置作为共享模板池。玩家、战斗、门和房间生命周期继续复用：首次进入锁门，击杀后开门，过门保留生命，重访已清场房不刷怪。

START 为安全出生房，忽略模板刷怪并立即清场开门；BOSS 使用普通敌人战斗占位；ANTIQUE 自动清场，没有古董内容（Phase 6）或 Boss 战斗（Phase 7）。已实现尸蟞追击咬击、盗墓枪手保持距离与射击。战斗房入房有 0.35 秒观察期，敌人暂停行动；橙色表示攻击前摇，红色菱形是敌方弹丸。修订版人工手感复验仍待反馈。

## 开发环境与运行

- Godot 4.6.2 标准版（GDScript），Windows 为主要开发平台。
- 渲染器：Compatibility；逻辑画布：1280 × 720，canvas_items 缩放。
- 使用 Godot 项目管理器导入根目录 `project.godot`，打开后按 F6 运行当前场景，或 F5 运行项目。
- WASD 移动，鼠标瞄准，按住鼠标左键连续射击。
- F1 或“测试伤害”按钮造成 25 点伤害；受伤后有 0.25 秒无敌期。默认 80 HP，间隔受伤四次死亡。
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

五模板组合为 4 尸蟞、6 尸蟞、3 枪手、4 尸蟞 + 1 枪手、3 尸蟞 + 2 枪手。编辑 data/enemies/*.tres 调整生命、速度、伤害、冷却和前摇；编辑 RoomDefinition.spawns 的每项场景/数据/位置，entry_grace_time 调整入房观察期。每个生成点与四入口至少相距 180 像素。

```powershell
godot --headless --path . --script res://tests/phase_4_smoke.gd
godot --path . --script res://tests/phase_4_smoke.gd -- --capture
```

完整结果、人工反馈与限制见 docs/PHASE_4_VERIFICATION.md。未实现完整寻路、正式美术、音效或 Boss；工程遗物只用于开发回归；正式池为 Phase 5B 的八件遗物。
START 与其他房复用 room.tscn 和随机视觉/障碍模板，不复制场景、不修改共享 spawns；START 不调用 EnemySpawner，因此不应用观察期。COMBAT 的 180px 入口间距、0.35 秒观察期和攻击前摇保持；BOSS 仍普通敌人占位，ANTIQUE 仍自动清场。

## Phase 5A 开发测试

当前新增 RelicDefinition / RelicInventory / RelicEffect / RelicRuntime 与局部战斗 Hook。遗物随唯一 Player 跨房保留，R/N 或死亡清空；定义只读，效果实例每次安装独立；同一 ID 不重复获得。

- 1：强力火药，攻击请求伤害 ×1.5（默认 20 →30，Tier1 65HP 尸蟞由 4 发变 3 发）。
- 2：双生铜钱，一次输入发射两枚方向 ±6° 的弹丸，只计一次冷却。
- 3：血契，每个敌人首次死亡恢复 5 HP，上限 MaxHP。
- Backspace：卸载全部工程遗物，后续攻击恢复原值。已经发射的弹丸保留发射时快照。

底部显示当前遗物列表。本节工程遗物不进入正式池；正式获得见下文。仍无永久存档或正式遗物美术。人工反馈确认“双弹清晰，跨房保留”；其余主观效果验收未确认，详情见 docs/PHASE_5A_VERIFICATION.md。

```powershell
godot --headless --path . --script res://tests/phase_5a_smoke.gd
godot --path . --script res://tests/phase_5a_smoke.gd -- --capture
godot --path . -- --seed=1
```

数据在 data/relics/，效果实现分别位于 scripts/relics/effects/。配置引用独立 effect_script，不添加核心脚本 ID 分支。新增参数或运行对象时继续维护 copy/卸载生命周期。Phase 5A 已合并 main；当前工作为 Phase 5B，仍不自动合并 main。
## Phase 5B 正式奖励与 Build

首次清场第2、4、7个普通COMBAT房生成一件底座奖励。START、ANTIQUE、BOSS占位不计数，重访不重复。靠近底座64px内按E拾取，名称/简短说明就地显示；离房未拾取则丢失，不在重访补发。

正式池只有五帝钱、黑火药、尸油灯、镇尸钉、铜镜、墨斗、洛阳铲、引魂纸鸢8件，不包含工程test_*。奖励按Seed和版本独立无放回抽取；R复现地图和奖励序列并清空Build；N重建新图/奖励进度。相同引擎/池/版本下可复现，尚无存档。

| 遗物 | 实际规则 |
| --- | --- |
| 五帝钱 | 双弹±5°，每发80%伤害，一次冷却 |
| 黑火药 | 每个成功命中产生半径72px、50%弹丸伤害爆炸；可伤原目标，不递归 |
| 尸油灯 | 3次3HP DOT，间隔0.35秒；同敌人刷新不叠层 |
| 镇尸钉 | 穿透1个敌人；撞墙消失，同一弹不重复命中同敌人 |
| 铜镜 | 每3次攻击在最终批次两侧±20°各复制一组；单弹变3，五帝钱双弹变6 |
| 墨斗 | 起点到命中点24px宽墨线，对其他敌人一次6伤害，视觉0.3秒 |
| 洛阳铲 | 每5次追加铲风：2.2倍伤害、1.3倍速度、寿命0.22秒、体积1.8倍 |
| 引魂纸鸢 | 有效非致命受伤充能；下次攻击加±15°两侧弹并消耗，未用充能跨房保留 |

E是正常获得方式。F2打开/关闭正式遗物开发添加按钮；1/2/3工程键和Backspace全移除仍保留，仅用于开发，不影响正式池。

```powershell
godot --headless --path . --script res://tests/phase_5b_smoke.gd
godot --path . --script res://tests/phase_5b_smoke.gd -- --capture
godot --path . -- --seed=192034
```

Seed192034正常测试在第2/4/7次清房获得墨斗/五帝钱/黑火药，再继续战斗。详细测试、文件清单和人工验收状态见docs/PHASE_5B_VERIFICATION.md。当前分支codex/phase-5b-relic-builds，提交并push后停止，不进入Phase6。
## Phase 5B 平衡修订（2026-10-06）

正式奖励改为第2/4/7个首次COMBAT清场，其他房型/重访/重复通知规则不变。短局只有5～6个COMBAT时只发2件，不动态补发；无放回序列及R同Seed复现不变。

尸蟞：HP65、速度165、伤害12、冷却0.9、前摇0.25。枪手：HP90、速度105、弹伤14、弹速340、冷却1.35、前摇0.4，距离逻辑与非追踪弹保持。

模板center/north/west/east/south分别为4尸蟞、6尸蟞、3枪手、4尸蟞+1枪手、3尸蟞+2枪手。新增点与其他点均验证四入口距离≥180、障碍边界安全及敌人间距≥40；观察期0.35秒保持。

EncounterDifficulty由Controller读取DungeonRoom.distance_from_start解析，再经Room/Spawner注入Enemy.configure_spawn。深度1～2：HP/伤害1.00；3～4：HP1.15/伤害1.15；≥5：HP1.30/伤害1.35。只缩放实例Health上限、咬击/枪弹伤害；不修改共享Definition，不缩放移速/弹速/前摇/冷却，不做BFS或完整难度系统。HUD显示深度和Tier。R重建新上下文，倍率不累计；CLEARED重访不刷强化敌人。

本次仅成长节奏与战斗压力修订；不增加敌人、Boss、词缀、遗物、经济或Phase6内容。实际试玩对底座+E体验已确认无问题，新平衡主观复验另见验证报告。
## Phase 5B 致死性修订

玩家默认80HP、有效受伤后0.25秒无敌；移动/攻击参数不改。尸蟞HP65不改，速度175、伤害14、冷却0.8、前摇0.25；枪手HP90/速度105不改，弹伤16、弹速380、冷却1.20、前摇0.4。无追踪/散射，咬击距离与LOS重判保持。

HP倍率仍1.00/1.15/1.30；伤害倍率改1.00/1.15/1.35。三Tier实际咬击14/16.1/18.9，弹伤16/18.4/21.6。80HP分别约6/5/5次咬击或5/5/4次枪弹死亡；均非一两下秒杀。倍率仍仅作用实例HP和伤害，不额外缩放时序/速度。

怪物数量、正式遗物、奖励2/4/7均不改。本次只提高失误代价，不以堆HP或数量延长战斗；若主观风险仍不足，后续应评估攻击模式而非继续堆HP。人工复验状态见验证报告，不进入Phase6。