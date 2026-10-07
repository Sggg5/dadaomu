# Phase 8C 验证：鉴定、品相与修复

日期：2026-10-07。Godot 4.6.2 标准版，Windows，Compatibility。

基准 main：`125080906182bc2b01ed4bcdca73050f90946369`。开始前 fetch 并确认 Phase 8B 已合并到本地与远端 main；从该 main 创建 `codex/phase-8c-appraisal-restoration`。本阶段仅鉴定/品相/修复，提交并 push，不合并 main、不进入 8D。

## 实际实现与边界

现场获得不等于正式馆藏鉴定。夜间仍显示名称、基础估值、格数，保留价值/格、背包取舍、撤离和死亡遗失机制；没有未知古董、野外判断、真假或战斗成长。

- OwnedAntique 增加 `identified: bool`、`condition: int`（合法0～100）。成功带回默认未鉴定，实际新战利品品相55～90。
- AntiqueCondition 使用稳定字符混合 `AntiquePool.stable_score` 与独立 RandomNumberGenerator，输入 run_seed、definition_id、cargo_index、collection_day（出发日），品相生成版本1。DungeonSession仅接收日期元数据；它不读取MuseumState/现金/馆舍等级。相同输入和当前Godot版本下结果一致，不消耗地宫/掉落/遗物RNG。
- `_finish_run` 在死亡清空背包前生成与 antique_ids 一一对应的 antique_conditions，EXTRACTED/COMPLETED/DEAD都有快照。GameFlow成功回馆逐项复制品相，未重新随机；DEAD不入藏。
- MuseumState.assign 拒绝未鉴定物品；库房显示待正式鉴定和入藏日期，隐藏精确品相与吸引力。数据层直接调用也不能绕过。
- 馆长办公室附近真实鉴定台(540,190)、修复台(730,190)，统一MuseumInteractable/64px距离交互。E打开→选中→E确认→Tab关闭。鉴定免费，Morning/Evening可作业；OPEN/NIGHT数据层拒绝，OPEN提示“营业中无法进行馆藏作业”。
- MuseumAppraisalPanel/MuseumRestorationPanel共用MuseumWorkPanel选择、确认和关闭；单次成功后按钮禁用且确认锁定，关闭重开才处理下一件，防快速连按。结果展示名称、精确品相、基础估值、基础/当前吸引力。
- 修复可选，不是开馆前置。不满100且已鉴定才能修复，费用只在MuseumState.restoration_cost集中计算：`ceil((100-condition)/10) × rarity_unit`；COMMON/UNCOMMON/RARE/TREASURE单位¥20/40/60/100。一次扣费恢复100。资金不足/满品相/重复操作不扣费、不改变品相、不发出保存事务。
- 有效吸引力唯一公式 `MuseumState.appeal_for(instance_id)`：未鉴定/不存在为0；已鉴定 `max(1,round(base_appeal×condition/100))`。total_appeal按实际展柜实例累加。HUD、展柜、库房、游客目标和选择权重使用此接口，共享Definition保持只读。
- 修复事务完成后changed刷新现有DisplayCase，无需撤展再布展；下一次营业读新目标/权重。修复中没有营业时的动态目标变更。
- 鉴定/修复成功立即通过GameFlow已有安全保存监听写盘，交易通知保留保存失败提示。夜间不保存中途状态。

## v1→v2 存档迁移

MuseumProfileStore.VERSION=2。继续使用`user://museum_profile_v1.json`原文件路径，文件名保留是为了自动发现Phase8B旧档，不代表schema仍为1。条目增加bool identified与整数condition。

v1读取：所有已有合法馆藏转换identified=true、condition=100，保留重复件独立身份、日期、现金、等级、展柜、next ID与Morning/Evening；正式GameFlow初始化随后的保存自动写v2。不能把已有展品变成待鉴定破损品。

v2逐条要求identified为bool、condition为0～100整数（JSON整数数值允许对应float表示）；负数、500、文本、null、小数或错误bool类型跳过对应条目，关联非法展柜也拒绝。未知Definition、重复/非法ID及锁定展柜继续沿用8B校验。非法根schema/未知版本回安全空档并warning。next ID至少在恢复有效实例之后，不复用已知ID。

## 真实第一件馆藏与修复流程

`phase_8c_flow_checks.gd`使用正式GameFlow和隔离磁盘存档，无测试赠送古董、无inventory.add/museum collection.add/cash写入/F2用于主流程：

1. Day1/Level0/空馆/现金0，人物WASD到售票台E，实际提示暂无展品、保持Morning。
2. 实际情报板E进入Seed192034夜间；通过真实Door进入ANTIQUE，真实E拾唯一唐三彩马；真实武器/弹丸击杀第一Boss，F撤离，E回馆。
3. RunResult快照品相76，Day2创建同品相未鉴定OwnedAntique。真实库房E显示待鉴定，不显示76。真实展柜UI尝试选择与直接assign都失败。
4. 人物真实WASD走到鉴定台，E打开/E免费鉴定；品相76立即存档。实际展柜E/UI放入，吸引力38，未修复也能开馆。
5. 实际修复台E确认时现金0，显示资金不足，数据不变。
6. 两个压缩经营日，每日实际24名游客、每人一次¥5，共真实门票¥240。至少一名游客真正走到展柜观看，保留重复收费防护验证。
7. Day3 Evening人物真实走到修复台，E打开/E确认并重复E，费用ceil24/10×60=¥180，仅扣一次，现金¥60，品相100，现有展柜立即吸引力50。保存再读完全一致，满品相不再列入修复列表。
8. 下次营业真实目标从24提高到30；之后销毁/重新创建GameFlow，完整恢复已鉴定/修复/现金/展柜/日期状态。

