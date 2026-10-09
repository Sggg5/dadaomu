# Phase 11I 整合验收（进行中）

基线 d9c840e；独立分支 codex/phase-11i-integration-qa。正式玩家存档未读写，main不合并。

## 11I.1 正式新档首趟闭环

`tests/phase_11i1_smoke.gd`：正式 game_flow.tscn、隔离内存新档，Campaign=52；Day1晋北自然派生 Expedition Seed=522269330。零馆藏、零现金开始，真实WASD、鼠标地图确认、真实Door/武器、E拾取、第一Boss后F撤离、E回Day2、免费鉴定、鼠标布展、售票台E与正式60秒营业。无资金、馆藏、生命、研究注入，无玩家瞬移。

初次正式运行通过30项：唯一带回馆藏、首日营业7名观众、35元收入。驾驶器知道拓扑并自动瞄准，不代表普通玩家理解地图或战斗难度已验收。中期资金建设、招聘、研究、专题与第二评级仍需后续验证。

日志保存在忽略的 logs/11i1.log；隔离 earned checkpoint 路径由日志打印。历史回归、图形审计、经济分析尚未完成，不宣称Phase完成。
