# Phase 8A：博物馆昼夜循环验证

## 范围与Git

基准main：0a8784d193b6c96471538027fe0d00dfba2c1c46（Phase7B已合并）。开发分支：codex/phase-8a-museum-day-night-loop。仅完成可玩昼夜闭环，授权验证后commit/push，不合并main、不进入8B。

## 系统边界

GameFlow是顶层装配入口，持有MuseumState/current_day/current_phase/current_dungeon_result。Museum只负责白天场景/交互；DungeonSession只负责夜间原有Run，不知道展柜、游客或票款。状态保存在同一进程内，关闭程序全部重置，无磁盘保存。

主入口scenes/main/game_flow.tscn。独立夜间入口scenes/main/dungeon_test.tscn保持，原Phase1～7B测试仍直接实例化它。Session.hub_mode默认为false，只有Flow夜间为true；新增run_started/result_ready/return_requested信号以及结果界面E返回地面。R/N继续重试夜间，清除旧结果，不加日期、不转移藏品。

用户试玩反馈『不必一直等着』后，营业改为可选：MORNING情报板E直接下墓；OPEN情报板E提前闭馆，停止进客、现客全部离场后自动出发；不等满60秒。跳过营业当日人数/收入为0，现金不变；已收门票不退、不重复收。两条路径均通过实际WASD/E测试。标准经营路径仍为：MORNING自由布展→售票台E→OPEN→停止生成并排空游客→EVENING→情报板E→NIGHT→结果E回馆→日期+1/MORNING。阶段真实来源为MuseumState.phase，Flow属性只读转发，避免两份阶段状态漂移。仅回馆推进日期，开馆/闭馆/R/N不推进。

## 馆藏与展览

RunResult增加Array[StringName] antique_ids，与名称/价值同次快照，死亡清包前也保留遗失ID。Flow严格只导入EXTRACTED/COMPLETED，DEAD没有新入藏。返回边界验证当前Session/当前Result身份与结束状态，并锁转换，双E或旧Result不会重复入藏/加日期。

OwnedAntique仅保存instance_id/definition_id/acquired_day。MuseumCollection维护独立数组，顺序生成A000001等身份；重复定义保留多件。acquired_day是安全返回的夜晚所属日期，先入藏再日历+1。夜间库存与MuseumCollection不是同一个对象。AntiquePool.find_by_id引用原八件资源，没有复制资源或价格。

| 古董 | 吸引力 |
|---|---:|
| 民国银元 | 3 |
| 青花小罐 | 12 |
| 铜鎏金佛像 | 22 |
| 汉代玉璧 | 25 |
| 战国错金银铜镜 | 35 |
| 唐三彩马 | 50 |
| 金丝玉佩 | 32 |
| 镇墓兽残片 | 60 |

吸引力固定配置，独立于base_value。正式主入口默认空馆藏/空展柜/零现金，不赠送古董。仅布展自动测试显式启用GameFlow.initial_test_collection，注入一件day0测试唐三彩马。

MuseumState保存day_number/cash/collection/display_assignments/last_day_visitors/last_day_ticket_income。三柜各一件，按instance_id查重；一件不可双柜，重复定义不同实例可以。assign/unassign数据层也拒绝OPEN时修改；换展只是替换归属，撤展不删除馆藏。库房显示所有实例、名称、吸引力、估值、库房/展柜状态；无限容量，无出售/删除按钮。

DisplayCase在场景真实更新名称与几何符号，新增符号仅呈现，不驱动玩法。E打开选择/查看，柜旁R撤展，面板Tab/E关闭。MuseumPlayer有加减速移动、朝向、统一最近64px交互，没有Health/Weapon/RelicRuntime。玩家不包含物体类型分支；库房/展柜/售票台/情报板/游客通过MuseumInteractable回调接入。

## 游客、营业与票款

MuseumConfig默认open_duration60秒，ticket_price5，max_active_visitors8；时间显示10:00→17:00。0件展品不能开馆且目标0；至少1件展品即可开馆，目标clamp(5+floor(total_appeal*0.5),1,60)，每0.35秒且有空位时进一人，离场后补客，不一次塞满60人。

Visitor状态ENTER→CHOOSE_EXHIBIT→WALK_TO_EXHIBIT→VIEW→下一柜或EXIT。门口→售票台→通道→展柜观看→门口离开；可看第二柜，不重复选已经看的柜。museum_seed/day/index派生独立RNG，按已有展品吸引力加权；银元仍有概率，未展出不参与；正式空馆不生成游客，Visitor本身仍保留无展品时的安全离场边界。E交谈只显示一条正在看的古董反应，无剧情树。

