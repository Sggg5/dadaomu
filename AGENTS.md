## Phase 10C 全球馆藏质量（当前完成，内容待人工审核）

分支codex/phase-10c-museum-quality，基线10B eb88e87。1441对象无变化；122自然史对象逐条/抽查、30图鉴v2、20逐图片核验CC0照片、4专题各8对象。Schema9前向扩展，未改已有迁移；人工锁/版本hash、学术审核和源字段验证分离。

HTTP本地预览四视图/8筛选，1280×720及390×844真实浏览器截图与注入检查通过。图片只用于策划，2对象4缩放样例入Git，其余可重建cache；不写正式game assets。图鉴/候选/专题均待审，陨石同号分样冲突待人工解析。正式8古董/概率/Profile4/战斗/Boss/遗物冻结。仅commit/push、不合并main、不继续下一阶段。详见database/docs/PHASE_10C_VERIFICATION.md。

## Phase 10B 全球藏品内容（当前完成，待内容人工审订）

分支codex/phase-10b-museum-content，基于10A 2336dbd。累计1441真实对象（新增1280），100中文图鉴草稿、80双语术语、500独立CANDIDATE（300中国/140全球/60自然史）。Schema6前向迁移、Normalizer5；RAW/NORMALIZED/EDITORIAL_DRAFT/GAME_CANDIDATE/APPROVED/RELEASED分离，程序通过不等于真人审核。

离线只读预览database/previews/index.html；重建运行python -m database.preview。图鉴全部DRAFT_PENDING_REVIEW，候选四审PENDING；大件远征运输只为提案，没有新运输玩法。正式八件古董/掉落概率/Profile4/战斗/Boss/遗物冻结，data/catalog/global_catalog.json保持原内容。无图片/3D下载、不合并main、不继续下一阶段。详见database/docs/PHASE_10B_VERIFICATION.md及CONTENT_REVIEW_WORKFLOW.md。

## Phase 10A全球藏品数据库（当前授权）

新分支codex/phase-10a-global-museum-database从1c3a614创建，保留全部本地9B有效提交。仅database/离线资料基础设施与审核本地JSON，不改战斗/Boss/遗物/随机规则/8古董数值/OwnedAntique身份/Profile VERSION4，无正式存档迁移，不合并main。10A.1/2/3顺序测试、三独立commit，完成尝试push，失败保留本地不force。

CollectionObject文化/自然分扩展、Human/Geological时间独立、Taxon/Occurrence/Specimen不同；未知字段保持NULL、缺中文pending，原文非自动译名。SourceRecord/FieldEvidence/Media分别追溯数据/媒体许可，CC BY署名、CC BY-NC/UNKNOWN/未核验媒体拒绝发行。真实记录不自动变掉落；明确GameCollectionDefinition策划关系，1933制造/发现/命名/虚构获取分审，大型骨架不进8格。SQLite schema/checksum/normalizer版本支持重建且保留人工锁。只小型合法metadata快照可入Git，SQLite/cache/媒体/日志不提交；database/.gdignore保持运行解耦。

161真实记录、5实际官方获取/9映射入口；15化石鉴定issues待review，不冒称真实物种已核验。原有442 gameplay文件冻结，导出8旧原型/2形制参考，参见database/docs/PHASE_10A_VERIFICATION.md。阶段完成停止，不扩图鉴UI、Museum经营、化石发掘或其它阶段。

## Phase 9B.3.2a-c最终实现（人工待验收）

A 51909c6潜地2.4秒硬生命周期/统一异常恢复，不杀怪不改账本；B 5af5bb1 Geometry v2、13普通/6Arena、中央8.4436%、全独立流；C按明确用户授权改生产240/3.5/750×1，保留80HP/0.25无敌/1800/2200，正式池41件但RewardPlan v3/13来源不变，五件成长效果不写共享Stats。十Boss真实半径40/44/36/36/32/44/48/双32/52/42、范围205/98.8/棺盖128，HP/伤害/时序与已存在压力机制保留。8格/RestPoint/经济/Profile v4冻结。下方36件/280速度等规则属历史基线，当前以本段及用户指令为准。

