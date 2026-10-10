# Phase12A.6 — 晋北A主棺墓室敌人与战斗视觉统一

## 范围与身份审计

基线c4b0625c0db6461fc026063d69833a35d1dc921d，当前美术分支。先提交a7c6dbb敌人审计，再实施美术。固定Seed522269330；正式GameFlow内存新档，真实情报地图确认晋北、真实Door进入首战COMBAT，然后沿用12A.4实验注入A几何。没有接入正式Geometry池，没有更改正式scripts/scenes/data/project.godot、12A.5建筑实现或四个真实障碍。

首战Encounter为encounter_03：2尸犬corpse_dog（40HP、14px身体碰撞）、3尸蟞scarab（65HP、14px身体碰撞）。旧尸犬无专属EnemyVisual，回退至36×20粉褐矩形；尸蟞使用actors第4行六帧且无四方向。生命细条、半径23前摇环、尸犬身体方向短线、环境危险提示和隔离碰撞调试不是同一绘制来源，均未因颜色相近而删除。完整审计见PHASE_12A6_ENEMY_AUDIT.md和phase12a6_enemy_audit.json。

## 两类专属DRAFT素材

使用内置imagegen原创生成，不引用现实馆藏媒体。源PNG与完整提示词保存在assets/art/sources，透明度原样留存。源图实际生成了尸犬12×8、尸蟞11×8（并非提示词要求的8×8）；按明确人工可查看的源格映射提取各方向16个独立姿态。确定性处理仅去除格间孤立残片、统一种类等比NEAREST缩小、固定脚底56px，没有旋转一张图充当方向，也没有非等比拉伸。

| 文件 | 原生尺寸 | 用途 |
| --- | --- | --- |
| a6_corpse_dog.png | 512×512，64格，每格64×64 | SOUTH/WEST/EAST/NORTH，尸犬身体最长约44px |
| a6_scarab.png | 512×512，64格，每格64×64 | 四方向尸蟞，最长约36px |

每方向：待机2、行走4、前摇2、攻击2、受击2、倒地4。脚底对齐实际世界位置+12；左上浅暖边光、低饱和骨色/棕灰尸犬、铜橄榄虫甲与场景冷灰石地协调。全部DRAFT/AI_GENERATED_ORIGINAL_PENDING_REVIEW，自动测试不是人工美术审批。源图骨骼/虫足细节、方向姿态和低分辨率自然度仍需逐帧人工检查。

## 视觉状态与战斗反馈

tests/support/phase12a6_enemy_visual.gd是Room的纯视觉兄弟节点，读取真实Enemy，不改变其状态机。完整像素身体替代旧Canvas绘制；只有图集有效且Basic/Enhanced开启时才将旧绘制变透明，Enemy本身仍可见、碰撞与AI仍运行。Legacy或缺图即时恢复旧身体、原血条和原预警，不以删敌人解决问题。

- 身体朝向以实际移动优先，静止时读取aim_direction；尸犬DASH读取已锁定dash_direction。
- 尸犬WINDUP→DASH自然驱动前摇/扑击；尸蟞真实RECOVERY驱动咬击收势，不伪造新的攻击判定。
- 有效HP减少读取Health.changed触发原时长内的受击姿态；既有白/红反馈语义保留。
- 倒地四帧按原death_duration读取，绝不延长死亡节点、伤害或清房时序；尸犬/虫实际释放后兄弟视觉与预警同步清理。
- 血条缩为28×2有效填充，仅受伤或正在前摇时显示，比例仍来自真实Health。前摇23px环位于z950，环境预警原高层保留。
- 武器请求和真实弹丸/Health信号驱动短枪口亮点、浅金弹丸拖线、小量命中/倒地碎屑；单缓冲最多48项，无新粒子系统/实时光源。带heavy/soul等标签弹丸保留原专属绘制，不抹掉遗物语义。
- 原主角红闪、身体/武器分层、脚影不改；人物/敌人按脚底Y排序，主棺原接触阴影与遮挡层保持。没有更改攻击发射坐标。

## 真实操作与受控测试区分

1. 原生1280×720同A房Basic/Enhanced/Legacy、真实WASD到四入口、北墙、棺前后及墓门，均经原驾驶器移动，无瞬移。
2. 普通完整战斗由原80HP、原武器清五敌，观察实际敌人位移、真实弹丸/预警、死亡、开门、E拾取、过门到START和再访CLEARED；没有collection.add或直接清空敌人生命代替战斗。
3. 普通自动驾驶会风筝尸蟞，单次录制未必出现咬击。独立attack_probe真实WASD靠近(480,260)，真实尸蟞AI进入前摇/咬击恢复；两个种类都实际经历待机、移动、前摇、攻击、受击、死亡。原80HP玩家结束40HP，无无敌/生命注入。记录原死亡动画尾部和真实开门，完整11项通过。
4. visual_smoke另有明确的受控姿态单元测试：暂存并恢复冻结夹具的状态/方向，验证四方向、六状态、倒地四帧、Legacy/缺图。它不冒充实际战斗，之后重新清空观察记录，再执行真实武器清场。

## 实机证据

