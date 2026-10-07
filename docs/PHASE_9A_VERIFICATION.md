# Phase 9A：墓室风险选择与隐藏探索

## 最终封版与人工验收：正式通过（2026-10-07）

用户已明确确认Phase9A/9A.1最终人工试玩通过，包括风险影响撤离/深入决策、满包/低HP贪心压力、真假墙面不直接暴露暗室、普通房假线索、无需刻意扫墙仍可自然发现、跨日换图/同日退出复现、正式两层回馆、Profile v4迁移及80HP/8格/原战斗参数保持。

最终结论：

> Phase 9A已经证明HP、8格背包、当前携货价值和继续深入之间能够形成真实风险决策。隐藏墓室采用真假WallMark后，不再通过专属视觉符号直接暴露答案。正式GameFlow跨日使用不同Expedition Seed，同一天异常退出后仍可稳定复现当前墓穴。

> 本阶段不继续调整风险概率、伤害、隐藏房频率或奖励数值，后续平衡等待多层墓穴结构完成后重新评估。

最终自动验收：Phase1～9A共15,840项、0失败；9A图形专项10,510项、0失败；导入与正式入口启动正常。封版只更新文档，没有新增生产代码改动，因此沿用上次完整回归，并补做导入/正式入口启动确认。

人工验收已正式完成。用户未提供逐晚开/不开数量等原始统计，不补造数字；下方早期“待反馈”表格仅为当时历史记录，全部以本节最终结论为准。授权一次性提交并push当前9A分支；不合并main、不进入9B，封版后停止。

## 正式下墓Seed生命周期实现与验证

修复GameFlow每天直接复用固定night_seed的问题，保留全部已有9A.1/WallMark工作区修改；不修改风险数值、WallMark规则、80HP/8格、DungeonGenerator/TombExplorationPlan/WallMarkGenerator或掉落/敌人/Boss/遗物算法。新增纯ExpeditionSeedService与3份Seed专项脚本及.uid。

### 生命周期与Profile v4

`campaign_seed → day_number → site_id(DEFAULT_TOMB) → expedition_seed → DungeonSession`。

MuseumState.campaign_seed默认0，表示尚未初始化；正式有效范围1～2147483647，JSON数值精度安全。MuseumProfileStore VERSION=4新增字段，v1/v2/v3保留馆藏、鉴定/品相、展柜、等级、现金、日期、next ID和v3待拍，纯decode不随机，暂留0。GameFlow启动时才初始化并保存：测试campaign_seed_override可指定确定值，生产默认0则独立RNG生成一次。已有有效Campaign永久保留，即便后续传入不同override也不重写。

非法v4 campaign字段（缺失/0/负数/超界/小数/字符串/bool/null/非有限值）安全修复为待初始化，保留其他合法地面数据。直接保存未初始化0拒绝，不产生非法v4正式档。原museum_profile_v1.json路径保留。所有测试in_memory或user://tests/phase_9a1隔离路径，不读取/写入正式档。

ExpeditionSeedService.VERSION=1：`1 + AntiquePool.stable_score(campaign_seed, day_number, site_id, "EXPEDITION", 1)`，稳定字符混合，范围正31位，不使用简单相加/全局RNG/时钟。没有额外下墓计数器，拍卖消耗的夜晚也按同一日期推进。

### 实际三天与退出恢复

固定Campaign52，真实GameFlow从Day1空馆开始，forced_night_seed=0：

| 日期 | 实际Expedition/Run Seed | 路径 |
|---|---:|---|
| Day1 | 522269330 | 真实情报板E下墓、普通房/古董E、实际武器击杀第一Boss、F撤离、E回Day2 |
| Day2 | 1639431332 | 真实情报板E下墓、活跃敌人攻击致死、E回Day3 |
| Day3 | 609109687 | 真实情报板E下墓、记录当日图、R/N边界、直接退出不结算后重建/再下墓 |

三天Seed和空间签名均不同。Campaign始终52。Day3在墓中销毁Flow后重建恢复Day3安全地面，重新下墓仍为609109687及相同完整空间签名；N生成的临时Seed不保存，退出重进恢复正式当天图。R当前Seed/图完全一致。正式成功/死亡路径没有调用_finish_run伪造结果，战斗使用真实Weapon/Projectile/AI，古董通过E，地面与夜间入口使用实际WASD/E。

