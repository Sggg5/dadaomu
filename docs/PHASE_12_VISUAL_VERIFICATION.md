# Phase 12 视觉改造验收（自动验证记录；美术与真人体验待验）

基线a4ea1fcb34c87597b8b455f36420aa54485ad309，独立分支codex/phase-12a-hd2d-art，不合并main。正式Profile仍VERSION10。所有GameFlow测试注入MuseumProfileStore.in_memory；中期界面只读取11I自动游玩所得隔离夹具，不操作正式档。

## 实际实现与范围

PlayerVisual、EnemyVisual、RoomVisual、AntiqueVisual、MuseumDisplayVisual独立读取状态，旧_draw保留。BossVisual明确无专属素材，保留原Boss机制画面。

- 36个48×64角色帧：四方向探索者、尸蟞、枪手六姿态。玩家攻击姿态由真实attack_requested触发，红闪读取原无敌时间，精英标记、HP和前摇覆盖贴图而非被遮住。
- 32×32石板TileMapLayer、墙/棺材贴图、脚线排序、两盏局部PointLight2D、精确映射既有墙与障碍的LightOccluder2D。遮光没有Physics collider，射线和门碰撞不改变。
- 博物馆木地面、组合柜基底、八种家具、男女游客和三岗位职业形象。导览员仍是原真实NPC；鉴定/修复职业形象不另造员工行为或服务数据。设施原有47项绘制叠层与真实槽位循环保留。
- 原8件独立透明古董图，拾取/背包/库房/鉴定/展柜/独立档案共用ID；42件原分类图回退，不修改定义数值或自动批准研究媒体。
- 三模式：legacy旧绘制、basic贴图、enhanced贴图加灯光。F6运行时切换，或命令行--art-mode=legacy/basic/enhanced。设置不进入存档。
- 地面变体只由模板/Geometry标识和坐标整数哈希决定；不消费地图、Boss、遗物、古董或全局RNG。洛阳/关中原装饰保留，轻量色调映射不改布局。

本轮不是全游戏美术完成；北向部分动作一致性、Boss/其它敌人/42件古董和完整环境道具仍需制作，详见PHASE_12_ASSET_GAPS.md。

## 素材数量与出处

6次内置imagegen生成/编辑，保存6张原始PNG（包括NPC编辑前原图）。26张派生运行PNG，全部接入对应视觉查询；合计32张PNG。原始图目录.gdignore排除Godot导入，运行时仅按需读取派生图，不解析全球研究库。

assets/art/manifest.json保存26个稳定ID、尺寸/锚点/过滤、来源、作者、许可状态、派生方式和SHA256；全部DRAFT/PENDING_USER_REVIEW。PNG为本项目原创AI草稿，没有宣称CC0、现实馆藏身份或专家审核。sources/GENERATION_NOTES.md记录请求及编辑链。

## 命令

```powershell
& $godot --headless --path . --editor --import --quit
& $python -m unittest discover -s database/tests
& $python tests/run_phase_11i_qa.py --godot $godot --history --graphical --long-run
& $python tests/run_phase12_qa.py --godot $godot --graphical --benchmark
& $godot --path . --script tests/phase12_playtest.gd
```

本机Godot4.6.2，Compatibility/OpenGL3.3，RTX2070SUPER。Python使用Codex已提供运行时/Pillow，不引入Godot插件。

## 失败与修复记录

1.第一次历史回归与新增类同时运行，尚未导入的MuseumDisplayVisual/MuseumNPCVisual导致SCRIPT ERROR。完成导入后重新执行，未把用例输出的零失败当作通过。
2.地面哈希误读RoomDefinition.id，而正确字段为room_id。视觉专项实际50检查/3失败；事件专项虽输出零失败，错误检测仍拒绝SCRIPT ERROR与资源泄漏。改用room_id，重新执行最终验证。没有修改测试断言掩盖异常。
3.实机发现地面过密，离线降噪/降低对比度并扩大木地板单元；没有调整战斗参数。素材质量仍待用户判断。

最终结果、截图和性能数据在末尾附录记录；日志保留于被Git忽略的logs目录，不发布用户数据。


## 最终自动结果

- 导入正常，最终日志没有ERROR或SCRIPT ERROR。
- 历史59组338,474项，0失败；双生尸煞、三地区、存档迁移、经营和数据库隔离覆盖保留。
- 11I真实30日新档流程834项、两套三策略经营分析726项、两次磁盘往返138项、历史图形232项：全部0失败。
- Python112个测试全部通过。新增冻结清单保护520个原数据/非视觉脚本及已有功能方法；旧107个测试保留。
- Phase12视觉专项50项；三个真实图形新档闭环各30项，博物馆图形1/2/2项，事件/缺图回退7项，性能场景7项：共159项，0失败。最终错误检测包含进程返回值、失败数和SCRIPT ERROR/ERROR，不仅依赖FPS或末尾摘要。

