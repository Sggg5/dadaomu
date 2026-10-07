# Phase 9B.2 验证记录

基线`b668fe37e2adc915fe610097e205df755ec5822a`，分支`codex/phase-9b-multifloor-endurance`。用户反馈9B初版房间/怪/道具少、缺每层Boss，人工手感未通过，本阶段调整为高频战斗Build+稀缺古董撤离压力。仅此次授权，不合并main、不进入后续阶段。

## 生产数据

|Floor|基础房数|Run33基础样本|100 Seed平均基础房数|Boss|初始敌数范围/均值|休整|
|---|---|---:|---:|---|---|---:|
|1|8～10|8|8.960|尸蟞母巢|4～6 / 5.000|0|
|2|10～12|10|10.870|晋北大帅尸|5～7 / 6.000|15|
|3|12～14|12|13.010|纸扎将军|6～8 / 7.000|0|
|4|14～17|16|15.560|铜甲尸王|7～10 / 8.333|20|
|5|12～15|14|13.380|镇墓兽|7～11 / 9.000|0|

基础图不计9A可选附加房。实际Run33完整World房量为8/10/14/18/17，其中未发现暗室不出现在小地图。每层一个START/RELIC/ANTIQUE/BOSS，四类互不相同，剩余普通COMBAT。Generator仍单层正交连通拓扑，终点仍最深叶子，Config上限18；RELIC为新增枚举末项，旧枚举值未漂移。

每层使用三个不同模板，共十五份新RoomDefinition（data/rooms/density/encounter_01～15）。五份旧测试模板保留作legacy。纯虫、枪虫、尸犬突袭、纸符混编、铜甲肉盾、母体虫群、深层混合等组合；F1旧两类，F2加入犬，F3加入纸人，F4加入披甲/母体，F5组合涵盖六类。没有提高Tier倍率，Tier3仍最高。所有模板初始点距四入口≥180、间距≥48、障碍留24px余量。START从共享模板中选安全出生点，避免中央障碍卡住玩家。

普通六类：尸蟞/枪手原资源与AI不改；尸犬40HP、速度220、伤害12、0.32前摇、420锁向短冲、0.8恢复；披甲尸140HP/65速度/20伤害/0.6前摇，复用有距离/LOS重判的近战；纸人55HP/110速度，中距漂移、0.55预警后三弹散射；母体100HP/静止、弱弹与周期召虫，Spawner负责清房计数与安全延迟生成。

## 五Boss

- 尸蟞母巢：380基础HP，五发短寿命弱虫弹；周期召2/3虫，半血加快并侧向移动，不是放大近战尸蟞。
- 晋北大帅尸：旧场景、原AI、原数值保持。
- 纸扎将军：500基础HP，横移、可读扇形纸符、半血追加交叉弹；两具三秒纸扎假身仅发弱弹，本体红冠区分。假身不进Health/击杀清房计数。
- 铜甲尸王：600基础HP，慢追、0.8秒重砸预警、0.55秒锁向短冲、明显恢复；护卫锁朝向，正面45%伤害、侧后全额。碰墙先终止，不继续墙后距离伤害。
- 镇墓兽：旧场景、原AI、原数值保持。

BossEncounter仅增加活召唤6上限和失效引用清理，保留大帅尸原同步召唤时机；这点经过旧Phase6三尸召唤断言回归。Boss死亡清自己的召唤与弹丸，再清房/出口/战斗遗物；五层结果cleared5/bosses5。

## 战斗遗物与奖励

正式二十件：原五帝钱/黑火药/尸油灯/镇尸钉/铜镜/墨斗/洛阳铲/引魂纸鸢全部保留。新增连珠簧、铁蒺藜、八卦镜、红绳结、朱砂符、火药纸包、阴阳钱、青铜箭簇、招魂铃、桃木尺、七星钉、定尸符；每件独立Effect，十余件包含数量/方向/穿透/范围/持续伤害/击杀后魂弹/周期模式的规则变化。没有组合专用ID分支。

RelicRewardPlan在Run开始按稳定ID排序、独立RNG洗牌后预先为F1:ITEM/F1:BOSS…F5:ITEM/F5:BOSS、MILESTONE:4/12/24分配13个不同ID。遗漏F1房间不改变F2Boss；Pickup不消费奖励RNG。Service普通清房里程碑THRESHOLDS=4/12/24，LEGACY_THRESHOLDS=2/4/7仅历史夹具使用。正式DEFAULT_POOL为20件，LEGACY_POOL明确8件。RoomController消费计划，仅当前房装配底座；房间/Boss一次领取写RoomState source，重访已领不补；最终Boss也有一件，可E拾取后再到RunExit。

RELIC安全、无敌、进入开门，64px E领取。Boss底座与出口分开放置。跨层同计划/Service、保持所持定义，新Runtime重新安装，临时计数按原Carry规则重置。R/N从空Build和新计划开始。

## 上限与效果卸载

