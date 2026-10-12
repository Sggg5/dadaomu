# Phase 13A 门派信物最终规则修订验收

## 状态与基线

2026-10-12。从干净的 c3bd02bb1c9fee6a90e9f031a34e04364fa44571（本地与远端美术分支一致）建立 codex/phase-13a-profession-tokens。既有正常游戏最高品质DRAFT美术保留。代码提交 f32cb06c60c2f09817f05937f0e7283e6a83d428；本报告与媒体另提交。没有合并main，没有读取或写入正式玩家存档。

自动验收已实现；真人体验、职业能力平衡和新增身份/视觉均待审核。未找到既有职业能力规范，采用已向用户说明的轻量暂定DRAFT，不代表用户或专家已批准数值。

## 实际实现

远征地图确认前显示五个门派按钮，四派全部开放，默认无门派。选择随只读 initial_profession_id 和 copy_for_departure 快照进入GameFlow与DungeonSession；保存失败不出发，已出发的选择不受地图UI修改影响。修复原 start_night 重新capture导致扩展选择丢失的问题。

本局独立信物背包保存门派ID，遗体身份与搜索键分开记录。普通遗物、古董和馆藏档案不接收职业信物。第一层在正常COMBAT房随机分配四派各一遗体，后续每层最多一具；使用独立VERSION1流，不改地图、Boss、Relic或Antique随机状态。生成点避开碰撞与其它可互动对象，遗体不新增阻挡。

清房且安全时，靠近64px按E搜索。新信物打开真实装备/稍后选择面板；重复同派只补充不同遗体身份，不叠效果。G可随时申请打开信物簿，Q申请当前能力。ACTIVE/存活敌人/危险确认或结算/危险区/切场/死亡禁止切换。只激活一个门派，Runtime同步更新全部效果后发布通知，消耗账本不随切换重置。

| 暂定门派 | DRAFT效果 | 本局主动次数 |
|---|---|---:|
| 摸金校尉 | 墙纹交互距离1.5倍；Q检查本房最近未检查墙纹，不直接揭示/生成暗室 | 1 |
| 发丘天官 | Q抄录当前背包货目，可在信物簿查看；不鉴定、不改价值 | 1 |
| 搬山道人 | Q准备一次非祭台机关抵免；仅激活搬山时生效，切走保留待用护符但不保护 | 1 |
| 卸岭力士 | 8格增至10格；无主动技能 | 0 |
| 无门派 | 无初始信物、无效果，仍能搜索前辈 | 0 |

从卸岭切走保留已有全部物品；负空余格阻止普通拾取，并明确显示超载，移动倍率0.8。恢复容量或丢弃至8格以内解除减速。不修改共享PlayerStats或古董资源。跨层通过原RunCarryState转移现有物品，restore_carry允许保留超额，只用于转移，不放宽普通add。

同一Session的ProfessionRunState跨层保留初始、发现、激活职业、已消耗次数、备好的护符与货目。撤离、完成或死亡清空；R/N是重新开始新Run，沿用本次初始选择但清掉发现信物与次数。下一次地面出发重新选择。维持原异常退出返回安全地面规则，不新增夜间存档或续跑恢复。

## 架构与文件

新增 data/professions/draft_professions.json；scripts/professions/ 下的 registry、run_state、runtime、corpse_plan、corpse；scripts/ui/profession_selection_view.gd 与 profession_panel.gd。所有新脚本小于1000行，Runtime为唯一效果装配者，RunState没有节点引用。

12个原接入脚本：ExpeditionSelection、GameFlow、DungeonSession、RoomController、Player、AntiqueInventory、RunCarryState、ExpeditionMapPanel、WallMark、TombRiskContent、EncounterHazard、EnemyProjectile。只增加出发快照、职业注入、安全结算钩子、非祭台机关过滤与超额转移；80HP、基础移动/武器、AI/Boss、正式资源与掉落池均保留。

Phase12旧冻结检查继续执行；phase13_authorized_hashes.json对上述12个文件及实际改动的旧函数逐项精确授权，不豁免其它脚本或数据。新Python测试验证授权集合、原始基线及所有旧data和ProfileStore字节未变。Profile仍VERSION10，数据库审核和媒体授权状态不变。

## 正式GameFlow证据

使用正式 scenes/main/game_flow.tscn、内存新档（Day1、零现金、零馆藏），Campaign52，开发夹具指定真实Run Seed192034。没有LAB几何、传送、HP/资金/遗物注入。通过原WASD、鼠标武器、Door、E/Q/G和真实GUI按钮完成：

