# 技术架构

## 当前实现

Godot 4.6.2 / GDScript / 2D / Compatibility。`project.godot` 启动 `scenes/main/dungeon_test.tscn`。DungeonSession 调用纯数据生成器，向 RoomController 注入 DungeonLayout，再复用现有玩家、战斗、Door、Room 和 RoomState。无Autoload或第三方插件；Phase6.5已增加两只正式Boss与通关结算，Phase7A已增加独立古董背包与安全房拾取，经济未实现。旧阶段记录保留，当前古董规则以Phase7A章节为准。

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

Session 的 R 回到相同run_seed第一层并重建整Run；N 使用独立随机来源最多选 16 个不同 Seed，比较空间签名找实际不同地图，失败保留原图并警告。新 Seed 不写存档。命令行 `-- --seed=192034` 可复现，HUD 始终显示实际 Seed。

### 模板与占位类型

RoomDefinition 的历史 `room_id` 是模板标识；`map_position` 只在 Phase 2 旧回归夹具读取，随机系统不读它。DungeonRoom 的类型、坐标和 ID 才是地图语义。Type 枚举在末尾增加 START，保留已有类型序号。

Controller 将模板、运行状态、已连接方向和实际节点类型注入 Room.configure。Room 原有普通战斗生命周期不重写；仅增加占位进入规则：START 忽略模板 spawns，经 ACTIVE → CLEARED 同次进入即开门；第一层BOSS使用正式Boss，第二层BOSS使用镇墓兽；ANTIQUE自动清场。没有古董奖励/背包；MERCHANT/TRAP/SECRET 尚无规则。

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

已使用自定义 Resource 和 `.tres` 存储玩家属性及房间定义；敌人数据已实现，遗物框架数据已在 Phase 5A 实现，后续用于古董和墓穴。每项内容具有稳定字符串 ID，展示名称独立于 ID。定义资源视为只读，运行时生命/冷却/房间状态/叠层/鉴定状态保存在实例或运行状态对象中。策略行为通过小脚本或枚举选择；不建立庞大条件分支。

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

入口公平性：真正生成敌人的战斗房默认 0.35 秒观察期内不推进 AI 状态机、不移动、不攻击；外观暂时变浅。每模板出生点距四入口至少 180 像素。观察期结束后攻击仍必须完整前摇；这不是玩家无敌或完整难度平衡系统。

墙体绕行仅短射线检测后沿法线切向移动，并短暂保持方向避免抖动；没有导航网格，复杂凹形障碍可能卡住。Phase 5 仅准备在既有攻击请求/受击接口周围设计可卸载的遗物效果，Phase 5A 已增加玩家局部 Runtime，见下文。
START 与其他房复用 room.tscn 和随机视觉/障碍模板，不复制场景、不修改共享 spawns；START 不调用 EnemySpawner，因此不应用观察期。COMBAT 的 180px 入口间距、0.35 秒观察期和攻击前摇保持；第一层BOSS为正式晋北大帅尸，第二层BOSS为镇墓兽，ANTIQUE自动清场。

## Phase 5A：单局遗物与战斗 Hook

| 模块 | 所有权与职责 |
| --- | --- |
| RelicDefinition / Resource | ID、中文名、描述、rarity、effect_script、只读 parameters |
| RelicEffect / RefCounted | 本次安装实例、幂等 install/uninstall、具体效果连接/计数和 modify_attack |
| RelicInventory / RefCounted | Runtime 拥有；唯一 ID、查询/添加/移除/clear；不处理地图、绘制或存档 |
| RelicRuntime / Node | Player 子节点；持有 Inventory，装配武器与 Health，并暴露局部 Hook |
| AttackContext / RefCounted | 一次攻击批次，持有请求副本，可展开成 0..N；不持有共享 PlayerStats |
| ProjectileHitContext / RefCounted | 成功伤害后的 target、位置、快照伤害，限同步使用 |
| RelicDebugPanel / CanvasLayer | 展示 Inventory，1/2/3 与 Backspace 操作适配，不包含效果逻辑 |

管线：Player → RangedWeapon（一次冷却）→ 基础 AttackRequest → Runtime.prepare_attack → AttackContext 复制 → Inventory 按阶段/优先级/稳定 ID 排序应用独立效果 → attack_prepared → 0..N attack_requested → Controller/CombatTest 在局部容器生成 Projectile → projectile_spawned。无遗物仍一个请求，数值/速度/方向/冷却与 Phase 4 一致。

