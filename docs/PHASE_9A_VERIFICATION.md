# Phase 9A：墓室风险选择与隐藏探索

## 范围与基线

基于已合并 main `b74bb35d4e7d4059f8272681f7fb8652629e7e18`，分支 `codex/phase-9a-tomb-risk-exploration`。仅本阶段墓内可选探索，提交并 push，不合并 main，不进入 9B。Godot 4.6.2 / Windows / Compatibility。

玩家仍80HP、0.25秒有效受伤无敌；背包8格；现有两类敌人、两Boss、武器与遗物2/4/7数值没有修改。没有新增博物馆、永久战斗成长、容量、敌人种类、Boss、消耗品或长期状态系统。

## 事件结构与所有权

| 模块 | 责任与生命周期 |
|---|---|
| TombRiskEvent / Resource | 只读ID、名称、类型、四结果权重、HP代价、波次、奖励策略 |
| TombRiskResult / RefCounted | 已结算类型、实际伤害、奖励ID、伏击完成；纯数据，无Node/Museum/存档 |
| TombRiskService / RefCounted | 本层一次性账本，`room/event`键先登记，再执行副作用；独立RNG |
| TombExplorationPlan / RefCounted | 原图之后复制节点、配置事件、附加可选汇合绕路和暗室；不修改生成器或共享模板 |
| TombExplorationConfig / Resource | 0.65绕路、0.65暗室、0.5独立祭台候选概率；无可用网格则省略 |
| TombRiskContent / Node2D | 当前Room局部交互、波次与既有AntiquePedestal装配，切房一起销毁 |
| TombRiskInteractable / Node2D | 64px、E查看/E确认、Tab取消；确认面板显示携货格数/价值、风险说明 |
| HiddenRoomEntrance / Node2D | 墙内24px的裂缝；E检查，再E进入；暗室E返回 |
| RoomController | 唯一Player、RoomState、探索账本；过门/暗道均冻结输入后延迟切换 |

START/ANTIQUE/SECRET/TRAP为安全入房政策，仍复用room.tscn。TRAP在本阶段表示可选事件偏殿，不是自动扣血机关房。普通RoomState仍单向UNVISITED→ACTIVE→CLEARED；清房后伏击是独立局部波次，暂时关门，不把RoomState改回ACTIVE，不重复COMBAT清场或遗物奖励。HUD显示“伏击中·门已关闭”。伏击敌人接入Room.damage_targets与现有遗物战斗Hook。

## 生成与出现频率

基础主图仍由原DungeonGenerator生成8～12房的正交树，START/BOSS/ANTIQUE位置、模板、深度及普通邻接保持。探索层可增加两间汇合绕路房和一间暗室，因此运行时最多15房；历史Phase3的8～12房约束继续针对基础主图。

绕路从合适COMBAT↔COMBAT连边旁的空网格选择一个方形：原安全边长1保持，新增路径长度3（风险棺椁→15HP祭台供物→原另一端）。不会新增更短的Boss路径。每层最多一处循环，不强制选择。入口血迹、暗色地面和供台表达风险，没有战力/危险度数值UI。

暗室附加到COMBAT旁的空格，用独立交互暗道访问，不加入普通Door邻接。未发现时不画小地图、不计可见房间总数；发现后本层可显示和重访。Boss和主路径完全不依赖它。没有炸墙或永久探测。

每层1～2棺椁、0～1暗室、0～1祭台、0～1绕路。若同时有绕路与暗室，棺椁分配到风险路线与暗室，祭台位于绕路奖励房；暗室另有高价值供物。无绕路但有暗室时，暗室为供物+祭台。候选不足时省略相应附加内容，不重试到必出。

Seed 0～99固定测试样本：60层有暗室、56层有绕路；四种棺椁结果都出现。这是本版本样本分布，不是保证每层出现或最终平衡结论。

## RNG与一次性边界

探索/事件版本1。以现有稳定字符混合 `AntiquePool.stable_score(run_seed, floor_number, room_id, source_id, version)` 派生私有RandomNumberGenerator，不调用全局随机。棺椁source为事件ID；奖励为`risk_reward:<id>`或`high_reward:<id>`；探索候选和存在性使用独立`exploration`键。Floor Seed继续采用旧Session规则；同一Run Seed、楼层、房间与事件ID在同引擎/配置/版本下结果固定。

