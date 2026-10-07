# Phase 8D 验证：古董商与夜间拍卖

2026-10-07，Windows / Godot 4.6.2 标准版 / Compatibility。

Phase8C提交`30a34047016dbdc7d34c18370f233ce8412eac41`开始前已在最新本地/远端main；fetch确认工作区干净，从main新建`codex/phase-8d-antique-market-auction`。本任务只实现卖方交易、单件委托和夜间拍卖，不合并main，不进入后续阶段。

## 经济公式与三种去向

留馆=长期门票；古董商=即时稳定现金；拍卖=一个夜晚机会成本+可能流拍的波动收入。古董商报价固定，但拍卖不是保证收入，尤其高保留价可能完全没有现金。

所有经济计算统一`AntiqueMarketService`，只读参数由`data/market/default_market_config.tres` / AntiqueMarketConfig提供，不在UI/NPC重复计算：

| 项目 | 公式 |
|---|---|
| 市场估值 | 已鉴定时round(base_value×condition/100) |
| 古董商 | max(10, round_to_10(market_value×0.75)) |
| LOW/NORMAL/HIGH保留价 | round_to_10(market_value×0.80/1.00/1.30)，最低10 |
| 起拍 | max(10, round_to_10(market_value×0.60)) |
| 步长 | max(10, round_to_10(market_value×0.10)) |
| 实际到账 | floor(final_bid×0.90) |
| 佣金 | final_bid－实际到账 |

`round_to_10`四舍五入到最近10元。成交价始终由10元倍数起拍/步长组成，佣金是成交价10%，展示与入账一致；流拍佣金/净到账为0。0品相合法条目按价格最低10保护，未鉴定不能进入交易。

唐三彩马品相76的单项验证：市场1216、商人910、起拍730、步长120，三档保留970/1220/1580；修复100后市场1600、商人1200。共享Definition.base_value仍1600、exhibit_appeal仍50，展览与市场价值继续分离。

## 古董商、委托与数据边界

博物馆新增真实MuseumInteractable：古董商(800,540)、拍卖委托台(430,540)，沿用64px距离和WASD/E交互。MuseumDealerPanel/AuctionConsignmentPanel共用MuseumMarketPanel；E打开列表、选择后E确认、Tab关闭；成功后确认锁定，关闭重开才处理下一件。报价/保留价通过统一Service展示，不接受任意保留金额输入。

MuseumState集中can_sell/can_consign/can_assign/can_repair/is_auction_locked。只可交易已鉴定、未展出、未待拍实例；展品须先撤展。出售一次加钱并删除独立实例，State通知时钱和身份都已完成，立即安全地面存档；重复E或数据层调用无第二笔款。next ID保留，未来同Definition新件使用新ID。

最多一件待拍：auction_lot_instance_id/auction_reserve_mode。委托不删除OwnedAntique，不修改品相，仅锁定。assign/repair/dealer/再次委托在数据层拒绝，不仅隐藏按钮；待拍库房显示锁定。已鉴定未展出其他物品仍可卖，但不能委托第二件。Morning/Evening免费取消恢复操作性；OPEN/NIGHT不允许交易/委托/取消。OPEN真实交互提示“营业中无法处理古董交易”。

## 夜间选择与架构

无待拍：情报板仍E直接下墓。有待拍：情报板E打开NightActivityPanel，选择“下墓（待拍品保留）”或“参加拍卖会（本晚不下墓）”。选择锁定且GameFlow提前设置_changing，快速点两种只产生一种活动；取消面板不出发。

营业中情报板E仍可提前闭馆，先停止入客、等待现客离场，安全Evening再进入选择或直接下墓。Morning也可直接选择夜间，不强制营业。

- GameFlow：并列装配Museum→DungeonSession→Museum与Museum→AuctionSession→Museum；只传入拍品快照、日期、auction_seed和保留模式，不包含竞价算法。出发前保存安全地面，返回后才day+1。
- AuctionSession：独立几何场景，显示拍品名称/品相/市场/起拍/保留价/当前价/最高NPC/历史。每次E一口或结束；结束后另一次E返回次日。无Dungeon实例、房间、敌人或玩家竞拍操作。
- AuctionBidding：纯状态机，三预算、循环游标、历史、结束结果。金额完全来自MarketService，不读MuseumState。
- AuctionResult：只保存instance_id/sold/market_value/reserve_price/final_bid/commission/net_proceeds/字符串bid_history，无Node、NPC对象或State引用。

NPC为三个虚构原型：地方收藏家(0.85～1.20)、沪上商人(1.00～1.45)、洋行买办(0.95～1.75)。稀有度倍率小加成为0/.05/.10/.20，均在市场配置集中定义。

预算使用独立RNG，以拍卖版本1、auction_seed、day_number、instance_id、definition_id、condition稳定字符混合派生。价格基于market_value，三NPC预算取最近10元。每轮从游标开始循环选择预算≥下一口者；第一次报起拍，以后加一个step，直到所有NPC预算低于下一口。预算驱动原型允许仍有预算的领先者继续报价，不模拟心理/退出策略；这严格保留第一版“所有预算不足下一口才结束”的简化规则。不会瞬间随机生成最终成交价，没有Space快进。

