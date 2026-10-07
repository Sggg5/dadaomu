# Phase 8B：持久化博物馆成长验证

## 基准与范围

已确认Phase8A合并：main b3c6dbc5308d47f96c2fdd52ed4f6384ff916783。新分支codex/phase-8b-museum-progression。只实现馆舍经营成长与地面存档，禁止合并main/进入8C。没有永久HP/攻击/攻速/移速/减伤、遗物/初始武器强化、背包扩容、开局Buff；没有其他消费、员工、拍卖、修复等。

## 配置与职责

统一配置data/museum/levels.tres（MuseumLevels + MuseumLevelDefinition只读）。

| 等级 | 名称 | 展柜 | 游客总容量 | 下一次费用 |
|---|---|---:|---:|---:|
| 0 | 私人古物陈列室 | 3 | 30 | 1000 |
| 1 | 古物陈列馆 | 5 | 45 | 3000 |
| 2 | 地方古物馆 | 8 | 60 | 最高级 |

MuseumState生成CASE_1…CASE_N，校验未解锁Case并求已展吸引力；upgrade(expected_level)验证MORNING/EVENING、等级快照、最高级和现金，成功才扣款/等级+1。建设牌E打开再E确认；成功后锁本次请求，关闭并重新打开才能继续。资金不足、OPEN、满级、旧请求均无扣款，无降级/退款。

Museum._sync_cases只追加新柜，旧Case节点/OwnedAntique/Collection/归属保持。Level0东西侧展区可见但标未开放；Level1追加东侧CASE4/5，Level2追加西侧CASE6/7/8。稳定位置在MuseumLayout，名称/图标在真实场景更新。经营HUD显示馆舍名、现金、展柜占用/数量、总游客容量和当日票款，不把大量调试指标塞进主HUD。

MuseumBusiness保留至少一件展品才开馆，空馆目标0。有展品时clamp(5+floor(total_appeal*0.5),1,当前等级容量)。同样高吸引力展品潜在客量30→45→60，票价仍5、同时在馆最多8，不改变游客个人收费去重与提前闭馆规则。

## 存档

MuseumProfileStore独立RefCounted，默认user://museum_profile_v1.json。编码纯字符串/数字/数组/字典，没有Resource/Node/Pickup/Visitor/Dungeon。

```json
{
  "version": 1,
  "day_number": 8,
  "phase": "EVENING",
  "cash": 50,
  "museum_level": 1,
  "next_antique_id": 5,
  "collection": [
    {"instance_id":"A000001","definition_id":"blue_white_jar","acquired_day":1}
  ],
  "display_assignments": {"CASE_4":"A000001"},
  "last_day_visitors": 30,
  "last_day_ticket_income": 150
}
```

示例仅示意一条馆藏，实际快照含全部条目。保存：初始化新档/读取校验后、布展/撤展、升级、闭馆统一结算、进入夜间之前、成功/失败夜间回馆之后。只允许MORNING/EVENING，OPEN流动收入与NIGHT风险背包都不能直接写入。phase保存安全阶段，闭馆重启仍EVENING，不允许同日重复开馆。

写.tmp→flush/close→rename替换；Windows已有档再次替换通过。失败warning并显示保存失败，进入夜间前未保存成功则拒绝离馆；其他修改保留内存状态待后续安全保存，不宣称失败写入成功。

无文件返回Day1/cash0/Level0/空馆藏。损坏JSON、不支持version、全局类型/范围异常回默认。未知定义/异常或重复实例跳过并warning；不存在实例、未解锁/非法柜、同实例多柜归属忽略。next ID至少提升到已有最大ID之后，太低字段会修正。保留acquired_day/重复定义不同身份。没有复杂迁移/备份管理。

夜间退出：重启恢复最近安全地面快照，不续房间/敌人/HP/遗物/背包。RunResult仍只有成功EXTRACTED/COMPLETED入馆藏，DEAD不入藏，原馆藏/等级/现金/布局保持；回馆日期推进后自动保存。

## 测试隔离

Phase8A所有GameFlow测试显式注入MuseumProfileStore.in_memory()，8B真实文件位于user://tests/phase_8b/<进程ID>_<标签>.json，图形与headless进程互不干扰。启动验证用--profile-path=user://tests/phase_8b/startup_validation.json；没有测试读取/写入正式museum_profile_v1.json。故障测试还注入不存在/坏JSON/无效字段/不可写目录，相关warning是预期处理路径，无Godot ERROR或失败断言。

## 夜间隔离证明

生产scripts/dungeon、player、combat、enemies、rooms、relics及对应战斗/掉落数据零修改。DungeonSession不引用MuseumState/MuseumLevel/cash。GameFlow进入夜间仍只设置hub_mode与原night_seed，不传等级。