### 原生渲染实测

同一Seed522269330、真实进入的第一战斗房、1280×720，关闭VSync，每模式预热1秒并采样3秒。只冻结物理以保证位置/敌人/障碍一致，动画与灯光继续；这是渲染快照，不是完整战斗或全场景稳定帧率保证。旧模式仍保留适配节点。测量时历史自动测试仍在后台，不能用于跨机器绝对性能结论。

| 模式 | 实测FPS | 墙钟p95帧间隔ms | Draw calls平均 | 纹理MiB | Nodes |
|---|---:|---:|---:|---:|---:|
| 旧绘制 | 693.0 | 2.453 | 175 | 17.51 | 171 |
| 基础贴图 | 477.5 | 2.984 | 626 | 17.51 | 171 |
| 增强光影 | 436.7 | 3.152 | 627 | 21.51 | 171 |

原始监控数据见screenshots/phase_12/performance.json；原生TIME_PROCESS可能含之前监控周期，不等同于逐帧墙钟延迟。FPS与p95使用实际墙钟计量。没有宣称全游戏稳定60FPS。

### 实机图

共54张真实Godot viewport PNG，无HTML模拟或概念图冒充。代表图：

- [晋北旧绘制](screenshots/phase_12/0_first_tomb.png)
- [晋北新贴图](screenshots/phase_12/1_first_tomb.png)
- [真实战斗](screenshots/phase_12/2_input_combat.png)
- [Boss房（专属美术仍回退）](screenshots/phase_12/2_boss_battle.png)
- [古董拾取](screenshots/phase_12/1_antique_pedestal.png)
- [事件房](screenshots/phase_12/1_event_room.png)
- [博物馆旧绘制](screenshots/phase_12/0_museum_composite_case.png)
- [博物馆组合柜](screenshots/phase_12/2_museum_composite_case.png)
- [古董档案](screenshots/phase_12/1_museum_dossier.png)
- [实际游客参观](screenshots/phase_12/1_museum_real_visitors.png)
- [缺图回退](screenshots/phase_12/1_missing_actor_fallback.png)

### 提交与停止

前七个独立提交：7392c0d、8962b6e、47487d9、f7ebf0f、7ca9729、7d522e3、595dcb6。第八个为本验收报告、完整测试、最终美术精修与隔离试玩所在提交，实际SHA见交付消息/git log。推送目标codex/phase-12a-hd2d-art；不合并main。

真人美术与体验验收未进行；全部素材DRAFT。北向动作、Boss与其它专属素材缺口未冒称完成。隔离试玩使用内存新档，经真实情报地图进入晋北Seed522269330，F6切换视觉模式。正式玩家档未读写，停止不进入新阶段。

## Phase 12A.2 空间返修追加

晋北墙顶/立面/墙根分层，六件原创墓室陈设透明图集，边缘积灰与接触影；基本模式也成立，增强模式仍两盏灯。原几何、门、出生、AI及掉落不改，61px主角/96px地面保留。真实四房样板与完整回归见PHASE_12A2_TOMB_SPACE_REWORK.md。仅DRAFT，人工空间验收待完成。

## Phase12A.3追加
晋北同房精修、等比陈设、门框与侵蚀、蜘蛛中间色调及静态绘制缓存；原功能冻结。真实截图、动态录帧、同机旧新性能及回归见PHASE_12A3_VISUAL_REFINEMENT.md。全部DRAFT，人工待验。

## Phase12A.4隔离实验
三种新Geometry仅实验池V1，正式GEOMETRY_VERSION2与Profile10不变；真实移动/避让/射击/拾取/过门及四布局原生截图、活动战斗性能见PHASE_12A4_LAYOUT_EXPERIMENT.md。正式UI隔离调试按钮，顶部重排仅方案；全部DRAFT、人工待验。

## Phase12A.5 A主棺样板

专属主棺/祭台/墓门/墓砖及静态接触光影只由隔离入口显式附加；原正式视觉与玩法不改。真实1280×720对比、绕棺/战斗GIF、性能和回归见 `PHASE_12A5_PRINCIPAL_TOMB_SAMPLE.md`。全部DRAFT，人工待验，不进入随机池。

## Phase12A.6 敌人与战斗视觉样板

先核实Encounter03为2尸犬/3尸蟞；粉褐矩形来自尸犬身体回退，不删除血条/前摇或环境危险。两类独立四方向64帧图、接触影、轻量真实攻击/命中反馈只在隔离A入口附加；正式玩法与A5建筑冻结，素材DRAFT。实际AI与受控帧测试分开、完整GameFlow武器清房/拾取/过门及性能证据见 `PHASE_12A6_COMBAT_VISUAL_SAMPLE.md`，不冒充人工验收。
