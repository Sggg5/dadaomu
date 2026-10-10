# Phase12A.3 晋北墓室视觉精修（DRAFT，人工待验）

基线d657c455f4c8405ff0652c256c18ce21afc65c28，分支codex/phase-12a-hd2d-art。不合并main，不操作正式档。

## 成因与范围

标准房四角对称源于原Geometry真实矩形布局，不能仅通过美术移走实体障碍。本轮不更改这些矩形或通道。12A.2把128×160整格陈设映射到任意长宽矩形，造成雕刻、棺盖和木带拉伸，是可独立修正的美术问题。

保留原碰撞大小石座作为阻挡边界，棺体改用统一比例缩放、脚底对齐与水平居中；宽障碍呈现棺床/祭台底座而非把棺体横向拉长。最靠北的既有障碍周边加入极淡的平面铺砌/磨损痕迹，陪葬陈设保持低调。没有新增实体器物、假通道或中央碰撞。四角拓扑仍对称，若人工认为不足，需要另行提案调整Geometry，不能声称本轮已经消除结构对称。

## 建筑、适配与可读性

原墙顶/立面结构保留，破损砂浆、短侵蚀线仅画在墙面内部。真Door两侧墙域加入石质门框，真实门开口上增加暗色门洞与浅门槛；不缩窄实际门洞，不改变锁门逻辑。低对比铺砌痕迹是平面地面信息，不是危险区。

棺体适配使用min(width/120,(height+18)/150)，保持0.8图集格宽高比。原石座尺寸精确对应原障碍，脚底不漂移。窄柱/横台仍可能需要专门资产，不以本轮数学适配冒称所有器型自然。全部既有素材DRAFT不变，没有新增第三方图或自动审核。

蜘蛛类已支持scarab贴图只提升中间色调至RGB1.22/1.16/1.06；受击仍用红闪，前摇环、血条、弹丸、危险区域和AI不变。不对未支持敌人伪造正式素材。人物尺寸、脚底、Z按原有脚线排序保留；障碍视觉仍以真实脚底Y排序，北墙保持环境层，不覆盖角色。南墙与人物接触需人工复看。

## 绘制成本

Godot CanvasItem绘制命令本来会缓存；12A.2仍每帧queue_redraw并递归房间树，是重复CPU工作。新适配器仅在模式/旧空间/地域开关变化时重绘静态房间、同步HUD和可见性。初次扫描一次原树，新增BossTelegraph/EncounterHazard通过SceneTree.node_added延后注册，保留原Z与弱引用；每帧只清理已登记危险节点的弱引用，模式变化恢复/提升Z。没有轮询整树，没有移除危险提示。原实时灯和动画仍正常推进。

## 实机证据

固定Seed522269330，Campaign52、内存正式GameFlow，实际地图确认→WASD→Door→Weapon。baseline_basic/enhanced.png在修改前运行旧原生基准得到，基线performance.json同机重新采样。新图combat_basic/enhanced、player_wall/coffin/door、event_room、antique_room、boss_battle/boss_room均来自Godot。不同尺寸专项使用原生TombSpacePiece数学适配检查，不冒称直接装配夹具就是普通玩家流程。

截图位于screenshots/phase_12a3。动态演示只由实际渲染帧组成，程序驾驶器掌握路径，不代表真人玩法体验。局部放大是实机图最近邻裁切，明确标记，非概念图。

| 证据 | 文件 |
| --- | --- |
| 12A.2 / 12A.3同房 | [旧基础](screenshots/phase_12a3/baseline_basic.png)、[新基础](screenshots/phase_12a3/combat_basic.png)、[对比GIF](screenshots/phase_12a3/before_after.gif) |
| 两模式 | [基础](screenshots/phase_12a3/combat_basic.png)、[增强](screenshots/phase_12a3/combat_enhanced.png)、[GIF](screenshots/phase_12a3/basic_enhanced.gif) |
| 真实武器/移动战斗 | [48帧GIF](screenshots/phase_12a3/actual_combat.gif)、motion_000～047原始PNG |
| 实际环境预警 | [actual_danger_warning.png](screenshots/phase_12a3/actual_danger_warning.png) |
| 墙边 / 棺旁 / 墓门 | [墙](screenshots/phase_12a3/player_wall.png)、[棺](screenshots/phase_12a3/player_coffin.png)、[门](screenshots/phase_12a3/player_door.png) |
| 事件 / 古董 / Boss | [事件](screenshots/phase_12a3/event_room.png)、[古董](screenshots/phase_12a3/antique_room.png)、[Boss战](screenshots/phase_12a3/boss_battle.png)、[出口](screenshots/phase_12a3/boss_room.png) |
| 实体尺寸适配夹具 | [基础](screenshots/phase_12a3/proportions_fixture_1.png)、[增强](screenshots/phase_12a3/proportions_fixture_2.png)；不是正式随机地图 |
| 最近邻3倍放大 | coffin_detail_3x.png、door_detail_3x.png、scarab_detail_3x.png |