专项顺序创建Level0/1/2的Flow并实际进入同Seed192034 DungeonSession，比对Player基础数值/实际80HP/8格背包、完整两层地图签名、敌人定义属性、Boss属性与场景、遗物参数/序列、两层古董来源与ID，结果全部一致。没有因经营升级修改共享Resource。

## 真实经营升级

1. 正式新档Level0/3柜/现金0/无馆藏，走到建设牌真实E打开，再E显示资金不足，钱和级不变。
2. 情报板E下墓，真实Room/Door、活AI、Weapon/Projectile清房，古董房/陪葬匣E获得四件；真实击杀大帅尸→F撤离→E回馆Day2。入藏青花小罐、唐三彩马、金丝玉佩两件，现金仍0。
3. 真实WASD/E/选择UI把唐马与两件玉佩放CASE1～3，总吸引力114、原始客量62，Level0容量限制目标30。
4. 七个营业日，每次真实售票台E、游客实际走售票/看展/离场，独立测试配置营业20秒、游客速度1800、观看0.1秒，默认玩家300。每次30名一次票款150，累计1050，没有写现金1000代替经营。中间日期辅助走真实情报板/回馆路径，空夜晚用直接死亡边界快速推进日历，不作为完整战斗或风险验收；这条辅助不提供现金/藏品。正式营业默认60秒保持。
5. Day8建设牌真实E确认，立即扣1000，Level1/现金50/5柜。连按E不二次扣款或跳到Level2。CASE1～3旧节点和展品仍在，同样展品客量上限变45。
6. 真实走到新CASE4 E选择剩余青花小罐，场景显示，归属保存。升级和每次闭馆都单独检查文件已更新，而不是靠后一次操作掩盖漏保存。

Level2的费用3000、八柜场景、满级拒绝、OPEN禁止等通过独立单项/图形夹具验证；不把单项现金构造冒充第二次真实经营升级。

## 重启与死亡恢复

销毁Day8已升级Flow→同隔离路径新建Flow自动加载：日期8、cash50、Level1、4个原Owned ID、四柜归属、5柜场景和EVENING完全一致。不能重新开当日营业。随后单项新增馆藏得到A000005而非旧ID，移除后next ID仍向前；这是恢复ID边界，不作为真实获宝路径。

实际进入夜间前保存，直接销毁夜间Flow不结算→重建恢复最近地面，日期/现金/收藏/柜归属不变，未恢复Night Run。

然后重新真实下墓，E获取夜间古董，由真实尸蟞咬击致死→DEAD→E回馆Day9。原4馆藏/Level1/现金50/四柜归属不变，夜间古董不入藏；自动保存后再销毁重建Flow，下一晨快照完全一致。

## 命令与真实结果

Godot4.6.2标准版，Windows Compatibility。

```powershell
$godot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path . --editor --quit
& $godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase_8b/startup_validation.json
foreach ($phase in @('1','2','3','4','5a','5b','6','6_5','7a','7b','8a','8b')) {
    & $godot --headless --fixed-fps 60 --quit-after 150000 --path . --script "tests/phase_${phase}_smoke.gd"
}
& $godot --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 150000 --script tests/phase_8b_smoke.gd -- --capture
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
| 8A | 468 | 0 |
| 8B | 277 | 0 |

总2838项/0失败。8B图形同277项/0失败，导入与隔离启动无错误。8A只适配等级容量的期望（Level0最大30）、动态case_ids及注入内存Store，原安全/真实流程断言保持；Phase1～7B测试无修改。

日志logs/phase_8b_import_final.log、phase_8b_start_final.log、phase_8b_final_regression_*.log、phase_8b_graphical_final.log。已查看level0_locked_wings/insufficient_upgrade/level1_unlocked/level2_layout/death_preserves_museum等图形截图，修正了东展厅标题遮挡与升级后旧现金摘要。日志/截图忽略不提交。

## 文件与限制

新增MuseumLevelDefinition/MuseumLevels、data/museum/levels.tres、MuseumLayout、MuseumProfileStore、MuseumConstructionPanel及.uid，五个phase_8b测试脚本与.uid，本文。修改GameFlow、MuseumState/Collection/Business/Museum、四个8A测试与AGENTS/README/ARCHITECTURE/PROJECT_PLAN。

几何素材/固定展厅路线，无游客避让，未开放区域以几何标识呈现。票价/升级价格仅原型；当前现金只有扩建消费。没有Level3/降级/退款、战斗成长、商店/员工/成本/拍卖/鉴定、存档迁移或云同步；坏档回默认可能丢掉不合法数据，初始化会写入校验后的状态，没有自动备份。保存失败不回滚已发生内存交易，但明确提示，离馆前保存失败拒绝出发。夜间断点与当次未闭馆营业收入不保存，重启回最近安全地面。人工主观手感未追加验收，不把程序驾驶当人工体验。提交并push当前分支，不合并main，结束后停止。
