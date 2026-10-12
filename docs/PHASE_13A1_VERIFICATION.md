# Phase 13A.1 四派玩法与前辈遗体分布返修

基线：c7f0711394d88daa6933c6cf098cf4cb15f1ce03。当前分支codex/phase-13a-profession-tokens。功能提交：acd73cc0cf275e8a0caa5460b99a8da2d7c55b57。

本次替换13A的暂定能力与首层四具遗体规则；保留出发快照、独立信物背包、安全原子切换、跨层、超载不丢货、远征结束清理。没有重构GameFlow，没有合并main，没有操作正式存档。全部美术DRAFT，自动验收完成，人工体验待验。

## 规则和触发位置

| 门派 | 当前规则 | 防重复与继承 |
|---|---|---|
| 摸金校尉 | 安全清房时Q；每层一次有效暗道或未访问特殊房线索 | MOJIN:CLUE:F#账本；没有有效目标不扣；切派、重访不恢复；下一层独立一次 |
| 发丘天官 | 每个首次进入的真实COMBAT/BOSS，第一筆实际正数伤害减免30% | 以F#:room稳定键记录访问和实际受伤；无敌期/零伤不扣；重访不刷新 |
| 搬山道人 | 移动倍率1.08；四次有效武器发射命中后，下次攻击批次伤害1.25 | 同一发射多弹/穿透最多信用一次；真实spawn后才消费准备；次数、进度和准备跨层/切派保留 |
| 卸岭力士 | 卸岭旗；容量8→10，正常9～10格满载移动因子0.95 | 退派超出8格保持全部物品和价值，因子0.8且禁拾；重新装备或减载解除超载 |

摸金只读取原TombExplorationPlan和DungeonLayout：真实暗道的parent+墙面方向，或实际未访问ANTIQUE/RELIC节点；不生成新地图、不揭门、不影响原随机状态。

发丘在已有遗物减伤之后、Health之前过滤；Health.damaged确认实际正数损失后记录，不使用接触每帧触发。祭台主动支付是原有风险成本，保持原值，不减免也不消耗防御首伤；机关伤害正常走职业过滤。已在其他职业实际受伤的房间不能后来切派刷首伤。BOSS作为战斗房纳入规则，安全出生房和纯空房排除。

搬山监听原武器最终AttackContext，为最终批次附独立Object元数据ID。RoomController真实创建弹丸时绑定命中回调。有效伤害才有信用，落空、拒伤、持续伤害、未经该批次的魂弹/回声等遗物派生弹不计。普通弹丸tags不变，避免干扰原遗物和空标签美术回退。强化覆盖下一批次的直接武器伤害，不改共享Stats、遗物或敌人定义。仅准备请求、弹丸预算拒绝不会消费；真实创建的首颗强化弹丸消费一次。已准备时不无限排队累积强化。

负重0.95/0.8是本次明确区分的可配置DRAFT策划值；其后仍沿用原遗物/环境倍率组合，并非覆盖所有移动规则。只有一个职业/负重键，反复切换不累乘。超额物品跨层用已有restore_carry完整转移，普通add仍拒绝超容量。

## 遗体分布

独立ProfessionCorpsePlan.VERSION2；data/professions/corpse_distribution.json配置后层概率0.5、最多一具。生产首层保底一具，后层0或1；后层禁用配置不能关闭首层保底。房间选择和门派选择均使用独立RNG，不调全局随机，不由初始门派保证第二种信物。

遗体落点避开实体障碍、其它交互物和危险区；只在清房且安全时64px内E搜索。同一遗体一次，重复门派不叠效果，可另存虚构身份。卸岭文本统一为“卸岭旗”，身份为“执卸岭旗的无名前辈”，不是历史人物或真实馆藏资料。

100 Seed ×5层的实际结果：

- 首层100具；摸金29、发丘25、搬山24、卸岭22。
- 后续400层生成210具（52.5%样本频率，配置概率50%）。
- 每局总数1/2/3/4/5对应4/25/34/31/6局，平均3.1具。
- 93/100局未集齐四派，不再保证首层或单局集齐。
- 各层最多一具；配置概率0/1正确；同Seed/配置结果重复一致。
- 原拓扑、Geometry、BossRunPlan、RelicRewardPlan和正式古董结果前后签名一致。

