# Phase 7A 验证：古董拾取与有限背包

## 基准、范围与架构

从最新main `8b19dfb9f658246688abe400197cb0644141f48d`建立`codex/phase-7a-antique-inventory`。Godot4.6.2标准版、Windows、Compatibility。本阶段只有古董Definition、独立池、安全古董房底座、8格库存、背包UI/HUD、跨层和本局结果展示。

新增AntiqueDefinition/AntiqueInventory/AntiquePool/AntiquePedestal，与RelicDefinition/Inventory/Runtime完全分开；不新增战斗Hook，不改PlayerStats或Health/Weapon。Player拥有RefCounted AntiqueInventory，只保存只读Definition引用数组，不存Pickup、Effect或UI节点；允许重复古董按件占格计值。items返回数组副本，remove(id)删第一个匹配项，remove_at(index)用于准确删除重复件；changed信号只驱动局部UI。

## 正式8件资源

| ID | 名称 | base_value | slots | rarity |
| --- | --- | ---: | ---: | --- |
| republic_silver_coin | 民国银元 | 120 | 1 | COMMON |
| blue_white_jar | 青花小罐 | 350 | 2 | COMMON |
| gilt_buddha | 铜鎏金佛像 | 600 | 2 | UNCOMMON |
| han_jade_disc | 汉代玉璧 | 900 | 1 | UNCOMMON |
| inlaid_bronze_mirror | 战国错金银铜镜 | 1200 | 2 | RARE |
| tang_sancai_horse | 唐三彩马 | 1600 | 3 | RARE |
| gold_thread_jade | 金丝玉佩 | 2200 | 1 | TREASURE |
| guardian_fragment | 镇墓兽残片 | 3000 | 3 | TREASURE |

值仅原型，无真实经济平衡。Resource具有说明文本，ID唯一，value>0、slots≥1。正式池位于data/antiques/formal_pool.tres。

## Seed与拾取生命周期

Pool版本1，key为`version|run_seed|floor_number|raw_room_id`，从17开始逐字符`mixed=(mixed*131+unicode)%2147483647`；创建独立RandomNumberGenerator.seed=mixed，按稳定字符串ID排序后均匀选择。无全局随机、时间或StringName指针顺序，不消耗地图/遗物RNG。相同引擎/池/版本下同三元组稳定，不同Seed可碰巧同件，100Seed验证至少覆盖6种。两层暂同池、同概率，不引入稀有度权重；“第二层允许更稀有”本阶段未采用额外偏置。

Session注入run_seed→Controller用Pool挑选→Room接收Definition。ANTIQUE忽略模板spawns，没有敌人，进入安全CLEARED/开门；这个状态只表达可自由离开，不是要求拾取的战斗房。底座显示名称、格式化估值、格数和E提示；64px内E且有足够空间才add成功、标RoomState.antique_claimed并释放。

满包拒绝并显示“背包空间不足”，不消耗底座、不自动丢物、不锁门。未领可以离房后重访同一件；已领状态随本层Controller的RoomState保留，不重刷。丢弃后同房也不补发。

## 背包、HUD与跨层

默认8格，used/free按slots求和，total_value按每件base_value求和。Tab打开/关闭，ItemList列出每件名称/格数/估值，Delete或按钮按选中索引永久从当前Run删除；不在地面重生成。背包不暂停战斗，面板明确提示“背包打开时战斗继续”；死亡、通关和短暂控制冻结时禁止管理。

HUD下沿独立显示“古董：X / 8格 估值：¥Y [Tab]背包”，不覆盖顶部Boss血条或RoomInfo。背包面板处于房间区域，关上后继续操作；库存changed同步刷新HUD与Panel。

RunCarryState新增antique_definitions数组；新层创建新Inventory/Panel并逐件加入，旧UI释放，定义引用只读共享。HP与遗物ID/效果生命周期仍按原规则。R/N重建新Player，古董空，不添加死亡掉落/回收机制；死亡后直到重开仍保留本次画面中的背包数据。

RunResult新增antique_names/antique_value纯快照，RunCompleteScreen显示“带回古董”和总估值。内容可滚动，R/N固定底部；普通三遗物+两古董的结果无需滚动即可看到Boss统计。没有永久钱包、出售、存档或任何真实收益入账。

## 文件

新增（GDScript .uid随源提交）：

- scripts/antiques/antique_definition.gd、antique_inventory.gd、antique_pool.gd、antique_pedestal.gd
- data/antiques/8份正式资源及formal_pool.tres
- scripts/ui/antique_inventory_panel.gd
- tests/phase_7a_data_checks.gd、phase_7a_run_checks.gd、phase_7a_smoke.gd
- docs/PHASE_7A_VERIFICATION.md

