# Phase12A.6 — 首战房敌人现状审计（先于美术实施）

基线c4b0625，固定Run Seed522269330，正式GameFlow零资产内存档，经真实情报地图确认晋北、穿START实际Door进入首个COMBAT。使用12A.4现有隔离A几何替换空间，保留实际Encounter及敌人。审计运行见phase12a6_enemy_audit.json。

## 全部敌人

本房为2只corpse_dog（尸犬，40HP）和3只scarab（尸蟞，65HP），均真实CircleShape2D半径14。不是枪手、墓弩手或Boss。A几何注入前后身份与数量一致。位置会由原Spawner几何合法搜索改变，不改spawn规则。

- 尸犬：scripts/enemies/corpse_dog.gd的_draw_body绘制36×20矩形。EnemyVisual.supported仅识别scarab/bandit_shooter，所以尸犬在Basic/Enhanced仍走矩形回退；粉褐色矩形是实际敌人身体，不能隐藏敌人解决。
- 尸蟞：scripts/art/enemy_visual.gd读取actors图集第4行，6列仅待机、两步移动、单帧前摇、受击、死亡。无四方向图集，动作和立体细节不足，需要专属多帧方向素材。
- 血条：Enemy._draw中40×4背景与生命比例填充，与身体不是同一对象。必须保留生命语义，不能当粉块删除。
- 前摇：Enemy._draw半径23警示环，尸犬额外锁方向线，尸蟞由telegraphing暴露前摇。预警优先级保留，不随身体替换丢失。
- 环境：A Geometry独立EncounterHazard节点的预警/激活范围，不是敌人；保留全部实际计时和危险判定。
- 调试：碰撞overlay只在测试主动显示，正式GameFlow未开启；不删除真实碰撞。

## 实施边界

仅隔离A样板附加视觉适配器，读Enemy实际velocity/telegraphing/state/Health，不改AI、伤害、HP、碰撞和死亡释放时序。新图缺失或Legacy模式必须完整恢复旧敌人身体、血条及预警。死亡表现须在既有death_duration内完成，不延长节点生命。尸犬与尸蟞采用各自专属四方向、多状态多帧图，不旋转单帧假装动画。只在确认替换有效后遮蔽旧绘制，并由新适配器明确重绘原预警语义。

首次审计夹具误读RoomDefinition.id导致SCRIPT ERROR，已改为resource_path并完整重跑成功；失败日志保留logs/12a6_audit.log，未纳入通过统计。

远端首次检查网络连接超时，本地HEAD与用户基线一致，工作区开始为空；后续重试远端核对，不覆盖任何提交。
