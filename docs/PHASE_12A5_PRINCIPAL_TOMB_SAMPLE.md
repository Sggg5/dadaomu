# Phase 12A.5 晋北主棺墓室美术样板

基线 `6f73f20c0866d91838c7f637f2983eb6bc09dcc6`，工作分支 `codex/phase-12a-hd2d-art`。素材全部DRAFT，等待人工美术验收。本轮不是历史复原鉴定，不代表正式美术或专家审核通过。

## 范围与隔离

只在 `tests/phase12a5_playtest.gd` / `tests/phase12a5_capture.gd` / `tests/phase12a5_smoke.gd` 显式附加A房视觉。原A几何、B/C几何、正式Geometry池、GEOMETRY_VERSION2、Profile10、玩家80HP及所有玩法保持不变。`tests/phase12a4_playtest.gd` 继续提供原四房对照。

生产scripts/scenes/data及12A.4实验几何的规范换行字节与基线比较，由Python专项保护。不读写正式玩家存档；GameFlow只用MuseumProfileStore.in_memory()。真实地图选择晋北、通过真实Door进入第一COMBAT后，才注入原有A几何和视觉；没有第二套地图生成器。隔离入口用原room_changed信号恢复重访A房的专属视觉，命名节点去重；不修改正式RoomController。

## 根因与本轮方案

旧A主棺从普通小棺图集等比缩放，宽阔碰撞基座与细窄棺体形成两层视觉语言；祭台同样使用通用竖向图。墙体沿用通用石面线框，刻线密度与高细节物件不协调。只有外围两灯时，主棺轴线缺少重点。

新增专属石椁/棺床整体、横向祭台、双叶墓门封石和重复石砖纹理。完整独立素材按固定像素画布裁切，不把小棺拉伸，也不将概念图当作地板。主角尺寸、动画与武器均未修改。

墙体分压顶、40px北墙立面、墙根暗带，侧墙向外投影而非侵占可走区域；砖纹按原像素截取重复而非拉伸整个墙段。门框侧柱位于112px开口之外，门槛为齐地面磨损，不绘制假台阶。封石严格读取Door.is_open，真实清场后让出开口。LEGACY恢复旧门绘制。

主棺真实阻挡范围仍160×128，专属160×148画布底部锚定原碰撞下沿408，浮雕与棺床向北投影。祭台144×60画布对应144×48碰撞，保留供器主次；木棺和石柱复用原DRAFT资产。所有新节点只有CanvasItem，不增加碰撞。

地板保持既有低噪声无缝基底。撤去A旧装饰的宽边框，仅保留齐地面的仪式轴铺痕；墙根及棺床接触暗带低透明叠加，中央战斗区保持清楚。Basic包含完整静态明暗，Enhanced将原两盏灯移到主棺两侧，仍由原RoomVisual轻微闪烁，不增加灯数量。其余房间灯光不变。

视觉静态绘制缓存于CanvasItem，仅渲染模式变化重新绘制；门封石只在开关状态变化时重绘。未引入每帧树递归或额外实时灯。缺失任一新素材时保留完整旧A绘制；LEGACY/BASIC/ENHANCED继续可切换。

## 原创素材与来源

使用内置imagegen生成，原图完整保存于 `assets/art/sources/`，精确提示词见 `phase12a5_prompts.json`，原始来源不删除。确定性处理见 `tools/build_phase12a5_assets.py`。manifest记录路径、SHA256、源图、处理方式及DRAFT状态。不是现实出土器物，不使用博物馆照片或未明授权素材。

| 素材 | 游戏像素 | 用途 | 处理 |
| --- | --- | --- | --- |
| a5_principal | 160×148 | 专属主棺、石质棺床与浮雕 | alpha边界裁切，等比nearest，底部锚定 |
| a5_offering | 144×60 | 横向石祭台与供器 | 等比nearest，无横向拉伸 |
| a5_gate | 112×28 | 真实Door闭合封石 | 原生绘制及90度旋转 |
| a5_masonry | 96×96 | 墓砖立面与墙顶 | 原图中心裁切，BOX缩小、32色、边界平均周期处理 |

原图与游戏图均保持DRAFT。石砖只用于建筑表面，不是高分辨率整房背景。图片生成中的像素簇质量仍需人工判断；主棺接近横向石椁比例，并未声称是某个时代的标准葬制。

## 实机证据

Godot4.6.2 Compatibility，固定晋北Seed522269330；新旧在相同1280×720原生渲染目标、相同Enhanced模式、相同入口位置比较。测试信息区在两版均统一收起标题/地图等冗余文字，未全局重构HUD。

- [新旧完整图轮播](screenshots/phase_12a5/before_after.gif)
- [旧A完整图](screenshots/phase_12a5/before_1_static_enhanced.png) / [新A完整图](screenshots/phase_12a5/after_1_static_enhanced.png)
- [Basic](screenshots/phase_12a5/after_1_static_basic.png) / [Enhanced](screenshots/phase_12a5/after_1_static_enhanced.png) / [原生对比轮播](screenshots/phase_12a5/basic_enhanced.gif)
- [原像素左右拼接](screenshots/phase_12a5/before_after_native_pair.png)，2560×720，两张原图不缩放
- [主棺旧](screenshots/phase_12a5/before_principal_native.png) / [主棺新](screenshots/phase_12a5/after_principal_native.png)
- [墓门旧](screenshots/phase_12a5/before_door_native.png) / [墓门新](screenshots/phase_12a5/after_door_native.png)
- [墙壁旧](screenshots/phase_12a5/before_wall_native.png) / [墙壁新](screenshots/phase_12a5/after_wall_native.png)
- [人物旧](screenshots/phase_12a5/before_player_native.png) / [人物新](screenshots/phase_12a5/after_player_native.png)
- [真实绕棺移动](screenshots/phase_12a5/walk_around_coffin.gif)：几何检查阶段敌人与机关暂停，仅玩家实际输入移动，禁止称作真人战斗
- [全AI启用的真实移动射击战斗](screenshots/phase_12a5/actual_combat.gif)
- [绕棺后接战斗](screenshots/phase_12a5/walk_then_combat.gif)，按录制顺序拼接，两阶段明确区分
- 靠墙/棺前后/门口等 `after_1_walk_*.png`、`after_1_door_near.png`、清场开门 `after_1_cleared_open_doors.png`

