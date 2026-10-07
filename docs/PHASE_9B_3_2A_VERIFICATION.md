# Phase 9B.3.2a：潜地清房软锁

基线298bf6a，保留已提交Geometry/Arena、可达性与出土占位保护。历史复现中两只潜地尸共享落点，实体恢复后互相挤压，被物理推出房间；账本仍然正确保留两只活怪。既有占位保护处理直接根因，本次补齐地下生命周期及异常恢复，禁止自动杀怪或自动扣清房计数。

`EnemySpawner.debug_living_snapshot()`仅DEBUG/test观察实例、定义、HP、位置、房内状态、行动资格、碰撞与AI状态。地下总时间最多2.4秒；失败、预警丢失、落点变化、房间状态变化、死亡及停止统一取消攻击并恢复SURFACE。落点变化不能无预警换位置出土。非法历史位置重新查当前Geometry，正常恢复保持同侧物理射线限制。完全无合法空间的人工破坏夹具显式报告recovery_failed；生产初始布局拒绝这种空间。

`tests/phase_softlock_smoke.gd`专项1030项，0失败：真实variety_17/29各100轮双潜地、中央棺、四角移动、2→1→0→all_defeated一次→CLEARED→真实门全部OPEN；容量11/12、marker提前释放、超时、落点后来非法、Room状态变化、死亡、卸载及完全无合法点恢复。非潜地敌人通过真实Health死亡退出账本，潜地尸通过真实take_damage死亡；没有直接修改账本。正常开放空间与不穿墙由既有9B.3 AI专项保留。

命令（Godot 4.6.2）：`godot --headless --fixed-fps 60 --path . --script tests/phase_softlock_smoke.gd`。全Phase1～9B.3.3及Geometry回归另见本次执行记录。日志位于ignored logs，不包含用户存档。

人工软锁复验等待最终窗口试玩；自动压力测试不能证明任何未来动态Geometry都存在合法恢复位置。
本次全回归21套：284472项、0失败；加Softlock专项1030项，共285502项、0失败。导入与隔离Profile正式入口启动正常，无SCRIPT ERROR/ERROR。8B/8C/8D/9A故意损坏Profile夹具产生预期WARNING。