全回归、潜地、Geometry、基线/自然Boss/五层回馆和图形通过；安全点驾驶器不是人工难度结论。禁止自动合并main或进入其它阶段；完成push后打开正式GameFlow等待人工验收。详见A/B/C对应验收文档。

## 当前追加：Phase 9B.3.2a-c

按用户授权顺序A生命周期→专项/全回归/commit→B地形补齐→专项/全回归/commit→C玩家成长/体型→专项/全回归/commit。保留当前HEAD全部有效Boss压力、独立Geometry和可达性保护；不reset、不合并main、不进入其它系统。地下硬上限2.4秒与统一恢复不能自动杀怪/扣账本，DEBUG诊断仅测试使用。各阶段验收记录见docs对应A/B/C文件。
# 项目协作规则

## Phase 9B.3.2b：Geometry / Boss Arena分离（当前实现，人工待验收）

基于已存在9B.3.3的 `5435e96872f2ff8a2b76d24cfb438406df9df39d`，继续 `codex/phase-9b-multifloor-endurance`。本次只空间拆分/合法性，不回退或继续调Boss压力，不改Boss HP/伤害/时序、Build或经济。完成只commit/push，不合并main，等待空间人工验收。

生产30个RoomDefinition只提供Encounter身份/敌人preferred spawns/threat/weight，空间迁到12个RoomGeometryDefinition与独立池。RoomGeometryPlan GEOMETRY_VERSION1按Run/Floor/RoomID/PoolID稳定RNG、距离/ID稳定装配，不修改Layout或其它随机流；邻接房ID去重、中央棺每层最多floor(COMBAT数/10)，实测1000Seed普通出现率0.5496%。安全房空空间使用稳定SAFE_RoomID，不消耗池RNG。

BossArenaDefinition/Pool/Plan ARENA_VERSION1独立选择六Arena，各Boss声明兼容tags；BossRunPlan VERSION1冻结。所有Boss不再继承普通Encounter障碍，未注入Arena的历史BOSS也只有空Arena。普通旧夹具仍可显式保留旧布局字段。Room统一obstacles()/environments()/coffin_style()供生成、危险区、掉落、风险交互和AI读取当前空间。

EnemySpawnPlacement先整波搜索preferred→边界/入口180px/障碍24px/间距48px，失败记录错误且不产生半波；Room/Spawner坐标转换显式。Boss/召唤/卵/危险区/假身读取当前Arena。潜地出土增加占位预留48px与Player身体40px，出土再校验，修复重叠实体被物理推出房外导致活怪不可见/卡门；HP/移速/技能预警时间不改。

详见 `docs/PHASE_9B_3_2B_VERIFICATION.md`；截图/日志在ignored logs。结构约束和自动战斗不能证明不存在所有掩体绕行策略，连续5～10房空间打法与Boss反绕柱体验等待人工反馈，不继续压力调优。

## Phase 9B.3.3：Boss压力调优（本次冻结的既有基线）

基线 `9f3ced053ea8e0f6e3ce3115fb4dbaeb715f7288`，继续 `codex/phase-9b-multifloor-endurance`，只commit/push，不合并main、不进入下一阶段。十Boss通过静态连段和近期Cycle历史提高压力；不按Player Build/DPS/HP/携货/Museum缩放。BossRunPlan VERSION1、随机池与所有独立随机流保持。

MechanismBoss使用BossDefinition.boss_recovery_time（F1→F5：0.9/0.8/0.7/0.6/0.55s）及combo_recovery_time（1.05～1.1s）。每3个普通Cycle后优先高压轮；阶段转换0.5s可视反馈，跨阈值第一击全额，随后0.4s×0.5减伤，无无敌/锁血/DPS上限。转换取消旧预警与旧冲锋计划，不能恢复无预警攻击。生产HP辅助调整F1+25%、F2/F4+20%、百足+20%、F5+30%；纸将军500不改。历史Boss数据/Actor保持。

母巢卵→环→短冲、老尸拍击/冲撞接手、大帅距离连段、铁索钩→扫、百足卵/曲线→腐液→尾扫、铜甲冲/砸、双生每3共享轮副方地圈且孤煞恢复×0.82、镇兽低血三段、墓主人场地命令接本体攻击；纸将军仅提高假身存在和低血旋转。组合后保留输出窗口。普通怪/36遗物/RewardPlan v3/13来源/80HP/0.25s受伤无敌/8格/F2+15/F4+20/经济/Profile v4均冻结。