## 真实GameFlow验收

全部使用正式game_flow.tscn和内存新档，Day1现金0/馆藏0，不用LAB房，不注入生命、资金、遗物、古董或研究成果。单元测试可构造隔离对象，以下主流程均真实输入。

### 摸金 / 搜索 / 切换

Seed192034，出发地图真实选择摸金。正常地宫真实武器清房、真实E搜索本层唯一卸岭前辈，得到第二种信物和身份。Q取得本层有效线索，G装备卸岭后摸金Q失效、容量变10；G切回摸金，容量回8且本层Q仍已用。真实第一Boss/出口进入第二层，新层Q另一次，旧层消耗和线索保留。再击败第二Boss撤离回馆，下一次选无门派，实际战斗伤害死亡验证原结束清理。

### 发丘

Seed192034，真实地图初选发丘，经Door进入普通战斗。真实枪手第一发输入16、实际承伤11.2；后续尸蟞输入14、实际14。真实武器清房，经真实Door重访，防御资格不刷新。正数/零数、无敌、重访的真实Health数值另有运行时专项。

### 搬山

Seed192034，初选搬山，实际WASD移动达到基础速度108%。真实鼠标射击/物理碰撞获得四次信用，HUD显示4/4待用，之后真实强化弹丸25伤害（原基础20）。第一战斗房录到4次实际强化发射。普通未伤害和重复碰撞、准备跨职业切换、消费账本另有运行时专项，未引入职业遗物。

### 卸岭十格完整性

Seed142初选卸岭。原地宫实际取得铜鎏金佛像2格/¥600、青花小罐2格/¥350、唐三彩马3格/¥1600×2，总10格/¥4150。通过真实拾取、原武器、真实第一/第二Boss和出口获得；正常满载95%显示清楚。

撤离场景：G卸下为无门派，全部10格与¥4150保持，容量8、移动80%、无法再拾取。真实F撤离/E回館，四件古董进入实际MuseumCollection，职业信物清空。

死亡场景：同Seed另一趟真实流程再取得相同四件，G卸下后E从第二层进入第三层，10格、名称序列、数量与价值完整保留，当前仍无门派容量8。G重新装备卸岭旗恢复10格/95%，真实Door进入第三层，实际敌人伤害死亡，原死亡规则清空古董和本局职业状态。没有通过直接清血或直接inventory.add替代主流程。

## 实机媒体

原生Godot4.6.2、1280×720；7.5fps按物理时间采样。MP4和原始PNG保留1280×720；GIF960×540最近邻，发丘/搬山7.5fps、长流程2.5fps。结尾附最后真实结算/死亡截图停留2秒，不是模拟动作。程序操作不等于真人试玩。

| 演示 | GIF | 完整MP4 |
|---|---|---|
| 摸金择派、线索、遗体、切换、跨层 | [摸金](screenshots/phase_13a1/mojin.gif) | [MP4](screenshots/phase_13a1/mojin.mp4) |
| 发丘真实首伤与重访 | [发丘](screenshots/phase_13a1/faqiu.gif) | [MP4](screenshots/phase_13a1/faqiu.mp4) |
| 搬山移动、四命中与强化 | [搬山](screenshots/phase_13a1/banshan.gif) | [MP4](screenshots/phase_13a1/banshan.mp4) |
| 卸岭十格、超载与撤离 | [卸岭](screenshots/phase_13a1/xieling.gif) | [MP4](screenshots/phase_13a1/xieling.mp4) |
| 十格超载跨层、重装与真实死亡 | [跨层死亡](screenshots/phase_13a1/xieling_death.gif) | [MP4](screenshots/phase_13a1/xieling_death.mp4) |

原始截图目录同上，关键图：MOJIN_after_search / second_faction_active / mojin_used_preserved / floor2_preserved；FAQIU_ability_description / first_damage / revisited；BANSHAN_four_hits_ready / enhanced_attack；XIELING_ten_slots / overload / returned_collection；XIELING_DEATH_overloaded_floor3 / actual_death。文件名前缀均13a1_。

