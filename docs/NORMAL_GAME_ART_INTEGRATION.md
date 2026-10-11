# 高品质样板接入正常游戏

用户追加授权：最高品质美术直接出现在正常游戏，不再要求进入专用试玩窗口。基线defda4f19be930f8d2b7cd3161946cc7b209e16a，继续codex/phase-12a-hd2d-art，不合并main。

## 实际接入

- 晋北所有正常房间使用a5墓砖墙顶/立面、门框、门槛和门洞，以及现有静态接触阴影。真实Door坐标与开关规则不变。
- 从原障碍中选最大且比例适合的棺床使用专属主棺，祭台使用供案素材。采用等比缩小、脚底贴原碰撞底边，立面北向投影最多24px；底座准确覆盖原footprint。不为美术增加障碍，不重排正式地图，也不强制每房生成实验A的碰撞构图。
- 正常尸犬与尸蟞自动使用a6四方向64帧身体及独立高层前摇警示。新出生的召唤物通过node_added延迟接入，按节点名去重；死亡和切房清理兄弟视觉。
- 旧身体使用self_modulate隐藏，单独隐藏旧EnemyVisual，避免遮掉Burn子节点。燃烧提示使用925层，低于攻击前摇950层；Legacy恢复原深度。原精英标识保留，不更改燃烧伤害或精英数值。
- 真实武器、弹丸与Health信号驱动原a6有限枪口/命中反馈，不更改伤害或武器行为。
- F6 Legacy / Basic / Enhanced保留；新资产缺失时保留原绘制。洛阳/关中保留地区建筑配色与布局，新敌人视觉可以正常使用。
- 正式代码不依赖tests；LAB_历史对比房继续使用原显式绑定，避免双重安装。

新增scripts/art/tomb_quality_visual.gd、tomb_quality_architecture.gd、tomb_quality_prop.gd、detailed_enemy_visual.gd、combat_feedback_visual.gd；RoomVisual仅增加视觉装配。原Enemy、Room、RoomController、GeometryPlan、数据资源、正式池、地图Seed、战斗数值、经营与Profile10均未修改。

## 验证

Godot共341147次最终有效检查、0失败；Python完整129项、0失败。重复调试运行和失败夹具不计入总数。最终导入与正常GameFlow增强模式启动正常。

| 检查组 | 项数 | 失败 |
| --- | ---: | ---: |
| 历史玩法/经营/30日/存档/图形 | 340404 | 0 |
| Phase12三模式与事件图形 | 152 | 0 |
| 接入headless | 78 | 0 |
| 接入graphical | 78 | 0 |
| 原A6四方向/生命周期 | 199 | 0 |
| 原5B遗物/燃烧复验 | 236 | 0 |

完整机器回执见screenshots/normal_art_integration/validation.json。自动测试不能替代人工美术与手感验收。

新增normal_art_integration_smoke由正式game_flow.tscn、情报地图点击、真实Door、原玩家武器完成清房、死亡节点清理、过门及CLEARED重访；没有LAB注入。全部13个正式普通Geometry的连通性及原障碍上的等比拟合边界另有检查。

第一次专项对“走到门中心”使用普通walk断言，自动过门提前切换Room使walk返回false，但实际上已进入START。修正为专门验证真实过门的driver.visit，仍验证目标房与重访，未删除断言。首轮失败日志保留logs/normal_art_initial_transition_assertion.log。

旧12A.5/12A.6的全脚本冻结断言允许用户本次授权的唯一旧文件scripts/art/room_visual.gd变化，使用normal_art_authorized_hashes.json精确新哈希校验；所有其他脚本、数据、场景、碰撞/Seed断言保持原样。

增加实际Burn绘制节点的视觉夹具验证，但禁用其DOT，仅检查透明度、深度和Legacy恢复，不冒充真实遗物获取或伤害流程。首轮在入树前禁用物理更新被Godot入树自动设置覆盖，节点自行取消后产生失效访问；修正为入树后明确停用夹具DOT，保留失败日志normal_art_burn_fixture_initial_failure.log，完整重跑。另重跑原Phase5B实际燃烧及遗物协同回归。

## 实机证据与使用

- [Basic正常首战房（含燃烧视觉夹具）](screenshots/normal_art_integration/mode_1.png)
- [Enhanced正常首战房（含燃烧视觉夹具）](screenshots/normal_art_integration/mode_2.png)
- [真实战斗及开门GIF](screenshots/normal_art_integration/normal_combat.gif)
- [无状态夹具的实际正常战斗](screenshots/normal_art_integration/normal_first_combat.png)
- [清房画面](screenshots/normal_art_integration/cleared.png)

固定验证Seed522269330，原生1280×720。GIF来自正常GameFlow原生画面，100ms采样，无缩放；provenance.json记录来源。自动验证使用内存档，日常试玩启动正常GameFlow与正常存档，不添加初始测试资产。

所有素材仍为DRAFT，尚有其它敌人/Boss和地区专属图缺口；接入正常游戏不代表全游戏美术完成或自动批准。主棺因真实Geometry大小等比适配，不承诺所有正常房都长成实验A。未新增素材、未新增玩法阶段。
