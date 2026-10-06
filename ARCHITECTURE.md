# 技术架构

## 当前实现

Godot 4.6.2 / GDScript / 2D / Compatibility。`project.godot` 启动 `scenes/main/room_test.tscn`，由 RoomController 装配固定十字形地图与唯一玩家。没有 Autoload、第三方插件、随机地图或敌人 AI。Phase 0/1 的独立入口保留供历史与回归检查。

### Phase 2 组件与状态

- `RoomDefinition` Resource：稳定 ID、房间名称、类型、地图坐标、地面颜色、敌人场景、生成点与障碍矩形。五份 `.tres` 共用 `room.tscn`，不复制房间逻辑。
- `RoomState` RefCounted：每局每房间独立的 UNVISITED → ACTIVE → CLEARED 状态，重复激活/清场无效；已清场状态不可倒退。
- `Room`：按定义创建墙、障碍和已连接方向的 Door；首次进入先锁门再生成；接收 all_defeated 后清场并开门。清场重访只重建布局与打开门。
- `EnemySpawner`：生成一次，按 Health.died 和实例 ID 管理存活集合；只把死亡作为击杀，卸载节点不算清场。使用已有 Dummy 作为测试敌人，没有 AI。
- `Door`：World 层阻挡与只检测玩家的 Area2D；持续观察区域，玩家跨过门槛才发出方向请求。即使清场时已经站在门边，继续移动也能过门；单纯开门不会自动传送。
- `RoomController`：持有固定邻接表、五个状态、唯一玩家及当前 Room；验证清场/相邻/死亡/切换条件，冻结输入后延迟替换房间。
- `RoomTestHUD` / `RoomMinimap`：只展示房间、存活数、清场进度与状态，不改战斗状态；按钮发出操作请求。

门的方向为 Door.Direction.NORTH/EAST/SOUTH/WEST，回房入口取相反方向。没有相邻房间的一侧是整面墙。门的形状禁用采用 set_deferred，避免在物理查询/死亡回调中修改形状。

### Phase 2 所有权与切换

RoomController
→ RoomHost / 当前 Room（Doors、EnemySpawner / 敌人、Projectiles / 弹丸、墙）
→ Player（Health、Weapon）
→ HUD

玩家始终挂在 RoomController 下，不随 Room 卸载，也不在切换时重新实例化。生命、初始属性、无敌期和武器冷却保留；位置更新到目标房间入口内侧 64 像素，速度归零，防止立刻触发回门。`Player.set_controls_enabled()` 用于短暂冻结及死亡停用。

切换前原 Room 停止处理并离开场景树，再 queue_free；敌人与弹丸一起释放。当前场景树只保留一个 Room。RoomState 由控制器保留，所以重访 CLEARED 不重新生成敌人。死亡阻止过门和射击并回收当前弹丸；R 重载整张地图，全部运行状态重建。

### 房间类型扩展（规划）

RoomDefinition.Type 预留 COMBAT、ANTIQUE、MERCHANT、TRAP、SECRET、BOSS；只有 COMBAT 有实现。其他类型需要对应进入/完成策略和内容，不能仅改枚举就使用。局部生命周期位于 Room，地图相邻关系位于 RoomController，后续可分别扩展而无需在每个房间复制脚本。

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
| DungeonGenerator | 房间图与模板选择 | 输入种子和配置，输出纯拓扑数据，不创建玩家 |
| RoomController | 地图连接、房间状态、当前 Room、唯一玩家 | 调度房间切换；Phase 2 已有固定地图实现 |
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

已使用自定义 Resource 和 `.tres` 存储玩家属性及房间定义；后续用于敌人、遗物、古董和墓穴。每项内容具有稳定字符串 ID，展示名称独立于 ID。定义资源视为只读，运行时生命/冷却/房间状态/叠层/鉴定状态保存在实例或运行状态对象中。策略行为通过小脚本或枚举选择；不建立庞大条件分支。

资源之间可使用类型化 Resource 引用；存档仅保存稳定 ID 和可序列化值，不保存节点或 Resource 实例。建立内容校验时检查重复 ID、缺失引用和非法参数。

## 生命周期与确定性

Phase 2 的所有权已在上文落实。后续 Run 拥有本局高层状态，RoomController 管理地图局部切换；禁止把玩家同时交给 Room 与 Run 重复创建。结算通过显式状态转换防止重复发放收益。Phase 3 才引入独立 RandomNumberGenerator；地图和战斗随机源分离，方便复现问题。

## 工程约定

- 文件名 snake_case，类型名 PascalCase，脚本使用静态类型提示，信号命名描述已发生事件。
- 碰撞层、输入动作及伤害接口已在 Phase 1 定义，如上表；新增实体必须明确自己的层和掩码。
- 脚本按职责拆分，建议 300 行内，超过 500 行检查拆分；禁止超过 1000 行。
- 注释解释责任、生命周期、约束和原因，避免逐行翻译代码。
- 存档规划使用 `user://`、版本号、临时文件及备份，错误回退在 Phase 10 实现。
- 不提前建立对象池、ECS、网络同步或通用插件框架；出现实测瓶颈后再选择局部优化。
