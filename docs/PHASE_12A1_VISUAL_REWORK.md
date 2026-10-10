# Phase 12A.1：角色与晋北地面返修（DRAFT）

基线：265ea6d95d25ee14859c5145ce9f96b4a505ed3c。分支：codex/phase-12a-hd2d-art。
Godot 4.6.2，Compatibility，1280×720，晋北 Expedition Seed 522269330。所有图像与动作仍待人工美术审核；程序测试不等于真人体验通过。未访问正式玩家档，Profile VERSION10不变。

## 三项根因与处理

1. **角色小且帧间比例不一致**：原48×64图集待机实际高度S/W/E/N为49/45/53/52px（58px只是最大容纳限制），逐帧裁切归一还会改变姿态比例。新增独立玩家4×4图集（原敌人actors.png完全不改），64×80帧，统一脚底线76。原生15/20/25三个版本的有效站立高度为58/61/63px。实机比较后选61px（相对S/N参考均值50.5px约20.8%；相对正面49px为24.5%、背面52px为17.3%），Sprite scale始终1，无运行时非整数拉伸。侧向旧帧因持枪外扩、错误裁切而偏矮，纠正姿态后不作单方向精确百分比承诺；宽度也不能作为精确同比指标。第一次按58px最大框估计得到70px，实测后弃用，最终为61px。
2. **地板接缝与重复**：原四块纹理独立降采样，然后逐32px单元随机散拼，不能保证纹路与亮度连续。新增96×96统一石地，由3×3的32px图块按原始相邻次序铺设。低对比16色，四边对向4px渐变、边缘像素一致，取消随机明暗块。第一次实机发现浅色边框造成96px大网格，已放弃该方案，最终采用对向配对混合。灰尘是墙/障碍底部低透明独立绘制；中央不铺密集裂纹或杂物。没有新碰撞或装饰实体。RoomGeometry和原有32px TileMapLayer位置不变。
3. **动作抽动/北向错误**：原身体直接跟随aim_direction，射击/受击分别强行切整身攻击/受伤帧；旧北向行走原画部分朝前。源图相邻行有少量像素越界，采用最大连通主体边界排除邻帧帽子碎片，避免侧身虚假高度。重做无持枪四向身体（S/W/E/N），纠正源图两个侧向行的方向顺序。身体由实际velocity选择朝向，8px/s阈值、12px/s对角迟滞；停步保持身体朝向。移动只用两步循环，起步重置步相，停止回待机。武器独立按360°aim绘制，仅有2px短后坐和枪口闪；真实攻击、子弹、发射点完全不写入。受击只染红、不抢占行走；死亡使用各方向独立卧倒帧、隐藏视觉武器。旧待机实际脚底偏移+10/+10/+10/+8px，与既有Z排序+12px不完全一致；新版统一为+12px（仅2～4px绘制锚点对齐，不移动物理位置），Z基准保持+12px。

## 实机证据

以下均是实际Godot viewport PNG，不是概念画或HTML。比较冻结敌人AI但保持玩家不变，之后恢复AI，通过真实武器清房。

- [原人物与原地板](screenshots/phase_12a1/before_body_floor.png)
- [新地板与原人物](screenshots/phase_12a1/after_floor_old_body.png)
- [15%](screenshots/phase_12a1/body_15.png) / [最终20%](screenshots/phase_12a1/body_20.png) / [25%](screenshots/phase_12a1/body_25.png)
- direction_0～3：四向后退射击；direction_4～11：八组斜向移动/瞄准组合。
- standing_0～7：原地八方向旋转鼠标，身体不突然转身。
- [受击](screenshots/phase_12a1/hurt_redflash.png) / [死亡](screenshots/phase_12a1/death_pose.png)：红闪使用原F1测试伤害；死亡是末尾专用take_damage终端视觉夹具，不用于证明敌人难度。
- mode_0/1/2：legacy/basic/enhanced。
- [动作演示GIF](screenshots/phase_12a1/movement_shooting.gif)：48张真实1280×720帧，120ms/帧播放（原采样50ms，2.4倍慢放），无补帧。各组合之间重返测试起点，片段间有剪切，不冒称连续录像。
- 原Phase12正式GameFlow图形回归覆盖真实Combat、Door、Boss房及事件房，证据归档于本目录regression/。

