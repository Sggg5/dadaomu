# 技术架构

## 当前实现

Godot 4.6.2 / GDScript / 2D / Compatibility。`project.godot` 启动 `scenes/main/dungeon_test.tscn`。DungeonSession 调用纯数据生成器，向 RoomController 注入 DungeonLayout，再复用现有玩家、战斗、Door、Room 和 RoomState。没有 Autoload、第三方插件、古董或 Boss 内容。

### Phase 3 数据与职责

| 模块 | 持有内容 | 职责 |
| --- | --- | --- |
| DungeonConfig / Resource | 8～12 房数范围、深度阈值、五份模板池 | 只读参数与有限约束校验 |
| DungeonGenerator / RefCounted | 每次调用的独立 RNG | 根据 Seed 和配置构造拓扑、类型、距离与模板引用；不创建节点 |
| DungeonLayout / RefCounted | Seed、节点字典、坐标索引、特殊房 ID、生成版本 | 一次纯结果；稳定完整签名与按坐标的空间签名 |
| DungeonRoom / RefCounted | 稳定 ID、Vector2i 坐标、类型、邻接、距离、模板引用 | 地图身份，和视觉模板、运行状态分离 |
| DungeonSession / Node2D | 当前 Seed、生成配置、独立新 Seed RNG、当前控制器 | 开发期启动、R/N 和场景装配，不是 Phase 8 单局 Run 系统 |
| RoomController | 注入布局、RoomState、唯一 Player、当前 Room | 只读拓扑，调度已有房间生命周期；没有生成算法或固定连接表 |

调用方向：Session → Generator.generate(seed, config) → Layout → Controller → Room / Door / EnemySpawner。HUD 读取 Layout 和 RoomState，不决定拓扑。

### 生成规则与终止

START ID 为 `START`，坐标 (0,0)，其余 ID 为按创建序号分配的 `ROOM_001` 等。先用局部 RNG 选择 8～12 的目标数量，再选择两个正交方向，构造至少 5 步的随机单调主路径；单调性保证不会自撞或形成环。

剩余节点从稳定顺序的合法边候选中随机选取。新格必须为空，且恰好邻接一个已有格；连接只在 NORTH/EAST/SOUTH/WEST 中建立，立即写入双向邻接。有限目标计数控制所有扩展，没有无限重试。有限坐标集的边界始终存在可扩展候选，异常仍返回明确失败。

树的父子距离就是最短路径距离；最远叶子标记 BOSS（至少 5 步，一扇门），排除 START/BOSS 后从至少 2 步的节点选择一个 ANTIQUE。其余为 COMBAT。节点全部共用原有五份模板池，不为每个地图节点创建 `.tres`。

### Seed 与复现

生成器不读取时钟/场景树/全局 RNG，仅使用本次 `RandomNumberGenerator.seed`。遍历候选和分配模板时显式按字符串 ID 排序；不能以 StringName 的默认比较顺序作为跨进程契约。完整签名包含 ID、坐标、类型、距离、连接、模板 ID/路径，空间签名忽略创建顺序和模板，仅比较位置/类型/连边。

同 Seed + 同配置 + 同模板顺序 + 同生成版本 + 同引擎版本重现完整结果。当前生成版本 1，验证引擎 4.6.2；没有承诺跨 Godot RNG 版本或算法升级后仍保持旧图。

Session 的 R 用当前 Seed 重新生成并替换控制器；N 使用独立随机来源最多选 16 个不同 Seed，比较空间签名找实际不同地图，失败保留原图并警告。新 Seed 不写存档。命令行 `-- --seed=192034` 可复现，HUD 始终显示实际 Seed。

### 模板与占位类型

RoomDefinition 的历史 `room_id` 是模板标识；`map_position` 只在 Phase 2 旧回归夹具读取，随机系统不读它。DungeonRoom 的类型、坐标和 ID 才是地图语义。Type 枚举在末尾增加 START，保留已有类型序号。