1. 博物馆地图选择摸金并确认，携摸金符进入正常地宫。
2. 真实武器清场，走到正常生成的搬山遗体，E取得搬山令及虚构身份。
3. 到正常墙纹房Q消耗摸金观气。
4. G面板鼠标装备搬山，摸金距离效果回到1.0；Q准备搬山抵免。
5. G装备回摸金，距离回1.5；已用观气仍1，不能再用。
6. 正常拾取遗物建立Build，实际击败第一层Boss，真实出口E进入第二层。
7. 检查信物、账本和备好护符仍在；实际击败第二层Boss，经F撤离、E回博物馆。
8. 下一次地图明确选择无门派，无旧信物。经实际开放门进入普通战斗，停止射击并接近敌人，真实伤害死亡，Session正常清理。

该图形流程39项零失败；最终解耦类型加载依赖后，完整同流程headless再跑39项零失败。非空状态的结束清理、实际搬山抵免/切走失效及超载转移另以实际Player/Session运行时专项验证。自然死亡流程在新一局无派状态；不冒称其单独证明每一种非空死亡状态。

记录来自原生Godot1280×720 viewport，按每30物理帧采样（2fps），没有生成或模拟画面。结尾附实际死亡PNG停留2秒（不是动作插帧）。GIF为960×540最近邻编码，MP4与PNG保留1280×720。因采样频率低，瞬时按钮操作可结合明确命名的PNG查验；不能用本片断定动画质量。

- [完整实机GIF](screenshots/phase_13a/gameflow_professions.gif)
- [完整实机MP4](screenshots/phase_13a/gameflow_professions.mp4)
- [出发择派](screenshots/phase_13a/13a_choose_MOJIN.png)
- [真实搜索前](screenshots/phase_13a/13a_before_search.png)
- [搜索与身份面板](screenshots/phase_13a/13a_after_search.png)
- [搬山激活](screenshots/phase_13a/13a_banshan_active.png)
- [切回摸金且次数已用](screenshots/phase_13a/13a_mojin_used_preserved.png)
- [第二层保留](screenshots/phase_13a/13a_floor2_preserved.png)
- [下一局真实死亡](screenshots/phase_13a/13a_actual_combat_death.png)

## 失败记录与修复

- 初次正式流程在522269330、33及其它Seed的第二层被自动驾驶打死，后续撤离断言未完成。保留失败日志，不注入HP；最终192034正常拾取Build后两层完成。不能据此声称所有Seed机器人均能通关。
- 初版运行时夹具Campaign与选择快照不一致，GameFlow正确拒绝；修正显式Campaign夹具，没有放宽生产校验。
- 中途工具文本输出曾产生非UTF8及额外CR，导致解析失败；统一UTF8/LF并重跑。不是忽略错误。
- Player直接类型引用ProfessionRuntime、其引用RoomController产生加载环：旧Phase4断言可通过但仍有SCRIPT ERROR。改为Node/Node2D注入边界，保留原调用职责，最终Phase4 105项且无ERROR；导入、运行时和真实GameFlow重新通过。
- 两个11I测试初次未传 earned checkpoint 而明确失败；按原官方runner使用本次从零真实获得的隔离checkpoint重跑。不删除原断言、不伪造资产。
- 实机发现职业HUD与古董估值重叠，移到右上角，PNG确认不遮挡背包与房间信息。

## 自动测试

Godot4.6.2。最终判据同时要求退出码、零失败摘要与无SCRIPT ERROR/ERROR，不能只看打印的失败数。

| 专项 | 检查/测试数 | 失败 |
|---|---:|---:|
| Phase13A model，含100个Seed及各独立流签名 | 325 | 0 |
| Phase13A真实运行时/原子切换/范围/重复/超载/R/N | 37 | 0 |
| Phase13A正常GameFlow headless | 39 | 0 |
| Phase13A原生图形同流程 | 39 | 0 |
| Python数据库/授权/历史兼容全部 | 133 tests | 0 |
| Phase1～11H，59组（含三地区和双生尸煞） | 338474 | 0 |
| Phase12及12A.1/4/5/6，5组 | 1145 | 0 |

以下为历史59组及视觉5组的实际摘要：