## 自动验证结果

退出码、零失败摘要与无SCRIPT ERROR/ERROR同时检查。原冻结断言仅精确授权本次实际改动，未删减原战斗、Boss、地图、存档、经济断言。旧13A“首层四具”“发丘货目”“搬山机关免伤”对应断言按照用户废弃规则替换，保留快照、背包独立、原子切换、安全门槛、超载完整性、R/N、结束清理覆盖。

| 专项 | 检查数 | 失败 |
|---|---:|---:|
| model | 325 | 0 |
| runtime | 49 | 0 |
| distribution | 2415 | 0 |
| mojin | 40 | 0 |
| faqiu | 11 | 0 |
| banshan | 11 | 0 |
| xieling | 25 | 0 |
| xieling_death | 27 | 0 |
| graphical_mojin | 40 | 0 |
| graphical_faqiu | 11 | 0 |
| graphical_banshan | 11 | 0 |
| graphical_xieling | 25 | 0 |
| graphical_xieling_death | 27 | 0 |

| 历史组 | 检查数 | 失败 |
|---|---:|---:|
| Phase1～11H（59组） | 338474 | 0 |
| Phase12/12A.1/4/5/6（5组） | 1145 | 0 |
| 11I真实从零30日 | 834 | 0 |
| 11I第一收入/中期两组A/B/C各30日经营 | 363+363 | 0 |
| 两组隔离磁盘往返与保护 | 69+69 | 0 |
| Python全库 | 134 tests | 0 |

Godot合计344334项，最终零失败。详细机器结果及媒体SHA见PHASE_13A1_TEST_RESULTS.json。导入解析通过，正式GameFlow入口启动由上述真实流程覆盖。Profile仍10，原50件藏品、正式8件晋北掉落、全部旧资源与研究数据库审核状态不变。

## 修复中发现的问题 / 未解决事项

- 初始暂定能力与用户原定位不符，本次已撤掉墙纹距离加成、发丘货目、搬山机关抵免，按明确规则实现。
- 曾使用普通tags编码批次ID，发现旧战斗特效依赖空tags；最终改为独立元数据并补录搬山，普通遗物标签/反馈保留。
- 测试操作器在19/407等Seed第二层死亡，23曾卡在寻路/攻击、106路线中断；不能冒称各Seed自动通关。最终只改测试输入操作器：不走真实房间外网格、连续移动中瞄准射击、八方向WASD和普通拦截瞄准，未改游戏碰撞、AI、HP或掉落。用实际可复现142完成十格流程。
- 历史11I2/4无checkpoint参数的初始调用明确拒绝，按原runner使用本次真实所得隔离checkpoint全量重跑通过，未伪造数据或删断言。
- 满载-5%/超载-20%的体验、尸体自然发现频率与摸金文字线索是否够清楚仍待人工；没有地图高亮新系统。
- 所有新美术和身份仍DRAFT；新增内容不冒充真人验收或史学审核。其它Seed的机器人表现不是玩家可玩性结论。

## 复现

```powershell
$qaGodot = 'C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
python tests/run_phase13a1_qa.py --godot $qaGodot --history --long-run --graphical
# 某一真实GameFlow演示，均使用内存档
& $qaGodot --path . --fixed-fps 60 --script tests/phase_13a1_flow_smoke.gd -- --case=MOJIN --run-seed=192034
& $qaGodot --path . --fixed-fps 60 --script tests/phase_13a1_flow_smoke.gd -- --case=XIELING --seed=142
# --case=FAQIU / BANSHAN / XIELING_DEATH 同样可运行
```

代码与测试/文档修改清单可由git diff c7f0711..acd73cc0cf275e8a0caa5460b99a8da2d7c55b57查看；验收媒体另提交。当前分支正常push，不合并main，不进入新阶段。人工请确认四派定位、摸金实际线索、首伤/强化反馈、正常满载和超载区别及遗体分布。完成停止。