游客自身ticket_paid和Business._paid索引共同去重。仅完成售票时cash +=5，visitors_today/income_today同步。到时停止补客，现客进入EXIT，全部离开后转EVENING并保存当天实际售票人数/收入。目标不是保证到客数；营业长度和路线可能使实际少于目标。现金只记录门票，古董估值不会转为现金。

## 实际完整流程

专项以独立测试配置压缩营业为5秒、游客速度1200、观看2秒；玩家仍使用默认300速度。白天通过实际WASD输入走动/E互动/选择按钮，不直接写展柜状态替代主流程。夜间复用现有真实Door、武器/弹丸、活敌人AI驾驶，测试射击位置辅助不代表人工手感。

1. Day1初始唐三彩马→WASD走到展柜→E选择→场景显示藏品/吸引力50。
2. WASD去售票台→E开馆→游客真实入馆/付票/观看→走到游客旁E交谈→停止进客并全部离场，实际11人/¥55。
3. 走到情报板E加载原DungeonSession，Seed192034真实清房/E获取青花小罐、唐三彩马、金丝玉佩两件；真实武器击杀大帅尸→F成功撤离。
4. 结算E回馆：Day2，新增4个OwnedAntique，共5件，价值¥6,350不会成为现金。实际走去库房E查看逐件条目（两件玉佩不同ID），再走到展柜E将昨夜玉佩换上，旧唐马仍在库房。
5. Day2再营业11人/¥55（累计现金¥110）→情报板夜晚→R重试不改变Day2→真实拾取多个古董→真实尸蟞咬击致死，DEAD损失¥6,350。
6. 结果E回馆：Day3，没有新入藏，原5件收藏/玉佩展柜/¥110现金保持，界面显示失败与损失。

COMPLETED入藏作为独立边界测试直接结束Session验证，双玉佩形成不同身份；完整两Boss真实击杀/通关仍由未改的Phase6.5/7A/7B回归验证。单项数据/状态边界允许直接调用，未将这种边界当作真实完整夜间流程。

## 命令与结果

Godot4.6.2标准版，Windows Compatibility。

```powershell
$godot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $godot --headless --path . --editor --quit
& $godot --headless --path . --quit-after 10
foreach ($phase in @('1','2','3','4','5a','5b','6','6_5','7a','7b','8a')) {
    & $godot --headless --fixed-fps 60 --quit-after 40000 --path . --script "tests/phase_${phase}_smoke.gd"
}
& $godot --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 40000 --script tests/phase_8a_smoke.gd -- --capture
# 独立夜间入口仍可运行：
& $godot --path . scenes/main/dungeon_test.tscn -- --seed=192034
```

| 测试 | 断言 | 失败 |
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
| Phase8A | 718 | 0 |

导入解析、主入口启动无错误；8A图形运行718项/0失败。最终回归共2811项/0失败。旧测试未修改或删除断言。重点覆盖ID快照/重复件/日期、成功两Outcome转移/死亡不转移、旧结果/双返回、夜间R、实际UI布展/开馆锁定/撤展、200游客确定性加权选择、空展馆真实营业/收费一次/上限/离场/停止补客、两日成功及额外死亡流程。

日志：logs/phase_8a_import_final.log、phase_8a_start_final.log、phase_8a_final_regression_*.log、phase_8a_graphical_final.log。已目视检查morning_exhibit/visitor_view/evening/hub_extracted/day2_storage/day2_new_exhibit/death_morning截图；馆藏列表原多行文字混排已改为单行分隔。日志与截图本地忽略。

## 文件

新增：scripts/flow/game_flow.gd；scripts/museum/owned_antique.gd、museum_collection.gd、museum_state.gd、museum_config.gd、museum_interactable.gd、museum_player.gd、display_case.gd、museum_visitor.gd、museum_business.gd、museum.gd；scripts/ui/museum_collection_panel.gd；scenes/main/game_flow.tscn、scenes/museum/museum.tscn；data/museum/default_config.tres；tests/phase_8a_smoke.gd、phase_8a_data_checks.gd、phase_8a_hub_checks.gd、phase_8a_flow_checks.gd及源.uid；本文。

修改：project.godot；scripts/antiques/antique_definition.gd、antique_pool.gd；八件data/antiques资源仅新增appeal；scripts/dungeon/dungeon_session.gd、run_result.gd；scripts/ui/run_complete_screen.gd；AGENTS.md、README.md、ARCHITECTURE.md、PROJECT_PLAN.md。战斗/敌人/Boss/遗物/房间/地图生成脚本与数值未改。

## 人工与限制

已打开游戏供用户试玩。用户反馈『其实不白天也可以下墓，不必一直等着吧』，已落实可跳过营业与提前闭馆两条实际入口；完整昼夜手感及新入口的人工复验待完成。图形程序驾驶与人工体验分开，不声称最终手感通过。

