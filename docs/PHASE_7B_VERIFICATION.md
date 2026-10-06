# Phase 7B 验证记录

## 范围与架构

基准 main：150390aba5b1efbb1321de453893c450cba963b7；分支 codex/phase-7b-greed-extraction。仅实现古董风险循环，未修改敌人/Boss/玩家数值、技能时序、遗物奖励或地图算法；没有经济、钱包、存档或第三层。

AntiqueLootService v1 对 COMBAT 以 run_seed、floor、room_id、cache_room 来源和版本评分排序（相同评分按字符串 ID），取前三；不足三个正常降级。只消费布局，不监听战斗顺序。正常每层有一个古董房与三个陪葬匣，共四次，两层八次机会。

AntiquePool v2 使用稳定字符折叠评分与独立 RandomNumberGenerator。来源 antique_room/combat_cache 参与键；相同 seed/floor/id/source/版本/资源池和引擎可复现。第一层八件正式池，第二层过滤 COMMON，均引用原有 Definition，价格不复制。版本更新会改变 Phase 7A 的古董序列，不改变地图或遗物序列。

RoomState 以 Dictionary[StringName,bool] 保存 claimed_loot_sources；旧 antique_claimed 是同一存储的兼容属性。战斗清场后才生成缓存，未领取重访还原，领取/丢弃后不重生，不追加清房或奖励计数。缓存与遗物底座间距至少160px，并避开当前障碍。

第一 Boss 出口改为 ExpeditionExit：活着且控制开启、Run未结束、64px内，E深入/F撤离，先锁 used 再发信号。第二 Boss 的 RunExit 保持。Session 统一 _finish_run：快照→冻结控制、攻击、房间遍历、奖励和遗物调试输入→关闭HUD/背包→死亡清空库存→显示结局。排队深入同帧死亡取消旧跨层回调。RunResult 明确 EXTRACTED/COMPLETED/DEAD，保存名称、单件价值、总价值和楼层等快照；只显示结果，不写永久收益。R/N均重建空库存。

## 真实交互流程

Seed 192034 正式八次掉落共15格，无修改掉落来满足测试。程序驱动真实 Door、E/F、Tab/Delete、武器/弹丸和敌人AI；移动辅助定位用于稳定测试，不能代替人工难度验收。完整风险死亡由真实尸蟞咬击造成，没有直接扣血代替死亡主流程；独立边界测试可以直接伤害。

| 流程 | 实际结果 |
|---|---|
| 保守撤离 | 第一层获取多个古董（包含陪葬匣），真实武器击杀大帅尸，F撤离；EXTRACTED、楼层1、Boss1、安全带回4件 ¥6,350，不进入二层 |
| 贪心失败 | 第一层→Boss1→E二层→满包E失败→Tab/Delete丢青花小罐 ¥350/2格→E拾残片 ¥3,000/3格→真实敌人致死；DEAD、遗失4件 ¥9,000，库存清空 |
| 两层成功 | 遍历两层机会，第二次丢唐三彩马 ¥1,600/3格换残片，真实武器击杀两Boss→RunExit E；COMPLETED、楼层2、Boss2、最终8格4件 ¥10,400 |

成功最终持有金丝玉佩两件与镇墓兽残片两件；重复古董合法。三种结束后操作冻结，重复结算不改变快照；R同Seed/N新Seed、空背包均通过。价值密度整数显示只属于UI。图形截图已检查陪葬匣/遗物分离、满包、背包密度、出口、成功撤离、全部遗失和最终通关。

## 命令与真实结果

引擎：Godot 4.6.2 标准版，Windows Compatibility。

```powershell
$godot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path . --editor --quit
& $godot --headless --path . --quit-after 10
foreach ($phase in @('1','2','3','4','5a','5b','6','6_5','7a','7b')) {
    & $godot --headless --fixed-fps 60 --quit-after 40000 --path . --script "tests/phase_${phase}_smoke.gd"
}
& $godot --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 40000 --script tests/phase_7b_smoke.gd -- --capture
```

| 阶段 | 断言 | 失败 |
|---|---:|---:|
| 1 | 27 | 0 |
| 2 | 204 | 0 |
| 3 | 94 | 0 |
| 4 | 105 | 0 |
| 5A | 61 | 0 |
| 5B | 236 | 0 |
| 6 | 164 | 0 |
| 6.5 | 174 | 0 |
| 7A | 306 | 0 |
| 7B | 722 | 0 |

导入解析、启动检查无错误。Phase7B图形运行同样722项/0失败。日志 logs/phase_7b_final_regression_*.log、phase_7b_import_final.log、phase_7b_start_final.log、phase_7b_graphical_final.log，截图 logs/phase_7b_*.png，均本地忽略不提交。

专项覆盖100个Seed选房、字典顺序变化、候选不足、楼层/来源分离、稀有度和资源引用、遗物序列不变、未清无缓存、满包/距离、未领重访、已领丢弃、防重复清房、共存底座、E/F互斥、所有死亡位置、结局冻结、同帧跨层死亡取消、两Boss真实击杀及真实敌人致死。旧Phase6/6.5只迁移出口节点名/类型，旧7A调整结果文案，原功能断言保留。

## 文件

新增：scripts/antiques/antique_loot_service.gd、antique_cache.gd；scripts/dungeon/expedition_exit.gd；tests/phase_7b_smoke.gd、phase_7b_plan_checks.gd、phase_7b_cache_checks.gd、phase_7b_outcome_checks.gd、phase_7b_risk_checks.gd、phase_7b_run_driver.gd（及对应.uid）；本文。

修改：project.godot、scenes/ui/room_test_hud.tscn；scripts/antiques/antique_pool.gd、antique_pedestal.gd；scripts/dungeon/dungeon_session.gd、run_result.gd；scripts/rooms/room.gd、room_controller.gd、room_state.gd；scripts/ui/antique_inventory_panel.gd、run_complete_screen.gd；tests/phase_6_boss_checks.gd、phase_6_floor_checks.gd、phase_6_5_run_checks.gd、phase_7a_run_checks.gd；AGENTS.md、README.md、ARCHITECTURE.md、PROJECT_PLAN.md。

## 人工反馈与限制

用户反馈『提示清楚』，确认风险提示可理解；没有据此宣称所有人工路径或最终难度已验收。测试驱动成功局会主动躲避且使用定位辅助，其HP不证明人工死亡风险。

当前是几何素材与开发界面；池内均匀抽取、可重复古董，没有复杂经济平衡。并非每个Seed都保证满包，但固定Seed192034已证明真实取舍。背包不暂停战斗；丢弃永久删除本局物品，不落地。仅两层；估值不持久化，无黑市、钱包、保险或尸体回收。完成后提交并push当前分支，禁止合并main，停止本阶段。
