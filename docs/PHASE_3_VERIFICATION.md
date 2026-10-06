# Phase 3 验证记录

日期：2026-10-06（Asia/Shanghai）。引擎 Godot 4.6.2.stable.official.71f334935 标准版；Windows / Compatibility / OpenGL 3.3 / RTX 2070 SUPER。工作分支 `codex/phase-3-random-dungeon`，基于 main `005ccfd`。未合并 main。

## 实际实现

独立 DungeonGenerator、DungeonLayout、DungeonRoom、DungeonConfig；开发入口 DungeonSession。RoomController 改为只消费注入布局，删除固定 CONNECTIONS 和五房启动假设。已有 Player、Health、弹丸、武器、EnemySpawner、Door、RoomState 不重写；Room 只新增实际类型参数及特殊房占位进入规则。

每张图 8～12 房，一坐标一节点，只有四方向双向连接，全图连通且无环。START 在 (0,0)，恰好一个 BOSS 和一个 ANTIQUE。共享五份原有普通房模板，不为随机节点创建 `.tres`。小地图根据真实坐标缩放/居中，并显示 S/B/A、访问状态和当前高亮。

START/BOSS 使用普通 Dummy 战斗；ANTIQUE 自动清场，无奖励或物品。古董内容属于 Phase 6，Boss 战斗属于 Phase 7。没有敌人 AI、遗物、背包、黑市、存档、正式美术/剧情或后续 Phase 内容。

## 算法与 Seed

本地独立 RNG 设置 Seed，选择目标数量和两个正交方向，构造随机单调主路径至少 5 步；再从空且只邻接一个已占用格的候选边中随机扩展，直到目标数量。单调主路径保证最低深度，额外扩展保持树结构；只有有限 for 循环，无生成重试或无限循环。

最远叶子作为 Boss，保证最短距离至少 5 且只有一个入口。其他距离至少 2 的节点中随机选古董房。候选与模板分配按显式字符串 ID 顺序，布局数据与模板、RoomState 分离。

相同 Seed、配置、模板顺序、生成版本 1 和 Godot 4.6.2 重现全部结果。默认 Seed `192034` 生成 11 房。R 重开当前 Seed，N 从独立 Seed RNG 最多尝试 16 次，按坐标/类型/连接比较空间签名，选取不同图；罕见失败保留原图并警告。Seed 不保存到磁盘。

```powershell
godot --path . -- --seed=192034
```

启动参数可替代 Inspector 的 seed_value；选到新 Seed 后 R 复现新图。测试将 N 的独立来源固定为 `20261006`，确定性地选到 `3580758926`（10 房），再验证 R 重复这个新 Seed。

## 执行命令与真实结果

`godot` 为命令示例；实际使用 `C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`。

| 参数 | 实际结果 |
| --- | --- |
| `--headless --path . --editor --quit` | 退出码 0，无解析错误 |
| `--headless --path . --script res://tests/phase_1_smoke.gd` | 27 次断言，0 失败，退出码 0 |
| `--headless --path . --script res://tests/phase_2_smoke.gd` | 原 204 次断言保留，0 失败，退出码 0 |
| `--headless --path . --script res://tests/phase_3_smoke.gd` | 最终 101 次汇总/场景断言，0 失败，退出码 0 |
| `--path . --script res://tests/phase_3_smoke.gd -- --capture` | 同样 101 次断言，0 失败，退出码 0；截图检查通过 |
| `--headless --path . --quit-after 120` | 默认项目启动成功，退出码 0 |
| `--path . --quit-after 120 -- --seed=192034` | 图形入口启动成功，退出码 0 |

101 是汇总与场景断言数，100 Seed 内部各自检查 14 条图规则，不是只抽查一张图。

### 用户要求的逐项验收

| 项目 | 真实结果 |
| --- | --- |
| 1. 连续 100 个 Seed | 完成 0～99，每个生成两次 |
| 2. 房数 8～12 | 100/100，通过 |
| 3. 坐标唯一 | 100/100，坐标索引与节点相符 |
| 4. START 可达全图 | 独立 BFS，100/100 |
| 5. 恰好一个 START | 100/100，ID START、类型 START、坐标 (0,0) |
| 6. 恰好一个 BOSS | 100/100 |
| 7. 恰好一个 ANTIQUE | 100/100 |
| 8. Boss 距离至少 5 | 独立 BFS，100/100；同时为最远叶子、单入口 |
| 9. 古董房距离至少 2 | 100/100，排除 START/BOSS |
| 10. 双向一致 | 100/100；同时检查正交方向与坐标偏移 |
| 11. 相同 Seed 完全一致 | 100/100，包含节点 ID、坐标、类型、距离、连接与模板 |
| 12. 不同 Seed 不同图 | 100 个不同空间签名，忽略 ID/模板差异后仍不同 |
| 13. 实际清场/开门/过门 | 两间房用真实武器和弹丸击杀；WASD 经过真实 Door Area 到邻居 |
| 14. CLEARED 重访 | 返回 START，不生成敌人，保留清场与开门状态 |
| 15. 唯一玩家 | 每次实际过门递归统计场景树仅一个 Player，实例 ID 保持，75 HP 保留 |
| 16. 弹丸无残留 | 每次切换带入长寿弹丸；旧 Room/弹丸均释放，新房没有残留 |
| 17. R 同 Seed | 真实 R 输入，原控制器释放，完整布局签名一致，HP/状态重置 |
| 18. 新 Seed 重开 | 真实 N 输入，Seed 和空间签名改变，唯一玩家；随后 R 复现新 Seed |

