# Phase12A.4 晋北墓室布局实验V1（DRAFT）

基线18dffab07c93ff67df3cde0ded516f2aea1c492c；当前美术分支，不合并main，不操作正式玩家档。

## 实验边界与架构

三个新RoomGeometryDefinition位于tests/fixtures/phase12a4，仅tests/support/phase12a4_lab.gd读取独立池LAB_JINBEI_V1_DRAFT。实验版本LAB_VERSION=1，正式GEOMETRY_VERSION仍2，Profile仍10。复用现有RoomGeometryPlan.pick/build、RoomGeometryValidation、Room、Spawner、Door、Weapon、拾取与清场逻辑，没有另一套地图生成器。生产代码/场景/数据不引用实验池。

正式GameFlow内存档通过情报地图选择晋北Seed522269330，真实Door进入原首战斗房。对照采用原SIDE_CRYPTS（视觉四角）几何，未另换FOUR_CORNER_COFFINS模板。实验仅替换此内存RoomGeometryPlan.assigned的一项；DungeonLayout、Encounter定义和正式随机流不变。

隔离选择器每次新建内存GameFlow，重新走原地图/门入口，避免死亡、奖励或前一布局残留影响下一局。实验室Room重装载时明确恢复80HP，作为新夹具起点，不在正式运行中自动回血。所有实际阻挡来自Geometry.obstacles构建的原StaticBody2D；装饰不添碰撞、不画假通道。

## 三种构图

### A 主棺墓室

中央偏北160×128主棺，西侧80×128陪葬木棺，东北144×48祭台及西北48×64柱。主棺前为低对比平面仪式铺砌；四面绕行空间由实际矩形与24px验证裕量约束。主棺不是一个覆盖开放区域的假Sprite。起点统一南入口，避免角色看似站在棺盖上。

### B 盗掘墓室

错位棺床两段136×64、88×48，南侧104×56木棺残存、东北柱、侧边112×48供案。分段之间有真实空隙；损坏线与少量拖拽痕迹表达盗掘方向，不铺碎石地毯。新增第二段是在原生预览后形成更明确断裂主设施的实验修订，未加入生产池。破损表面不在完整实体矩形上画可通行洞。

### C 侧室/陪葬室

西北168×56靠墙台、西南96×96台、东侧72×168长石台、东北112×64设施，前后错位，不形成四角镜像。小面积侧向铺砌指向服务空间；没有必须居中的主棺。宽长台上复用等比陈设，存在石座显得过空的美术缺口，未通过拉伸消除。

视觉角色、仪式铺砌、损伤/拖痕只由测试专用decor接入。既有像素图集最近邻/统一比例使用，不新增授权未知图片。所有表现DRAFT游戏原型，不冒称真实晋北年代形制已考证。

## 功能验证与隔离夹具

每种布局使用相同原Encounter：实际5个敌人、既有AI、参数与武器。几何通行阶段暂停敌人和环境，同时关闭这些冻结敌人的身体碰撞，避免它们作为静止路障挡住测试驾驶器；墙、主棺、平台和玩家碰撞始终开启。随后明确恢复全部敌人身体碰撞及AI，验证实际攻击、局部绕障、圆形实体不穿墙、敌人死亡及开门。AI是既有探针/沿墙避让，不冒称新增Navmesh寻路。

测试只将本层陪葬匣选源指向实验房，保证每种布局都有一次掉落位置验收。这是明确的内存掉落夹具，不是生产预算/概率改动，也不以inventory.add替代拾取。实际Weapon清场→Room生成匣→行走→E领取→Door进入相邻START→再真实过门重访；实例卸载及不重刷断言保留。

实验A/B/C使用已有SPIKES环境类型和默认8伤害/0.8秒预警规则，位置(704,488)，与四入口都保持大于预警半径+玩家16px的净距。没有调整敌人或现有环境的全局定义。对照保留原环境，故活动战斗测量也包含不同Geometry环境开销，不是只比较静态遮挡物。

## HUD与调试边界

