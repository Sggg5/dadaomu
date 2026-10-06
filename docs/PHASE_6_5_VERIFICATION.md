# Phase 6.5 验证：镇墓兽与两层Demo结局

## 基准与边界

从最新origin/main `d833efe8ddd99f8df278e5202a503f3601af0d2f`创建`codex/phase-6-5-tomb-beast-finale`。Godot4.6.2标准版/Windows/Compatibility。本阶段到第二层E通关结算为止，不实现第三层、第三Boss、古董/背包/撤离经济、黑市、永久成长、存档、新普通敌人、正式美术音效或Boss掉落。

第一层晋北大帅尸已获用户人工验收（本次任务明确说明）。其warlord_boss.gd完全未修改，650基础HP/845实例HP、冲锋/震荡/召尸数据与时序保持；只调整Boss资源场景引用和装配。

## Boss泛化

BossDefinition新增boss_scene；BossEncounter从definition.boss_scene实例化Enemy，注入只读Definition/Player/本房Projectiles/Difficulty。遇到声明summon_requested的Boss才订阅通用召唤请求；无Boss ID判断、无硬编码warlord_boss.tscn。Health/killed/remaining/targets/defeated继续共用，HUD与Room.boss_started类型改为Enemy。

资源→场景单向引用：大帅尸tres引用scene，scene不再反向引用tres，防止循环加载。新增TombBeastDefinition保存镇墓兽参数，TombGuardianBeast独立Enemy子类，不复制大帅尸脚本。Session.boss_for_floor明确1→晋北大帅尸、2→镇墓兽、其他null；不引入Campaign或第三层。

## 镇墓兽实际数据与机制

| 数据 | 实际值 |
| --- | --- |
| ID / 中文名 | tomb_guardian_beast / 镇墓兽 |
| 基础HP / Tier3 HP / 移速 | 800 / 1040 / 80px/s |
| INTRO / 决策 / 后摇 | 1.0 / 1.0 / 0.6秒 |
| 扑击前摇 / 移动时间 / 落地半径 | 0.7 / 0.35秒 / 90px |
| 扑击基础伤害 / Tier3 | 20 / 27 |
| 石吼前摇 / 基础伤害 / Tier3 | 0.75秒 / 14 / 18.9 |
| 石煞弹速度 / 寿命 | 320px/s / 3秒 |
| 地刺施法状态 / 预警 / 爆发视觉 | 0.8 / 0.75 / 0.25秒 |
| 地刺半径 / 基础伤害 / Tier3 | 55px / 18 / 24.3 |
| 狂暴阈值 / 决策间隔 | 首次存活且HP≤50% / 0.8秒 |

固定INTRO→DECIDE→扑击→石吼→地刺→重复，无全局RNG。

扑击开始记录玩家位置，在记录点绘制圆形落点提示，前摇结束0.35秒扑向快照；不追踪移动玩家，到点/撞障碍结束，一次落地冲击。World LOS阻止隔墙伤人，不复用直线冲锋。

石吼前摇结束锁定朝向，直接构造AttackRequest生成EnemyProjectile，正常5枚[-30,-15,0,15,30]°，狂暴7枚[-36,-24,-12,0,12,24,36]°。固定速度/方向，墙体销毁，每枚沿原Projectile消费逻辑最多一次。不会走Player遗物修改管线，普通枪手代码未改。

地刺施法开始以当时玩家位置产生预警，交替Pattern A (0,0)/(100,60)/(-100,60)与B (0,0)/(80,-90)/(-80,-90)，狂暴再加±150侧点。候选避开World中心/房边，有限网格补位，点间至少40px。独立TombSpike警告0.75秒后55px内一次伤害，视觉0.25秒后释放；施法状态0.8秒与警告同时推进，不把前摇和警告串成1.55秒。

第一次半血只进入一次Rage，不召怪；弹数5→7、地刺3→5、决策1→0.8，三技能前摇完全不变。兽形几何轮廓有角、石躯、发光眼；与军帽/披风大帅尸区分，无正式素材。

## 所有权、胜利、出口与结算

两层BOSS都忽略随机模板spawns，只复用视觉/障碍。BossEncounter同一组件运行两只Boss。镇墓兽活着时ACTIVE/关门/显示名字与HP，死亡一次defeated，停止AI，清自身弱引用跟踪的地刺、弹丸、落地反馈；Room再清局部弹丸、CLEARED/开门/隐藏HUD。玩家死亡也stop_ai并清未爆地刺，TombSpike主动检查owner.can_act，不能继续伤害。

