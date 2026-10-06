# 项目协作规则

## 范围与阶段

本项目是 Godot 4.x / GDScript / Windows 的原创 2D 俯视角 Roguelite《大盗墓时代》。阅读 README、PROJECT_PLAN、ARCHITECTURE、GAME_DESIGN 后再修改。用户指令优先；每次只执行明确授权的 Phase。当前授权 Phase 4，完成后必须停止，不自动实施 Phase 5、真正 Boss 或古董内容。

每阶段保持可运行入口，结束前检查导入解析、启动和阶段相关行为。报告修改文件、架构变化、验证命令与真实结果、已知限制及下一阶段范围。未执行的检查必须明确标注，不能把规划写成已实现。

## 技术要求

- 优先标准 Godot 节点、场景组合、类型化 GDScript 和 Resource 数据。
- 降低系统耦合，显式引用与局部信号优先；不要创建万能管理器/事件总线。
- 数据定义与运行时状态分离，稳定 ID 与显示名称分离。
- 单脚本禁止超过 1000 行，建议 300 行内；超过 500 行应检查拆分。
- 核心系统注释说明职责、生命周期和边界；不堆无意义注释。
- 未有明确需要不引入第三方插件、框架、对象池或额外依赖。
- 设计不确定时采用最简单、易扩展且能验证的实现，并记录假设。
- 不复制参考游戏的美术、角色、敌人、道具、地图或剧情；外部素材记录来源和许可。

## 文件与 Git

使用 scenes/、scripts/、data/、assets/ 按职责归档；文件 snake_case。修改前查看 Git 状态，保留用户已有修改。不重置、覆盖无关文件；不自动提交、推送或改写历史。新分支默认 codex/ 前缀。提交源 `.uid`，忽略 `.godot/` 和构建/日志。

## 验证

优先使用本机 Godot 4.6.2 标准版；如果命令不在 PATH，定位完整路径。

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10
godot --headless --path . --script res://tests/phase_1_smoke.gd
godot --headless --path . --script res://tests/phase_2_smoke.gd
godot --headless --path . --script res://tests/phase_3_smoke.gd
```

启动冒烟不能代替实际交互检查。涉及随机生成、效果卸载、重复结算和存档的修改应有针对性验证；简单占位 UI 不写镜像式测试。失败先修复当前阶段，不跨阶段规避问题。

## Phase 2 房间约定

- 五房复用同一个 Room 场景，差异放在 RoomDefinition 数据中。
- RoomController 持有唯一玩家和 RoomState；Room 持有局部敌人、弹丸、门与墙。
- 状态只能 UNVISITED → ACTIVE → CLEARED；重访 CLEARED 不刷怪。
- 切换必须验证相邻关系和清场状态，冻结输入并延迟卸载；禁止在 Area/物理信号中立即删除碰撞体。
- 生成器通过 Health.died 计数；卸载房间不能被当成击杀或清场。
- 真正非战斗房内容尚未实现；Phase 3 的占位进入规则见下文，不要把枚举或占位报告为完整内容。

## Phase 3 地宫约定

- 本阶段工作分支为 `codex/phase-3-random-dungeon`。用户已授权验收后提交，禁止自行合并 main；未明确要求的推送不自动执行。
- DungeonGenerator 只生成纯布局，使用独立 RNG；不创建节点，不依赖全局 RNG、时钟或场景树。
- DungeonRoom 决定 ID、坐标、类型、距离和连接；RoomDefinition 只提供内容模板。不要为每个随机图节点新增 `.tres`。
- RoomController 只消费注入的 DungeonLayout，不添加生成算法或固定五房拓扑。启动/Seed/重开由开发入口 DungeonSession 装配。
- 图为 8～12 房的正交树；START 在 (0,0)，Boss 为最深叶子且距离至少 5，ANTIQUE 距离至少 2。
- 候选遍历与签名必须显式稳定排序，StringName 应转字符串后排序；检查跨进程复现，不能只验证同进程重复调用。
- R 保留当前 Seed；N 用独立 Seed 来源获得新布局。生成版本、配置、模板池和引擎版本影响复现结果。
- START/BOSS 为普通战斗占位，ANTIQUE 自动清场。古董内容属于 Phase 6，Boss 战斗属于 Phase 7。
- Phase 2 固定图仅保留在 tests/fixtures；改旧测试时保留原始行为断言，不通过删除断言掩盖回归。

## Phase 4 敌人约定

- 当前分支 codex/phase-4-enemies；用户已授权验证后提交，未授权推送或合并 main。
- EnemyDefinition / RangedEnemyDefinition 只读；Enemy 持有实例 HP、冷却和观察期。Player 与弹丸容器通过 Spawner 显式注入。
- RoomDefinition.spawns 是唯一生成入口，EnemySpawnDefinition 指定场景、数据和位置。Dummy 只保留给旧回归夹具。
- 敌人弹丸仅检测 World / Player；不伤友军，不追踪移动目标，房间卸载或玩家死亡必须清理。
- 入房默认 1 秒观察期，暂缓 AI 移动和攻击；模板生成点距四入口至少 180 像素。不得跳过攻击前摇补偿难度。
- 必跑 Phase 1～4 smoke，保留旧功能断言。人工试玩与程序驱动图形验证分开报告。
- Phase 5 准备仅文档规划，不提前实现遗物、Boss、古董、黑市或存档。