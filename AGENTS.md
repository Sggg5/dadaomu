# 项目协作规则

## Phase 8A：博物馆昼夜循环（当前授权）

基准 main 0a8784d193b6c96471538027fe0d00dfba2c1c46；工作分支 codex/phase-8a-museum-day-night-loop。仅实现可玩昼夜闭环，验证后提交并push，不合并main、不进入8B。旧阶段章节为历史，以本节授权为准。没有磁盘存档；门票现金仅本进程记录，无消费、出售、拍卖、鉴定、真假、修复、员工、成本、扩建或新墓穴。

GameFlow持有MuseumState、日期、阶段和当前RunResult，只装配Museum与现有DungeonSession。MORNING自由布展→售票台E开馆→OPEN游客营业→停止进客并等现有游客离开→EVENING→情报板E进入NIGHT→结算E回馆→次日MORNING。营业是可选的：MORNING可从情报板E直接下墓；OPEN可从情报板E提前闭馆并出发，停止进客、现客离场后自动进入NIGHT，无需等满60秒。跳过营业不产生票款，当日营业统计为0。只在夜晚结果实际回馆时日期+1；R/N夜间重试不推进日期，也不转移战利品。

OwnedAntique按instance_id/definition_id/acquired_day保存单件；MuseumCollection与夜间AntiqueInventory是不同对象。成功EXTRACTED/COMPLETED结果antique_ids逐件入藏，重复定义仍有不同实例ID；DEAD只显示遗失，无新入藏，已有收藏/展柜/现金不变。acquired_day记录实际出墓当晚日期，回馆后日期再+1。初始一件唐三彩马明确作为原型测试馆藏（day0），可关闭GameFlow.initial_test_collection。

MuseumPlayer只有加减速移动、朝向和统一64px交互，不带Weapon/Health/RelicRuntime。3个DisplayCase按实例归属，场景真实显示名称/几何图标；同件不可双柜、不同重复件可以。E选择/查看、柜旁R撤展；白天没有删除/出售入口。营业中禁止调整，闭馆后恢复。库房无限，Tab/E关闭面板。

MuseumBusiness默认营业60秒，10:00至17:00，票价¥5；目标clamp(10+floor(appeal*0.5),10,60)，同时最多8名，分批入场。Visitor独立RNG以museum_seed/day/index稳定派生，按已有展品吸引力加权选择、看一至两柜后离场，未展出藏品不会被选择，无展品也能安全营业。票款由游客和营业索引双重一次保护，实际售票人数可能小于目标。时间结束不再补客，所有现客退出后结算门票收入。

主入口scenes/main/game_flow.tscn；scenes/main/dungeon_test.tscn仍可单独运行并保留R/N。DungeonSession可选hub_mode只增加结果/返回信号和E回馆，完全不知道展柜/游客/票款。夜间战斗数据、地图/掉落算法、两Boss和奖励2/4/7保持。

详见docs/PHASE_8A_VERIFICATION.md。人工反馈与自动/图形验证分开记录，不以测试驾驶代替手感验收。完成本阶段后停止。


## Phase 7B：贪心与撤离（历史验收）

工作分支 codex/phase-7b-greed-extraction，基于 main 150390aba5b1efbb1321de453893c450cba963b7。用户授权验证后提交并 push，禁止合并 main。旧阶段条款是历史记录，当前以本节为准；禁止黑市、钱包、出售、鉴定、存档、第三层及新阶段。

每层 1 个 ANTIQUE 底座加最多 3 个 COMBAT 清房陪葬匣，普通布局共 4 次机会，两层共 8 次。AntiqueLootService 按 seed、floor、room ID、source 和版本的稳定评分排序选前三，排除所有特殊房；不足三个时取实际数量。选择与探索顺序无关，不使用全局 RNG，不改变遗物奖励 2/4/7。