## 测试命令

```powershell
$godot = 'C:/Users/atian/Downloads/Godot_v4.6.2-stable_win64.exe/Godot_v4.6.2-stable_win64_console.exe'
$python = 'C:/Users/atian/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --script tests/phase12a1_smoke.gd
& $godot --path . --script tests/phase12a1_graphical.gd --fixed-fps 60
& $python -m unittest discover -s database/tests
& $python tests/run_phase_11i_qa.py --godot $godot --history --graphical --long-run
& $python tests/run_phase12_qa.py --godot $godot --graphical --benchmark
```

## 实际结果

- 返修headless：67项，0失败；新增缺图回退、方向与武器隔离、脚底、死亡、3×3拼接验证。
- 返修真实图形：28项，0失败；真实情报板/地图/门/战斗，12组移动瞄准、原地旋转、受击死亡。
- Python：115测试，0失败，含520文件及原核心方法冻结、源图SHA/DRAFT、像素边缘连续、三个图集脚底尺寸验证。
- 历史59组：338,474项，0失败。
- 11I零资产30日正式输入流程：834项，0失败。经营两套726项、磁盘两套138项、11I真实图形232项均0失败。历史加11I合计340,404项。
- 原Phase12：159项，0失败，50项smoke、三模式正式流程90项、博物馆5项、事件7项、性能7项。原断言全部保留。
- Godot总计340,658项，0失败；导入无SCRIPT ERROR/ERROR。逐组机器结果：screenshots/phase_12a1/validation_results.json。520原文件和83功能方法冻结校验通过；VERSION10和50种定义保持。

## 原生渲染采样

同一真实第一COMBAT，冻结物理以对齐画面，RTX2070 SUPER、OpenGL Compatibility、关闭VSync，每模式暖机1s/采样3s，后台仍有回归。原始数据见regression/performance.json。

|模式|采样FPS|帧间隔P95 ms|Draw calls|纹理MiB|节点|
|---|---:|---:|---:|---:|---:|
|legacy|678.9|2.727|175|18.0|171|
|basic|796.1|2.698|142|18.0|171|
|enhanced|781.5|2.661|143|22.0|171|

宏图集共用一个TileSetAtlasSource，避免原四来源随机拼接造成多次纹理批次；没有增加场景节点。原生TIME_PROCESS监视量与帧间隔不同且采样可能滞后，表中使用墙钟process_frame时间，不用它推算实际FPS。不声称整局战斗或其它设备达到此FPS。

## 文件及隔离

新增：player_body_15/20/25.png、stone_macro.png，两份DRAFT源图；tools/build_phase12a1_assets.py；两个Godot专项及Python专项；本报告、实机图与GIF。
修改：scripts/art/player_visual.gd、room_visual.gd；scripts/player/player.gd仅_draw；严格视觉SHA授权记录；manifest.json；隔离phase12_playtest.gd及协作说明。Player._draw仅取消新武器与旧瞄准线的重复绘制，并更新严格授权SHA；所有功能方法冻结检查仍保留。Player/Enemy/Boss/Room控制与碰撞、所有游戏资源数值、随机流、存档和研究数据库没有修改。

manifest逐文件记录来源与SHA；原actors、敌人、其它美术、古董图片保持原文件。源图不参与Godot导入。原32px四纹理与原actor保留缺图回退；F6保留三模式。

## 人工待验与限制

- 请确认61px体量相对棺材、敌人及战斗预警是否合适。
- 两步行走仍是首轮草稿，不是最终多帧上下身骨骼动画；身体保持移动方向、武器独立瞄准，后退射击不会把整个人扭成鼠标朝向。
- 96px纹理周期仍可能被观察到；目前避免了亮度格子与密集裂纹，但不声称完全不可察觉的自然石地。
- 墙边灰尘为轻量绘制，未扩展Boss/敌人/42件古董素材。
- 性能数据是相同冻结房间的原生渲染比较，不代表整局实战帧率。
- 隔离试玩由正式地图和Door进入第一COMBAT，等待时暂停，点击或空格恢复；F6切换，R/N保留原行为，不读写正式档。

完成仅commit/push当前美术分支，不合并main，不继续其它美术阶段。