额外通过：无环且边数 n-1；缓存距离与 BFS 一致；模板引用合法且特殊类型不改共享模板；全局 RNG 状态不变；8/12 房极限深度配置、负 64 位 Seed；无效配置在生成前被识别；ANTIQUE 实际进入自动清场；BOSS 实际进入普通战斗占位；死亡阻止切换。

远端特殊房路径上的普通敌人由测试通过 Health 接口加速清场；核心 START → COMBAT 两房使用真实弹丸。测试会将发射起点放到靶子附近，人工长时间瞄准/手感不在此次自动验收范围内。

### 跨进程复现与视觉

无窗口与 Windows 图形两个独立进程，对全部 100 Seed 的完整结果生成 SHA-256 摘要，结果完全一致：

```text
7152b02c8ff732437333e93776f43427acb61bf83e310511424c39fbd1a04c0e
```

摘要保存在忽略的 `logs/phase_3_digest_headless.txt` 和 `logs/phase_3_digest_Windows.txt`。早期同进程检查未暴露跨进程差异；发现 StringName 默认排序依赖后，改为显式字符串比较，重新完成两进程全部检查，最终摘要如上。

已查看 `logs/phase_3_start.png`、`combat.png`、`antique.png`、`boss.png`、`death.png`、`new_seed.png`（后五个同样有 phase_3_ 前缀）：中文 HUD、Seed、门、布局、S/B/A、当前标记与不同图的动态缩放正常。未做跨硬件或人工长时间试玩。

## 文件清单

新增：

- `scripts/dungeon/dungeon_generator.gd`、`dungeon_layout.gd`、`dungeon_room.gd`、`dungeon_config.gd`、`dungeon_session.gd`。
- `data/tombs/default_dungeon_config.tres`、`scenes/main/dungeon_test.tscn`。
- `tests/phase_3_smoke.gd`、`phase_3_layout_checks.gd`、`tests/fixtures/fixed_room_test.gd/.tscn`。
- 本记录及 Godot 生成的脚本 `.uid`。

修改：

- `scripts/rooms/room_controller.gd`：删除固定拓扑，消费 Layout、注入节点类型、将重开请求交给入口。
- `scripts/rooms/room.gd`：类型参数和占位策略；原生成/门/清场逻辑保留。
- `scripts/rooms/room_definition.gd`：末尾增加 START，注明模板与节点语义。
- `scripts/ui/room_minimap.gd`、`room_test_hud.gd`、`scenes/ui/room_test_hud.tscn`：动态地图、Seed、R/N 展示。
- `scenes/main/room_test.tscn`、`project.godot`：通用控制器装配与新的项目入口/N 输入。
- `tests/phase_2_smoke.gd`：只调整固定图夹具和 Layout 数据读取，未删除断言。
- `AGENTS.md`、`README.md`、`ARCHITECTURE.md`、`PROJECT_PLAN.md`。

Player、Health、武器、弹丸、Door、EnemySpawner、RoomState、五份原模板、Phase 1 测试均未修改。

## 限制与 Phase 4 准备

- 地宫是树，没有环、秘密入口、多层或真正特殊房机制；主路径有单调方向偏好。
- 只使用五种现有模板，尺寸、入口偏移和门宽仍固定；没有正式素材、动画或音效。
- 复现契约限定当前引擎/生成版本/配置/模板顺序，未保证跨版本兼容。
- 新 Seed 选择最多 16 次；失败保留当前图。Seed 和状态不写存档。
- 未发现未解决的解析/运行错误；跨硬件、长时间游玩和手感需后续测试。
- Phase 4 只准备追击和远程敌人、预警与实际受伤验证，复用 Health / EnemySpawner / 清场信号；没有开始实现。

验收后提交指定开发分支，不合并 main。当前任务仅要求提交，未自动推送；提交 SHA 在最终交付报告中提供。Phase 3 完成后停止。
