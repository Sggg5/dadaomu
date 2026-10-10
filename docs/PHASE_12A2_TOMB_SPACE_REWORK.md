# Phase 12A.2 晋北墓室空间返修（DRAFT，人工待验）

基线：e4f8cdd4cc41ba1b40c2e4412b5cf57ad54c6c2a；分支codex/phase-12a-hd2d-art。Godot4.6.2，1280×720，实际GameFlow晋北Seed522269330。只修改独立视觉适配器、新增美术与测试；没有修改碰撞、地图、AI、Boss、掉落、经济或Profile10，也没有访问正式玩家档。

## 根因与方案

旧RoomVisual把128px墙面直接缩放成16px碰撞条，墙面没有独立的立面和压顶。障碍只根据coffin_style选同一张棺材图，四角相同几何就成为四个同样的箱子。地面虽已无缝，但没有边缘积灰、物件接触和门槛过渡。旧光源数量有限且缺乏基础模式中的接触阴影。

RoomVisual保留原TileMapLayer、原墙碰撞矩形和两个Light2D。TombSpacePiece仅把原矩形解释为建筑或陈设，TombSpaceFloor仅绘制地面叠加层，均不创建物理体，不消费玩法RNG。地域隔离先读取现有SiteLootProfile，非FORMAL_DEFAULT不启用晋北空间（包括没有地区motif的Boss Arena）；再检查HAN_BRICK/TANG_MURAL。洛阳、关中仍走原地域视觉，不套用晋北陈设。

## 墙体

北墙压顶14px、立面36px，向室外扩展34px；原16px碰撞不变。侧墙向外扩展28px，形成44px压顶面；南墙以14px压顶、28px外侧立面收边。纹理采用原墙素材的原像素裁切重复，不把整张纹理拉成细条。砖缝、顶沿高光、凹壁龛和小破损由独立建筑绘制补充。

墙根低透明度压暗、墙边灰尘与门槛接触带位于地面层。实际Door.WIDTH和原墙段负责门洞，没有在开口新增碰撞或假门。建筑的厚度主要向室外展开，不侵占可走地面。未新增“绕柱”Boss障碍。

顶部信息在新晋北视觉模式仅收紧Y位置：标题6、HP/房间/敌人数44、Seed/进度/深度72，为北墙留出空间；不改文字、字体、按钮或HUD业务逻辑。legacy和旧空间比较恢复原20/64/106/108位置。没有新UI系统。

## 陈设与主次

新增一套六物件透明像素图集：石棺、木棺、棺床、石柱、残损供案、陪葬陶罐。每格128×160，全部DRAFT，原始生成图和确定性规范化工具保留。石棺有收口棺盖和雕刻，木棺有旧漆、铁箍，棺床为空石台，柱有柱础/柱头，祭台有破损和供器。

障碍形状优先决定表现：小型短障碍为石柱，明显横长障碍为供案，其余按原Encounter ID的固定算术哈希与障碍索引分配石棺/木棺/棺床/供案。四个相同矩形不再共用一张箱子图。图像脚底落在原障碍end.y，最多向上投影18px；底座仍明确覆盖实际碰撞矩形。

保持原Geometry不变意味着原四角障碍位置仍然对称。本轮通过材质、器型和空棺床建立主次，不声称已重新布置物理布局。没有为了美术把主棺移入原先开放的战斗区。

## 地面与光影

12A.1的96×96无缝石地文件字节不变。新增墙边12px渐变压暗、少量外围磨损和罐片、障碍脚下10px软投影及积灰、真实门连接上的淡色门槛。中央战斗区不铺随机大裂纹或高对比碎片。

Boss房中央增加平嵌地面的低对比石质仪式台刻痕，不增实体障碍、碰撞或危险区。事件与古董内容仍由原系统实例化，没有用装饰取代交互物。

玩家保持61px身体、脚底锚点和身体/武器分层；仅在脚底13px增加半径15px（横宽30px）、纵向比例0.23、低透明度接触椭圆。未改射击原点或碰撞。

基础模式已有烘焙的墙根、物件及脚下接触影，墙边有低强度暖色池。增强模式继续仅启用原有两个Light2D（无新增实时灯）。结构底面为冷灰、木棺及局部光池偏暖，不以大幅压暗掩盖素材。

原BossTelegraph/EncounterHazard显示优先级不足以保证高障碍前的预警可见。视觉适配器只记录原Z并在新晋北模式把这些真实节点绘制Z提升至1100；legacy/旧空间恢复原值。弱引用清理卸载节点，不修改危险范围、计时、伤害或AI。地面叠加层Z=-90，仍在危险与人物下方。

## 真实截图

所有截图来自实际Godot渲染器，无HTML/概念图替代。正式内存GameFlow通过地图确认晋北，实际WASD/Door进入第一COMBAT；比较时只暂停Enemy物理，保证静态对象一致。恢复AI后用真实Weapon/Projectile清房，再通过真实门路线进入事件、古董和Boss房。

- [原提交实机图](screenshots/phase_12a2/combat_before_original.png)：e4f8cdd的12A.1 body_20.png原字节。
- [旧空间同帧比较](screenshots/phase_12a2/combat_before.png)：只切换旧墙/障碍视觉，保留当前角色与光源。
- [标准战斗房基础](screenshots/phase_12a2/combat_basic.png)
- [标准战斗房增强](screenshots/phase_12a2/combat_enhanced.png)
- [事件房](screenshots/phase_12a2/event_room.png)
- [古董房](screenshots/phase_12a2/antique_room.png)
- [Boss战实际画面](screenshots/phase_12a2/boss_battle.png)
- [Boss清场/出口](screenshots/phase_12a2/boss_room.png)
- [玩家墙边](screenshots/phase_12a2/player_wall.png)
- [玩家棺旁](screenshots/phase_12a2/player_coffin.png)
- [玩家门口](screenshots/phase_12a2/player_door.png)