Room.final_floor决定胜利出口，不判断Boss ID；第一层FloorExit深入，第二层RunExit返回，两者独立类。已清Boss房重访恢复对应出口，不刷Boss或重复统计。RunExit文字“墓穴深处已肃清 / [E] 返回地面”，距离≤64px且玩家活着/控制可用时E仅一次发run_complete_requested。

Room.boss_defeated→Controller→Session显式按floor去重，第一Boss1、第二Boss2，不靠房间数量猜。第二Boss死亡并不立即run_completed，只有RunExit E通过第二层/CLEARED/两Boss验证后置true。

RunResult仅保存run_seed、floors_cleared、current_hp、max_hp、relic_names、combat_clears、bosses_defeated，无节点/Effect引用。RunCompleteScreen只读快照展示Seed/两层/当前HP/遗物中文名/普通清场/Boss2，以及R同Seed/N新局。未加入计时器。

通关关闭Player.controls_enabled、停止本房战斗/奖励；Controller.run_finished同时挡住Door traversal、_spawn_projectile和开发测试伤害，防额外调用绕过输入冻结。E不能重复结算；R/N沿既有新Run逻辑释放旧界面、恢复floor1/80HP/空Build/零奖励进度与Boss统计。R同Run布局/奖励序列，N新Seed；Floor Seed、跨层HP/Build与2/4/7整局规则不变。“返回地面”本阶段只到结算，不是黑市或收益入档。

## 遗物自然接通

沿既有Room.damage_targets/CombatGeometry/Projectile hit工作，无Boss ID或组合特判。八件正式遗物逐件使用真实Weapon/Projectile命中镇墓兽；黑火药真实范围伤害、尸油灯真实三tick燃烧、镇尸钉穿透、数量/镜像/重弹/纸鸢修改均沿原Runtime。

墨斗原规则排除直接命中者并伤墨线上的其他目标，不能把“命中Boss再额外伤Boss”当断言。专项使用镇尸钉穿过Boss后真实命中后方靶，再让墨线自然回扫Boss，确认额外6伤害。未修改墨斗或CombatGeometry。全部八件同时安装时，Boss敌弹伤害/速度/穿透/标签不受影响。

## 新增与修改文件

新增（GDScript .uid随源提交）：

- scripts/bosses/tomb_beast_definition.gd、tomb_guardian_beast.gd、tomb_spike.gd
- scenes/enemies/tomb_guardian_beast.tscn、data/enemies/tomb_guardian_beast.tres
- scripts/dungeon/run_exit.gd、run_result.gd、scripts/ui/run_complete_screen.gd
- tests/phase_6_5_boss_checks.gd、phase_6_5_relic_checks.gd、phase_6_5_run_checks.gd、phase_6_5_smoke.gd、beast_fight_driver.gd
- docs/PHASE_6_5_VERIFICATION.md

修改BossDefinition/Encounter、Warlord资源/场景、Session、Room/Controller、BossHUD/RoomHUD及HUD标题、Phase6两个夹具测试，四份主文档AGENTS/README/ARCHITECTURE/PROJECT_PLAN。大帅尸AI、PlayerStats、普通敌人数据、遗物/奖励服务、Generator/Seed算法未修改。

旧Phase6第二层普通占位断言改为正式镇墓兽单实例/忽略模板spawns/显示HUD；普通占位清场调用换成真实武器击杀镇墓兽，保留第二层清场、跨层、奖励和无第三层断言，并增加RunExit断言。旧第一Boss冲锋隔墙与死亡HUD回归全部保留。

## 验证命令与真实结果