为压缩营业验收时间，仅测试夹具把营业时长设20秒、游客速度1800、观看1秒；生产默认营业60秒/票价¥5等未改。两次经营日之间和修复后的下一次营业之间，以真实情报板进入空背包夜间再直接触发死亡边界推进日期。这是经营日历辅助，不作为真实敌人致死试玩、现金/古董获取或风险路径证明。主获取路径使用真实Door、武器、E/F；夜间自动驾驶在接近底座/出口与Boss战中会设置人物位置，地面人物移动使用实际WASD。没有声称全部由人工游玩完成。

## 自动验证覆盖

专项297项包括：100 Seed品相范围/重复生成；独立重复件；未鉴定assign/非法展出0吸引力；Morning/Evening鉴定免费、重复拒绝；OPEN/NIGHT作业拒绝；55品相舍入与100基础值/min1；四稀有度单位费用、62唐马240、55残片500；资金不足无半事务；修复精确扣款/重复防护/共享Definition不变；40固定Seed逐一验证实际Visitor使用50/45有效权重；v2磁盘精确读写；v1磁盘及正式GameFlow自动迁移；v2异常条目跳过/关联归属拒绝；next ID稳定；三种结算快照等长/成功入藏/DEAD不入藏；实际OPEN交互提示；真实经营闭环与重启。

夜间隔离专项：同Seed下分别以未鉴定、鉴定后、修复后馆藏及不同现金/馆舍等级实际进入DungeonSession，对比Player基础参数与80HP、8格背包、两层地图签名、两层古董掉落、敌人Definition、两BossDefinition、RelicDefinition和奖励序列，全部一致。生产玩家/战斗/敌人/房间/遗物/地图生成/古董掉落算法及资源无差异；DungeonSession仅新增结算日期元数据与品相快照调用，RunResult仅新增数组。

## 回归实测结果

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
| Phase8C headless |297|0|0|
| Phase8C graphical |297|0|0|

13套headless合计3177检查、0失败。Phase8C图形另297检查、0失败。导入解析与隔离存档headless/graphical启动退出0；日志无ERROR/解析错误/资源泄漏。坏档专项产生的warning是预期拒绝日志，不是游戏运行错误。

旧测试适配：8A/8B数据与存档单项需要已展出对象时显式传condition100/identifiedtrue；8A COMPLETED边界夹具先鉴定再布展。8A真实first_exhibit/flow与8B真实progression复用地面驾驶助手，在首次布展前通过真实鉴定台E/E登记，新CASE4同样先鉴定。保留原归属、票款、扩建、重启、夜间和死亡断言，没有删除旧覆盖。Phase1～7B测试未改。

运行命令（项目根目录PowerShell）：

```powershell
$godot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path . --editor --quit
& $godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase_8c/startup_validation.json
foreach ($phase in @('1','2','3','4','5a','5b','6','6_5','7a','7b','8a','8b','8c')) {
    & $godot --headless --fixed-fps 60 --quit-after 150000 --path . --script "tests/phase_${phase}_smoke.gd"
}
& $godot --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 150000 --script tests/phase_8c_smoke.gd -- --capture
```

最终日志：logs/phase_8c_final_*.log、phase_8c_graphical_final.log、phase_8c_import_final.log、phase_8c_startup_final.log（忽略不提交）。图形截图实际查看waiting_storage、appraisal_result、imperfect_exhibit、insufficient_repair、repair_complete、visitor_view等；鉴定/修复面板使用不透明背景避免展厅文字透出，操作后现金提示同步。没有本阶段人工主观验收反馈。

## 新增与修改文件

新增脚本（各有.uid）：scripts/antiques/antique_condition.gd；scripts/ui/museum_work_panel.gd、museum_appraisal_panel.gd、museum_restoration_panel.gd；tests/phase_8c_smoke.gd、phase_8c_data_checks.gd、phase_8c_profile_checks.gd、phase_8c_isolation_checks.gd、phase_8c_result_checks.gd、phase_8c_flow_checks.gd。新增本文档。

修改：scripts/dungeon/dungeon_session.gd、run_result.gd；scripts/flow/game_flow.gd；scripts/museum/owned_antique.gd、museum_collection.gd、museum_state.gd、museum_profile_store.gd、museum.gd、display_case.gd、museum_visitor.gd；scripts/ui/museum_collection_panel.gd；tests/phase_8a_data_checks.gd、phase_8a_flow_checks.gd、phase_8a_hub_checks.gd、phase_8b_data_checks.gd、phase_8b_profile_checks.gd、phase_8b_progression_checks.gd；README.md、ARCHITECTURE.md、PROJECT_PLAN.md、AGENTS.md。

## 已知限制与停止范围

占位美术/固定展厅与游客路线，未验证长期最终经济平衡。新品相基于最终cargo_index，不保留原拾取来源身份；重排/丢弃背包可能改变同件在结算时的确定性品相，当前没有源级档案。修复成功需关面板再处理下一件，不做批量作业。

存档沿用8B原子写入和安全地面边界；写盘失败保留运行时已完成事务并提示，不实现回滚/备份，未成功保存前进入夜间被阻止。坏条目跳过可能损失该条目，非法根schema安全空档；无多档/云同步/更复杂迁移。鉴定/修复完全不作用于夜间战斗、基础估值或出售价格。

没有拍卖、买卖、真假、研究树、员工、修复小游戏/失败率、专题展、声望、成本、调票价或战斗成长。Phase8C完成后停止，8C.5/8D需另行授权。