最高价达到保留价才成交。回馆时State检验pending ID/市场/保留价/佣金与净额；成交原子加净额、删除原件、清待拍；流拍保留原件/品相/identified，不加现金，仅解锁。GameFlow仅接受当前已完成Session的那个Result对象，Session返回锁与Flow切换锁拒绝重复emit/E/旧结果；清pending后State再次结算也拒绝。拍卖返回后已是次日，无法同夜追加下墓。

## v2→v3 与安全地面恢复

MuseumProfileStore.VERSION=3，仍读写原`user://museum_profile_v1.json`路径以自动发现老档。v2迁移时无待拍，原日期/现金/等级/实例/identified/condition/展柜/next ID完全保留，正式GameFlow初始化随后的保存写v3。v1兼容鉴定=true/品相100迁移继续保留。

v3多保存pending ID和reserve mode。载入先恢复展柜，再处理委托：不存在/未鉴定/已展出待拍清空，已展出时优先保留展柜并warning；非法字段/保留模式安全清理，不崩溃。库房行品相校验延续v2规则。

出售、委托、取消立即保存；拍卖前安全地面保存待拍与模式，回馆结算、清锁、day+1再保存。AuctionSession不做中途存档。中途退出/销毁Flow后重启回同一安全地面，原待拍、现金、日期保持，不加载半途报价，重新参加按相同输入重演。

测试全部显式in_memory或`user://tests/phase_8d/<process_id>_*.json`隔离路径；启动也用测试路径，没有触碰正式玩家档。

## 三条真实流程与夜间二选一

`phase_8d_flow_checks.gd`从正式空Day1/GameFlow开始，无初始赠送、无主流程collection.add/inventory.add/cash注入、无F2：真实Door探索、武器/弹丸清房、E拾取四次古董、真实第一Boss击杀、F撤离/E回馆，Day2获得4件原件。

1. **古董商**：真实WASD走鉴定台/E/E鉴定唐三彩马A000002。它在四件cargo中索引1，确定品相85；市场1360、报价1020。真实人物走古董商，E打开/E出售/重复E，现金由0精确变1020，原件消失。读档及销毁/重建Flow后现金保持、原件不复活，next ID保留。
2. **下墓保留委托**：真实鉴定金丝玉佩A000003（品相62），委托台E打开/选择NORMAL/E确认。真实情报板E出现选择，点击下墓；仅创建Dungeon，待拍仍锁定。真实敌人攻击造成死亡，E回馆推进Day3，已有现金/待拍件保持。下一晚仍可参加该委托拍卖。
3. **标准成交**：Day3真实情报板选择拍卖，AuctionSession逐轮真实E输入（每次一口，预算自然结束）。auction_seed192034，市场1364、保留1360，最终2220，佣金222，净到账1998。结束另E回馆Day4，现金3018，A000003删除、待拍清空；重复E/旧Result不会再入账；磁盘与重启完全一致。
4. **高保留流拍**：真实鉴定A000004（品相66，市场1452），选择HIGH保留1890。为流拍回归夹具，在不改NPC预算/公式的前提下对0～127拍卖Seed有限扫描，取第一可流拍的seed15。正式运行默认auction_seed192034未改，夹具仅覆盖确定性流拍输入。进入后推进3口并销毁Flow，重建恢复Day4/现金3018/HIGH待拍；重新选择拍卖逐轮E，到最终1770低于1890，自然流拍。E回Day5，现金仍3018、原件/品相66/鉴定状态保持、待拍清空；保存/重启一致，再真实展柜E/UI摆上这件退回古董。

UI选择使用实际面板的选择/按钮回调，地面人物通过WASD移动。夜间复用已有程序驾驶，在战斗/底座/出口会定位玩家；仍触发真实Door、武器、敌人AI、Health、E/F，不用直接入藏替代主路径。上述是程序驱动图形/逻辑完整路径，不是人工主观试玩。没有本阶段人工手感反馈。

## 自动覆盖与确定性样本

专项1569项包含：全部经济公式/最近10元/最低10/佣金；品相修复提高市场而Definition只读；unidentified/displayed/pending拒绝；OPEN数据/UI拒绝；唯一待拍、取消免费、失去实例不可再用、ID不倒退；100 Seed三预算同输入稳定、每口增幅/预算上限、重复全历史/最终结果一致、结束后三预算均不足下一口、再次advance不产生报价；成交及流拍一次性State结算、错误佣金/低于保留价成交拒绝；v2实际GameFlow迁移/v3pending读写/坏pending清理；真实三路径/重启/中途退出/二选一；市场后Dungeon隔离快照。

固定样本而非全游戏概率承诺：RARE唐马76同实例/Day5、100个auction_seed，LOW/NORMAL/HIGH成交100/100/67；COMMON小罐90同实例/Day5、512个seed，成交512/504/319。说明三档存在差异，NORMAL也能流拍，HIGH更冒险。没有做最终经济平衡，也不保证每种古董样本三档均严格不同。