修改Player只增加独立库存字段；RoomState只增加antique_claimed；Room/Controller注入与装配拾取、Panel/HUD连接；Session/RunCarryState/RunResult与结算UI加古董快照；HUD标题/房型标签；AGENTS/README/ARCHITECTURE/PROJECT_PLAN。

旧phase_6_5_run_checks增加三处默认空测试扩展钩子，让Phase7A复用同一真实两层战斗并在钩子真实访问/领取古董。未删旧断言，Phase1～6.5原检查数量保持。Boss、普通敌人、遗物效果/RewardService、Generator/Floor Seed、玩家基础数值未改。

## 自动验证

本机godot为`C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`。项目根目录运行：

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
godot --headless --fixed-fps 60 --path . --script res://tests/phase_7a_smoke.gd
godot --path . --disable-vsync --fixed-fps 60 --script res://tests/phase_7a_smoke.gd -- --capture
```

| 检查 | 真实结果 |
| --- | --- |
| 导入解析、启动 | 均退出0，无Godot解析或运行错误 |
| Phase1 | 27检查，0失败，退出0 |
| Phase2 | 204检查，0失败，退出0 |
| Phase3 | 94检查，0失败，退出0 |
| Phase4 | 105检查，0失败，退出0 |
| Phase5A | 61检查，0失败，退出0 |
| Phase5B | 236检查，0失败，退出0 |
| Phase6 | 164检查，0失败，退出0 |
| Phase6.5 | 174检查，0失败，退出0 |
| Phase7A | 306检查，0失败，退出0 |
| Phase7A实际OpenGL图形 | 306检查，0失败，退出0 |

用户33项覆盖：1～3资源唯一/正值/正格与准确8件数值；4～10容量、空/混合3+3+2格、溢出、ID/索引删除、clear及副本；11～12库存隔离/战斗Stats与HP未变；13～19真实安全房/开门/距离/满包/E一次/不拾取可过Door；20～22连续100Seed同元组稳定、不同Seed变化、第二层有效选择；23～26真实跨层定义保留且新库存/旧Panel释放，HP/Relic旧断言与R/N清空；27～30HUD/Panel值/真实Tab/Delete腾出空间再E、丢弃不重刷；31～32完整结算名称与估值；33完整Phase1～6.5回归。额外重复件计数、items不暴露内部数组和新层UI生命周期覆盖。

日志在忽略的logs/phase_7a_final_*.log、phase_7a_graphical_final.log。检查最终汇总、helper.completed及ERROR/SCRIPT ERROR，不只看退出码。初次辅助测试动态类型无法推断panel，改显式AntiqueInventoryPanel后重跑；图形捕获在Tab后等两帧完成UI布局，结算压缩一行空白保证常规结果可见，未删除功能断言。

## 真实完整流程与截图

Seed192034，从Floor1 START沿真实Door/WASD进ANTIQUE，实际E拿金丝玉佩（¥2200、1格），离房并真实重访不刷第二件；继续活跃AI普通战斗、正常E领遗物，真实武器/弹丸击杀大帅尸，实际E进第二层。

Floor2先继续正常COMBAT，累计第7清场正常领第三遗物；确认第一件金丝玉佩仍在新的Inventory且旧Panel释放。再沿真实Door进第二层ANTIQUE，实际E拾第二件金丝玉佩，真实Tab显示两件、2/8格、总¥4400，关闭面板继续活跃AI战斗。真实Weapon/Projectile击杀镇墓兽，实际E返回地面结算，显示两条古董名称与¥4400、HP80/80、3件正式遗物、普通清理11、Boss2。之后真实R/N新局，古董清空。

正常主流程没有直接inventory.add、改HP、工程遗物/F2或直接高伤杀Boss；单位容量/丢弃/R/N边界可直接add。程序驾驶沿原框架为战斗选择安全射击位置，不能作为人工手感或风险验收。实际OpenGL窗口全流程与PNG已检查底座/面板/底部HUD/结算，离屏位置仅避免干扰用户桌面，仍真实图形渲染。

## 已知限制与停止范围

两层暂同池均匀概率，不承诺不同Seed必定不同或第二层一定更稀有；重复古董允许，初始价格只是配置。背包不暂停战斗。数据定义按只读约定，尚无完整内容编辑校验工具。没有死亡掉落、撤离、出售/黑市、真假/鉴定、钱包/永久货币、战斗古董、保险箱/尸体回收或存档，也没有第三层/新Boss。

本次自动与图形交互已完成；未要求、未进行额外人工手感验收，不把程序驾驶当人类试玩。提交push当前分支后停止，禁止合并main或开始Phase7B。