| Hook | 来源与边界 |
| --- | --- |
| attack_prepared(context) | 效果处理后、生成前，可访问本次批次；不是共享属性 |
| projectile_spawned(projectile) | 玩家弹丸 setup 后由装配入口 bind_projectile 通知 |
| projectile_hit(context) | 玩家弹丸成功 take_damage 后通知；碰墙/失败伤害不算命中；不连接敌方弹丸 |
| enemy_killed(enemy) | 唯一 Spawner 首次从存活集合删除后通知，重复回调或卸载不通知 |
| player_damaged(amount) | 已接受的非致命 Health.damaged；死亡标记后不通知效果 |
| room_cleared(context) | Controller 创建 RoomClearContext，首次 CLEARED 通知，重访不重复；type/was_combat 明确区分自动清场 |

三个工程效果分别实现 damage ×1.5、每条请求展开 ±6° 双弹、kill Hook heal 5。无 ID 分支、无全局 EventBus。Health.heal 拒绝死亡/非法量并限制最大生命。定义与 PlayerStats 均不修改，卸载只移除实例/断开连接；旧弹丸的发射快照不追溯修改。

跨房：Runtime/Inventory 是 Player 所有，Room 卸载只删除该房敌人与弹丸，Build 保留，下一房重新接通局部来源。死亡：is_active 立即由 Health.is_dead 拒绝晚到事件，shutdown 清空库存；R/N 与整场景卸载调用 _exit_tree/shutdown，断开 Health 和效果连接及回指。新局创建新 Player/Runtime/Inventory，效果计数不共享。

Phase 5A 原先仅稳定 ID 排序；当前规则为 stage/priority/ID 排序，解决本阶段两个修改器获得顺序差异；不承诺未来任意效果都可交换。新增请求字段须更新 AttackRequest.copy。爆炸/穿透/反弹等后续采用独立弹丸策略或命中订阅，不在 Projectile 中加入遗物 ID 分支；Phase 5B 已实现本阶段所需爆炸/燃烧/一次穿透，尚无反弹。enemy_killed 是本房首次死亡事件，尚无击杀归因/伤害来源系统。
## Phase 5B：上下文、阶段、奖励与局部攻击

RoomController是RoomClearContext唯一装配入口：room_id、实际DungeonRoom.room_type、was_combat、原始生成enemy_count。START/ANTIQUE自动清场的enemy_count=0/was_combat=false；普通COMBAT=true；BOSS占位虽有敌人，本阶段was_combat=false，不计普通奖励。Context先转发Runtime局部Hook再通知RewardService，重访不会重复clear。

效果排序为AttackStage DAMAGE → COUNT → DIRECTION → PROJECTILE_PROPERTY → FINAL；每阶段按priority升序，同值按stable ID。五帝钱COUNT产生两条±5°请求；纸鸢DIRECTION追加充能侧弹；镇尸钉PROJECTILE_PROPERTY统一加穿透；铜镜FINAL priority0复制最终批次；洛阳铲FINAL priority10在镜像之后追加一枚短距重弹。运行次数不写回Definition。

AttackRequest新增pierce_count=0/projectile_scale=1/tags=[]，copy复制全部字段且tags独立。Projectile只读取通用参数：碰撞后已命中ID集合防重伤，穿透剩余>0时递减并对目标增加碰撞例外，墙立即消费；默认0仍首次碰撞消费。heavy是通用呈现标签而非遗物ID。EnemyProjectile的请求不经过玩家Runtime，仍默认普通红弹。

ProjectileHitContext新增origin。HitRelicEffect管理命中连接与弱引用局部对象；具体黑火药/墨斗调用CombatGeometry瞬时范围/线段伤害，再生成CombatPulse几何反馈；非Projectile伤害不发projectile_hit，所以无递归。范围/线段只扫描本房存活敌人，当前不额外遮挡检测。

Burn仅一个轻量Node2D，每目标/效果一实例；重复命中刷新3次计数及0.35秒间隔。不建立StatusEffect注册框架。组件随敌人/Room释放；效果remove/shutdown取消已拥有的Burn和反馈对象。Runtime.is_active与Health死亡门控阻止晚到DOT、充能或击杀反应。

DungeonSession拥有当前局RelicRewardService，创建World前注入Controller；R/N先卸载旧World/Service，再创建独立新实例。Service只处理COMBAT首次ID与第2/4/7进度；版本1，独立RNG seed XOR (version*7919)。正式池先按ID稳定排序、Fisher-Yates洗牌，序列无放回；不会读取全局RNG或改变DungeonGenerator。

