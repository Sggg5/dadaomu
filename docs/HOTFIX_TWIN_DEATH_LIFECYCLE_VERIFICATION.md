# P0 Hotfix：双生尸煞成员死亡生命周期

## 修复前复现

基线 `ab314024b2af8a3145293a903a76a9024e23cf37`，干净工作区，从最新本地HEAD新建 `codex/hotfix-twin-death-lifecycle`。基线与其远端0/0；未reset、覆盖、合并main。

先创建专项，在生产代码未修改时执行：8项，2失败，2次SCRIPT ERROR。成员0先死正常；成员1先死，等待 `ceil(death_duration*60)+12` 物理帧确认节点已释放，再伤害成员0，稳定出现：

```
Cannot call method 'is_node_ready' on a previously freed instance.
_member_changed (scripts/bosses/encounters/twin_revenants.gd:41)
take_damage (scripts/combat/health.gd:27)
run (tests/phase_twin_death_hotfix_smoke.gd:13)
```

共享HP不下降，第二成员死亡无法完成BossEncounter。原始失败日志保留在ignored `logs/twin_before.log`，不是FPS判断，也未忽略Script Error。

## 根因与时序

旧实现求和时检查有效性，却随后无条件访问 `members[1].is_node_ready()`。阴尸queue_free后，任何阳尸Health.changed均中断父级同步。旧机制测试只等待2帧，未跨过尸体释放，因此漏检。

新实现保留固定成员索引，增加 initialized/dead/retired 三组生命周期证据与整体initializing屏障。初始化的changed只记录，在两个子节点完成装配后同步。有效成员贡献实际Health；已观测零HP成员贡献0；没有死亡证据的异常失效引用不会被当作死亡、不会发清场奖励。

`Health.take_damage → is_dead=true → changed(0) → member_dead记录 → sharedHP同步 → died → Enemy.stop_ai/取消owned预警 → killed → retire一次/激活有效幸存者 → death_duration → queue_free`。

最后一成员changed(0)只通过父级Health.take_damage触发已有父级killed→BossEncounter._on_defeated；finished保护保持，统一清弹丸/危险区、Room CLEARED、Session once计数。随后子成员killed不能重新激活死者。没有直接设置finished、开门或给成员绑定独立结算。

轮换、支援、combat_targets均检查固定索引的实际存活状态；旧成员回调不能夺回turn。幸存者只设置已有solo/may_attack，并保留当前状态、技能数值与原独存节奏。

## 测试边界与真实流程

专项分别覆盖两种击杀顺序，等待真实尸体释放后继续伤害；相邻物理帧双死亡；失效成员迟到回调；一次结算；预警清理。

真实武器测试以正式GameFlow启动、in_memory Profile、Expedition33进入夜间；隔离快速到达夹具装配真实F4并指定双生尸煞/两种正式Arena。不声称从F1徒步通关。测试携带现有黑火药、连珠簧、血契符、飞虎靴四件遗物作为已抵达F4的Build夹具；不使用F2、不改PlayerStats、BossDefinition、技能或倍率。玩家仍80HP，基础移动240。

每种Arena分别先杀阳尸/阴尸。全战斗通过真实Weapon.try_attack、碰撞弹丸、物理输入移动；不瞬移跳过独存。停火观察660帧（11秒），确认尸体已释放、solo/may_attack、至少两个新技能周期、WINDUP/RECOVERY与共享HUD。继续真实武器击杀，正常步行至ExpeditionExit按E进入F5。

最初简易自动驾驶曾因死亡或掩体挡射而失败，这些日志仍保留；修正的是隔离驾驶选点的攻击视线/危险预警避让与明确携带Build，不改生产平衡。最终结论以最终完整测试为准。

## 冻结与兼容

唯一生产修改：`scripts/bosses/encounters/twin_revenants.gd`。新增两测试脚本及UID、本报告。Boss基础840HP、两成员独立Health、技能数值、独存倍率、随机计划、Seed、正式遗物/掉落、80HP、博物馆均保持原样。最新有效基线已有Profile VERSION5扩容；本次保留，不回退到历史VERSION4。

## 执行命令

```powershell
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://tests/phase_twin_death_hotfix_smoke.gd --fixed-fps 60 --quit-after 50000
Godot_v4.6.2-stable_win64_console.exe --path . --script res://tests/phase_twin_death_hotfix_smoke.gd --fixed-fps 60 --quit-after 50000 -- --capture
Godot_v4.6.2-stable_win64_console.exe --headless --editor --path . --import
Godot_v4.6.2-stable_win64_console.exe --path . --script res://tests/phase_twin_death_hotfix_smoke.gd -- --manual
```

完整历史28组逐个运行其原 `tests/phase_*` 脚本，fixed-fps60/quit-after180000。汇总结果见报告末尾；8B/8C/8D/9A/10D6坏档夹具预期WARNING另计，不忽略SCRIPT ERROR/ERROR。

图形截图来自真实Godot Viewport，ignored `logs/phase_9b32_twin_solo_boss_*_order*.png`；两Arena/两顺序均截图。最后隔离试玩停在F4双生尸煞战，按P开始/暂停，Seed33，不写用户正式档。人工最终复验仍需真人完成；本次已稳定复现并修复所指出无效引用故障，不宣称排除所有未报告战斗问题。

## Git交付

本报告与修复属于同一个独立hotfix提交，实际SHA见交付消息或 `git log -1 --format=%H`。push指定开发分支，不合并main，不启动扩容或下一阶段。

## 最终自动结果

历史28组共 **293842 项，0失败**，每个退出码0，无SCRIPT ERROR/ERROR。

| suite | checks | failures |
|---|---:|---:|
| 1 | 27 | 0 |
| 2 | 204 | 0 |
| 3 | 94 | 0 |
| 4 | 105 | 0 |
| 5a | 61 | 0 |
| 5b | 236 | 0 |
| 6 | 164 | 0 |
| 6_5 | 174 | 0 |
| 7a | 306 | 0 |
| 7b | 722 | 0 |
| 8a | 482 | 0 |
| 8b | 305 | 0 |
| 8c | 297 | 0 |
| 8d | 2153 | 0 |
| 9a | 10510 | 0 |
| 9b | 30753 | 0 |
| 9b2 | 4842 | 0 |
| 9b3 | 29132 | 0 |
| 9b32 | 1733 | 0 |
| 9b33 | 2701 | 0 |
| geometry | 206884 | 0 |
| softlock | 1030 | 0 |
| baseline | 727 | 0 |
| 10a | 49 | 0 |
| 10d_bridge | 9 | 0 |
| 10d_media | 11 | 0 |
| 10d | 40 | 0 |
| 10d6 | 91 | 0 |

专项headless **47项，0失败**；graphical **47项，0失败**，同脚本同四种真实战斗组合。导入、正式入口headless与graphical启动通过。

注意：原Boss房顶部“存活敌人”文本按BossEncounter初始目标数量显示，独存期间可能仍显示2；本次共享HP与实际combat_targets正确、最终归零和出口正确。该既有文本计数不作为本次清场判据。