Controller 将模板、运行状态、已连接方向和实际节点类型注入 Room.configure。Room 原有普通战斗生命周期不重写；仅增加占位进入规则：START/BOSS 使用普通敌人，ANTIQUE 经 ACTIVE → CLEARED 自动开门。没有古董奖励/背包（Phase 6），没有 Boss 战斗（Phase 7）；MERCHANT/TRAP/SECRET 尚无规则。

### 小地图与回归夹具

RoomMinimap 从 Layout 坐标包围盒计算缩放/居中，只绘制实际邻接边。未访问暗色、已访问绿色、当前房金框；S/B/A 标记特殊房。没有固定十字或五房数量假设。

Phase 2 十字图只在 `tests/fixtures/fixed_room_test.gd/.tscn` 内生成并注入同一个 Controller；原 204 个断言保留，仅替换夹具/数据读取入口。生产 Controller 中不保留固定图兼容分支。

### Phase 2 组件与状态

- `RoomDefinition` Resource：模板 ID、房间名称、地面颜色、敌人场景、生成点与障碍矩形。五份 `.tres` 共用 `room.tscn`，不复制房间逻辑；拓扑坐标和实际类型在 Phase 3 移到 DungeonRoom。
- `RoomState` RefCounted：每局每房间独立的 UNVISITED → ACTIVE → CLEARED 状态，重复激活/清场无效；已清场状态不可倒退。
- `Room`：按定义创建墙、障碍和已连接方向的 Door；首次进入先锁门再生成；接收 all_defeated 后清场并开门。清场重访只重建布局与打开门。
- `EnemySpawner`：生成一次，按 Health.died 和实例 ID 管理存活集合；只把死亡作为击杀，卸载节点不算清场。Phase 4 按统一生成项创建 Enemy；旧测试夹具仍使用 Dummy。
- `Door`：World 层阻挡与只检测玩家的 Area2D；持续观察区域，玩家跨过门槛才发出方向请求。即使清场时已经站在门边，继续移动也能过门；单纯开门不会自动传送。
- `RoomController`：持有布局、各房状态、唯一玩家及当前 Room；验证清场/相邻/死亡/切换条件，冻结输入后延迟替换房间。固定拓扑在 Phase 3 已移出生产代码。
- `RoomTestHUD` / `RoomMinimap`：只展示房间、存活数、清场进度与状态，不改战斗状态；按钮发出操作请求。

门的方向为 Door.Direction.NORTH/EAST/SOUTH/WEST，回房入口取相反方向。没有相邻房间的一侧是整面墙。门的形状禁用采用 set_deferred，避免在物理查询/死亡回调中修改形状。

### Phase 2 所有权与切换

RoomController
→ RoomHost / 当前 Room（Doors、EnemySpawner / 敌人、Projectiles / 弹丸、墙）
→ Player（Health、Weapon）
→ HUD

玩家始终挂在 RoomController 下，不随 Room 卸载，也不在切换时重新实例化。生命、初始属性、无敌期和武器冷却保留；位置更新到目标房间入口内侧 64 像素，速度归零，防止立刻触发回门。`Player.set_controls_enabled()` 用于短暂冻结及死亡停用。

切换前原 Room 停止处理并离开场景树，再 queue_free；敌人与弹丸一起释放。当前场景树只保留一个 Room。RoomState 由控制器保留，所以重访 CLEARED 不重新生成敌人。死亡阻止过门和射击并回收当前弹丸；R/N 由 Session 重建控制器、玩家与运行状态。独立 Phase 2 夹具的 R 仍通过重载自身场景注入固定图。

### 房间类型扩展（规划）

真正内容仅有 COMBAT 原型；Phase 3 START/BOSS/ANTIQUE 的占位策略如上。其他类型仍需对应内容和规则。局部生命周期位于 Room，邻接数据位于 Layout，切换位于 Controller，可分别扩展而无需每房复制脚本。

### Phase 1 组件