`tests/phase_9b33_smoke.gd`覆盖自然3/5/8/11/13遗物十Boss、移动/站桩、实际技能/阶段/连段/HP损失与五层真实回馆；站桩用无障碍夹具，移动保留真实障碍。自动驾驶可瞬移到安全点，不是真人难度或时长结论。详见 `docs/PHASE_9B_3_3_VERIFICATION.md`。此前普通房2敌人不可见卡门反馈仍未复现/解决，不得标为已修复。

## Phase 9B.3.2：Boss Pool与机制重构（历史基线）

基于 `0a5cb37a6f6314c8f232131da07d5ddd15777245`，继续 `codex/phase-9b-multifloor-endurance`。9B.3三局人工已出现完整通关、F4撤离和死亡丢货，普通怪/Build方向保留。本次只新增随机Boss遭遇与机制，不合并main、不进入下一阶段。

五层各二Boss：母巢/棺中老尸，大帅尸/铁索僵，纸扎将军/百足尸母，铜甲尸王/双生尸煞，镇墓兽/墓主人。生产 `data/bosses` 十Definition、五BossPool；TombFloorDefinition只保存boss_pool。历史fixture显式单Boss池，旧data/enemies Boss与旧场景仅用于历史回归；没有boss_definition回退生产路径。RoomController/Room里的boss_definition代表本层已选结果，职责保持。

BossRunPlan VERSION1在DungeonSession开Run时一次build全部楼层，用Run/Floor/PoolID/version独立稳定RNG和ID排序选择；R复现、N通常变化，Boss未知时小地图仅B，进入后HUD揭示名字。选择不读取Build、HP、古董或Museum，不消耗地图/RelicRewardPlan/古董流。每层奖励仍F#:BOSS，一局五Boss、五层、最多十三遗物。

新生产Boss使用独立子类决策与有限MechanismBoss执行器，Actor只按自身阶段/距离/上次技能决策。BossTelegraph独立高z预警，所有者弱引用、LOS、有限持续、取消；虫卵可打、3秒孵化、最多4，召唤活上限4～6、总上限12～18。双生两个独立Health、共享总HUD与轮流节奏，双方死亡只完成一次；独存者继承简化技能。铜甲诱导破甲2.5秒，镇兽锁落点飞扑与上下文组合，墓主人危险线/弱兵/落石和本体配合。原五BossDefinition HP380/650/500/600/800保持，原Room难度倍率仍存在，不按Build缩放。高Build仍可加快击杀。

冻结RelicRewardPlan VERSION3/36遗物/13来源、12普通敌人/3精英/30模板/4普通环境、80HP、8格、F2+15/F4+20、古董经济/Profile v4/跨日Seed/潜地可达性修复。敌弹逐发检查256容器上限；钩锁只施加有限0.6秒×0.75减速，Player基础参数不变。详见 `docs/PHASE_9B_3_2_VERIFICATION.md`：三十组3/8/12实战、十组站桩探针、1000Seed32路线与完整回馆。自动驾驶不是人工难度结论，等待三局Boss路线反馈。

## Phase 9B.3：敌人威胁、组合战斗与Build波动（历史基线）

基于 `a10ceb39517321cabad2d6a509a9eeb9f1b129e3`，继续 `codex/phase-9b-multifloor-endurance`。9B.2 的 Build 乐趣已获得反馈，普通敌人威胁不足，本轮用功能性敌人、组合和空间压力调整。完成代码验证后只 commit/push 本分支，不合并 main、不进入后续阶段。

普通敌人12类：保留尸蟞/枪手/尸犬/披甲尸/纸人/母体，新增潜地尸、胀爆尸、分裂尸、墓穴弩手、腐尸和悬棺尸。三种独立精英变体：尸犬侧波、纸人死亡慢环、母体临终两虫；不修改共享 EnemyDefinition。30个生产模板按楼层独立池加权选择，威胁1～5只作开发数据/tooltip；保留轻松房。地刺/箭孔有预警和周期，石棺复用静态障碍，积水仅0.75移动倍率。临时危险归Room管理，死亡/卸载取消；死亡子体先计pending再延迟生成，最多24，总清房数包含子体。