Day2鉴定/布展在真实地面执行；资金修复/升级隔离断言使用单独状态副本，不给真实三日流程注入现金。相同日期/遗址不会因这些地面操作重新播种。实际AuctionSession逐口E竞价→E回馆推进Day1→Day2，随后下墓正确使用1639431332；Campaign不受拍卖收入影响。

HUD始终显示实际Run Seed，tooltip保留当前Floor Seed；结果快照也为实际Run Seed。开发日志输出Campaign/Day/Site/Expedition，玩家UI不展开这些内部元数据。

### 迁移与CLI实际进程验证

构造正式v3磁盘档（Day5、现金2468、Level1、两件已鉴定/品相藏品、CASE4展出、HIGH待拍、营业统计和next ID）：纯decode全部保持、Campaign0。GameFlow用初始化override777加载并写v4；第二次启动即便override999，仍Campaign777，所有原字段相同。31位边界1/2147483647磁盘JSON往返精确。

两个独立Godot进程实际传入--seed=52：正式GameFlow初始化Campaign52，Day1为522269330、Day2为1639431332，子DungeonSession不再覆盖成52；独立dungeon_test的run_seed=52。CLI单位测试用正式Health死亡回馆驱动日期，真正活跃敌人死亡和Boss撤离另由上方完整流程覆盖。

```powershell
# 新测试档/旧档首次迁移：52是Campaign Seed，不是本次Run Seed。
godot --path . res://scenes/main/game_flow.tscn -- --seed=52 --profile-path=user://tests/phase_9a1/campaign_playtest.json
# 复现HUD报告的实际Run Seed，使用独立地宫入口：
godot --path . res://scenes/main/dungeon_test.tscn -- --seed=522269330
```

已有有效Campaign的存档不会被--seed重新播种；如需独立Campaign序列，使用新的隔离测试档。下方旧人工命令中的GameFlow--seed在当前版本均应按此新语义解释。

### 当前回归与工作区

旧固定Run功能夹具显式forced_night_seed，存档单位夹具显式有效campaign_seed；保留全部旧断言，新派生路径单独验证。v3字面版本断言改为当前VERSION；v1纯迁移后的直接保存单位夹具显式初始化Campaign，以符合v4正式规则，不在decode中随机。

Phase1～8D仍5,330项/0失败；当前9A headless **10,510项/0失败**，15套合计**15,840项/0失败**。9A graphical另计**10,510项/0失败**。导入/正式入口headless与graphical启动无错误。修复Seed生命周期同时保留WallMark、风险事件与真实两层回馆全部覆盖。日志logs/phase_9a1_seed_regression_*.log、phase_9a1_seed_graphical.log、phase_9a1_seed_import_final.log、phase_9a1_seed_startup*.log。

技术三天/退出行为由真实程序流程验证，最终用户亦已人工确认通过。按顶部封版授权提交push，不合并main、不进入9B。

## 9A.1墙面真假线索实现与验证

用户进一步反馈：原专属裂纹无论提示多小，仍等于“看见就知道是暗室”。本次改为**看见异常不等于知道答案**，保留石棺35/25/20/20、20HP机关、25HP祭台、普通棺椁0～1、暗室35%、绕路45%、80HP、8格等已确认参数，未进入9B。

新增WallMarkDefinition / WallMarkGenerator / WallMark及各.uid，统一真假外观和初始文案；新增phase_9a_wall_checks.gd及.uid。修改TombExplorationPlan、本层Controller装配、HiddenRoomEntrance（仅暗室返回）、9A真实探索/交互测试与smoke、ARCHITECTURE。其他9A.1未提交修改完整保留，项目说明中的旧36px提示已同步为30px。

### 生成与流程

所有普通COMBAT房参与环境流：55%概率生成假线索，命中后15%概率增加第二个，结果0～2处；不是每间房都有。隐藏父房保证一个真实线索，35%概率附加一个假线索。真假数量分布互相重叠，均从裂纹/砖缝/掉灰三个程序绘制variant抽取，无秘密专属颜色/图标/光效。位置也从共用墙段候选中抽取，真线索不固定在墙中央。

