# 大盗墓时代

## Phase 9B.3：敌人威胁、组合战斗与Build波动（当前实现，人工验收待完成）

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

基于已合并main b74bb35d4e7d4059f8272681f7fb8652629e7e18，开发分支codex/phase-9a-tomb-risk-exploration。仅墓内可选探索；完成后提交并push本分支，不合并main、不进入9B。下方旧阶段为历史记录，以本节为准。

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


## Phase 8B：馆舍成长与存档（历史验收）

当前开发分支codex/phase-8b-museum-progression，基于main b3c6dbc。首次没有存档时Day1/空馆藏/现金0；早晨可直接下墓。成功返回后亲手布展，至少1件展品才能营业，门票现金唯一消费是馆舍建设。

| 等级 | 馆舍 | 展柜 | 游客总容量 | 下一次扩建费用 |
|---|---|---:|---:|---:|
| 0 | 私人古物陈列室 | 3 | 30 | ¥1,000 |
| 1 | 古物陈列馆 | 5 | 45 | ¥3,000 |
| 2 | 地方古物馆 | 8 | 60 | 已满级 |

靠近馆舍建设牌E查看，再E确认，Tab关闭；资金不足不扣款，成功后须关闭并重新打开才能继续扩建。营业中不能扩建/换展。Level1开放东侧展厅，Level2开放西侧展厅，旧展品保留。游客目标为有展品时min(5+floor(吸引力×0.5),馆舍容量)，空馆仍0，同时在馆最多8人，票价¥5。

存档为user://museum_profile_v1.json，自动保存布展、撤展、闭馆、扩建、夜间前和回馆后的安全地面状态。重启自动恢复日期/现金/等级/藏品实例/展柜；闭馆后重启仍是傍晚。夜间退出不续Run，回最近地面状态。坏档安全新档/异常条目跳过并提示；没有多档管理或迁移。馆舍成长不影响夜间HP/攻击/敌人/遗物/掉落/八格背包。

```powershell
godot --headless --fixed-fps 60 --quit-after 150000 --path . --script tests/phase_8b_smoke.gd
godot --path . --disable-vsync --fixed-fps 60 --quit-after 150000 --script tests/phase_8b_smoke.gd -- --capture
# 验证启动使用隔离存档，不碰正式档：
godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase_8b/startup_validation.json
```

配置data/museum/levels.tres。完整真实门票升级、重启和死亡恢复见docs/PHASE_8B_VERIFICATION.md。旧阶段章节为历史，最新规则以本节为准；本阶段禁止合并main或继续8C。


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


原创独立 2D 俯视角房间式 Roguelite。背景为 1920～1940 年代架空中国：盗墓者探索古墓，收集古董与遗物，选择继续深入或带着收益撤离。

## 当前状态

当前 **Phase 9B.2 多层Boss与高频Build**，尚未合并main。正式入口从博物馆出发，夜间五层基础房量为8～10/10～12/12～14/14～17/12～15，五层分别尸蟞母巢、大帅尸、纸扎将军、铜甲尸王、镇墓兽。普通敌人六类、生产战斗模板十五份，越深组合更多、初始敌数更高，Tier3倍率不变。

每层一个安全遗物房和一件Boss遗物，普通Combat第4/12/24清房再奖励，完整探索最多13件无重复战斗遗物，正式池20件。五帝钱/黑火药/穿透/镜像等自然叠加，F2仅开发调试，正式试玩不用它。非最终层Boss后E深入/F撤离，最终Boss先捡奖励再RunExit E结算回馆。

古董仍每层1Antique Room+1Combat Cache，背包8格、质量随Profile提升。F2/F4医疗包+15/+20，满血不消费。80HP、跨层HP/Build/古董、R/N重开、Profile v4与跨日Seed保持；风险真假墙和事件参数不变。人工新手感待试玩，详见顶部说明与9B.2验收文档。

## 开发环境与运行

