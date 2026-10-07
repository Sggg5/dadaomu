# Phase 9B.3.2c：Player Baseline / Relic Growth / Boss Scale

## 基线与边界

A提交51909c658f828f686bea246e847e7505f2a24008；B提交5af5bb1d6cf37ce5ec7c93bce0214d796f690a39；保留已有9B.3.3压力逻辑，不reset、不合并main。C仅生产Player基线、5件属性成长/取舍遗物、Boss真实体型及范围。Boss HP/伤害/技能前摇/速度/组合、80HP/0.25秒无敌/8格/F2+15/F4+20/五层结构/古董经济/Profile v4均不改；RewardPlan VERSION3、BossPlan VERSION1保持。没有Museum或新阶段。

## 基线与成长

生产default_player_stats：HP80、move_speed240、attack_damage20、attack_speed3.5、projectile_speed750、lifetime1、acceleration1800、deceleration2200、hurt_invulnerability0.25。PlayerStats类的旧工程构造默认不代替正式场景资源；测试实际读取正式Player。

正式池36→41：机括簧cooldown×0.84；飞虎靴movement×1.12；雁翎speed×1.28/lifetime×1.08；缩地尺movement×1.20/lifetime×0.85；定风珠lifetime×1.20/speed×0.90。统一数据驱动growth_properties_effect只改AttackRequest快照与实例移动倍率，原远照灯×1.4与回风靴受伤0.8秒×1.2保持。移动总倍率0.5～1.5、最终冷却倍率0.5～2保持，卸载恢复、极端冷却数据仍受限、共享Stats只读。

|射程组合|实际物理飞行px|理论px|
|---|---:|---:|
|基础|737.50|750.00|
|far_lantern|1037.50|1050.00|
|goose_feather|1024.00|1036.80|
|goose_feather+far_lantern|1440.00|1451.52|
|wind_still_pearl+far_lantern|1125.00|1134.00|

实际Projectile在独立无墙容器以60Hz逐帧飞行，不用Room墙壁截断替代寿命测试。现有Projectile先扣寿命再移动，实际距离允许一个物理步差；理论基础750、远照灯1050，实际737.5/1037.5。

|攻速组合|10秒实际发射|连续理论|物理步理论|
|---|---:|---:|---:|
|基础|34|35.00|34|
|mechanism_spring|40|41.67|40|
|ghost_drum|47|47.25|47|
|mechanism_spring+ghost_drum|55|56.25|55|

|移动组合|实际速度|倍率|
|---|---:|---:|
|基础|240.00|1.00|
|flying_tiger_boots|268.80|1.12|
|wind_boots|288.00|1.20|
|shrinking_ruler|288.00|1.20|
|flying_tiger_boots+shrinking_ruler+wind_boots|360.00|1.50|

移动使用真实Input→加速→move_and_slide，随后放键减速到0；没有修改加减速。卸载后的下一次真实Weapon冷却恢复1/3.5。

## Boss身体与范围

|Boss|CircleShape半径px|
|---|---:|
|尸蟞母巢|40|
|棺中老尸|44|
|晋北大帅尸|36|
|铁索僵|36|
|纸扎将军|32|
|百足尸母|44|
|铜甲尸王|48|
|双生尸煞（每只）|32|
|镇墓兽|52|
|墓主人|42|

生产场景独立Shape，不写共享运行资源。角色占位轮廓按实际body_radius缩放，纹样/角/百足尾节是装饰，不新增攻击碰撞。draw_set_transform在每个身体绘制结束恢复，HP条不被放大。铜甲重砸205px、冲锋预警宽度至少body_radius×2（铜甲96）；镇兽扑击圈与命中半径98.8px，原0.8s前摇保持；老尸棺盖宽128px。近身冲锋命中使用body_radius+玩家16，碰墙优先、LOS及一次伤害保持。

BossEncounter、召唤与卵读取各自真实身体半径，避开当前Arena障碍和其它真实身体；双生子体32半径出生。20个Boss/Arena兼容组合全部实际实例化、召唤/卵与危险区合法性验证。Boss机制未额外缩放速度、伤害或改变HP。

## 150/300/500真实距离探针

每个Boss各三次，真实AI/物理/攻击，起始距离准确；玩家不射击、不补血、站桩30秒上限或死亡终止。距离随后由Boss的正常移动改变，不能把这叫固定距离无限时长证明。记录实际技能；双生汇集两个成员技能史。F3～F5六Boss500px探针均出现伤害，未发现该夹具的永久零压力区。Arena使用显式开放单元夹具以排除遮挡；实际兼容Arena另外验证。

|Boss|150px HP损失|300px HP损失|500px HP损失|500px技能数|
|---|---:|---:|---:|---:|
|scarab_nest|80.00|80.00|80.00|6|
|coffin_old_corpse|80.00|80.00|80.00|8|
|jinbei_warlord_corpse|80.00|80.00|80.00|6|
|chain_zombie|80.00|80.00|0.00|18|
|paper_general|80.00|80.00|80.00|9|
|centipede_mother|80.00|80.00|80.00|5|
|bronze_king|80.00|80.00|80.00|6|
|twin_revenants|80.00|80.00|80.00|8|
|tomb_guardian_beast|80.00|80.00|80.00|5|
|tomb_master|80.00|80.00|80.00|7|

