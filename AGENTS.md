# 项目协作规则

## 范围与阶段

本项目是 Godot 4.x / GDScript / Windows 的原创 2D 俯视角 Roguelite《大盗墓时代》。阅读 README、PROJECT_PLAN、ARCHITECTURE、GAME_DESIGN 后再修改。用户指令优先；每次只执行明确授权的 Phase。当前授权 Phase 2，完成后必须停止，不自动实施 Phase 3 或敌人 AI。

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
```

启动冒烟不能代替实际交互检查。涉及随机生成、效果卸载、重复结算和存档的修改应有针对性验证；简单占位 UI 不写镜像式测试。失败先修复当前阶段，不跨阶段规避问题。

## Phase 2 房间约定

- 五房复用同一个 Room 场景，差异放在 RoomDefinition 数据中。
- RoomController 持有唯一玩家和 RoomState；Room 持有局部敌人、弹丸、门与墙。
- 状态只能 UNVISITED → ACTIVE → CLEARED；重访 CLEARED 不刷怪。
- 切换必须验证相邻关系和清场状态，冻结输入并延迟卸载；禁止在 Area/物理信号中立即删除碰撞体。
- 生成器通过 Health.died 计数；卸载房间不能被当成击杀或清场。
- 非战斗房枚举仅预留，当前没有对应实现；不要把枚举声明报告为功能完成。