- Godot 4.6.2 标准版（GDScript），Windows 为主要开发平台。
- 渲染器：Compatibility；逻辑画布：1280 × 720，canvas_items 缩放。
- 使用 Godot 项目管理器导入根目录 `project.godot`，打开后按 F6 运行当前场景，或 F5 运行项目。
- WASD 移动，鼠标瞄准，按住鼠标左键连续射击。
- F1 或“测试伤害”按钮造成 25 点伤害；受伤后有 0.25 秒无敌期。默认 80 HP，间隔受伤四次死亡。
- 清场后走入绿色门过房；橙色门锁定。小地图显示未探索、战斗中、已清场和当前位置。
- R 或“同图重开”回到相同run_seed第一层、80HP、空Build、零奖励进度。N 或“新图”选择新 Seed，生成不同拓扑。
- HUD 显示当前 Seed；动态小地图以 S/B/A 标记出生/Boss/古董占位房。Esc 或“退出”关闭窗口。
- 命令行：`godot --path . --editor`；Godot 不在 PATH 时使用安装位置的完整路径。
- 导入/解析检查：`godot --headless --path . --editor --quit`。
- 启动冒烟检查：`godot --headless --path . --quit-after 10`。
- Phase 1 行为检查：`godot --headless --path . --script res://tests/phase_1_smoke.gd`。
- 图形/鼠标检查：`godot --path . --script res://tests/phase_1_smoke.gd -- --capture`，截图保存在忽略的 `logs/`。
- Phase 2 五房完整检查：`godot --headless --path . --script res://tests/phase_2_smoke.gd`。
- Phase 2 图形检查：`godot --path . --script res://tests/phase_2_smoke.gd -- --capture`，保存各房间、清场和死亡截图。
- Phase 3 完整检查：`godot --headless --path . --script res://tests/phase_3_smoke.gd`。
- Phase 3 图形检查：`godot --path . --script res://tests/phase_3_smoke.gd -- --capture`。

正式GameFlow的`--seed`用于新档Campaign初始化；已有有效Campaign不会被覆盖。复现HUD报告的实际Run Seed应使用独立地宫：

```powershell
godot --path . res://scenes/main/dungeon_test.tscn -- --seed=192034
```

也可修改 `dungeon_test.tscn` 根节点 Inspector 的 `seed_value`。不传参数时从默认 Seed 开始；选到新 Seed 后 R 重复该 Seed。独立/开发N选择的Run Seed不持久化；正式退出重进按已保存Campaign和当日恢复，应记录HUD的实际Run Seed用于独立复现。

相同引擎（当前验证为 Godot 4.6.2）、生成版本、配置与模板池顺序下，相同 Seed 重现完整拓扑与模板选择。不同 Seed 不保证每次都得到不同图，所以 N 最多尝试 16 个候选，失败保留当前图并提示警告。无窗口与图形测试还会在 `logs/phase_3_digest_*.txt` 保存 100 Seed 的结果摘要供跨进程比较。

调参：编辑 `data/definitions/default_player_stats.tres`，修改 MaxHP、MoveSpeed、AttackDamage、AttackSpeed（每秒次数）、ProjectileSpeed、加减速、弹丸寿命和无敌期。CurrentHP 属于每个玩家的 Health 实例，不能写回共享初始资源。Dummy 的初始 HP 可在 `dummy.tscn` Inspector 调整，测试伤害可在测试场景 Inspector 调整。

房间内容：编辑 `data/rooms/test_*.tres` 的敌人场景、生成点、障碍、名称和颜色。生成配置位于 `data/tombs/default_dungeon_config.tres`，可调整房数、最低深度和模板池。地图状态属于运行实例，不能写回模板；模板的历史 `room_id` 是模板 ID，`map_position` 仅供 Phase 2 旧夹具使用，随机节点不读取该坐标。

尚未配置发行导出预设；需要发布时再安装对应版本导出模板。不同 Godot 4.x 版本升级前应重新执行导入和启动检查。

## 目录