正式遗物池36件，新增16个独立Effect，按CORE/SYNERGY/UTILITY/TRADEOFF和只读power_band记录。RelicRewardPlan VERSION3按固定source与独立RNG无放回预分配；遗物房40/35/15/10、Boss10/45/35/10、里程碑10/30/30/30为基础角色权重，叠加温和Run archetype和核心数量软倾向，不查询DPS/背包/博物馆。最低两个核心，通常2～6个，允许偶发更高；power proxy不等同实战强度。每层遗物房+Boss、4/12/24清房里程碑总上限仍13；choices只预留互斥选项API，生产仍单件，不自动补发。跳过来源不影响后续，R复现、N重建。

冻结五Boss AI/数值、Tier3上限、80HP、8格、F2+15/F4+20、每层1古董房+1Cache、古董质量曲线、9A风险、Profile VERSION4与跨日Seed。48弹/单攻、256弹/房、四污水池、十二危险区域、弱引用/限寿命/卸载取消继续约束。历史9B.2测试显式pre_threat_tomb/pre_variation_relic_pool/build_uniform夹具，保留原断言；生产专项单独验证。详见 `docs/PHASE_9B_3_VERIFICATION.md`；自动驾驶通过不代表人工难度通过。

## Phase 9B.2：肉鸽密度、每层Boss与Build加速（历史版本）

基于`b668fe37e2adc915fe610097e205df755ec5822a`，继续`codex/phase-9b-multifloor-endurance`。9B初版工程通过但人工手感未通过：房间/怪物/道具偏少、每层需要Boss。本次按用户授权调整，不封版旧9B，不合并main、不进入后续阶段；以下旧章节为历史。

生产基础房量8～10/10～12/12～14/14～17/12～15，Config支持4～18。五层终点全部Boss：尸蟞母巢→晋北大帅尸→纸扎将军→铜甲尸王→镇墓兽。其中大帅尸/镇墓兽原AI与数据保持；新三Boss分别虫群短弹/半血横移、扇弹横移/真假身/交叉弹、锁朝向护卫/重砸/短冲。普通敌人六种，新增尸犬/披甲尸/纸人/母体；十五个生产战斗模板，每层三个不同组合，平均初始敌数5/6/7/8.333/9，Tier3仍最高。

每层一个独立安全RELIC房，与START/ANTIQUE/BOSS不同；底座64px E领取。RelicRewardPlan按Run Seed与固定source预分配13份无重复奖励（五遗物房+五Boss+4/12/24普通清房），漏房/拾取顺序不改变后续分配。正式Pool二十件，原八件保留，新增十二个独立Effect，通过AttackStage自然叠加，不写组合ID条件。房间/Boss奖励领取写本层RoomState，重访不补发，最终Boss奖励可先捡再RunExit。HP/Build/古董跨层机制保持，R/N重建计划与空库存。

单次攻击48弹上限，每阶段截断；Room弹丸容器256保护；普通母体每房活召唤最多4、每母体2、总生成8，Boss活召唤最多6，纸将军假身最多2且三秒到期。追加伤害不发命中Hook，DOT有限tick且卸载取消；魂弹为弱引用限寿命追踪，每房最多12次，来源不再走攻击修饰器。安全START避开中央障碍；新模板出生点距四入口至少180、间距48且无障碍重叠。HUD显示遗物件数，F2列表可滚动但人工验收禁止用F2加物。

古董仍8格，每层仅1 Antique Room+1 Combat Cache，Profile曲线/9A风险参数/80HP/现有战斗数据/Profile v4/跨日Seed/F2+15与F4+20均不改。历史回归显式legacy两层/八遗物/2-4-7、9B初版单独pre_density五层夹具保留全部原断言，生产默认绝不回退。详细数据/命令/实际流程见`docs/PHASE_9B_2_VERIFICATION.md`。人工手感待本轮重新试玩，不把自动驾驶存活率当难度验收。

## Phase 9B：多层墓穴与单局续航（历史初版）

基线 main `aaefb2e653cdbfa1dd87deb4e46ba5772fdef72c`，分支 `codex/phase-9b-multifloor-endurance`。本阶段授权验证后commit/push本分支，不合并main、不进入后续阶段。下方旧阶段规则为历史；当前以本节和用户9B要求为准。

