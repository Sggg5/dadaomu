# Phase 11I 全游戏整合验收

2026-10-09；基线 d9c840e2148d416009a44f70040f078e09ca212f。独立分支 codex/phase-11i-integration-qa，自动验收完成，真人体验待验。main及正式玩家存档未操作，Profile仍VERSION10。

## 证据分类

- 正式GameFlow输入：正式game_flow.tscn、原60秒营业、零现金/馆藏新档。机器人使用真实WASD、鼠标瞄准/攻击、Door、E/F及鼠标列表/按钮。不写玩家位置/HP/库存/现金，不调用Health清敌、不赠送遗物、不使用F2。知道拓扑和读取状态规划路线是自动化优势，不代表普通玩家理解或难度合适。
- 真实MuseumBusiness经济测试：完整复制上述真实所得存档、正式60秒营业、fixed-fps加速墙钟；夹具推进日期，没有每晚远征。单独报告。
- 历史专项/大量馆藏夹具：保留59组Godot与107项Python，包括50/100/500管理、81位、拍卖出售、任务取消、v1～9迁移、备份和双生尸煞。不替代新档操作。
- 图形：真实Godot窗口截图及输入检查，不是HTML；未真人验收，没有纯数学经济模型。

## 新档闭环与成长

Campaign=52，Day1晋北自然Expedition Seed=522269330。零现金、零馆藏/员工，无升级/专题/荣誉/研究。空馆售票台拒绝营业；情报板E→鼠标选晋北→确认→真实移动战斗过门→E拾取→第一Boss→F撤离→E回Day2→免费鉴定→鼠标布展→售票台E。第一收入35元、7名付费游客，无先付钱才能赚钱的死锁。

同一新档继续三地区实际远征。Day5招聘并完成员工类型研究；Day6第二经营称号及合格专题；Day13首次1000元扩建。没有资产、研究或等级注入，80HP及8格背包不变。

## 完整30日GameFlow

到Day31，30个连续营业日、首趟加29趟追加远征，共30趟（5次死亡按原逻辑丢携货并回馆）。地区、Seed与结果见qa_tables/PHASE_11I_GAMEFLOW_DAYS.json。

- 门票6010、实际付费1202人。
- 招聘120、工资378、馆舍扩建4000（1000+3000）；本路径没有设施维护/修复支出。
- 现金6010−120−378−4000=1512，与实际事务链一致。
- 持有38件、23种已鉴定定义；20件实物陈列（13种定义），11种类型研究、1个合格专题。
- 最高馆舍等级2（全馆81合法位置）；独立经营评级为第三级“地方知名古物馆”，扩建不等同评级。

此新档路径未出售/拍卖/修复；这些操作、离馆历史归档、旧档迁移由保留的专项回归验证，不混称新档操作。所得档另做30次磁盘重载、正式GameFlow恢复、OPEN/NIGHT拒绝写、外部坏档保护，无重复现金或成就。坏档测试两条预期WARNING保留，没有SCRIPT ERROR。

## UI与唯一生产修复

I-001：空馆明确远征→免费鉴定→布展→营业，移除情报板“直接下墓”旧描述。根因、前后行为及待决策见PHASE_11I_ISSUES.md。没有重写UI或经济系统。

真实1280×720空档/所得Day13中期档：办公室八页、设施/员工/专题、荣誉/收藏、库房及研究档案的鼠标导航和关闭恢复；可见按钮在窗口内，查询不产生收入或荣誉。不能自动判断全部文字易读性与审美。OPEN限制、跨厅、搜索分页、大量馆藏性能由原专项补充。

Python旧文件哈希保护仅更新game_flow.gd的精确期望（该文字改动），没有宽泛免检。CSV证据置qa_tables/.gdignore下，避免Godot误作本地化导入。

## 执行结果

|测试|真实结果|
|---|---:|
|全部历史Godot，59组|338474项，0失败，0 SCRIPT ERROR/ERROR|
|新增正式新档30日输入闭环|834项，0失败|
|首笔收入起点，A/B/C各30日|363项，0失败|
|所得Day13起点，A/B/C各30日|363项，0失败|
|所得Day31磁盘/财务|69项，0失败|
|图形正式首趟闭环|30项，0失败|
|图形空档及中期UI|101+101项，0失败|
|Python SQLite/导出/授权/兼容|107项全部通过|
|导入、隔离空档及中期启动|通过，无解析/脚本错误|

59组明细见PHASE_11I_HISTORICAL_RESULTS.json；逐日180条策略数据见qa_tables/PHASE_11I_ECONOMY_DAYS.csv。驾驶器初期错误、过短8秒营业样本不计最终通过，修正后复测。机器人死亡是正常游戏结果，卡住/脚本错误明确失败，未删断言。

## 复测与隔离试玩

在项目根目录，PowerShell：

    $qaGodot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
    python tests/run_phase_11i_qa.py --godot $qaGodot --history --graphical --long-run
    python -m unittest discover -s database/tests
    & $qaGodot --headless --path . --editor --import --quit
    & $qaGodot --path . --script tests/phase_11i_playtest.gd
    & $qaGodot --path . --script tests/phase_11i_playtest.gd -- --midgame

runner保留输出，拒绝非零退出、缺少总结、失败及SCRIPT ERROR/ERROR。两个试玩入口内存隔离；中期只读tests/fixtures/11i_earned_midgame.json（实际Day13所得：现金339、一级馆舍、员工研究和专题），不更新该快照，不读写正式档。空新档固定Campaign52。

## 截图与人工待验

screenshots/phase_11i包含正式起步、实际Boss战/拾取/鉴定/布展/首笔收入，以及空/中期办公室、专题、员工、设施、收藏图鉴、库房与研究台。可看flow_input_combat.png、new_game.png、midgame_office_7.png。

人工待验：第一步指引、办公室复杂度、库房筛选、战斗/撤离理解、字号/装饰间距、设施在游客取整与容量封顶时的价值。自动结果不能冒充真人体验，本次没有经济重平衡。

## 提交与停止

11I.1 27b1245；11I.2 38e9f94；11I.3 e4c7d74；11I.4 081a1c1；11I.5为分支最终交付HEAD。push独立分支，不合并main。停留隔离空新档，保留所得中期快照；不开始Phase12。