| 路径 | 用途 |
| --- | --- |
| scenes/ | 主入口及后续玩家、房间、敌人、UI 场景 |
| scripts/ | 按职责划分的 GDScript |
| data/ | 后续 Resource 数据定义及实例 |
| assets/ | 原创美术、音频、字体 |
| tests/ | 后续核心行为验证场景与脚本 |
| docs/ | 后续设计记录和验证报告 |

尚未实现的目录由 `.gitkeep` 保留。当前运行入口为 `scenes/main/game_flow.tscn`，独立夜间入口为 `scenes/main/dungeon_test.tscn`；`room_test.tscn` 是需注入布局的控制器装配场景，不直接 F6 运行。Phase 0/1 独立入口保留；Phase 2 原始十字图位于 `tests/fixtures/fixed_room_test.tscn`，原来的 204 个断言全部保留。

## 文档与 Git

- `PROJECT_PLAN.md`：逐阶段范围和验收。
- `ARCHITECTURE.md`：系统边界、数据与依赖约定。
- `GAME_DESIGN.md`：核心玩法与首个 Demo 范围。
- `AGENTS.md`：所有后续开发任务必须遵守的项目规则。
- `docs/PHASE_3_VERIFICATION.md`：实际验收、命令、逐项结果及限制。
- 跟踪源码、场景、Resource、源资产和 Godot `.uid`；不提交 `.godot/`、构建输出和本地日志。
- 开始任务前检查 `git status`；功能分支默认使用 `codex/` 前缀。提交需有明确阶段与范围，不自动推送。

## Phase 4 敌人与验证