| 原套件 | 检查数 | 失败 |
|---|---:|---:|
| 1 | 27 | 0 |
| 2 | 204 | 0 |
| 3 | 94 | 0 |
| 4 | 105 | 0 |
| 5a | 61 | 0 |
| 5b | 236 | 0 |
| 6 | 164 | 0 |
| 6_5 | 174 | 0 |
| 7a | 306 | 0 |
| 7b | 722 | 0 |
| 8a | 486 | 0 |
| 8b | 305 | 0 |
| 8c | 297 | 0 |
| 8d | 2153 | 0 |
| 9a | 10513 | 0 |
| 9b | 30758 | 0 |
| 9b2 | 4843 | 0 |
| 9b3 | 29133 | 0 |
| 9b32 | 1734 | 0 |
| 9b33 | 2702 | 0 |
| geometry | 206885 | 0 |
| softlock | 1030 | 0 |
| baseline | 728 | 0 |
| 10a | 49 | 0 |
| 10d_bridge | 9 | 0 |
| 10d_media | 11 | 0 |
| 10d | 40 | 0 |
| 10d6 | 92 | 0 |
| 11a | 717 | 0 |
| 11b_tombs | 1172 | 0 |
| 11b_catalog | 178 | 0 |
| 11b | 40984 | 0 |
| twin_death_hotfix | 47 | 0 |
| 11d1 | 7 | 0 |
| 11d2 | 20 | 0 |
| 11d3 | 9 | 0 |
| 11d4 | 169 | 0 |
| 11d5 | 235 | 0 |
| 11d_flow | 108 | 0 |
| 11e1 | 335 | 0 |
| 11e2 | 19 | 0 |
| 11e3 | 9 | 0 |
| 11e4 | 131 | 0 |
| 11e5 | 10 | 0 |
| 11f1 | 23 | 0 |
| 11f2 | 18 | 0 |
| 11f3 | 14 | 0 |
| 11f4 | 129 | 0 |
| 11f5 | 27 | 0 |
| 11g1 | 4 | 0 |
| 11g2 | 9 | 0 |
| 11g3 | 5 | 0 |
| 11g4 | 18 | 0 |
| 11g5 | 75 | 0 |
| 11h1 | 5 | 0 |
| 11h2 | 5 | 0 |
| 11h3 | 24 | 0 |
| 11h4 | 25 | 0 |
| 11h5 | 82 | 0 |
| 12 | 50 | 0 |
| 12a1 | 67 | 0 |
| 12a4 | 408 | 0 |
| 12a5 | 421 | 0 |
| 12a6_visual | 199 | 0 |

导入解析通过；真实入口由上面的GameFlow启动、地图互动、战斗、回馆覆盖，未启动默认磁盘存档入口来触碰正式档。


### 11I从零30日与安全磁盘回归（正确earned-checkpoint调用）

| 套件 | 检查数 | 失败 |
|---|---:|---:|
| clean_flow | 834 | 0 |
| economy_first_income | 363 | 0 |
| disk_first_income | 69 | 0 |
| economy_midgame | 363 | 0 |
| disk_midgame | 69 | 0 |

实际从零正式GameFlow 834项完成30营业日与三地区；两个真实所得checkpoint各跑A/B/C三策略，每策略30日，门票/维护/工资/投资现金一致。两个隔离checkpoint各完成V10磁盘往返与坏档/冲突保护。未使用正式玩家存档。

Godot总计341757项（含图形39项），Python另133项测试，最终均零失败。早期失败和错误参数调用不混入通过次数。

## 复现命令

PowerShell：

```powershell
$qaGodot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
python tests/run_phase13a_qa.py --godot $qaGodot --history --long-run --graphical
# 仅录制正式GameFlow输入驱动流程（使用内存档）
& $qaGodot --path . --fixed-fps 60 --script tests/phase_13a_flow_smoke.gd -- --run-seed=192034
```

Python应使用已有Pillow依赖的运行环境。runner拒绝无摘要、脚本错误、失败退出，不动正式Profile。视频PNG采样留于ignored logs，可用ffmpeg按2fps编码。不要用测试夹具当作真人试玩。

## 人工待验与限制

需确认：择派说明是否清楚；前辈遗体能否自然发现；G面板与Q能力是否符合预期；安全切换提示、卸岭超载处理是否直观；四派能力数值是否认可。遗体和UI均DRAFT，未扩大敌人、Boss、古董、经济或其它职业技能。本阶段停止，不进入下一阶段。

## Git交付

功能提交 f32cb06c60c2f09817f05937f0e7283e6a83d428。验收提交另包含本报告、原生截图/GIF/MP4、复现runner和纯空行清理，未再变更生产行为。最终分支由git正常push建立，无强推。main基线aaefb2e653cdbfa1dd87deb4e46ba5772fdef72c未合并；最终完整SHA与push校验见交付回复。