- [新旧同房完整对比](screenshots/phase_12a6/before_after.gif)
- [Basic / Enhanced](screenshots/phase_12a6/basic_enhanced.gif)
- [普通完整实战](screenshots/phase_12a6/new_full_combat.gif)
- [真实近身前摇、受击与清房](screenshots/phase_12a6/probe_full_combat.gif)
- [尸犬真实AI局部](screenshots/phase_12a6/corpse_dog_actual_ai.gif) / [尸蟞真实AI局部](screenshots/phase_12a6/scarab_actual_ai.gif)
- [尸犬全部64帧](screenshots/phase_12a6/corpse_dog_all_64_frames.png) / [尸蟞全部64帧](screenshots/phase_12a6/scarab_all_64_frames.png)
- [尸犬旧/新原像素](screenshots/phase_12a6/corpse_dog_before_after_native.png) / [尸蟞旧/新原像素](screenshots/phase_12a6/scarab_before_after_native.png)
- [真实绕棺移动](screenshots/phase_12a6/real_walk_around_coffin.gif)
- [敌人/弹丸/警示同时出现](screenshots/phase_12a6/probe_dense_warning.png)
- new_walk_640_180.png北墙、new_walk_530_344.png/new_walk_750_344.png棺侧、new_walk_640_445.png棺前、new_walk_640_245.png棺后、new_door_near.png门口。

PNG是Godot原生viewport输出；全房GIF不缩小视口，100ms真实物理采样，绕棺200ms。局部GIF仅对同次真实战斗进行96×96原像素裁切跟随，不重新绘制身体。64帧图是实际接入资产图集，不冒充实机截图。gif_provenance.json保存帧数、时长及同帧真实敌人数/弹丸数/警示数量。

## 回归与性能

Godot最终有效检查共343,600项、0失败；Python完整129项、0失败。导入与隔离正式GameFlow启动通过。重复开发运行、早期失败与被替代的性能采样不计入该总数。明细见validation_results.json。

| 检查组 | 项数 | 失败 |
| --- | ---: | ---: |
| 历史完整经营/玩法 | 340,404 | 0 |
| Phase12 | 152 | 0 |
| 12A.1至12A.5基础专项 | 1,059 | 0 |
| 12A.1至12A.5补充图形专项 | 1,421 | 0 |
| 12A.6最终headless | 199 | 0 |
| 12A.6最终graphical | 199 | 0 |
| 旧敌人对照 | 42 | 0 |
| 真实近身AI及死亡尾部 | 11 | 0 |
| 旧版串行性能/流程 | 42 | 0 |
| 新版串行性能/流程 | 63 | 0 |
| 暂停原生预览 | 8 | 0 |

| 指标 | 旧敌人 | 新敌人 |
| --- | ---: | ---: |
| FPS | 729.73 | 682.87 |
| P95帧耗时(ms) | 2.176 | 2.221 |
| Draw Calls均值 | 180.45 | 180.75 |
| 纹理内存(MiB) | 23.41 | 26.07 |

条件：Godot4.6.2 Compatibility，RTX2070SUPER/NVIDIA595.97，1280×720，VSync关闭，物理60Hz、不限制渲染FPS；1秒预热、3秒实际战斗采样，采样期间不写PNG。两版本串行复测；已关闭本任务其它图形回归，但机器仍有其它任务的headless进程，因此不是独占机器的基准。新版FPS约下降6.4%，P95增加0.045ms、纹理约增加2.67MiB，不宣称性能改善。短样本须后续人工重复测量。

原A几何4个障碍、原碰撞、地图/各随机流与正式素材代码冻结检查通过。原历史断言未删减；原始可行走面积92.11%、角色净空采样80.44%沿用A5结果。新测试不读取或写入正式玩家档案。

## 失败与修正记录

- 初次只读审计误取RoomDefinition.id产生脚本错误，改为真实resource_path后完整重跑；原失败日志保留。
- 新capture最初多重if少一层缩进导致解析失败，修正后导入/启动及全流程通过，未忽略SCRIPT ERROR。
- 首次旧benchmark用headless运行被原测试明确拒绝；调整runner为真实图形模式，不删除其断言，失败日志单独保留。
- 生成图集实际列数与提示词不同，审查后按12/11列重切并去除格间残片，明确记录源映射，不宣称生成工具自动输出完美图集。
- 首次性能采样与其它图形回归并行，保留原始结果，正式报告使用全部图形回归结束后的串行复采。
- 暂停试玩初始身体尚未绑定纹理的问题已修正为_ready同步初始化姿态，并新增5项原生身体立即可见检查；不改游戏AI或开场观察期。

## 人工待验

请检查：两类敌人一眼可辨；四方向和腿部步相是否自然；尸犬扑击/虫咬与前摇衔接是否可信；深色石地和暖光下轮廓足够清楚；靠棺后/北墙/门洞无关键部位异常消失；低密度血条不抢眼且生命可读；命中小碎屑不覆盖危险范围。敌人骨骼及虫足细节与主角的像素密度统一程度仍待人工，不能以测试通过宣称正式美术定稿。

## 复验与试玩

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/phase12a6_visual_smoke.gd --fixed-fps 60
godot --path . --script tests/phase12a6_attack_probe.gd --fixed-fps 60
python tools/run_phase12a6_qa.py --godot GODOT_CONSOLE
python tests/run_phase_11i_qa.py --godot GODOT_CONSOLE --history --graphical --long-run
python tests/run_phase12_qa.py --godot GODOT_CONSOLE --graphical
python -m unittest discover -s database/tests
godot --path . --script tests/phase12a6_playtest.gd
```

最终隔离窗口停A房、Seed522269330、纯内存档；Space开始，F6三模式，R重开本实验。B/C仍旧样板，未接入本轮新敌人素材。不合并main、不读写正式存档、不继续下一阶段。