## 新基线自然Build Boss快照

独立Build Seed77，按F1～5前3/5/8/11/13来源，真实Weapon/Projectile，十Boss各移动/站桩两次。移动驾驶器在合法安全点间直接重新定位，不能用它证明真人无伤或难度合格；站桩只初始选位后不继续重定位。记录阶段跳过、阶段技能数、总技能、Combo、HP损失和最远实际交战距离，完整JSON位于ignored logs。以下是移动快照：

|Boss|遗物|秒|技能|Combo|HP损失|最远px|阶段|
|---|---:|---:|---:|---:|---:|---:|---|
|scarab_nest|3|9.80|7|2|0.00|530.31|1,2,3|
|coffin_old_corpse|3|9.05|4|1|0.00|328.29|1,2|
|jinbei_warlord_corpse|5|16.35|14|5|0.00|480.27|1,2|
|chain_zombie|5|12.90|7|3|0.00|298.90|1,2|
|paper_general|8|8.70|8|2|0.00|454.35|1,2,3|
|centipede_mother|8|12.70|8|2|0.00|545.97|1,2,3|
|bronze_king|11|17.00|10|4|0.00|323.86|1,2,3|
|twin_revenants|11|13.75|8|4|0.00|410.91|1,2|
|tomb_guardian_beast|13|23.40|13|5|0.00|346.13|1,2,3|
|tomb_master|13|24.35|16|5|0.00|578.35|1,2,3|

移动10/10实际击败Boss；站桩6/10玩家死亡，其余夹具战斗有限结束。此轮不根据安全点驾驶器擅自改整体平衡。

## 五层普通战斗续航

正式GameFlow内存测试Profile→真实夜间Run33→逐房战斗/真实遗物与古董拾取/五Boss/休整/最终出口→真实Day2Museum。不用F2/inventory.add替代本主流程，不补满HP、不改敌伤；保留原F2/F4一次RestPoint。自动驾驶会重定位安全点，所以如下零掉血/零死亡仅是该驾驶器一局结果，不能据此报告人类死亡率。

|层|首次Combat|合计战斗秒|HP损失|死亡|
|---|---:|---:|---:|---:|
|F1|4|46.35|0.00|0|
|F2|6|45.25|0.00|0|
|F3|8|54.75|0.00|0|
|F4|12|96.05|0.00|0|
|F5|10|55.30|0.00|0|

## 回归与图形

旧Phase2/3/4/5A/9A击杀夹具将14帧冷却假设改为真实weapon.cooldown_remaining×60向上取整+2帧；保留击杀、治疗次数、门、跨房、唯一Player、重启等所有原功能断言。历史生存测试移速期望更新240，其余生存断言保持；9B.3池总数/1000Seed全覆盖由36更新41，仍13无重复、最少两CORE及原分布检查。原扑击锁点预警70期望改真实身体×1.9，保留锁点与可躲避断言。

Phase1～9B.3.3+Geometry 21套共291885项、0失败；Softlock1030项、0失败；Player/Boss新专项727项、0失败；合计293642项、0失败。Phase4等待帧数适配修正后单套105项重新跑通过；Geometry增补20兼容组合后206884项重新跑通过，其他已通过回归未删除断言。

|套件|项数|失败|
|---|---:|---:|
|1|27|0|
|2|204|0|
|3|94|0|
|4|105|0|
|5a|61|0|
|5b|236|0|
|6|164|0|
|6_5|174|0|
|7a|306|0|
|7b|722|0|
|8a|482|0|
|8b|305|0|
|8c|297|0|
|8d|2153|0|
|9a|10510|0|
|9b|30753|0|
|9b2|4842|0|
|9b3|29132|0|
|9b32|1733|0|
|9b33|2701|0|
|geometry|206884|0|

Boss/player graphical专项727项0失败，生成十Boss身体/30距离/自然Build/五层回馆截图；目检铜甲、镇兽、老尸身体明显大于玩家，预警与HUD独立。B图形空间专项206582项0失败，13普通/6Arena覆盖；C进一步实际验证全部20兼容组合与新半径。导入和隔离Profile正式入口启动正常。故意损坏Profile夹具的WARNING是预期；全部最终测试无SCRIPT ERROR/ERROR。

命令：`godot --headless --fixed-fps 60 --path . --script tests/phase_<阶段>_smoke.gd`；新专项分别`phase_softlock_smoke.gd`、`phase_geometry_smoke.gd`、`phase_player_baseline_smoke.gd`。图形省略`--headless`并加`--disable-vsync --fixed-fps 60 -- --capture`。导入`--headless --editor --quit`；正式入口`--headless --quit-after 10 -- --profile-path=user://tests/player_baseline/startup.json --seed=33`。截图/日志/脚本辅助全部ignored logs，不提交用户存档或输出。

人工验收待最终正式窗口：不用F2，观察开局输入、成长差异、潜地尸可击杀、五层Boss与地形打法。没有据自动驾驶无伤宣布手感验收通过，也没有自行进入Museum/其它阶段或重新大改Boss Pressure。
最终当前版本Geometry graphical已重跑206884项0失败，包含新半径及20个真实兼容组合；与Boss/player graphical727项合计207611项0失败。