候选只在N/E/S/W墙段，避开普通门、风险门、大型障碍、真实线索位置与既有底座交互区；仅COMBAT，故不与Boss出口冲突。交互锚点在墙内20px，绘制在墙体中线；玩家站位有18px障碍余量。已对100个Seed所有生成点执行16px网格连通验证，确认可从正常室内连通区域到达。

30px内、房间清场时，初始统一**[E] 检查墙面**；32/40/64px均不提示或接受检查。未检查不出现暗门/隐藏房等文字。假线索第一次E给出固定实心/自然破损/掉灰反馈，记录已查，无重复E提示；重复E不会刷文本。真线索第一次E提示“敲击声有些发空。[E] 继续检查”；第二次E才打开并进入。已打开重访提示推开暗门，暗室内保留返回墓道操作。

第一次真检查仅secret_inspected=true，SECRET_CHAMBER仍不显示；第二次实际打开设置secret_discovered=true并切房，小地图才显示。真/假检查状态均存TombExplorationPlan.checked_wall_marks，稳定ID为room:wall:side:index；离房重访保留，新Run/换层清空。没有Profile字段或中途存档。

### 确定性与隔离

环境流VERSION=1，以run_seed/floor_number/room_id/"wall_mark"/version稳定混合后使用局部RNG；数量、位置、variant、真假和假检查反馈均可复现。不消费地图/敌人/Boss/普通古董/遗物/棺椁流。inspect-none和通过真实E第一次检查全部活WallMark的对照：上述快照及棺椁结果全部相同；检查全部不等于打开暗门，没有提前泄露地图。

100个Seed样本：60张完全没有暗室的地图仍出现假墙痕；非父房一处假痕327间、两处假痕52间；隐藏父房一个真痕22间、真+假17间。真假都覆盖3种variant。样本数量仅记录当前结果，不作为精确概率或人工KPI。

检查还发现旧小地图过滤视图遗漏Seed元数据，导致有未发现暗室时HUD可能显示Seed0。已修正为保留实际Seed、START/BOSS/ANTIQUE身份，新增断言，方便多Seed人工记录；不改变生成结果。

### 自动与图形结果

Phase1～8D再次重跑：5,330项、0失败。当前9A headless **10,279项、0失败**；总计 **15,609项、0失败**。9A graphical另计 **10,279项、0失败**；导入/正式入口启动无错误。真实两层回馆与原风险撤离/死亡、满包、RNG隔离、80HP/8格等断言全部保留。

新增覆盖：无暗室也有假痕迹、真假数量/variant重叠、初始文案一致、墙段/站位可达、假墙一次性、真墙两次E与小地图时机、真假离房重访、新Run/换层重置、真实inspect-all随机隔离与全局RNG不消耗。图形查看中性提示、假墙实心反馈、真墙发空反馈及进入暗室；程序图形检验不代替人工惊喜/无聊感。

日志为logs/phase_9a1_wall_regression_*.log、phase_9a1_wall_final.log、phase_9a1_wall_graphical_final.log、phase_9a1_wall_import_final.log、phase_9a1_wall_startup*.log；截图仍在忽略的logs/phase_9a_*.png。仅in_memory/隔离测试档，不触碰正式档。

### 墙面人工验收（正式通过）

用户最终确认真假墙面机制正常、不再一眼暴露；普通房有假线索，未刻意扫墙仍可自然发现暗室。隐藏发现机制整体验收通过。其余单项未提供独立主观评分，不编造评价：

| 观察 | 状态 |
|---|---|
| 是否仍能一眼识别真暗门 | 通过：不再一眼暴露 |
| 假线索是否打破“看见就知道”的规律 | 通过：真假墙面机制正常，普通房假线索存在 |
| 是否变成无聊贴墙扫E | 通过：未刻意扫墙仍可自然发现 |
| 发空反馈是否带来发现异常的感觉 | 整体通过，未提供单项评分 |
| 假线索是否过多 | 整体通过，未提供单项评分 |
| 找到暗室是否仍有惊喜 | 整体通过，未提供单项评分 |

当前按最终封版授权提交并push，不合并main、不进入9B。原9A.1完整回馆修正及历史测试记录保留如下。