五模板组合为 4 尸蟞、6 尸蟞、3 枪手、4 尸蟞 + 1 枪手、3 尸蟞 + 2 枪手。编辑 data/enemies/*.tres 调整生命、速度、伤害、冷却和前摇；编辑 RoomDefinition.spawns 的每项场景/数据/位置，entry_grace_time 调整入房观察期。每个生成点与四入口至少相距 180 像素。

```powershell
godot --headless --path . --script res://tests/phase_4_smoke.gd
godot --path . --script res://tests/phase_4_smoke.gd -- --capture
```

完整结果、人工反馈与限制见 docs/PHASE_4_VERIFICATION.md。未实现完整寻路、正式美术、音效或 Boss；工程遗物只用于开发回归；正式池为 Phase 5B 的八件遗物。
START 与其他房复用 room.tscn 和随机视觉/障碍模板，不复制场景、不修改共享 spawns；START 不调用 EnemySpawner，因此不应用观察期。COMBAT 的 180px 入口间距、0.35 秒观察期和攻击前摇保持；第一层BOSS为正式晋北大帅尸，第二层BOSS为镇墓兽，ANTIQUE安全清场并提供古董底座。

## Phase 5A 开发测试

当前新增 RelicDefinition / RelicInventory / RelicEffect / RelicRuntime 与局部战斗 Hook。遗物随唯一 Player 跨房保留，R/N 或死亡清空；定义只读，效果实例每次安装独立；同一 ID 不重复获得。

- 1：强力火药，攻击请求伤害 ×1.5（默认 20 →30，Tier1 65HP 尸蟞由 4 发变 3 发）。
- 2：双生铜钱，一次输入发射两枚方向 ±6° 的弹丸，只计一次冷却。
- 3：血契，每个敌人首次死亡恢复 5 HP，上限 MaxHP。
- Backspace：卸载全部工程遗物，后续攻击恢复原值。已经发射的弹丸保留发射时快照。

底部显示当前遗物列表。本节工程遗物不进入正式池；正式获得见下文。仍无永久存档或正式遗物美术。人工反馈确认“双弹清晰，跨房保留”；其余主观效果验收未确认，详情见 docs/PHASE_5A_VERIFICATION.md。

```powershell
godot --headless --path . --script res://tests/phase_5a_smoke.gd
godot --path . --script res://tests/phase_5a_smoke.gd -- --capture
godot --path . -- --seed=1
```

数据在 data/relics/，效果实现分别位于 scripts/relics/effects/。配置引用独立 effect_script，不添加核心脚本 ID 分支。新增参数或运行对象时继续维护 copy/卸载生命周期。Phase5A/5B已合并main；当前工作为Phase7A，仍不自动合并main。
## Phase 5B 正式奖励与 Build

首次清场第2、4、7个普通COMBAT房生成一件底座奖励。START、ANTIQUE、BOSS占位不计数，重访不重复。靠近底座64px内按E拾取，名称/简短说明就地显示；离房未拾取则丢失，不在重访补发。

正式池只有五帝钱、黑火药、尸油灯、镇尸钉、铜镜、墨斗、洛阳铲、引魂纸鸢8件，不包含工程test_*。奖励按Seed和版本独立无放回抽取；R复现地图和奖励序列并清空Build；N重建新图/奖励进度。相同引擎/池/版本下可复现，尚无存档。

| 遗物 | 实际规则 |
| --- | --- |
| 五帝钱 | 双弹±5°，每发80%伤害，一次冷却 |
| 黑火药 | 每个成功命中产生半径72px、50%弹丸伤害爆炸；可伤原目标，不递归 |
| 尸油灯 | 3次3HP DOT，间隔0.35秒；同敌人刷新不叠层 |
| 镇尸钉 | 穿透1个敌人；撞墙消失，同一弹不重复命中同敌人 |
| 铜镜 | 每3次攻击在最终批次两侧±20°各复制一组；单弹变3，五帝钱双弹变6 |
| 墨斗 | 起点到命中点24px宽墨线，对其他敌人一次6伤害，视觉0.3秒 |
| 洛阳铲 | 每5次追加铲风：2.2倍伤害、1.3倍速度、寿命0.22秒、体积1.8倍 |
| 引魂纸鸢 | 有效非致命受伤充能；下次攻击加±15°两侧弹并消耗，未用充能跨房保留 |

E是正常获得方式。F2打开/关闭正式遗物开发添加按钮；1/2/3工程键和Backspace全移除仍保留，仅用于开发，不影响正式池。

```powershell
godot --headless --path . --script res://tests/phase_5b_smoke.gd
godot --path . --script res://tests/phase_5b_smoke.gd -- --capture
godot --path . res://scenes/main/dungeon_test.tscn -- --seed=192034
```

Seed192034正常测试在第2/4/7次清房获得墨斗/五帝钱/黑火药，再继续战斗。详细测试、文件清单和人工验收状态见docs/PHASE_5B_VERIFICATION.md。以上为Phase5B历史验收；当前分支codex/phase-6-5-tomb-beast-finale，完成后停止。
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
## Phase 6：Boss与第二层

第一层BOSS忽略普通模板刷怪，出现晋北大帅尸（基础650HP，Tier3实际845HP）。冲锋前红色方向线0.65s，然后650px/s直冲0.45s；撞墙停止、方向不追踪、一次伤害。震荡前橙色圆环0.8s，180px内结算一次。首次半血召唤3只尸蟞，Boss死亡清理余下召唤物、开门并产生墓道。

靠近墓道64px内按E进入第二层，当前HP和遗物ID保留；效果重新安装，铜镜/铲计数、纸鸢充能、燃烧及武器冷却重置。奖励2/4/7为整局累计，不按层重发，不会有第四件。第二层深度加3，第一普通房至少Tier2；第二层BOSS为镇墓兽，胜利后E通关，无第三层。

HUD显示墓层、当前层Seed、有效深度与Tier。R在第二层也重开整个Run：同run_seed第一层、80HP、空Build、零奖励进度；N开始新Run。第二层Seed为`(run_seed XOR (2*104729)) + attempt*7919`，attempt从0开始，最多16次选与第一层空间签名不同的结果。参数、引擎、生成版本变化会影响复现。

```powershell
godot --headless --path . --script res://tests/phase_6_smoke.gd
godot --path . --script res://tests/phase_6_smoke.gd -- --capture
godot --path . res://scenes/main/dungeon_test.tscn -- --seed=192034
```

详细实际结果和人工验收状态见`docs/PHASE_6_VERIFICATION.md`。Phase6历史范围不含第二Boss；当前Phase6.5已补第二Boss与通关，仍无古董、撤离经济、第三层或存档。

## Phase 6.5：镇墓兽与两层Demo通关

第一层晋北大帅尸保持原数值/技能与已验收手感。第二层现在只有镇墓兽，不刷模板普通敌人：800基础HP、Tier3实际1040HP、速度80；固定扑击→石吼→地刺。

- 扑击开始记录位置，0.7s落点预警，0.35s扑向旧位置；90px落地一次27伤害（Tier3），障碍限制移动且不隔墙伤人。
- 石吼0.75s前摇锁向，5弹±30/15/0°，速度320、寿命3s、Tier3弹伤18.9，不追踪。
- 地刺固定交替Pattern，3个警告点，0.75s后55px内一次24.3伤害，0.25s后消失；Boss地刺施法状态0.8s。
- 首次半血狂暴：7弹±36/24/12/0°、5地刺、决策1→0.8s，所有前摇不缩短，不召怪。

第二层胜利后出现“墓穴深处已肃清 / [E] 返回地面”。64px内E显示通关结算：Run Seed、清理2层、剩余HP、当前遗物名字、COMBAT清理数、Boss击败2。通关后停止移动/攻击/过门；R同Run Seed重开第一层、N新局，均80HP空Build零奖励/击杀。没有第三层、古董经济、永久结算或存档；“返回地面”本阶段只通向开发结算界面。

```powershell
godot --headless --fixed-fps 60 --path . --script res://tests/phase_6_5_smoke.gd
godot --path . --script res://tests/phase_6_5_smoke.gd -- --capture
godot --path . res://scenes/main/dungeon_test.tscn -- --seed=192034
```

新增代码、真实流程、测试与人工状态见docs/PHASE_6_5_VERIFICATION.md。第一层与第二层Seed、跨层Build、2/4/7整局奖励规则保持。

## Phase 7A：古董房与随身背包

小地图A房现在安全开门并有一件古董：靠近64px按E带走，显示名称、估值和占格。背包默认8格，满包提示“背包空间不足”；Tab打开列表、选择一件后Delete或按钮丢弃（本Run永久删除，不在地上重生成）。背包打开时战斗继续；未领取的古董可离房后回来领取，领取或丢弃后不会补发。

古董与遗物完全分离，古董不改变HP、攻击或移动。正式8件资源位于data/antiques，初始价值/槽位按用户指定；两层同池均匀选择。版本1+Run Seed+楼层+房间ID确定选择，独立RNG不影响地图或遗物。重复古董可带多件，按各自槽位/价值累加。

古董随HP/遗物跨层保留，新层重建库存与UI；R/N清空。通关仅展示带回名称和总估值，没有黑市、钱包、出售、鉴定、真假或存档。结算内容可滚动，R/N提示固定在底部。

```powershell
godot --headless --fixed-fps 60 --path . --script res://tests/phase_7a_smoke.gd
godot --path . --script res://tests/phase_7a_smoke.gd -- --capture
```

详细资源表、实际拾取与回归结果见docs/PHASE_7A_VERIFICATION.md。当前分支codex/phase-7a-antique-inventory，提交push后停止，不合并main。

## Phase8A 独立入口与测试

```powershell
godot --path . res://scenes/main/dungeon_test.tscn -- --seed=192034
# 单独运行夜间（不经过博物馆）：
godot --path . scenes/main/dungeon_test.tscn -- --seed=192034
godot --headless --fixed-fps 60 --path . --script tests/phase_8a_smoke.gd
godot --path . --disable-vsync --fixed-fps 60 --script tests/phase_8a_smoke.gd -- --capture
```

Phase1～8A最终回归2811项/0失败；8A专项与图形均718项/0失败。用户提出“不必一直等着”，已改为可跳过营业或提前闭馆出发；完整人工手感复验待完成。命令、文件列表和限制见 docs/PHASE_8A_VERIFICATION.md。