GIF为1280×720真实帧，每16模拟帧采样，48张约13秒，低采样演示不替代60FPS流畅度验收。GIF256色限制已明确，PNG保留原始画质；差分压缩后逐帧RGB与量化输入一致验证，不增删动作。可使用tools/build_phase12a3_evidence.py重建。

## 测试、性能与失败记录

最终Godot 340,910项，0失败；Python120项，0失败。历史及11I共67组340,404项，其中零资产30日834项、三地区/双生尸煞/博物馆/Profile10及实际图形流程均保留。Phase12八组152项；12A.1 67+28；12A.2空间43×2、地域18×2；12A.3空间50×2、尺寸6×2；当前基准9、独立旧基线基准9、原性能脚本7。完整分组及退出/失败标记见screenshots/phase_12a3/validation_results.json。导入无解析错误，所有原断言保留。预览测量不计最终性能或检查总数。

同机NVIDIA RTX2070SUPER、Godot4.6.2 Compatibility、1280×720、关闭VSync，真实首战斗房冻结物理，预热1秒、采样3秒。12A.2使用git archive独立解包原提交运行，不回写当前代码；正式对照均单窗口顺序运行，没有其它QA图形窗口并行。两个版本均182节点，仍两盏原有实时灯。

| 版本 / 模式 | FPS | P95(ms) | Draw calls | 纹理MiB |
| --- | ---: | ---: | ---: | ---: |
| 12A.2 / Basic | 679.2 | 3.093 | 225 | 18.61 |
| 12A.2 / Enhanced | 650.7 | 3.051 | 226 | 22.61 |
| 12A.3 / Basic | 704.4 | 3.319 | 241 | 18.61 |
| 12A.3 / Enhanced | 674.4 | 3.134 | 242 | 22.61 |

新增门框、侵蚀和铺砌痕迹使两模式Draw calls各增加16，纹理内存不变。本次FPS小幅上升，但P95略增加；单轮短采样和桌面环境存在波动，不归因于缓存、也不宣称稳定提速。确定性专项证明每帧全树递归和静态重绘已移除。灯光/角色仍动态更新，危险节点登记没有取消；低端硬件与完整密集战斗性能仍待验。原始五模式记录（含legacy与旧空间开关）见两个performance.json，原性能脚本另存regression/performance.json。

第一次导入发现tomb_space_floor.gd的jamb类型推断失败；显式Vector2修正后重新导入。预览时发现实色石座遮盖石材纹理，去掉该覆盖，仅保留淡描边；最终图形/视觉回归、截图和性能使用此修正。没有改玩法或删减旧断言。新增专项覆盖缓存不重复扫描、动态新增预警/legacy恢复、不同长宽适配、原碰撞、真实门、四种房型与Profile10。

## 人工验收清单

主要复验命令（godot指向4.6.2 console；不使用正式档）：

```powershell
python -m unittest discover -s database/tests
godot --headless --path . --editor --import --quit
python tests/run_phase_11i_qa.py --godot GODOT_CONSOLE --history --graphical --long-run
python tests/run_phase12_qa.py --godot GODOT_CONSOLE --graphical
godot --headless --path . --script tests/phase12a3_space.gd --fixed-fps 60
godot --path . --script tests/phase12a3_space.gd --fixed-fps 60
godot --path . --script tests/phase12a3_proportions.gd --fixed-fps 60
godot --path . --script tests/phase12a3_benchmark.gd
python tools/build_phase12a3_evidence.py
```

另运行未改动的12A.1 smoke/graphical、12A.2 space/regional两种模式及原phase12_benchmark.gd；逐组数值在validation_results.json。试玩用tests/phase12_playtest.gd，内存隔离首战斗房，空格开始/F6三模式。实际提交SHA以交付消息及git log为准，不在提交自身文件内伪造自引用SHA。

- 第一眼是否仍像竞技场；主棺与陪葬石座是否有主次。
- 真实碰撞石座是否容易理解，等比棺体是否显得过小。
- 木棺、石棺、棺床/细柱是否需要专门横向或窄体资产。
- 北墙、南墙和棺前后移动时脚底遮挡是否自然。
- 蜘蛛、血条、弹丸和预警在密集战斗中是否清楚。
- 门框是否明确显示真开口，低噪声地面是否保持清楚。
- Basic/Enhanced是否都可独立成立，低端设备性能待真人验证。

仍缺专用墙角/墓门像素图、横向棺床、精细窄柱及不同古墓年代的建筑形制审订。本轮程序绘制是DRAFT游戏原型，不声称真实晋北墓葬复原。Boss和42件古董正式素材不扩展。自动测试不能批准美术品质；完成提交推送后停止。