## 前一轮Phase 9A.1修正记录（墙面修正前）

继续同一分支`codex/phase-9a-tomb-risk-exploration`，基于`17c7703800f6b710aefc81f17f0299e068ef8c01`；没有创建9B分支，不合并main。本节为当前配置与验收；后文原9A记录保留为历史，旧概率/15HP/测试数量不再代表当前版本。

### 人工反馈与修正

用户对原9A实际试玩反馈：棺椁基本都会开、祭台基本都会开、暗门过于明显、风险绕路不值得、墓内古董产出过高；从独立dungeon_test两层完成后不能返回地面。

| 项目 | 9A.1正式规则 |
|---|---|
| 普通石棺 | ANTIQUE/AMBUSH/TRAP/EMPTY权重35/25/20/20 |
| 伏击奖励 | ambush_reward=false，杀完开门但不送古董、没有安慰奖励 |
| 石棺机关 | 正式Health入口20HP，可以致死 |
| 祭台 | 25HP，保留RARE/TREASURE高价值池，可以致死 |
| 祭台确认 | 展示当前HP→支付后HP，clamp下限0；HP≤25警告“这会导致死亡”，允许确认 |
| 出现频率 | fork=.45 / secret=.35 / standalone_altar=.25 / coffin=.65 |
| 普通棺椁数量 | 每层0～1口，只抽一次，不补数量；暗室中的棺椁另计 |
| 隐藏入口 | 裂纹约旧版60%大小、低对比近墙色、不发光；36px内才显示/接受E |
| 风险环境 | 原血迹/暗色偏殿加断裂木板、擦痕和机关孔，仅视觉，不新增伤害机制 |

探索装配版本2、事件抽样版本1。新配置内确定性保持，旧配置的事件位置与结果不作为跨版本兼容契约。普通棺椁使用独立`ordinary_coffin`流；有绕路时可放在RISK_PATH，无绕路时选一间COMBAT。风险路线终点仍为高价值祭台，不额外塞普通古董。暗室保留供物+独立风险棺椁，不要求玩家必须开棺才能带走已发现的供物。无绕路时按25%候选放一座独立祭台，仍最多一座。

### 1,000 Seed样本

连续Seed0～999：直接古董357、伏击260、机关196、空棺187；暗室340层、绕路426层、无普通棺椁345层。全部主图/确定性/一次性/RNG隔离断言通过；普通棺椁每层最多1口。测试只断言四类都存在、古董结果明显非多数、有缺席层等稳健边界，不断言精确概率。

满包不吞奖励、真实Tab/Delete腾空间、领取后丢弃不重生、重访恢复未领取奖励、死亡遗失、80HP/8格、R/N、开启所有事件与完全不打开事件的RNG隔离、Museum/市场/拍卖Dungeon隔离均保留。正式伏击无古董新增断言；可配置伏击奖励的生命周期单元夹具明确开启ambush_reward=true，只用于保持原可选奖励能力覆盖，不影响正式石棺。

### 正式GameFlow两层通关与回馆

新增`tests/phase_9a_complete_flow_checks.gd`。正式GameFlow / Seed33 / in_memory隔离存档：Day1空馆→实际情报板E→Night→真实普通房战斗/E拾货→真实Weapon/Projectile击杀Boss1→ExpeditionExit E深入→Floor2真实战斗/拾货→真实Weapon/Projectile击杀Boss2→RunExit64px外E不能结束→靠近E→RunCompleteScreen。

验证真实结果：`COMPLETED`、`floor_reached=2`、`bosses_defeated=2`、`floors_cleared=2`。没有直接调用_finish_run(COMPLETED)、没有向主流程注入库存/HP、没有F2、Boss AI保持开启。程序驾驶使用安全位置定位，不称为人工游玩。

`hub_mode=true`的结算显示**[E] 返回地面**。连续快速E实际返回：旧DungeonSession释放、Museum重新创建、MORNING、Day1→Day2恰好一次。带回战国错金银铜镜×2、唐三彩马、金丝玉佩，共4件、基础估值**¥6,200**；均成为未鉴定OwnedAntique，品相与RunResult逐件一致、acquired_day=1，现金仍0。额外E/旧结果重复提交不会再次入藏或推进日期。两层都未结算风险事件/进入暗室，继续证明主路径不依赖额外机会。