几何占位，游客使用固定通道路线而非复杂寻路/避让，允许游客相互重叠；不是正式经营平衡。当前只有三柜和已完成墓穴；夜间默认Seed192034，可命令行指定和R/N重试。长馆藏名称列表可滚动，回馆提示为简短总览。藏品无白天删除/出售，门票现金暂不消费。所有长期状态仅在程序运行期，不保存；不做员工、成本、票价调整、扩建、专题展、任务、拍卖、鉴定、修复或8B内容。完成commit/push后停止，不合并main。

## 正式入口取消测试赠品修复（2026-10-07）

GameFlow.initial_test_collection默认false，正式场景没有true覆盖；Museum默认提示也不再显示测试唐三彩马。Phase8A完整布展测试显式启用夹具；空馆测试直接实例化未改参数的正式入口，新增验证默认开关关闭、馆藏/展柜为空、现金0、提示不含赠品。正式空馆可直接下墓；开馆资格修订见下一节，成功出墓入藏逻辑保持。

本修复Godot导入/启动无错误，Phase8A专项721项/0失败，日志logs/phase_8a_no_gift_import.log、phase_8a_no_gift_start.log、phase_8a_no_gift_smoke.log。此前718项图形与全阶段回归保留为阶段历史结果，本修复未声称重跑所有旧阶段。仅修改默认值、提示、夹具与文档，不改战斗和收益规则。

## 正式开馆资格修订（2026-10-07，当前规则）

继续在当前8A分支，保留已提交8fec3ca的initial_test_collection=false，正式Day1馆藏0/三柜空/现金0。需要初始唐三彩马的旧完整布展夹具显式启用测试开关；新增正式首次展览流程不启用、不调用collection.add代替夜间获取。

MuseumBusiness.can_open集中判断display_assignments非空，start在任何营业状态变更前再次校验。空馆售票台提示『暂无展品，无法开馆』，真实E及直接start均拒绝；保持MORNING、target0，不生成游客/票款，不改现金、当天计数或原非零上日统计。至少一件合法实例布置到任一柜即可，无价格、吸引力、稀有度、多样性门槛。

新公式：展品数0→游客目标0；展品数≥1→clamp(5+floor(total_appeal*0.5),1,60)。配置base_visitors从10改5；银元一件6人、唐三彩马一件30人、唐马+玉璧42人；票价5、活客上限8、收费去重保持。Morning直接下墓与OPEN提前闭馆待游客离场后下墓均保持，通过原真实输入路径回归。

### 正式空馆到第一次开馆真实流程

Seed192034：正式GameFlow默认启动→Day1馆藏0、三柜空、现金0→WASD到售票台→真实E拒绝且提示明确→WASD到情报板E直接NIGHT→真实Door/活敌人/武器推进→ANTIQUE房E仅拾一件正式唐三彩马→真实武器/弹丸击杀大帅尸→F撤离→结果E回馆→Day2唯一OwnedAntique（acquired_day1），现金仍0→走到展柜2 E打开选择、按钮亲手布展唯一一件→走到售票台E开馆→真实游客进入/付票/观看，玩家E交谈→正常闭馆EVENING。

测试独立营业配置5秒，游客速度1200，玩家仍默认300；游客目标30，实际12人，收入¥60。目标不等于强制到客数。主流程没有collection.add或Inventory.add注入馆藏；夜间驾驶沿用现有真实武器/AI与射击位置辅助，不声称人工手感验收。

### 测试变更与结果

旧『Empty exhibition still sells once tickets』和每帧空馆游客循环已移除，改为正式入口默认空、direct start/E拒绝、MORNING/target0、无游客/收入、上日非零统计不变。新增phase_8a_first_exhibit_checks.gd覆盖空馆夜间带回唯一真实古董后首次营业；data_checks更新公式和单银元资格。Phase1～7B脚本及原断言未修改。

| 回归 | 断言 | 失败 |
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
| Phase8A | 468 | 0 |

本次总2561项/0失败，Phase8A headless与graphical均468项/0失败；专项计数下降因旧空馆每帧售票断言正式废弃，不通过保留错误逻辑维持数字。导入/正式入口启动无错误。命令使用上文同样的11套脚本与图形--capture；日志logs/phase_8a_exhibits_import.log、phase_8a_exhibits_start.log、phase_8a_exhibits_regression_*.log、phase_8a_exhibits_graphical.log。已目视检查first_empty_ticket、first_real_exhibit、first_exhibition_income截图，显示0→唯一真实藏品→首次收入。

修改Business/Config/default_config、Museum售票提示，Phase8A三个旧测试，并新增首次展览helper及.uid。README/ARCHITECTURE/PROJECT_PLAN/AGENTS同步当前规则。未改变夜间、Phase8B、票价或其他经营机制。此前阶段与取消赠品的结果为历史记录，以本节最新规则与结果为准。完成后commit/push开发分支，禁止合并main，停止。