Service发reward_available(definition, room_id)，Controller只在当前活房生成RelicPedestal。底座使用Room视觉之外的轻量Node2D，安全位置避开障碍；64px内E调用Inventory.add成功后标记claimed并释放。离房未领即销毁并丢失，不回补；死亡销毁未领取底座并stop Service。固定Phase2回归夹具不注入奖励服务，生产入口始终由Session注入。

三组协同没有专用combo脚本：数量批次自然进入FINAL镜像；穿透逐目标发独立hit，爆炸逐hit响应；双弹逐目标附加独立Burn。没有第三敌人、正式Boss、经济/古董/存档或复杂状态系统。
## Phase 5B 平衡修订（2026-10-06）

正式奖励改为第2/4/7个首次COMBAT清场，其他房型/重访/重复通知规则不变。短局只有5～6个COMBAT时只发2件，不动态补发；无放回序列及R同Seed复现不变。

尸蟞：HP65、速度165、伤害12、冷却0.9、前摇0.25。枪手：HP90、速度105、弹伤14、弹速340、冷却1.35、前摇0.4，距离逻辑与非追踪弹保持。

模板center/north/west/east/south分别为4尸蟞、6尸蟞、3枪手、4尸蟞+1枪手、3尸蟞+2枪手。新增点与其他点均验证四入口距离≥180、障碍边界安全及敌人间距≥40；观察期0.35秒保持。

EncounterDifficulty由Controller读取DungeonRoom.distance_from_start解析，再经Room/Spawner注入Enemy.configure_spawn。深度1～2：HP/伤害1.00；3～4：HP1.15/伤害1.15；≥5：HP1.30/伤害1.35。只缩放实例Health上限、咬击/枪弹伤害；不修改共享Definition，不缩放移速/弹速/前摇/冷却，不做BFS或完整难度系统。HUD显示深度和Tier。R重建新上下文，倍率不累计；CLEARED重访不刷强化敌人。

本次仅成长节奏与战斗压力修订；不增加敌人、Boss、词缀、遗物、经济或Phase6内容。实际试玩对底座+E体验已确认无问题，新平衡主观复验另见验证报告。
## Phase 5B 致死性修订

玩家默认80HP、有效受伤后0.25秒无敌；移动/攻击参数不改。尸蟞HP65不改，速度175、伤害14、冷却0.8、前摇0.25；枪手HP90/速度105不改，弹伤16、弹速380、冷却1.20、前摇0.4。无追踪/散射，咬击距离与LOS重判保持。

HP倍率仍1.00/1.15/1.30；伤害倍率改1.00/1.15/1.35。三Tier实际咬击14/16.1/18.9，弹伤16/18.4/21.6。80HP分别约6/5/5次咬击或5/5/4次枪弹死亡；均非一两下秒杀。倍率仍仅作用实例HP和伤害，不额外缩放时序/速度。

怪物数量、正式遗物、奖励2/4/7均不改。本次只提高失误代价，不以堆HP或数量延长战斗；若主观风险仍不足，后续应评估攻击模式而非继续堆HP。人工复验状态见验证报告，不进入Phase6。
## Phase 6：正式Boss与两层所有权

| 组件 | 职责 |
| --- | --- |
| BossDefinition | EnemyDefinition子资源；只读技能参数、召唤阈值、决策时序 |
| WarlordBoss | Enemy子类；复用Health/受伤/死亡/scaled_damage，确定性交替状态机；不查地图/奖励/库存 |
| BossEncounter | Room子节点；安全生成Boss/3尸蟞，Boss死亡停AI/清召唤物/defeated一次 |
| FloorExit | Room局部交互；64px内E一次信号，不生成地图 |
| BossHealthDisplay | HUD局部订阅HP/死亡；仅正式Boss房显示 |
| RunCarryState | HP与只读遗物定义快照；不持节点/Effect |
| DungeonSession | run_seed/floor_number/current_floor_seed；新Run与下一层分别装配 |

Room.enter：CLEARED开门（第一层Boss恢复墓道）；START/ANTIQUE直接清场；BOSS+正式Definition启动BossEncounter；其余调用原EnemySpawner。第一层Boss仍共用Room场景和模板视觉/障碍，忽略spawns。Boss死亡清余下召唤物和弹丸，CLEARED开门、产生单一FloorExit。第二层不注入正式BossDefinition，所以仍普通占位，无墓道。