独立`dungeon_test.tscn`继续`hub_mode=false`，不强行生成Museum。独立结算底部明确为“独立地宫测试模式 / [R] 同Seed重试 / [N] 新地宫”，没有E返回提示，E不发送回馆信号。旧Phase6.5独立真实两层战斗回归保留；新UI测试显示刚才真实两层完成的结果快照，仅检测独立展示边界。

### 风险撤离与死亡回归

新配置按有限0～999扫描选到正式机会齐备的Seed52，不能强行补事件。真实主流程清房/拾货→风险石棺→墙缝E进入暗室→供物与棺椁→25HP祭台→满包取舍→真实Boss/F撤离→E回馆：4个事件，共丢弃5件，带回唐三彩马、镇墓兽残片、战国错金银铜镜，估值**¥5,800**，Day2三件未鉴定馆藏。

另一晚同Seed继续贪心探索，携货**¥4,800**，真实敌人致死；本Run背包清空，E回Day3不入新货，之前三件安全馆藏仍在。祭台取消不扣血、25HP支付可致死、20HP棺椁机关可致死、伤害入口和重复E一次性都另有单项覆盖。

### 当前自动/图形结果

原Phase1～8D的14套回归仍为**5,330项，0失败**（逐套数量见后文历史表，均重跑）。当前Phase9A专项headless **8,139项，0失败**，15套合计**13,469项，0失败**。当前9A graphical另计**8,139项，0失败**。导入解析无错误；正式入口headless/graphical启动正常。已实际查看祭台普通/致死预览、正式两层结算、回馆四件藏品HUD与独立模式底部截图。

日志：logs/phase_9a1_regression_*.log、phase_9a1_final.log、phase_9a1_graphical_final.log、phase_9a1_import_final.log、phase_9a1_startup*.log；截图仍以logs/phase_9a_*.png保存当前结果。日志/截图不入Git；测试只用in_memory或user://tests/phase_9a1，未碰正式档。

### 当前人工入口与五晚记录

完整白天→夜晚→两层→回馆必须使用正式主场景：

```powershell
$godot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $godot --path . res://scenes/main/game_flow.tscn -- --seed=33
# 需要隔离人工测试档、保持真实空馆Day1：
& $godot --path . res://scenes/main/game_flow.tscn -- --seed=33 --profile-path=user://tests/phase_9a1/manual_playtest.json
# dungeon_test仅作独立墓穴手感，结果只提供R/N：
& $godot --path . res://scenes/main/dungeon_test.tscn -- --seed=33
```

已打开可见正式GameFlow测试窗口（Seed33、独立测试档），请求不用F2完成至少5晚并记录选择。夜间N可换Seed，R同Seed重试。**目前尚未收到新版五晚人工数据，不能宣称手感目标完成，也不能将程序驾驶五条流程计作人工五晚。**

| Night | Seed | 棺椁开/不开 | 祭台开/不开（当时HP） | 暗室发现 | 风险路线走/放弃 | 因HP/携货主动撤退 |
|---|---|---|---|---|---|---|
| 1 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 |
| 2 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 |
| 3 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 |
| 4 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 |
| 5 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 | 待反馈 |

不要求固定选择率；若仍全部开棺/祭台/走风险路线，不能判为风险手感验收通过。

### 本次文件与限制

修改三份正式事件/频率资源；事件/探索配置默认值；TombExplorationPlan密度与版本；TombRiskInteractable损失预览；HiddenRoomEntrance视觉/距离；Room风险环境；RunCompleteScreen独立提示；原9A数据、交互、生命周期和真实撤离/死亡测试；5B测试驾驶增加默认关闭的避开可选房开关。新增正式两层回馆集成脚本及.uid，接入9A smoke。同步四份项目文档与本文件。

原玩家、敌人/Boss、遗物、背包容量、Museum功能与保存边界均未修改。高价值池没有贬值。主观手感与5晚记录待人工反馈，不能把数值目标/程序零失败等同主观目标完成。仅9A.1，不合并main、不进入9B。

---

## 原Phase9A工程验收（历史：17c7703）

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