程序驾驶器掌握路径与敌人位置，不代表普通玩家已认可空间、难度或可读性。

## 测试与性能

最终Godot共340,789项检查，0失败；Python118项，0失败。历史/11I共67组340,404项（含零资产真实30日834项）；Phase12三模式与事件152项；12A.1专项67+28项；新空间headless/graphical各43项；地域隔离各18项；原性能7项、新性能9项。导入无解析错误，正式内存入口/地图/真实门及战斗流程通过。完整分组证据见screenshots/phase_12a2/validation_results.json。

RTX2070SUPER、Compatibility、1280×720、关闭VSync；同一真实首战斗房冻结敌人，预热1秒、采样3秒。旧空间对照共用当前玩家脚下阴影，不等于旧版本全程序二进制。182节点，未新增实时灯。

| 模式 / 空间 | FPS | P95帧耗时(ms) | Draw calls | 纹理MiB |
| --- | ---: | ---: | ---: | ---: |
| legacy/新空间 | 428.8 | 8.800 | 175 | 18.61 |
| basic/旧空间 | 743.2 | 2.809 | 143 | 18.61 |
| basic/新空间 | 627.5 | 2.919 | 225 | 18.61 |
| enhanced/旧空间 | 701.7 | 2.645 | 144 | 22.61 |
| enhanced/新空间 | 595.9 | 3.032 | 226 | 22.61 |

基础新空间draw calls比旧空间增加82，增强也增加82，FPS下降约15%（当前显卡短采样）；不宣称没有性能成本或低端硬件已验。legacy首轮采样受预热/系统波动影响，不作跨模式优劣结论。该表是冻结场景渲染测量，不是完整战斗性能保证。原性能脚本结果及真实截图另保留于screenshots/phase_12a2/regression/，低端性能与艺术质量待人工审核。

完整命令：

```powershell
python -m unittest discover -s database/tests
godot --headless --path . --editor --import --quit
python tests/run_phase_11i_qa.py --godot GODOT_CONSOLE --history --graphical --long-run
python tests/run_phase12_qa.py --godot GODOT_CONSOLE --graphical
godot --headless --path . --script tests/phase12a1_smoke.gd
godot --path . --script tests/phase12a1_graphical.gd --fixed-fps 60
godot --path . --script tests/phase12a2_space.gd --fixed-fps 60
godot --path . --script tests/phase12_benchmark.gd
```

原历史断言保留。新增专项验证实际门通行、原碰撞快照、四类真实房间、真实攻击清房、预警优先级/恢复、HUD紧凑布局/恢复、80HP/8格/Profile10和原地图signature。Python另检查六图透明/完整、无物理/全局随机/玩法写入、原人物和地面字节。

开发期曾捕获并修复视觉适配器显式RoomController引用导致的循环加载依赖。专项的临时无伤预警夹具也曾在入树前停物理、被引擎重新启用而提前释放，已改为入树后停物理；未取消断言。另有一次并行图形流程在首Boss路径返回false（13项、1失败），没有脚本解析错误；当时另一个原生图形窗口在运行。保留失败日志；单窗口基本模式独立复验30/0，随后完整视觉串行重跑的基本模式再次30/0。未修改战斗或断言。窗口焦点干扰仅是待验证解释，不冒称已确定根因。最终结果只计完整重跑，未把早期失败当成通过。

## 素材与待验

使用内置imagegen生成原创六物件透明图集，tools/build_phase12a2_assets.py只裁切/最近邻规范化至原生格，不重绘原图。源图assets/art/sources/tomb_props_original.png；运行图assets/art/tomb_props.png；manifest逐文件SHA与DRAFT状态。生成提示见sources/GENERATION_NOTES.md。不引用真实文物馆藏身份，没有第三方图片下载。

仍需人工确认：墙体厚度/高度是否舒服；平移视角下棺床与碰撞底座是否容易理解；物件对不同长宽矩形的适配；四角原拓扑仍对称时的主次；墙边灰尘和暖光是否过多；人物/弹丸/预警的整体可读性。为守住原碰撞，图集按既有矩形进行纵横适配；细长矩形上的柱/棺体可能显得过瘦，横长矩形上的棺体可能偏扁，未冒称每尺寸专门绘制。若人工审核不通过，应增加横向/细长专用资产，而不是扩大碰撞。生成像素材质及雕刻不冒称真实晋北墓葬复原。

地域隔离专项另从真实地图进入洛阳/关中并过真实门，Boss房仅直接装配用于无motif边界测试，不冒称武器完整流程；完整两地区流程由原11B回归验证。额外截图为LUOYANG_EAST/GUANZHONG_MOUND的combat_unchanged及arena_unchanged。

Boss本体、其它敌人、42件古董和地域美术缺口保持，未扩展正式美术阶段。所有新增素材与建筑效果DRAFT/PENDING_USER_REVIEW，自动测试不能批准艺术质量。

隔离试玩：tests/phase12_playtest.gd通过正式地图/真实门进入Seed522269330第一战斗房，内存档，空格开始，F6三模式。停止在本轮，不合并main，不继续新阶段。