本机godot路径为`C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`。

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10
godot --headless --fixed-fps 60 --path . --script res://tests/phase_1_smoke.gd
godot --headless --fixed-fps 60 --path . --script res://tests/phase_2_smoke.gd
godot --headless --fixed-fps 60 --path . --script res://tests/phase_3_smoke.gd
godot --headless --fixed-fps 60 --path . --script res://tests/phase_4_smoke.gd
godot --headless --fixed-fps 60 --path . --script res://tests/phase_5a_smoke.gd
godot --headless --fixed-fps 60 --path . --script res://tests/phase_5b_smoke.gd
godot --headless --fixed-fps 60 --path . --script res://tests/phase_6_smoke.gd
godot --headless --fixed-fps 60 --path . --script res://tests/phase_6_5_smoke.gd
godot --path . --script res://tests/phase_6_5_smoke.gd -- --capture
```

| 检查 | 真实结果 |
| --- | --- |
| 导入解析、启动 | 均退出0，无Godot解析/运行错误 |
| Phase1 | 27检查，0失败，退出0 |
| Phase2 | 204检查，0失败，退出0 |
| Phase3 | 94检查，0失败，退出0 |
| Phase4 | 105检查，0失败，退出0 |
| Phase5A | 61检查，0失败，退出0 |
| Phase5B | 236检查，0失败，退出0，三组协同保持 |
| Phase6 | 164检查，0失败，退出0，包含两只正式Boss真实击杀 |
| Phase6.5 | 174检查，0失败，退出0 |
| Phase6.5实时图形 | 174检查，0失败，退出0 |

对用户68项要求的覆盖：1～10场景泛化/映射/无ID分支/正式单Boss/HP与HUD；11～19固定扑击前摇/快照/移动/内外伤害一次/障碍与LOS；20～27五弹角度/参数/锁向/非追踪/墙销毁/不受Player遗物影响；28～35三预警/定时/内外伤害一次/释放/双方死亡清理；36～42首次Rage/7弹/5地刺/决策/前摇不变；43～52胜利一次/Room与HUD/清攻击/只RunExit/距离与E一次；53～68真正E通关/冻结与防额外发射/快照与文字字段/遗物名字/显式Boss数/R和N重开及旧界面释放。

日志在忽略的logs/phase_6_5_*.log。首次开发发现条件数组需assign转换到typed Array，修正后无Script Error；燃烧测试等待包含飞行+三tick，墨斗断言修正为既有“其他目标”语义，未删效果覆盖。离屏图形复跑曾出现新静态体夹具未稳定的扑击障碍断言；增加3帧静态体登记等待和1帧角色姿势同步，保留原几何/HP/LOS断言，最终整套图形174项通过（停止位置565.49、隔墙距离84.51、HP80、LOS=false）。
检查每套completed与最终汇总/ERROR，不能只依赖退出码。

## 完整真实两层流程与图形

Seed192034第一层安全START，活跃普通AI，实际Weapon/Projectile清六个COMBAT，实际E拾取墨斗/五帝钱；真实WASD/Door到大帅尸，实际冲锋/震荡/半血召尸后真实弹丸击杀。实际E深入第二层Seed121872，HP/两件遗物保留；普通战斗累计第7次真实E获黑火药，再经真实Door到镇墓兽。

镇墓兽实际执行扑击、石吼、地刺与半血Rage，真实Weapon/Projectile击杀；只产生RunExit，死亡后尚未完成；距离外E拒绝，64px真实E才结算。截图结算显示Seed192034、2层、80/80HP、墨斗/五帝钱/黑火药、普通清理10、Boss2。R实际同Seed第一层空Build；N使用独立结算边界夹具验证新Seed与界面清理，不把夹具当正常通关。

主流程不restore Boss到1、不直接高伤害杀Boss，不用F2、不添加工程或额外正式遗物，不改玩家HP通过战斗。程序驾驶会瞬时选择安全射击点，并为观察狂暴扇弹/地刺暂缓收尾开火；不是人工移动或手感。镇墓兽程序驾驶约18.2秒，不能据此宣称人工25～45秒目标已达成。

实际实时OpenGL窗口全流程174项通过，已查看兽形与血条、弹幕、胜利返回提示及结算截图；另外捕获明确扑击/扇弹/地刺预警与地刺爆发截图，图形日志与PNG均位于忽略的logs。固定60fps离屏窗口捕获仅避免干扰用户正在试玩，不是headless模拟图形。

## 人工试玩与已知限制

第一层Boss已获用户验收，本阶段未改其技能/数值。已打开当前游戏Seed192034，请用户不使用F2检查第二Boss落点、弹幕缝、地刺、狂暴压力、25～45秒时长、返回结算与R/N；用户回复“先交付，人工验收待完成”，已按该状态交付。自动/图形通过不等于人工手感通过。

已知限制：几何占位，无正式美术/音效；简单绕障非完整寻路；固定Pattern边界用有限安全点补位；程序驾驶瞬移降低受伤概率和耗时；人工Boss时长/压力仍需复验。结局只开发结算，没有黑市/古董/收益存档。仅两层两Boss，不建第三层。单脚本均≤300行。完成本分支提交push后停止，不合并main、不进入古董。