正式GameFlow/DungeonSession默认使用`data/tombs/default_tomb.tres`：浅层4～6普通终点、前墓5～7大帅尸、中层7～9普通终点、深层8～11普通终点、主墓6～9镇墓兽。普通终点仍是真实COMBAT，不伪装BOSS；基础房数不含9A可选附加房。四次可选撤离/深入，第五层RunExit E完成。HUD显示层数/总层数/层名，小地图T表示普通终点。

TombDefinition持有只读FloorDefinition顺序；每层配置、Boss引用、rest_amount和AntiqueRewardProfile独立资源。最终层只有数组位置这一真相。DungeonGenerator仍只生成单层；DungeonLayout.terminal_id代表终点，boss_id仅真实Boss层有效。RoomController只消费布局；Room复用原场景。

TombFloorGenerator派生楼层：F1=Run Seed，F2保留旧XOR/最多16次空间差异策略，F3+按Run/Floor/Tomb ID独立稳定混合。Campaign/Day/Site→Expedition生命周期与Profile VERSION4保持；不保存墓内中途状态。RunCarryState继续传HP/古董/遗物定义，新World重新装配临时实例；RelicRewardService仍整Run共享2/4/7进度。终点不计普通清房奖励和陪葬匣候选。

cleared_floors与defeated_bosses分开计数，五层全通=5层/2Boss。每个非最终层终点清场后恢复ExpeditionExit，最终层只RunExit。F2医疗包+15、F4+20，其他层无；64px E只调用Health.heal，满血不消费，死亡不可用，RoomState source一次领取，重访不重生，未用治疗随旧层World作废，不能携带或购买。

普通古董来源使用当前层Profile，权重依次55/30/12/3、35/35/22/8、20/35/30/15、10/25/40/25、5/15/40/40；独立稳定RNG先稀有度再组内稳定ID选择，缺组重新归一化。旧Pool.pick保持历史语义，legacy两层fixture不注入Profile；祭台/暗室高价值池继续RARE/TREASURE。80HP、8格背包、两敌人/两Boss参数、Tier3上限、9A风险数值冻结；Museum不进入治疗/收益计算。

历史Phase1～9A测试显式注入`tests/fixtures/legacy_two_floor_tomb.tres`，保留核心断言。9B另跑生产五层真实战斗/拾取/满包Delete换货/休整/四次早退/最终回馆；人工手感与自动驾驶分开。完整结果见`docs/PHASE_9B_VERIFICATION.md`，未获得人工反馈不能宣称手感验收通过。

## Phase 9A.1：墓室风险与完整回馆修正（历史实现，同9A分支）

基于已合并main b74bb35d4e7d4059f8272681f7fb8652629e7e18，开发分支codex/phase-9a-tomb-risk-exploration。仅墓内可选探索；当前墙面发现修正完成后仅报告并等待人工反馈，不自动commit/push，不合并main、不进入9B。下方旧阶段为历史记录，以本节为准。

每层普通棺椁0～1口（独立65%抽签，不补数量），暗室中的棺椁不占此配额；暗室0～1间、祭台0～1座、汇合分岔0～1处。正式棺椁权重古董/伏击/机关/空棺=35/25/20/20；机关20HP，伏击两只现有尸蟞且不送安慰古董。伏击保留0.35秒观察期和安全出生点，不重复普通清场/遗物。祭台支付25HP、可致死，仍用RARE/TREASURE池；确认显示当前生命→支付后生命和致死警告。频率fork/secret/standalone_altar/coffin=0.45/0.35/0.25/0.65。

真假墙面异常共用3种外观，普通COMBAT也会有0～2处假线索；只有30px内显示“[E] 检查墙面”，真线索检查两次才进入，假线索只反馈一次；未发现的隐藏房不出现在小地图和已清房总数中，发现后本层可重访。危险墓道用血迹与偏殿暗色表达，原安全连边保留，另加两房绕路后汇合；不强制走风险路线，Boss最短距离不变。隐藏房有高价值供物和一次风险交互。基础8～12房主图保持，最多额外增加2个绕路房和1个隐藏房，仍复用room.tscn。