AntiquePool 版本 2 使用包含 source_id 的稳定键和独立 RNG；第一层完整八件池，第二层过滤为 UNCOMMON/RARE/TREASURE 六件同一资源。RoomState.claimed_loot_sources 统一记录 antique_room/combat_cache；领取后即使丢弃也不重生，未领重访还原同一件。旧 antique_claimed 仅作为同一字典的兼容属性。

第一 Boss 胜利后 ExpeditionExit 在 64px 内接收 E 深入、F 撤离，先锁定 used 再发信号，避免双触发。第二 Boss 仍由 RunExit 接收 E 返回。DungeonSession._finish_run 集中生成 EXTRACTED/COMPLETED/DEAD 快照，停止控制、战斗、遍历、奖励和调试遗物输入，关闭 Boss HUD 与背包；死亡先快照再清空古董。已排队深入遇到同帧死亡会取消。结束后 R 同 Seed、N 新 Seed 均从第一层空背包开始。

背包仍为 8 格，Tab/Delete 管理不暂停战斗；价值/格在 UI 计算并取整数展示。估值仅为本局结果，没有钱包、出售或持久化。Seed 192034 两层 8 次机会共占 15 格，实际完成满包 E 失败→Tab/Delete→E 换入高价值物品。三条程序驱动真实交互流程分别安全撤离 ¥6,350、敌人致死损失 ¥9,000、两 Boss 通关带回 ¥10,400。

Phase 1～7B 共 10 套回归均通过；专项 722 项、0 失败。用户人工反馈：『提示清楚』。仅确认风险提示清晰，不据此声称所有人工路径或最终平衡已验收。详细命令、结果及限制见 docs/PHASE_7B_VERIFICATION.md。阶段完成后停止。


## 范围与阶段

本项目是 Godot 4.x / GDScript / Windows 的原创 2D 俯视角 Roguelite《大盗墓时代》。阅读 README、PROJECT_PLAN、ARCHITECTURE、GAME_DESIGN 后再修改。用户指令优先；每次只执行明确授权的 Phase。当前授权 Phase 8A；范围和 Git 规则见本文顶部当前实现章节。

每阶段保持可运行入口，结束前检查导入解析、启动和阶段相关行为。报告修改文件、架构变化、验证命令与真实结果、已知限制及下一阶段范围。未执行的检查必须明确标注，不能把规划写成已实现。

## 技术要求

- 优先标准 Godot 节点、场景组合、类型化 GDScript 和 Resource 数据。
- 降低系统耦合，显式引用与局部信号优先；不要创建万能管理器/事件总线。
- 数据定义与运行时状态分离，稳定 ID 与显示名称分离。
- 单脚本禁止超过 1000 行，建议 300 行内；超过 500 行应检查拆分。
- 核心系统注释说明职责、生命周期和边界；不堆无意义注释。
- 未有明确需要不引入第三方插件、框架、对象池或额外依赖。
- 设计不确定时采用最简单、易扩展且能验证的实现，并记录假设。
- 不复制参考游戏的美术、角色、敌人、道具、地图或剧情；外部素材记录来源和许可。

## 文件与 Git

使用 scenes/、scripts/、data/、assets/ 按职责归档；文件 snake_case。修改前查看 Git 状态，保留用户已有修改。不重置、覆盖无关文件；不自动提交、推送或改写历史。新分支默认 codex/ 前缀。提交源 `.uid`，忽略 `.godot/` 和构建/日志。

## 验证