- `PlayerStats` Resource：共享只读初始值；`default_player_stats.tres` 是默认配置。
- `Player` CharacterBody2D：输入、加减速、鼠标方向、短暂无敌期；组合 `Health` 和 `RangedWeapon`。
- `Health`：MaxHP / CurrentHP 运行状态，拒绝无效伤害；发出 changed、damaged、died，死亡只触发一次。
- `RangedWeapon`：按 AttackSpeed 控制冷却，发出 `AttackRequest` 数值快照。
- `CombatTest`：监听发射请求，创建弹丸到场景内 Projectiles 容器；连接 HUD 和测试操作；重载整场景完成重开。
- `Projectile` CharacterBody2D：速度、寿命和扫掠碰撞；首次命中后消耗，用 `take_damage(float) -> bool` 显式接口请求伤害。墙体没有伤害接口，仍会挡住弹丸。
- `Dummy` StaticBody2D：组合 Health，画占位几何与生命条，死亡通知测试计数后销毁；没有 AI。

### 攻击扩展边界（尚未实现）

攻击拆成“控制意图 → 武器策略/冷却 → 请求 → 世界内执行对象 → 受击接口”。后续霰弹与多重弹由武器策略产生多个请求；穿透/反弹由弹丸碰撞策略决定继续飞行；爆炸通过独立范围伤害执行对象；环绕物作为武器拥有的持续对象；近战武器使用独立 Hitbox 和同一伤害接口。引入这些武器时抽取共同武器接口并替换 Player 中当前 RangedWeapon 装配；不把近战伪装成弹丸，也不在 Player 中添加效果分支。当前没有实现这些策略、标记或空管理器。

### 输入与碰撞

输入动作：move_left/right/up/down（WASD 物理键）、attack（左键）、test_damage（F1）、restart（R）、quit（Esc）。移动通过 Input.get_vector 归一化；射击使用 physics_process，鼠标位于 UI 控件上时暂停射击。

| 层 | 位值 | 用途 / 掩码 |
| --- | --- | --- |
| 1 World | 1 | 静态墙；掩码 0 |
| 2 Player | 2 | 玩家；检测 World + Targets（5） |
| 3 Targets | 4 | Dummy；检测 Player（2） |
| 4 PlayerProjectiles | 8 | 玩家弹丸；检测 World + Targets（5），忽略玩家和其他弹丸 |

玩家死亡后禁止移动/攻击，场景停止并释放已有弹丸。重开整体释放旧场景，重建独立 HP、冷却和靶子状态。

## 后续系统边界（规划）

| 模块 | 持有内容 | 允许的交互 |
| --- | --- | --- |
| Main / 场景路由 | 当前地面或单局场景 | 创建、销毁场景，不处理攻击或背包细节 |
| RunController | 本局种子、层数、状态、临时收益 | 调度地宫，发出结算事件 |
| DungeonGenerator / Layout | 房间图与模板选择 | Phase 3 已实现纯结果，不创建玩家 |
| RoomController | 注入布局、房间状态、当前 Room、唯一玩家 | 调度房间切换，Phase 3 已消除固定拓扑依赖 |
| Room / EnemySpawner | 门、布局、本房间敌人与弹丸、存活数 | 局部生成与清场，发出过门请求；Phase 2 已实现 |
| Player / Enemy | 移动、攻击控制 | 组合 Health、攻击器等小组件 |
| Combat 组件 | 伤害包、生命、命中与弹丸 | 显式伤害接口和局部信号，不依赖 UI 或经济 |
| Relic 系统 | 本局效果与挂接生命周期 | 响应攻击/受击钩子；添加和移除均明确 |
| Inventory | 本局古董及容量 | 根据 ID 管理实例，通过信号刷新 UI |
| Market | 鉴定、交易、收藏操作 | 请求结算/档案服务，不能直接写磁盘 |
| Profile / SaveService | 永久货币、收藏、解锁、存档版本 | 提供显式读写入口；不持有活跃战斗节点 |
| UI / Audio | 展示和反馈 | 订阅局部信号，用户操作发出请求 |