正式棺椁权重：古董50、伏击25、机关15、空棺10。伏击配置两只现有尸蟞，继承本房Tier、0.35秒观察期；动态出生点避障、相距至少80px、距玩家与四入口至少180px。清掉后产生一件普通池古董。机关/祭台走Health.take_damage及damaged/died信号，并显示受伤红闪；主动风险代价不会被短暂无敌免单。祭台固定请求15伤害，可致死，一次生成RARE/TREASURE池供物；不是保证TREASURE。

数据账本先resolved，交互层再锁确认，快速E不能重复伤害、刷怪或出货。领取仍用原RoomState.claimed_loot_sources；满包不消耗底座，未领取重访重建原件，领取后即使丢弃也不重生。死亡后的供物不可拾取；死亡结果先快照已有背包再清空，不能直接写入MuseumCollection。

R：同Seed同图，重建账本/发现/背包。N：新Run。跨层：新账本，既有Carry保留已领取古董/HP/遗物，旧事件节点与临时敌人不跨层。墓中退出：事件、HP、背包均不保存，恢复上一安全地面。

## 程序驱动真实流程

主流程仅使用正式资源/概率，不通过inventory.add、MuseumCollection.add或HP注入造收益；正常AI保持开启，伤害来自真实Weapon/Projectile，门通过WASD触发Door，事件与拾取用真实E，背包用Tab/Delete，撤离用F，回馆用E。测试驾驶为选安全位置会直接设置玩家位置，不把它称为人工手感或纯人工路径移动测试。

### 成功撤离，Seed 33

正式GameFlow Day1空馆→情报板E→真实夜晚→清普通房并E拾取既有古董→Door到RISK_PATH→两次E开正式古董结果棺椁→墙缝两次E进入暗室→E确认供物与危险棺椁→E返回→Door到RISK_REWARD→祭台两次E支付15HP。

奖励多次遇到满包，实际E失败、原件仍在、Tab/Delete释放空间后再E领取；共丢弃4件。本次4个事件结算。后续真实战斗、获得正式遗物、击杀大帅尸，最终HP65，F撤离。

带回4件：金丝玉佩×2、唐三彩马、战国错金银铜镜，总基础估值 **¥7,200**。E回Day2，4件均成为未鉴定OwnedAntique，品相与原RunResult一一对应，现金仍0。Boss程序驾驶战斗15.10秒，仅记录程序执行时间，不作为人工平衡时长。

### 贪心死亡，Seed 33第二晚

Day2再次情报板E下墓→真实战斗开风险棺椁→暗室供物/棺椁→祭台→携带 **¥5,000** 古董继续探索→真实敌人持续攻击致死。结果为DEAD，快照记录遗失¥5,000，当前背包0格。E回Day3没有新增馆藏，前一晚4件安全馆藏与现金0保持。

### 单项边界与隔离

四结果单项夹具使用明确强制权重覆盖古董/伏击/机关/空棺，只有边界单元测试直接构造满包和15HP致死点。另一次正式Enemy AI伏击由真实武器击杀，验证一次关门/开门，不重复遗物进度。

实际不开任何事件与打开全部事件的双Run对照：完整布局、实际普通敌人位置/资源/实例HP/伤害、Boss参数、遗物序列、普通古董源/定义相同。另重跑开启探索的8D市场隔离：出售过古董、待拍与真实拍卖结算均不改变Dungeon快照。Museum等级隔离保留于8B回归。

夜间祭台扣血/真实E带货之后，ProfileStore.save_count不变；销毁Flow重建恢复Day1安全地面、空馆藏；重新下墓80HP/空背包/新账本。仅测试in_memory或user://tests/phase_9a隔离路径，未触碰正式存档。

## 自动验证结果

| 套件 | 检查数 | 失败 |
|---|---:|---:|
| Phase1 | 27 | 0 |
| Phase2 | 204 | 0 |
| Phase3 | 94 | 0 |
| Phase4 | 105 | 0 |
| Phase5A | 61 | 0 |
| Phase5B | 236 | 0 |
| Phase6 | 164 | 0 |
| Phase6.5 | 174 | 0 |
| Phase7A | 306 | 0 |
| Phase7B | 722 | 0 |
| Phase8A | 482 | 0 |
| Phase8B | 305 | 0 |
| Phase8C | 297 | 0 |
| Phase8D | 2,153 | 0 |
| Phase9A headless | 1,061 | 0 |
| **15套headless合计** | **6,391** | **0** |
| Phase9A graphical（另计） | 1,061 | 0 |

导入解析无错误；正式GameFlow入口headless和graphical启动正常。图形程序真实执行全部专项流程并截图，已查看确认面板、墙缝、供物、满包和结算画面。截图/日志在忽略目录logs/，不提交生成物。