CombatGeometry通过Room.damage_targets获取普通Spawner与BossEncounter的活目标，爆炸/墨线/燃烧继续自然作用Boss，不添加遗物ID分支。BossEncounter转发实际killed到Runtime；胜利自动清除召唤物不伪造击杀。

Session新Run卸载World/RewardService重建两者。下一层只卸载旧World，使用RunCarryState恢复新Player，复用原RewardService（序列、_seen、进度均保留）。第二层Context.room_id为F2:<local_id>，防止两个Layout复用ROOM_001时漏算清场。Room/Controller不负责层Seed算法。

层Seed：floor1=run_seed；floor2=(run_seed XOR (2*104729))+attempt*7919。独立Generator，固定候选顺序，最多16次空间签名比较。若全部失败拒绝切换，保留旧局。R从任意层回同Run第一层，N新Run；两者都80HP空Build零奖励。

HP恢复使用Health.restore，clamp0..max并更新is_dead，只通知changed；不制造受伤/死亡Hook。跨层Effect重新安装，旧Runtime离树完整uninstall；不带走DOT、计数、纸鸢充能、武器冷却。难度解析在Controller用local_distance+(floor-1)*3，仍注入实例，共享Definition不改。

## Phase 6.5：Boss场景泛化与Run结局

BossDefinition增加boss_scene；TombBeastDefinition仅增加镇墓兽参数。BossEncounter按场景实例化Enemy、配置Spawn、统一Health/killed/targets/defeated；只有声明summon_requested的Boss才连接通用召唤请求，不读取Boss ID。HUD签名也改为Enemy。大帅尸AI文件未修改；其tres新增场景引用，scene移除反向tres引用防循环。

TombGuardianBeast独立状态机，复用Enemy，不复制大帅尸AI。TombSpike只持OwnerBoss/Player与预警/一次爆发/视觉生命周期，归Room.Projectiles，Boss弱引用跟踪所有地刺/弹丸/落地反馈；stop_ai禁用并释放，Room退出也自然释放。扑击和地刺伤害用World LOS阻止隔墙；弹幕直接AttackRequest→EnemyProjectile，不经过Player Runtime。

Session.boss_for_floor(1/2)解析Boss，注入Controller；Controller再注入Room。Room.final_floor区分FloorExit与RunExit，首次Boss死亡明确boss_defeated信号→Controller→Session按floor去重计数；重访已清Boss只恢复对应出口，不重复计数。

RunExit 64px内E→run_complete_requested→Session.request_run_complete验证第二层CLEARED且两Boss已击败。置run_completed/world.run_finished，停止Player/战斗/奖励，再构建RunResult只读快照，RunCompleteScreen只展示快照。Controller同时阻断过门与_spawn_projectile，防手动发射请求绕过Player控制冻结。R/N沿既有新Run路径释放旧界面、重置完成标记/HP/Build/Service/Boss计数。未加计时器、Campaign、存档或经济。

## Phase 7A：古董与单Run背包

AntiqueDefinition只读id/name/description/base_value/slots/rarity；AntiqueInventory是Player独立RefCounted，8格、定义数组、changed局部信号，完全不接RelicRuntime或Health/Weapon。Pool从(version,run_seed,floor_number,room_id)文本以乘131模2147483647稳定混合，独立RNG对稳定ID排序的池均匀选择。两层暂同概率，无额外权重或经济系统。

Controller接收Session.run_seed，调用Pool选择并注入Room.antique_definition；Room的安全ANTIQUE进入/重访只装配AntiquePedestal，不生成敌人，不改变邻接或地图RNG。Pickup64px内E→Player.antiques.add成功→RoomState.antique_claimed=true→释放节点。满包不消耗底座；已领标记随Controller本层状态存活，不写Resource。未领重访重建相同底座，已丢弃不回补。

Controller创建AntiqueInventoryPanel，注入Inventory与can_manage回调；Panel只是Tab/选择/Delete UI，不查Session，不暂停战斗。HUD底部局部订阅changed更新槽位/估值；死亡和完成隐藏Panel。库存只持定义，无Pickup/UI引用。

RunCarryState增加antique_definitions，旧World/Panel释放、新Player加入新库存并更新新HUD；不搬节点。Session通关构建RunResult.antique_names/antique_value数值快照，结算独立ScrollContainer与固定R/N提示，不持Inventory或Resource。R/N仍整Run重建，HP/遗物与奖励规则不改。没有死亡掉落、钱包、永久货币或磁盘写入。