## Dungeon隔离证据

实际GameFlow分别以普通馆藏、HIGH待拍、商人现金+拍卖净收入状态进入同Seed DungeonSession，对比完整PlayerStats与80HP、8格背包、两层Layout签名、两层古董掉落、敌人/Boss资源参数、Relic参数/奖励序列，全部相同。预算独立RNG不消耗地宫RNG。

本阶段生产DungeonSession/RunResult/Player/Weapon/Enemy/Boss/Room/Relic/DungeonGenerator/古董掉落算法和对应data资源Git差异为0；改动仅地面State、UI、Profile与GameFlow并列场景装配，没有市场值进入战斗。鉴定/修复的既有80HP/8格规则保持。

## 回归结果与运行命令

| 套件 | 检查数 | 失败 | 退出码 |
|---|---:|---:|---:|
| Phase1 |27|0|0|
| Phase2 |204|0|0|
| Phase3 |94|0|0|
| Phase4 |105|0|0|
| Phase5A |61|0|0|
| Phase5B |236|0|0|
| Phase6 |164|0|0|
| Phase6.5 |174|0|0|
| Phase7A |306|0|0|
| Phase7B |722|0|0|
| Phase8A |482|0|0|
| Phase8B |305|0|0|
| Phase8C |297|0|0|
| Phase8D headless |1569|0|0|
| Phase8D graphical |1569|0|0|

14套headless合计4746检查、0失败；图形另1569检查、0失败。导入解析、headless正式入口与图形正式入口（均隔离存档）退出0，最终日志无ERROR/资源泄漏。坏档测试的warning为预期拒绝/清理路径。

唯一旧测试修改：phase_8c_profile_checks.gd的“下一次保存schema=2”改为当前MuseumProfileStore.VERSION，非法未来版本改为VERSION+1；保留旧v1迁移与identified/condition/展柜/next ID的全部断言。新增8D专项独立验证v2→v3。其余Phase1～8C测试未删断言或改行为。

```powershell
$godot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path . --editor --quit
& $godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase_8d/startup_validation.json
foreach ($phase in @('1','2','3','4','5a','5b','6','6_5','7a','7b','8a','8b','8c','8d')) {
    & $godot --headless --fixed-fps 60 --quit-after 150000 --path . --script "tests/phase_${phase}_smoke.gd"
}
& $godot --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 150000 --script tests/phase_8d_smoke.gd -- --capture
& $godot --path . --position -16000,-16000 --quit-after 10 -- --profile-path=user://tests/phase_8d/startup_graphical.json
```

忽略不提交的最终日志：logs/phase_8d_final_*.log、phase_8d_graphical_final.log、phase_8d_import_final.log、phase_8d_startup_final.log、phase_8d_startup_graphical_final.log。实际查看图形截图dealer_offer/dealer_sold、consignment_choice_1/_2、night_choice、bidding、auction_sold/unsold、unsold_return_exhibit；文字不遮挡成交/佣金/收入、夜间互斥提示明确。

## 文件与限制

新增data/market/default_market_config.tres、scenes/auction/auction_session.tscn；scripts/market/antique_market_config.gd、antique_market_service.gd；scripts/auction/auction_result.gd、auction_bidding.gd、auction_session.gd；scripts/ui/museum_market_panel.gd、museum_dealer_panel.gd、auction_consignment_panel.gd、night_activity_panel.gd；tests/phase_8d_smoke.gd、phase_8d_market_checks.gd、phase_8d_profile_checks.gd、phase_8d_boundary_checks.gd、phase_8d_isolation_checks.gd、phase_8d_flow_checks.gd（所有新脚本含.uid）；新增本文档。

修改scripts/flow/game_flow.gd；scripts/museum/museum_state.gd、museum_profile_store.gd、museum.gd；scripts/ui/museum_collection_panel.gd、museum_work_panel.gd；tests/phase_8c_profile_checks.gd；AGENTS.md、README.md、ARCHITECTURE.md、PROJECT_PLAN.md。

只做单件卖方委托，固定三NPC预算模型，不做真实心理/策略、买方竞拍、批量拍品、手续费流拍费、自由输入保留价或Space快进。价格仍原型数字，无长期经营平衡人工验收。正式auction_seed通过GameFlow Inspector参数配置，同版本/资源/日期/实例/品相输入下重现；next ID/日期变化自然改变未来预算。

存档沿用原安全地面边界，没有拍卖断点、云档、多档或自动备份；写盘失败保留运行时完整事务并提示，出发前存档失败会阻止夜间，未引入回滚机制。坏条目按既有规则可能跳过，未知根schema回安全空档。

没有买方拍卖、专题拍卖、行情/朝代热度/城市差价、声望/VIP、线上竞拍、任务、假货、砍价/关系、员工、专题展、博物馆Buff或战斗成长。完成提交push后停止。