历史测试只在原主图相关夹具显式设置exploration_enabled=false（Flow为tomb_exploration_enabled=false），全部原断言保留。生产默认true；9A专项/完整Flow/开启探索的隔离对照均默认开启，不能通过关闭生产探索来通过9A。5B战斗驾驶默认32次尝试不变，9A完整驾驶用128次且检查弹丸半径墙边余量，解决新Seed站在墙角只中心线通视而弹丸被挡的问题；游戏代码/数值没有为驾驶修改。

```powershell
$godot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path . --editor --quit
foreach ($phase in @('1','2','3','4','5a','5b','6','6_5','7a','7b','8a','8b','8c','8d','9a')) {
    & $godot --headless --fixed-fps 60 --quit-after 150000 --path . --script "tests/phase_${phase}_smoke.gd"
}
& $godot --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 150000 --script tests/phase_9a_smoke.gd -- --capture
& $godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase_9a/startup_final.json
& $godot --path . --position -16000,-16000 --quit-after 10 -- --profile-path=user://tests/phase_9a/startup_graphical_final.json
# 人工试玩独立夜晚（不读写地面存档）：
& $godot --path . res://scenes/main/dungeon_test.tscn -- --seed=33
```

## 新增与修改文件

新增：scripts/dungeon/events/下event/result/service/content四脚本；scripts/dungeon/interactables/下风险交互与隐藏入口两脚本；scripts/dungeon/tomb_exploration_plan.gd、tomb_exploration_config.gd；data/dungeon/events/下exploration_config、quiet_chamber、coffin_wave、stone_coffin、risk_altar、hidden_reward六资源；tests/phase_9a_smoke/data_checks/interaction_checks/lifecycle_checks/flow_checks五脚本；本验收文档。所有新增GDScript对应.uid纳入Git。

修改：DungeonSession、GameFlow（默认开启探索的装配开关）；RoomController（账本/局部内容/暗道/可见地图）；Room（安全特殊房、局部伏击目标/门禁）；RoomTestHUD及其场景（标题/伏击状态/可见房数）；历史测试夹具phase_3_smoke、phase_4_room_checks、phase_5a_smoke、phase_5b_smoke、phase_6_smoke、phase_6_5_smoke、phase_7a_smoke、phase_7b_smoke、phase_8a_smoke、phase_8b_progression_checks、phase_8d_flow_checks；phase_5b_run_checks测试驾驶扩展；AGENTS/README/ARCHITECTURE/PROJECT_PLAN。

## 人工手感验收

已打开可见独立夜晚试玩窗口（Seed33），请求不用F2进行实际游玩。**人工反馈待完成**，不以自动/图形驾驶代替以下主观结论：

| 人工观察 | 当前结论 |
|---|---|
| 墙缝可发现但不突兀 | 待人工反馈 |
| 棺椁风险提示清楚 | 待人工反馈 |
| 是否有“要不要开”的犹豫 | 待人工反馈 |
| 祭台15HP是否形成压力 | 待人工反馈 |
| 风险路线收益是否值得 | 待人工反馈 |
| 事件频率是否过高 | 待人工反馈 |
| 是否频繁打断战斗节奏 | 待人工反馈 |
| 满包是否产生真实取舍 | 程序流程已验证容量与操作；主观取舍待人工反馈 |

目前可以确认HP、携货价值、背包空间、未知棺椁结果同时进入选择流程；**不能据此宣称玩家的主观犹豫已比8D更强**。

## 已知限制与停止边界

隐藏房使用交互暗道而非普通Door邻接；发现后显示独立地图格，当前没有专门暗道连接线。不是每层必出。风险路径可从两端进入，供物代价各自确认，不要求按固定事件顺序通行。祭台等确认暂时停止玩家移动/射击，仅允许清场时开始，不支持战斗中交互。

占位几何美术；高价值池仍可能出现较大占格物品，没有最终经济/频率/手感平衡。没有中毒、诅咒、复杂机关、消耗工具或秘密探测。基础主图8～12，附加房可超过12；这是显式探索装配范围，不是生成器原约束失效。

测试存档恢复覆盖同进程销毁重建Flow；夜间本来不保存中途状态，没有新增事件存档。复制拓扑仍共享只读RoomDefinition，没有复制共享数据作难度增长。核心脚本均远小于1000行，无第三方依赖。

本阶段提交并push后停止。未经单独授权不合并main、不开发9B。