AttackContext.MAX_PROJECTILES=48，每个Stage效果后截断；Room容器256保护，EnemyVolley单组至多12。普通母体每母体活虫2、房间活虫4、房间总生成8，死亡计入Spawner清场；待处理请求遇到owner死亡/已清场/失控目标就拒绝。Boss活虫6，假身2且自动过期。追加范围/近伤不发送projectile_hit，避免爆炸递归；两种Burn各有限tick、刷新不新增无限节点，卸载取消。魂弹最多12次/房，弱引用追踪、1.5秒寿命，绕过武器修饰器，不能递归复制攻击批次。共享Definition不写入计数。

5/8/12件Build实际请求峰值12/32/32，均≤48且方向归一/伤害与速度合法；二十件叠加实际投射物命中耐久测试靶、范围/DOT运行，容器≤256、每目标最多两份有限Burn，卸载清弹后继续两秒HP不再变化。靶是单项测试，绝不替代完整主流程。图形截图是实际Godot渲染，不是示意。

## 真实完整五层程序流程

正式GameFlow场景+生产默认新Tomb/二十件Pool/进阶计划；隔离内存档，测试专用forced_night_seed=33。真实情报板E→Door→活AI战斗→探索每层遗物房E→普通清房里程碑E→古董E/满包Tab/Delete→五名真Boss武器击杀→Boss遗物E→休整（有且受伤才消费）→E深入→最终RunExit E→结算E回Day2 Museum。

没有F2、inventory.add、HP注入或直接_finish_run伪造此主流程。自动驾驶会选安全射击点并移动坐标，这不是人工难度结论。

|Floor结束|实际所持遗物|普通Combat累计|Boss奖励累计|HP（程序驾驶）|古董估值|
|---|---:|---:|---:|---:|---:|
|1|3|4|1|80|1800|
|2|5|10|2|80|3300|
|3|8|18|3|80|4500|
|4|11|30|4|80|4400|
|5|13|40|5|80|5520|

累计13个不同正式遗物=5房+5Boss+3里程碑，最终cleared5/bosses5，实际回馆日期+1、成功古董只入藏一次。F1已3件，F2开始成形，后续实际技能效果持续叠加。程序驾驶全血不说明玩家压力不足/足够，等待实际试玩。

## 冻结与兼容

古董八格、每层1Antique+1Cache、原八古董/质量曲线不变；9A棺椁35/25/20/20、机关20HP、祭台25HP、暗室35%/绕路45%/普通棺椁0～1/WallMark不变。玩家80HP、既有敌人/两Boss数据、Tier3上限、F2+15/F4+20、Profile4与跨日Expedition生命周期保持，无新永久成长。

legacy_two_floor_tomb文件未修改。旧Phase1～9A显式progressive_relics=false、LEGACY_POOL、LEGACY_THRESHOLDS并保留全部核心断言。9B初版配置复制到tests/fixtures/pre_density_tomb及pre_density_floors，旧五层普通终点/两Boss/数量/Seed测试保留，9B.2另外覆盖生产五Boss。生产GameFlow/DungeonSession默认progressive_relics=true，无隐藏生产回退。

## 验证命令与结果

Godot4.6.2 stable Windows console，全部真实执行：

```powershell
godot --headless --path . --editor --quit
godot --headless --fixed-fps 60 --quit-after 180000 --path . --script tests/phase_9b2_smoke.gd
godot --path . --position -16000,-16000 --disable-vsync --fixed-fps 60 --quit-after 180000 --script tests/phase_9b2_smoke.gd -- --capture
godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase_9b2/startup.json --seed=52
# 同样逐套运行Phase1～9B历史smoke。
```

Phase1～9B历史46,593项0失败；9B.2 headless4,842项0失败，总计51,435项0失败；9B.2 graphical4,842项0失败。导入/正式隔离入口启动返回0，无解析错误。日志logs/phase_9b2_regression_*.log、phase_9b2_graphical.log、phase_9b2_import.log、phase_9b2_startup.log均忽略，不提交用户存档/截图/临时脚本。测试数量及错误/泄漏扫描以最后一轮实际日志为准。

图形已检查Build5/8/12、纸将军真假身、新Boss技能与各层Build截图。截图logs/phase_9b2_build_12.png、phase_9b2_paper_general_decoys.png、phase_9b2_floor_1_build.png…floor_5_build.png。

## 人工验收与限制

人工反馈待本轮正式窗口试玩；9B初版人工未通过的结论保留，不能因自动全通声称9B.2手感通过。正式窗口用隔离user://tests/phase_9b2/manual_playtest.json，Campaign初始化52，正常跨日派生Seed，不用强制Run33。请不用F2，重点看F1是否2～3件、F2是否成形、F3攻击变化、F4/F5是否夸张；每层Boss节奏、敌人组合、再找道具房的驱动力、古董背包与撤离取舍、总时长。

新Boss/新敌人/新遗物是第一轮占位原型，数值和可读性尚需人工检验；没有正式美术、复杂护甲/状态框架、多人、存档升级或新地面经济。F5三个模板组合包含六类敌人，不声称所有十五模板同时进入F5池。计划要求Pool≥2×层数+3，目前20件足够五层；更多层需要同步扩池。攻击上限会在极端Build截断追加尾部，原13件可见变化仍保留。不合并main，不进入下一阶段，交付后等待人工试玩。