TombRiskEvent只读资源与TombRiskResult纯结果分离；TombExplorationPlan在原生成器之后装配可选图，TombRiskService持本层一次性账本，TombRiskContent只装配局部交互/波次/现有拾取物。普通古董源先从原主图选择；事件RNG独立派生run_seed/floor/room/event/version，不消费地图、遗物、Boss、普通敌人或普通古董流。频率与事件配置位于data/dungeon/events/。

事件奖励只进入AntiqueInventory，容量仍8格；满包不消耗Pickup，整理后可捡，未捡离房重访恢复。已领取/已丢弃不重生。伤害使用Health正式入口与红闪；主动代价不能被受伤无敌免单。确认锁与数据账本双重防重复；死亡/结束不能再触发。R同Seed重置事件/发现/库存，N新Run，跨层新账本；仅已捡古董随既有Carry保留。不保存墓穴中途状态。

探索装配版本2，事件抽样版本1（新配置内同Seed复现）。正式完整试玩从GameFlow启动，Museum→两层真实战斗→RunExit E→结算E→次日回馆。独立dungeon_test只作墓穴手感测试，结算明确显示“独立地宫测试模式”与R/N，绝不自行创建Museum。5晚人工选择记录与自动驾驶分开，未取得记录不宣称手感目标完成。

玩家仍80HP，两敌人/两Boss/武器/遗物2-4-7/八格背包数值未改。市场、现金、等级、待拍、拍卖结果不参与探索或战斗计算。历史回归显式关闭探索使用原主图夹具，保留全部断言；9A正式入口、完整流程、开启探索的Museum隔离与新功能另外覆盖。验收命令、真实结果及人工手感状态见docs/PHASE_9A_VERIFICATION.md。禁止新Museum功能、永久战斗成长、背包扩容、新敌人/Boss或9B。


## Phase 8D：古董商与夜间拍卖（历史验收，已合并main）

基准main 30a34047016dbdc7d34c18370f233ce8412eac41（8C已合并），分支codex/phase-8d-antique-market-auction。仅卖方交易/单件委托/夜间拍卖，验收后commit/push，不合并main，不进入后续阶段。以下旧阶段为历史，以本节为准。

已鉴定古董有三种去向：留馆展览获得长期门票；古董商收购换即时稳定现金；委托拍卖承担流拍与一晚机会成本。MarketService集中计算品相市场估值、75%古董商报价、80/100/130%保留价、60%起拍、10%步长与10%佣金；参数统一data/market/default_market_config.tres。市场估值round(base_value×condition/100)，报价等取最近¥10，最低¥10；净到账floor(final_bid×0.90)。Definition只读，修复现在也影响市场报价，不影响战斗。

古董商/拍卖委托台为真实64px Interactable，E打开并确认，Tab关闭。只交易已鉴定、未展出、未锁定古董。MuseumState集中can_sell/can_consign/can_assign/can_repair/is_auction_locked，数据层拒绝非法操作；一次成功锁确认，卖掉永久删除该实例且next ID不倒退。最多一件待拍，仍属于Collection，不能展/修/卖；Morning/Evening可免费取消，OPEN禁止交易并提示。

无待拍情报板E直接下墓；有待拍打开NightActivityPanel，下墓保留委托，拍卖不创建Dungeon。营业中情报板E仍先提前闭馆、等游客离场，再按待拍状态选择活动。GameFlow只装配Museum/DungeonSession/AuctionSession，同夜只进入一种，返回才day+1。

AuctionBidding是独立逐口确定性状态机，AuctionSession只呈现几何NPC/拍品/历史并处理E。三名虚构NPC预算使用独立RNG，按auction_seed/day/实例ID/定义ID/品相生成；每口轮转选预算足够者，跳过当前最高出价者，其他人都无法加价时结束。最终达到保留价成交，否则流拍；AuctionResult只持纯值。GameFlow验证当前Session结果身份/返回锁，MuseumState按pending ID校验一次原子结算。成交加净额、删除实例、清委托；流拍保留品相和身份，仅清委托。