发现原正式GameFlow会显示伤害测试、新Seed按钮，F2还可打开遗物调试按钮。新增视觉侧player_hud_boundary只在正式GameFlow层级隐藏这两按钮、关闭RelicDebugPanel调试输入并去除工具提示文本；遗物名称/数量继续显示。Standalone历史测试入口保留原调试行为。未重写RoomTestHUD/RelicDebugPanel核心方法，不更改InputMap、R/N/F1旧控制器动作。F1旧测试快捷键是保留的开发输入缺口，发布输入策略待另行审查；本轮确保正式界面不显示上述调试按钮。

隔离实验UI独立在tests/phase12a4_playtest.gd：四个布局按钮、开始/暂停按钮及简要帮助。切布局重置隔离本局，菜单不进入正式场景。R重开当前实验，N由测试专用输入守卫拦截以保护固定Seed；正式R/N控制器未改。隐藏实验视图中的长标题、Seed/深度/进度、旧菜单与小地图，避免遮挡；正式全局顶部不重排。

后续正式HUD层级方案（本轮未自动实施）：一级常驻HP、战斗/锁门状态、剩余敌人；二级携货槽位/价值与交互提示；三级Seed、Tier、调试数据和完整图例折叠到开发面板。Boss时保留血条优先。需人工确认信息取舍后再全局重构。

## 失败及修复

新增测试首次有枚举WARN命名错误、WeakRef类型推断及常量预加载资源类型别名冲突，已改为实际枚举/明确类型/运行时typed资源加载。没有改正式资源模型。

第一轮运行391项、32失败：冻结敌人仍阻塞静态路线；矩形扩张误报圆形敌人贴角。将几何测试与活动敌人测试分离，并改为圆心到矩形最近点距离，0.5px物理容差。随后补充敌人碰撞恢复断言。未取消通行/清场/拾取断言，历史断言不变。

新增Python源码哈希第一次因Windows CRLF/Git LF差异失败；只规范换行后比较全部内容，不忽略任何代码差异。最终结果见下。原生入口截图另发现地刺覆盖初始站位，已仅在实验资源移开并新增三项四入口净距断言；选择器截图增加两帧等待以刷新最终提示，不改正式资源。

## 截图、统计、回归与性能

最终Godot 342,148项，0失败；Python123项，0失败。历史/11I 67组340,404项（零资产30日834），Phase12八组152；旧12A.1～3专项329、原性能7；本轮headless/graphical/活动基准各408项，实际选择器32项。导入正常，全部旧断言保留。分组退出码/失败标记见validation_results.json。

| 布局 | 障碍 | 墙+障碍 | 门阻挡 | 原面积可用 | 24px裕量可走格 | 连通 |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| 旧房 | 4 | 10 | 2 | 95.04% | 84.62% | 通过 |
| A主棺 | 4 | 10 | 2 | 92.11% | 80.44% | 通过 |
| B盗掘 | 5 | 11 | 2 | 94.58% | 82.20% | 通过 |
| C侧室 | 4 | 10 | 2 | 92.66% | 83.08% | 通过 |

面积比是Room.ROOM_RECT减矩形面积，非身体可达性。可走格来自原验证器455格/24px裕量，包含中心及四入口洪泛；门阻挡单列，未把Area2D触发形状算成实体障碍。各房原Encounter均5敌人。

| 布局 | 活动战斗FPS | P95(ms) | Draw Calls均值 | 纹理MiB | 采样秒 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 旧房 | 636.8 | 2.601 | 224.6 | 23.19 | 3.000 |
| A主棺 | 619.4 | 2.671 | 233.3 | 23.19 | 2.999 |
| B盗掘 | 630.9 | 2.631 | 232.8 | 23.19 | 3.001 |
| C侧室 | 729.3 | 2.114 | 225.5 | 23.19 | 3.000 |

性能来自RTX2070SUPER / Godot4.6.2 Compatibility / 1280×720。未设置fixed-fps、关闭VSync，物理仍正常60Hz，1秒预热后约3秒实际战斗窗口，NPC/武器/环境均启用，没有PNG写盘或录帧。逐房按旧/A/B/C顺序单窗口测量，各种几何/环境导致不同真实行动与弹丸数，因此是活动场景观测，不是纯静态GPU隔离实验，不宣称跨硬件或稳定优劣。B有5障碍，其他4；未通过减少敌人数提高帧率。