所有PNG均来自Godot原生Viewport，局部图仅裁切原像素；GIF由真实连续采样帧生成并验证解码一致，没有概念图、HTML模拟或AI画面替换实机。GIF使用256色，PNG保留完整色彩。

## 测试与性能

最终Godot **343,154项，0失败**；Python **126项，0失败**。历史/11I 67组340,404项（包含零资产30日834、三策略经营/磁盘及真实图形入口）；Phase12八组152；旧12A.1～4专项1613；新样板headless421、graphical421、聚焦实机新42/旧26、聚焦活动性能新42/旧26；原渲染基准7。所有分组退出码及实际计数见validation_results.json。导入正常，SCRIPT ERROR/ERROR均作为失败处理，旧断言全部保留。

初采418/418项通过，但采图DPI和缺图覆盖尚未补全，不计入最终总数。最终采图全部固定原生1280×720。只读生产脚本/场景/数据与全部原实验几何逐文件比较通过；Profile10、50种定义、三地区、双生尸煞、掉落/经济和历史存档回归通过。

| A房Enhanced | FPS | P95(ms) | Draw Calls均值 | 纹理MiB | 采样秒 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 12A.4旧A | 663.1 | 2.531 | 200.2 | 23.19 | 3.001 |
| 12A.5新A | 673.5 | 2.708 | 180.5 | 23.41 | 3.002 |

RTX2070SUPER / NVIDIA595.97 / Godot4.6.2 Compatibility，1280×720原生VIEWPORT。单个本次图形进程顺序测量旧/新A，关闭VSync、没有fixed-fps，物理60Hz；实际战斗启用全部敌人、武器与机关，1秒预热后约3秒采样，采样期间不写PNG或录制GIF。两个旧外部headless进程未操作，本数据不是独占机器或跨硬件保证。

新版本Draw Calls减少，平均FPS略升，但P95从2.531升至2.708ms；尾部耗时没有证明改善，不宣称稳定优化。纹理增加约0.22MiB。原始before_focused_performance.json / after_focused_performance.json完整保留；不同实战行动/弹丸时序及短样本噪声也会影响均值和尾部。尚未观察到功能错误或低帧率卡死，长期性能和主观流畅度仍待人工确认。

A房仍为4个障碍、10个墙/障碍碰撞和2个实际门阻挡；原面积可用92.11%，24px裕量网格可走80.44%，四入口连通。只改视觉，没有扩大可走区或改变碰撞。

测试保留原12A.4的全部断言，并额外检查原生尺寸、专属素材、无新增碰撞、缺图回退、LEGACY门恢复、实际绕棺、原地图签名、真实武器、环境预警、掉落E拾取及真实门出口。

开发采图问题：初次沿用canvas_items时，Windows DPI让部分截图成为2048×1152；已在隔离入口强制1280×720 VIEWPORT原生目标并重新采集，没有将大图后期缩小充当1280证据。首次北墙压顶与测试标题重叠，已在新旧对比夹具统一收起冗余调试文字。没有通过修改正式HUD、战斗或碰撞处理。

## 复验

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/phase12a5_smoke.gd --fixed-fps 60
godot --path . --script tests/phase12a5_capture.gd --fixed-fps 60
godot --path . --script tests/phase12a5_capture.gd --fixed-fps 60 -- --old-a
godot --path . --script tests/phase12a5_capture.gd -- --benchmark
godot --path . --script tests/phase12a5_capture.gd -- --benchmark --old-a
python tests/run_phase_11i_qa.py --godot GODOT_CONSOLE --history --graphical --long-run
python tests/run_phase12_qa.py --godot GODOT_CONSOLE --graphical
python -m unittest discover -s database/tests
godot --path . --script tests/phase12a5_playtest.gd
```

## 未解决问题与人工验收清单

- 不看标题，石椁、祭台、墓门是否足以读成中国墓葬，而非普通石质竞技场。
- 主棺是否具有中心地位；横向石椁外形与竖向仪式轴是否协调，是否需要更长的内部棺盖。
- 墓砖细节、主角、石棺浮雕与木棺是否像素密度一致；暖光是否过黄或局部过亮。
- 北墙、棺后、南门附近的人物前后遮挡是否自然；弹丸、敌人血条与预警是否清楚。
- 旋转墓门封石的烘焙亮边与世界灯光方向是否足够协调；这仍是人工美术判断。
- Basic是否无需实时灯也成立，Enhanced是否形成适度而非抢眼的闪烁。
- 原敌人部分仍为基础几何占位，不在本轮扩素材；不把这一房宣称为全游戏美术定稿。
- 试玩控件和正式HUD仍有原先输入层缺口，本轮没有全局HUD重构。

只推送美术分支，不合并main，不接入正式Geometry候选池。自动测试不等于人工美术通过。完成打开A房隔离内存试玩，等待人工验收，不进入12A.6。