优先使用本机 Godot 4.6.2 标准版；如果命令不在 PATH，定位完整路径。

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10
godot --headless --path . --script res://tests/phase_1_smoke.gd
godot --headless --path . --script res://tests/phase_2_smoke.gd
godot --headless --path . --script res://tests/phase_3_smoke.gd
```

启动冒烟不能代替实际交互检查。涉及随机生成、效果卸载、重复结算和存档的修改应有针对性验证；简单占位 UI 不写镜像式测试。失败先修复当前阶段，不跨阶段规避问题。

## Phase 2 房间约定

- 五房复用同一个 Room 场景，差异放在 RoomDefinition 数据中。
- RoomController 持有唯一玩家和 RoomState；Room 持有局部敌人、弹丸、门与墙。
- 状态只能 UNVISITED → ACTIVE → CLEARED；重访 CLEARED 不刷怪。
- 切换必须验证相邻关系和清场状态，冻结输入并延迟卸载；禁止在 Area/物理信号中立即删除碰撞体。
- 生成器通过 Health.died 计数；卸载房间不能被当成击杀或清场。
- 真正非战斗房内容尚未实现；Phase 3 的占位进入规则见下文，不要把枚举或占位报告为完整内容。

## Phase 3 地宫约定

- 本阶段工作分支为 `codex/phase-3-random-dungeon`。用户已授权验收后提交，禁止自行合并 main；未明确要求的推送不自动执行。
- DungeonGenerator 只生成纯布局，使用独立 RNG；不创建节点，不依赖全局 RNG、时钟或场景树。
- DungeonRoom 决定 ID、坐标、类型、距离和连接；RoomDefinition 只提供内容模板。不要为每个随机图节点新增 `.tres`。
- RoomController 只消费注入的 DungeonLayout，不添加生成算法或固定五房拓扑。启动/Seed/重开由开发入口 DungeonSession 装配。
- 图为 8～12 房的正交树；START 在 (0,0)，Boss 为最深叶子且距离至少 5，ANTIQUE 距离至少 2。
- 候选遍历与签名必须显式稳定排序，StringName 应转字符串后排序；检查跨进程复现，不能只验证同进程重复调用。
- R 保留当前 Seed；N 用独立 Seed 来源获得新布局。生成版本、配置、模板池和引擎版本影响复现结果。
- START 为安全出生房，忽略模板 spawns 并立即清场开门；第一层BOSS为正式Boss，第二层BOSS为镇墓兽，ANTIQUE自动清场。当前Phase6范围经用户改为晋北大帅尸与两层推进；古董另待授权。
- Phase 2 固定图仅保留在 tests/fixtures；改旧测试时保留原始行为断言，不通过删除断言掩盖回归。

## Phase 4 敌人约定

- Phase 4 已合并 main；本次从最新 origin/main 创建 codex/phase-5a-relic-framework，用户授权验证后提交并 push，禁止自行合并 main。
- EnemyDefinition / RangedEnemyDefinition 只读；Enemy 持有实例 HP、冷却和观察期。Player 与弹丸容器通过 Spawner 显式注入。
- RoomDefinition.spawns 是唯一生成入口，EnemySpawnDefinition 指定场景、数据和位置。Dummy 只保留给旧回归夹具。
- 敌人弹丸仅检测 World / Player；不伤友军，不追踪移动目标，房间卸载或玩家死亡必须清理。
- 真正生成敌人的战斗房入房默认 0.35 秒观察期，暂缓 AI 移动和攻击；模板生成点距四入口至少 180 像素。不得跳过攻击前摇补偿难度。
- 必跑 Phase 1～4 smoke，保留旧功能断言。人工试玩与程序驱动图形验证分开报告。
- Phase 5 准备仅文档规划，不提前实现遗物、Boss、古董、黑市或存档。
START 与其他房复用 room.tscn 和随机视觉/障碍模板，不复制场景、不修改共享 spawns；START 不调用 EnemySpawner，因此不应用观察期。COMBAT 的 180px 入口间距、0.35 秒观察期和攻击前摇保持；第一层BOSS为正式晋北大帅尸，第二层BOSS为镇墓兽，ANTIQUE自动清场。

## Phase 5A 遗物框架约定

- 遗物仅单局临时 Build；普通遗物按稳定 ID 唯一，重复获得返回 false，不安装第二实例。
- RelicDefinition 与 PlayerStats 只读；RelicEffect 是每次安装的新实例，运行计数/连接不得写回 Resource。
- Runtime 挂在唯一 Player 下；Inventory 只管理持有、安装和卸载。具体效果是独立脚本，不在 Player/Projectile/Controller 写遗物 ID 分支，不使用全局 EventBus。
- 武器单次输入消耗一次冷却，AttackContext 存 0..N 请求快照，按 AttackStage、priority、稳定 ID 排序应用效果；copy 必须保留请求的全部数值。
- Hook 仅 attack_prepared、projectile_spawned、projectile_hit、enemy_killed、player_damaged、room_cleared。节点上下文仅同步使用，不长期保留死亡敌人。
- 新遗物必须实现幂等 install/uninstall，卸载断开自己建立的连接。玩家死亡/离树清空 Inventory；R/N 重建空 Build，跨房不得卸载 Player 的效果。
- 开发期 1/2/3 添加三个测试遗物，Backspace 全卸载；不是正式拾取界面或正式内容量。
- 必跑 Godot 导入和 Phase 1～5A smoke。旧 Phase 1～4 断言不删；人工验收单独记录。
- Phase 5A 当时仅工程效果；Phase 5B 的授权范围见下文，仍不提前做古董、Boss、商店或存档。
## Phase 5B 正式遗物与奖励

- 分支 codex/phase-5b-relic-builds，从指定 main d7660a1 开始；本任务授权提交并push，不合并main，结束后停止，不开发Phase6。
- RoomController 创建 RoomClearContext（ID/type/was_combat/enemy_count）。was_combat 仅普通COMBAT为true；START/ANTIQUE/BOSS占位均不计普通清房奖励，重访不重复通知。
- RelicRewardService 由 DungeonSession 持有，独立RNG：seed XOR (reward_version*7919)，稳定ID排序后Fisher-Yates无放回；不能改变地图RNG或把奖励逻辑塞入Runtime。
- 第2/4/7个首次COMBAT清场产生底座；E靠近拾取一次。离房未领取奖励丢失且不补发；工程test_*不得入正式RelicPool。
- AttackStage为DAMAGE/COUNT/DIRECTION/PROJECTILE_PROPERTY/FINAL，先stage再priority再ID。AttackRequest新增pierce_count/projectile_scale/tags，copy须完整且tags独立。
- 正式效果各自独立，核心Player/Projectile/Controller/Spawner/Runtime禁止正式遗物ID特判或组合专用脚本。
- 爆炸/墨线是瞬时非Projectile伤害，不递归命中；Burn仅轻量3tick可刷新组件，不扩展万能状态框架。
- 卸载/死亡取消效果拥有的Burn/反馈，跨房释放旧房对象并保留库存/充能；R/N清空全部运行状态和奖励进度。
- 必跑Phase1～5B；Phase5A仅调整typed清房Hook测试，保留断言。至少一次真实Weapon/Door/E流程获得3件奖励，并单独记录人工手感。
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
## Phase 6 当前约定

- BossDefinition继承EnemyDefinition且只读；BossEncounter独立拥有Boss和一次召唤物，普通Spawner不生成正式Boss。第一层BOSS忽略模板spawns；START/ANTIQUE规则不改。第二层BOSS只用普通占位，绝不生成第三层出口。
- 晋北大帅尸确定性交替冲锋/震荡，INTRO 1s；前摇0.65/0.8s不随Tier或阶段缩短，冲锋方向只在前摇结束锁定。一次技能只结算一次伤害；半血召3尸蟞只一次，死亡不要求清完召唤物。
- Room拥有FloorExit，只发交互信号；Session负责新Run和下一层两种不同生命周期，Controller仍只消费Layout。已清Boss房重访恢复出口，不重新生成Boss。
- RunCarryState只持HP与只读RelicDefinition，不保存Effect/Node。Health.restore只emit changed；跨层新效果安装、旧效果卸载，临时计数/纸鸢充能/武器冷却/燃烧重置。
- 同Run保持唯一RewardService、2/4/7进度/sequence/_seen；第二层room_id加F2前缀。层Seed确定性派生并有限16次空间差异检查；N的独立随机Seed源不参与下一层。
- 第一层offset0，第二层offset3；只缩放实例HP/伤害，现有Tier倍率不变。R任何层都回同Seed第一层、80HP空Build零奖励；N新Run。
- 必跑导入、启动、Phase1～5B与Phase6 smoke；完整流程必须真实Weapon/Projectile击杀Boss和真实Door/E过层。单项直接设HP/状态与完整流程须分开记录。人工手感不能由自动测试替代。

## Phase 6.5 当前规则

BossDefinition.boss_scene选择Enemy根场景，BossEncounter/HUD只依赖Enemy，无Boss ID条件；大帅尸AI脚本和数值保持。Boss场景不反向引用其Definition，避免Resource→Scene→Resource循环；Encounter在入树前注入只读数据。

Session.boss_for_floor映射1大帅尸/2镇墓兽，其他null；Room.final_floor只决定胜利出口。两层都忽略模板spawns，复用同Room场景。镇墓兽固定扑击→扇弹→地刺，不用全局RNG；伤害仍实例scaled_damage，临时弹丸/地刺由Boss弱引用管理并在停止/死亡清除，禁止隔墙落地伤害。

RunExit与FloorExit职责区分：第二层只有RunExit，64px内E一次才run_completed；Boss死亡只清房与计数，不立即通关。显式boss_defeated信号按层去重，不能用房数猜。结算RunResult只持数值与名称，不保存Effect或节点；完成冻结输入/Room traversal/弹丸生成，R/N重置结果界面、Build/HP/进度/击杀。

必跑Phase1～6.5。改Phase6第二层占位断言时保留真实第二层清场与无第三层覆盖，新增正式Boss真实战斗；至少一次正常拾取遗物、真实Door/E、真实两Boss武器击杀到结算。人工试玩单独记录，不把程序驾驶时间当人工25～45秒验收。禁止第三层、第三Boss、古董经济、背包、黑市、存档或新普通敌人。

## Phase 7A 当前规则

AntiqueDefinition/Inventory/Pool与RelicDefinition/Inventory/Runtime彻底分离。Player拥有独立8格AntiqueInventory，仅持只读定义数组、允许重复件；不保存Pickup/Effect/UI，不修改任何战斗属性。remove(id)删首个同ID项，remove_at(index)支持重复件准确丢弃；items返回数组副本。

AntiquePool以版本/run_seed/floor/raw room_id稳定文本混合后建立独立RNG，按ID排序均匀选择；不得消耗地图/遗物全局随机状态。当前两层同池同概率，不做权重框架。ANTIQUE安全CLEARED/开门且忽略spawns，64px内E领取；满包提示，不自动丢物，不要求领取才能离开。

RoomState.antique_claimed跟随本层状态，未领可重访恢复同件，已领/已丢弃不重新生成。Tab背包不暂停战斗，Delete/按钮按索引永久删除当前Run物品，无落地重生成。死亡/通关/过门冻结期间禁止管理；未加死亡掉落系统。

RunCarryState仅增加古董定义数组，新层加入新的Inventory、新UI；HP/Relic原规则不变。RunResult保存名称与总估值，只当前Run展示，绝不钱包/出售/保存。R/N新Run背包空。

必跑Phase1～6.5及Phase7A；真实主流程使用Door/E两层领取、真实武器击败两Boss后结算，不用inventory.add替代正常获取。单位边界可直接调用Inventory。只实现本阶段，禁止撤离、黑市、鉴定、真伪、永久货币、战斗古董、保险箱、尸体回收、存档、第三层或新Boss。