ProfileStore VERSION=3，保留原user://museum_profile_v1.json路径。v2迁移无待拍，其余完整保留；v1继续迁移已鉴定100品相。v3待拍缺失/未鉴定/已展出/字段非法安全清理，优先保留展柜归属。交易/委托/取消/拍卖回馆保存；拍卖前先保存，途中退出恢复同一安全地面待拍状态，不恢复竞价。测试仅in_memory或user://tests/phase_8d等隔离路径，不读写正式档。

市场/拍卖/现金/委托不得传入Dungeon战斗、地图、掉落或Seed；保留80HP、8格背包、武器/敌人/Boss/遗物原参数。必跑Phase1～8D和8D图形/导入/启动。真实出售、标准成交、高价流拍、中途退出与夜间二选一结果见docs/PHASE_8D_VERIFICATION.md，人工手感和程序驾驶分开报告。禁止买方竞拍、市场行情、砍价/关系、声望、员工、专题展和战斗成长。完成后停止。


## Phase 8C：古董鉴定、品相与修复（历史验收）

基准main 125080906182bc2b01ed4bcdca73050f90946369（8B已合并），工作分支codex/phase-8c-appraisal-restoration。仅授权鉴定/品相/修复，验收后提交push，不合并main、不进入8D。以下旧阶段章节为历史，以本节为准。

现场获得不等于正式馆藏鉴定：夜间名称、基础估值、格数与风险取舍不变。结算RunResult新增与antique_ids等长的antique_conditions；独立AntiqueCondition RNG按run_seed/definition_id/cargo_index/出发日期生成55～90品相，不污染地宫RNG。成功EXTRACTED/COMPLETED入藏时identified=false、condition取快照；DEAD不入藏。

馆长办公室旁新增鉴定台和修复台，靠近E打开，选中后E确认，Tab关闭；成功后关闭重开才可处理下一件。鉴定免费，未鉴定不能布展且不贡献吸引力。Morning/Evening可作业，OPEN/NIGHT在MuseumState数据层拒绝。修复可选，不是开馆前置；费用ceil((100-condition)/10)×稀有度单位20/40/60/100，一次恢复100，资金不足/重复修复不扣款。没有战斗属性、出售或小游戏。

MuseumState.appeal_for集中计算max(1,round(base_appeal×condition/100))，未鉴定为0。HUD、库房、展柜、营业目标和游客选择读取同一结果；共享AntiqueDefinition不修改，修复无需重新布展。MuseumWorkPanel共用选择/确认逻辑，Appraisal/Restoration仅区分作业。

地面存档升级schema VERSION=2，保留user://museum_profile_v1.json原路径以读取旧档。v1所有已有馆藏迁移identified=true/condition=100，保持展柜/现金/等级/日期/next ID；下一次保存自动写v2。v2非法condition或非bool identified跳过该条目，非法归属继续拒绝。鉴定/修复成功立即触发安全地面保存。测试只使用in_memory或user://tests/phase_8c等隔离路径，禁止读写正式档。

Day1空馆→真实夜间拾取/击杀Boss/F撤离→Day2库房待鉴定→免费E鉴定→低品相直接布展营业；真实门票收入可支付可选修复。Phase1～8C及8C headless/graphical/import/startup必须通过。手感人工验收与程序驱动图形验证分开报告，见docs/PHASE_8C_VERIFICATION.md。鉴定/修复/现金/馆舍成长不得改变80HP、8格背包、地图/Seed、武器、敌人、Boss、遗物或古董掉落。


## Phase 8B：持久化博物馆成长（历史验收）

基准 main b3c6dbc5308d47f96c2fdd52ed4f6384ff916783，分支 codex/phase-8b-museum-progression。用户授权验证后commit/push，禁止合并main、不进入8C。旧阶段章节为历史，以本节为准。只新增馆舍等级、展柜/游客经营上限、建设牌消费和地面存档；禁止任何永久战斗属性、背包扩容、开局Buff、商店/拍卖/修复/员工等扩展。

等级数据唯一来源data/museum/levels.tres，Definition只读。MuseumState按等级生成稳定CASE_1…CASE_8，upgrade(expected_level)校验阶段/旧等级/余额并原子扣款；建设牌单次确认成功后必须关闭再打开，防连按重复扣费/跳级。Museum只追加新柜，不重建收藏和旧柜。升级不允许降级、退款。