实际避让标记：新A/B/C都观察到_avoid_remaining>0且移动/无穿墙/清场断言通过；旧房本次没有触发该标记，不伪造为发生过。没有修改Enemy.move_actor。四种布局都用真实门离开并重访，不重刷；旧Room弱引用释放。实际选择器鼠标四按钮、R重开及N固定Seed验证通过。

正式算法、池与原Geometry资源和HUD核心脚本均与基线规范换行字节一致，由新增Python及原freeze保护。旧v1～9读取/迁移、Profile10磁盘往返/冲突保护、三地区、双生尸煞/经营与经济在历史回归中通过。Meta显示边界不存入玩家档。

原生截图命名0旧房、1A、2B、3C，均1280×720：static_basic/static_enhanced、door_approach、obstacle_circuit、actual_warning、input_combat、drop_claimed、door_traversed、lab_selector。colliders_debug用原生绘制读取实际Walls/CollisionShape2D，不从视觉图反推矩形；仅截图夹具暂时显示，不加入正常画面。

每种有24张活动战斗采样帧motion_000～023，每12模拟物理帧一张，约4.8秒。GIF有256色限制，PNG保留原画质。tools/build_phase12a4_evidence.py复用逐帧RGB解码一致性校验的差分压缩，不改动作。四图拼接保留各1280×720原像素，标明拼接而不是另一张渲染。夹具/普通玩家体验区分明确，自动驾驶器掌握路线不代表人类能自然理解。

- [四布局原生截图轮播](screenshots/phase_12a4/four_layouts.gif)
- [四图原像素拼接](screenshots/phase_12a4/four_layouts_contact_sheet.png)（左上旧、右上A、左下B、右下C）
- [旧房战斗](screenshots/phase_12a4/0_combat.gif)、[A战斗](screenshots/phase_12a4/1_combat.gif)、[B战斗](screenshots/phase_12a4/2_combat.gif)、[C战斗](screenshots/phase_12a4/3_combat.gif)
- [A实际碰撞](screenshots/phase_12a4/1_colliders_debug.png)、[B实际碰撞](screenshots/phase_12a4/2_colliders_debug.png)、[C实际碰撞](screenshots/phase_12a4/3_colliders_debug.png)
- [A实际预警](screenshots/phase_12a4/1_actual_warning.png)、[B实际预警](screenshots/phase_12a4/2_actual_warning.png)、[C实际预警](screenshots/phase_12a4/3_actual_warning.png)
- 原生单图与入口界面完整保留在screenshots/phase_12a4/，不以GIF代替PNG验收。

复验命令：

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/phase12a4_smoke.gd --fixed-fps 60
godot --path . --script tests/phase12a4_smoke.gd --fixed-fps 60
godot --path . --script tests/phase12a4_smoke.gd -- --benchmark
godot --path . --script tests/phase12a4_playtest.gd -- --verify-switches
python tests/run_phase_11i_qa.py --godot GODOT_CONSOLE --history --graphical --long-run
python tests/run_phase12_qa.py --godot GODOT_CONSOLE --graphical
python -m unittest discover -s database/tests
```

## 人工待验与停止

- 四种构图是否确实改变绕行、射线选择与空间体验。
- 主棺视觉中心/祭台主次是否可信，A的南入口到主棺仪式轴是否舒服。
- B能否自然读成盗掘而非随机障碍，C能否读成侧室功能。
- 宽长石台是否需要横向/长条专用像素图；本轮没有拉伸。
- 障碍遮挡、预警、弹丸和密集敌人的辨识度。
- 是否接受当前原生HUD信息密度；方案尚未全局应用。

实验几何只准通过隔离入口启用；人工验收不等于批准进入正式随机池。完成只推送当前美术分支，不合并main、不继续下一阶段、不操作正式存档。