优先用场景组合和显式依赖注入。节点引用由父节点/构造入口传入，不通过绝对场景路径查找。局部事件用类型化 signal；暂不创建万能事件总线。只有确实跨场景存活的服务才考虑 Autoload。

## 数据驱动

已使用自定义 Resource 和 `.tres` 存储玩家属性及房间定义；敌人数据已实现，后续用于遗物、古董和墓穴。每项内容具有稳定字符串 ID，展示名称独立于 ID。定义资源视为只读，运行时生命/冷却/房间状态/叠层/鉴定状态保存在实例或运行状态对象中。策略行为通过小脚本或枚举选择；不建立庞大条件分支。

资源之间可使用类型化 Resource 引用；存档仅保存稳定 ID 和可序列化值，不保存节点或 Resource 实例。建立内容校验时检查重复 ID、缺失引用和非法参数。

## 生命周期与确定性

房间所有权已在上文落实；后续 Run 才拥有结算等高层状态，不能把玩家交给 Room 重复创建。Phase 3 地图 RNG 与选择新 Seed 的 RNG 均独立；将来战斗随机源也必须独立，不能因射击/掉落改变同 Seed 地图。

## 工程约定

- 文件名 snake_case，类型名 PascalCase，脚本使用静态类型提示，信号命名描述已发生事件。
- 碰撞层、输入动作及伤害接口已在 Phase 1 定义，如上表；新增实体必须明确自己的层和掩码。
- 脚本按职责拆分，建议 300 行内，超过 500 行检查拆分；禁止超过 1000 行。
- 注释解释责任、生命周期、约束和原因，避免逐行翻译代码。
- 存档规划使用 `user://`、版本号、临时文件及备份，错误回退在 Phase 10 实现。
- 不提前建立对象池、ECS、网络同步或通用插件框架；出现实测瓶颈后再选择局部优化。

## Phase 4 敌人架构

EnemyDefinition 存通用参数，RangedEnemyDefinition 增加射程带和弹丸参数。Enemy 共享 Health、目标注入、受伤闪白、死亡缩小与轻量墙体切向绕行。ScarabEnemy 的 CHASE / WINDUP / RECOVERY 与 BanditShooter 的 MOVE / AIM / RECOVERY 分别负责攻击，不依赖 RoomState 或地图。

RoomDefinition.spawns 保存 EnemySpawnDefinition 数组，每项指定场景、数据与坐标。唯一 EnemySpawner 注入 Player 与本房 Projectiles，在加入场景树前设置 entry_grace_time；只订阅 Health.died 维护存活实例集合。生成完成及最后死亡都有一次性清场保护。旧 Dummy 通过同一入口运行，没有另建生成系统。

EnemyProjectile 继承 Projectile 的扫掠、寿命与消费流程，仅覆盖伤害对象和几何外观。枪手开火时快照方向；玩家死亡取消追踪弹丸并停用 AI。Room.stop_combat 停止生成器内 AI、释放局部弹丸；地图切换仍由原 Controller 卸载整个 Room。玩家唯一、HP 跨房保留、Seed 算法不变。

碰撞：World=1，Player=2，Targets/Enemies=4，PlayerProjectiles=8，EnemyProjectiles=16。新 Enemy mask=7，玩家弹丸 mask=5，敌人弹丸 mask=3；敌人弹丸不会与友军或玩家弹丸碰撞。Dummy 夹具 mask=2 保留。

入口公平性：默认 1 秒观察期内不推进 AI 状态机、不移动、不攻击；外观暂时变浅。每模板出生点距四入口至少 180 像素。观察期结束后攻击仍必须完整前摇；这不是玩家无敌或完整难度平衡系统。

墙体绕行仅短射线检测后沿法线切向移动，并短暂保持方向避免抖动；没有导航网格，复杂凹形障碍可能卡住。Phase 5 仅准备在既有攻击请求/受击接口周围设计可卸载的遗物效果，当前未添加效果管理器。