MuseumProfileStore仅编码地面纯值JSON v1，默认user://museum_profile_v1.json；保存日期、现金、等级、OwnedAntique/next ID、展柜归属及安全MORNING/EVENING阶段。保存触发：初始化、布展/撤展、升级、闭馆、夜间前、夜间成功/死亡回馆。OPEN与NIGHT不能直接保存。恢复闭馆阶段防同日重启再次开馆；夜间退出只回最近地面快照，不恢复Run。

无文件/坏JSON/不支持版本/全局非法字段安全默认；未知古董、重复/非法实例、非法/未解锁/重复展柜归属跳过并warning。next ID不得重用。写临时文件flush后rename替换，失败显示提示并拒绝从未保存地面进入夜间。测试必须显式注入in_memory或user://tests/phase_8b下隔离路径，严禁读写正式档。

GameFlow只装配夜间原接口，DungeonSession不得读取museum_level/cash；Player、Enemy、Boss、Relic、背包、掉落/Floor Seed与规则完全不改。必跑Phase1～8B及8B图形/导入/隔离路径启动；人工体验与程序驱动分开报告。验收见docs/PHASE_8B_VERIFICATION.md，完成后停止。


## Phase 8A：博物馆昼夜循环（历史验收）

基准 main 0a8784d193b6c96471538027fe0d00dfba2c1c46；工作分支 codex/phase-8a-museum-day-night-loop。仅实现可玩昼夜闭环，验证后提交并push，不合并main、不进入8B。旧阶段章节为历史，以本节授权为准。没有磁盘存档；门票现金仅本进程记录，无消费、出售、拍卖、鉴定、真假、修复、员工、成本、扩建或新墓穴。

GameFlow持有MuseumState、日期、阶段和当前RunResult，只装配Museum与现有DungeonSession。MORNING自由布展→售票台E开馆→OPEN游客营业→停止进客并等现有游客离开→EVENING→情报板E进入NIGHT→结算E回馆→次日MORNING。营业是可选的：MORNING可从情报板E直接下墓；OPEN可从情报板E提前闭馆并出发，停止进客、现客离场后自动进入NIGHT，无需等满60秒。跳过营业不产生票款，当日营业统计为0。只在夜晚结果实际回馆时日期+1；R/N夜间重试不推进日期，也不转移战利品。

OwnedAntique按instance_id/definition_id/acquired_day保存单件；MuseumCollection与夜间AntiqueInventory是不同对象。成功EXTRACTED/COMPLETED结果antique_ids逐件入藏，重复定义仍有不同实例ID；DEAD只显示遗失，无新入藏，已有收藏/展柜/现金不变。acquired_day记录实际出墓当晚日期，回馆后日期再+1。正式主入口默认空馆藏、空展柜、零现金，不赠送古董。只有自动测试显式设置GameFlow.initial_test_collection=true时，才注入day0测试唐三彩马用于布展夹具。

MuseumPlayer只有加减速移动、朝向和统一64px交互，不带Weapon/Health/RelicRuntime。3个DisplayCase按实例归属，场景真实显示名称/几何图标；同件不可双柜、不同重复件可以。E选择/查看、柜旁R撤展；白天没有删除/出售入口。营业中禁止调整，闭馆后恢复。库房无限，Tab/E关闭面板。

MuseumBusiness默认营业60秒，10:00至17:00，票价¥5；空馆不能开馆且游客目标为0；至少一件展品即可开馆，目标clamp(5+floor(appeal*0.5),1,60)，同时最多8名，分批入场。Visitor独立RNG以museum_seed/day/index稳定派生，按已有展品吸引力加权选择、看一至两柜后离场，未展出藏品不会被选择，空馆不会生成游客，开馆资格统一由MuseumBusiness.can_open/start校验，不只依赖UI。票款由游客和营业索引双重一次保护，实际售票人数可能小于目标。时间结束不再补客，所有现客退出后结算门票收入。

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

本项目是 Godot 4.x / GDScript / Windows 的原创 2D 俯视角 Roguelite《大盗墓时代》。阅读 README、PROJECT_PLAN、ARCHITECTURE、GAME_DESIGN 后再修改。用户指令优先；每次只执行明确授权的 Phase。当前授权 Phase 9B.2；范围和 Git 规则见本文顶部当前实现章节。

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
