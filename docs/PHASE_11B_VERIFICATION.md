# Phase 11B — 地区古墓与50种古董（开发记录）

基线6dbfcfe；用户确认允许从整合HEAD开发，保持main不变。分支codex/phase-11b-regional-tombs-loot。11B完成后再执行11C。

## 11B.1 洛阳

新增原创两层北邙汉魏疑冢：四种砖砌/耳室/分岔甬道Geometry，二层独立地图编排与现有Boss池；门闸扫击提供长条1秒预警、有限命中并随房间取消。旧Room/Encounter/Enemy/Boss流程复用；未改既有技能数值。此时地图仍保持调查中，直到正式地区掉落和完整GameFlow验收完成。

新增通用RoomGeometry主题属性、原创建筑装饰和两个数据驱动危险形状支持，不更改旧Geometry默认表现。地图/奖励随机流保持独立。

20 Seed×两层生成/合法出生点检查，以及Seed33/52真实两层武器、门、古董拾取、Boss、终点完成：586项，0失败。修正新测试驾驶器需初始化已跨层携带遗物的期待列表，保留原唯一Player/Build遍历断言。

后续阶段：关中→42件原型→地区掉落与Museum接通→全部回归/图形。
## 11B.2 关中

关中唐陵隐墓已制作：两层长墓道/壁画陪葬室、四种独立Geometry、定向火口扇区预警与区域伤害。复用既有Boss池1/3，不改HP、技能或攻击节奏。晋北资源无变化。新图形装饰只绘制原创示意，不冒称真实壁画。

洛阳+关中合计1172项，0失败：每地区20个生成Seed、两次真实两层探索/拾取/Boss/终点流程。地图地点暂保持调查中，等待11B.4接入。
## 11B.3 原型资源

新增42个独立game_id/.tres：洛阳18、关中18、共享6；试玩总目录playtest_catalog_50.tres包含原8件引用+42新资源。原formal_pool.tres及8件本体/数值不修改。新增文化时期、地区、类型、游戏年代范围、组别/权重、出处与PLAYTEST_PENDING_HISTORICAL_REVIEW元数据，均不是博物馆馆号/出土身份证明。

类型或时期参考来自Met、UMMA、Cleveland、British Museum、Cornell、DIA的官方资料，JSON逐条保留参考URL与局限说明。不下载图片、不修改500候选及其审核状态。造型细部/地方关联/尺寸/数值待人工审订；没有专家审批。

对应组合柜的42个显式游戏尺寸配置与真实馆藏测量分离，全部HAND_CARRY、1–3格，不增加大型运输。178项资源/合法尺寸/旧8件身份/年代/出处/18-18-6分类检查通过后提交。此阶段只建资源，下一阶段接入掉落与馆藏。
## 11B.4 地区池与完整生命周期

两座新地点在真实地图上开放。FORMAL_DEFAULT/Jin北仍精确走原8件AntiquePool VERSION2/旧风险奖励代码；两个新SiteLootProfile使用独立VERSION1的Site/Seed/Floor/Room/Source随机域。普通来源先选70/20/10组，再按楼层rarity曲线及同稀有度权重选原型；高价值风险源只保留RARE/TREASURE并归一化有候选组，不通过空组回退到现代物。

当地18件+共用早期6件+明确前代传世的汉玉璧/战国镜。洛阳制作年代上限280、关中907；原型结束年代超过上限、时代未知的旧器、宋明清白瓷及民国银元被拒绝。关中的早期旧器采用游戏原创旧墓道再利用/传世收藏说明，不冒充考古发现。

AntiqueRoom、Combat Cache、石棺/暗室/祭台风险奖励均接入本Site profile。Museum/Collection读取50件试玩目录；原formal_pool.tres、正式数据库global_catalog八定义、SQL与候选状态不改。Profile VERSION5格式保持，旧8件读取与case映射不变；新增42件有显式组合柜尺寸，原8尺寸不改。

每地区10,000 Seed普通来源统计：洛阳LOCAL7015/CIRCULATION2022/HEIRLOOM963；关中7003/2000/997。全部42件观察到非零可达概率；高价值来源额外100 Seed/地区验证年代。Jin北50 Seed样本结果与旧选择逐个相等。

40973项，0失败：每地区Seed33真实两层通关、Seed52首Boss撤离；情报板真实E/鼠标选择→武器/门/古董真实E→回Day2→真实鉴定/组合柜UI→原ID/陈列位置v5往返。新原型修复/出售/待拍锁覆盖为隔离事务测试（资金只在这部分夹具设置，前述拾取/撤离/鉴定/布展主流程没有库存/HP注入）。另一件真实携货经原Auction GameFlow与E逐轮竞价、结算回Day3。没有新的经济平衡结论。

旧10D6夹具明确使用原八件小集合以保持原8槽/分类断言；11A不可用点击改指仍调查中的洛水线索，保留拒绝出发覆盖，并增加已开放地点集合说明。

## 11B.5 最终回归与视觉验收

33组Godot历史+新增+Twin专项共 **336947项，0失败**；原28历史组、11A、两个新墓、50定义、11B主流程及Twin逐个执行，所有退出码0且无SCRIPT ERROR/ERROR。原坏档夹具WARNING为预期。Python数据库92 tests，0失败。图形版完整11B主流程40973项，0失败；真实Room图形布局8项，0失败。导入通过。

图形来自真实Godot Viewport：洛阳四布局`logs/11b_geometry_LUOYANG_*.png`、关中四布局`11b_geometry_GUANZHONG_*.png`；两地区实际地图/拾取/新展品/拍卖`11b_LUOYANG_EAST_*.png`与`11b_GUANZHONG_MOUND_*.png`。布局画廊是隔离的Geometry覆盖夹具，真正游戏流程另由完整GameFlow图形主流程完成；没有HTML游戏模拟。砖缝视觉在画廊验收后裁到Room边界，未改玩法。

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
| 8a | 486 | 0 |
| 8b | 305 | 0 |
| 8c | 297 | 0 |
| 8d | 2153 | 0 |
| 9a | 10513 | 0 |
| 9b | 30758 | 0 |
| 9b2 | 4843 | 0 |
| 9b3 | 29133 | 0 |
| 9b32 | 1734 | 0 |
| 9b33 | 2702 | 0 |
| geometry | 206885 | 0 |
| softlock | 1030 | 0 |
| baseline | 728 | 0 |
| 10a | 49 | 0 |
| 10d_bridge | 9 | 0 |
| 10d_media | 11 | 0 |
| 10d | 40 | 0 |
| 10d6 | 91 | 0 |
| 11a | 717 | 0 |
| 11b_tombs | 1172 | 0 |
| 11b_catalog | 178 | 0 |
| 11b | 40973 | 0 |
| twin_death_hotfix | 47 | 0 |

## 50件试玩目录

原八件价格/占格/稀有度/吸引力与ID冻结：民国银元、青花小罐、铜鎏金佛像、汉代玉璧、战国错金银铜镜、唐三彩马、金丝玉佩、镇墓兽残片。晋北仍只掉这八件。新42件如下，地域表示游戏出现地区，不等于已证实生产地/窑口。参考只支持类型或时代，特定细部/来源未核实者仍待审。

| game_id | 中文名 | 地区 | 价值 | 格 | rarity | appeal | 类型参考 |
|---|---|---|---:|---:|---|---:|---|
| ly_picture_brick | 画像砖残片 | LUOYANG | 520 | 2 | UNCOMMON | 12 | [官方参考](https://www.metmuseum.org/fr/press/exhibitions/2016/age-of-empires) |
| ly_attendant | 灰陶侍俑 | LUOYANG | 300 | 2 | COMMON | 8 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| ly_warrior | 灰陶武士俑 | LUOYANG | 650 | 2 | UNCOMMON | 15 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| ly_granary | 陶仓明器 | LUOYANG | 700 | 2 | UNCOMMON | 17 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| ly_well | 陶井明器 | LUOYANG | 380 | 2 | COMMON | 9 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| ly_stove | 陶灶明器 | LUOYANG | 330 | 2 | COMMON | 8 | [官方参考](https://www.metmuseum.org/art/collection/search/48435) |
| ly_pig | 陶猪明器 | LUOYANG | 240 | 1 | COMMON | 6 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| ly_dog | 陶犬明器 | LUOYANG | 280 | 1 | COMMON | 7 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| ly_green_jar | 绿釉陶罐 | LUOYANG | 560 | 2 | UNCOMMON | 13 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| ly_grey_tripod | 灰陶小鼎 | LUOYANG | 420 | 2 | COMMON | 10 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| ly_mirror | 汉式铜镜 | LUOYANG | 1150 | 1 | RARE | 24 | [官方参考](https://www.metmuseum.org/fr/press/exhibitions/2016/age-of-empires) |
| ly_lamp | 汉式铜灯 | LUOYANG | 1350 | 2 | RARE | 29 | [官方参考](https://www.metmuseum.org/fr/press/exhibitions/2016/age-of-empires) |
| ly_censer | 汉式铜熏炉 | LUOYANG | 2150 | 2 | TREASURE | 43 | [官方参考](https://www.metmuseum.org/fr/press/exhibitions/2016/age-of-empires) |
| ly_jade_pendant | 汉式玉佩 | LUOYANG | 1400 | 1 | RARE | 28 | [官方参考](https://www.britishmuseum.org/collection/object/A_1945-1017-87) |
| ly_cicada | 玉蝉 | LUOYANG | 2400 | 1 | TREASURE | 48 | [官方参考](https://dia.org/collection/cicada-3430) |
| ly_belt_hook | 铜带钩 | LUOYANG | 750 | 1 | UNCOMMON | 16 | [官方参考](https://www.britishmuseum.org/collection/object/A_1945-1017-87) |
| ly_wuzhu | 汉式五铢钱 | LUOYANG | 180 | 1 | COMMON | 5 | [官方参考](https://www.americanhistory.si.edu/collections/object/nmah_1340623) |
| ly_gilt_mount | 鎏金铜饰片 | LUOYANG | 1600 | 1 | RARE | 32 | [官方参考](https://www.metmuseum.org/fr/press/exhibitions/2016/age-of-empires) |
| gz_sancai_horse | 三彩小马俑 | GUANZHONG | 1250 | 2 | RARE | 30 | [官方参考](https://www.clevelandart.org/art/1955.295) |
| gz_sancai_camel | 三彩小驼俑 | GUANZHONG | 2250 | 3 | TREASURE | 46 | [官方参考](https://www.clevelandart.org/art/1955.295) |
| gz_sancai_attendant | 三彩侍俑 | GUANZHONG | 800 | 2 | UNCOMMON | 19 | [官方参考](https://www.clevelandart.org/art/1955.295) |
| gz_sancai_warrior | 三彩武士俑 | GUANZHONG | 1450 | 2 | RARE | 33 | [官方参考](https://www.clevelandart.org/art/1955.295) |
| gz_sancai_jug | 三彩小壶 | GUANZHONG | 650 | 2 | UNCOMMON | 16 | [官方参考](https://www.clevelandart.org/art/1955.295) |
| gz_sancai_plate | 三彩小盘 | GUANZHONG | 340 | 1 | COMMON | 9 | [官方参考](https://www.clevelandart.org/art/1955.295) |
| gz_white_bowl | 唐式白瓷小碗 | GUANZHONG | 400 | 1 | COMMON | 10 | [官方参考](https://emuseum.cornell.edu/objects/6857/ewer) |
| gz_white_ewer | 唐式白瓷执壶 | GUANZHONG | 1200 | 2 | RARE | 27 | [官方参考](https://emuseum.cornell.edu/objects/6857/ewer) |
| gz_celadon_cup | 唐式青瓷盏 | GUANZHONG | 720 | 1 | UNCOMMON | 16 | [官方参考](https://emuseum.cornell.edu/objects/6857/ewer) |
| gz_dancer | 彩绘舞俑 | GUANZHONG | 850 | 2 | UNCOMMON | 21 | [官方参考](https://www.clevelandart.org/art/1955.295) |
| gz_silver_box | 银盖盒 | GUANZHONG | 1500 | 1 | RARE | 31 | [官方参考](https://www.metmuseum.org/art/collection/search/49566) |
| gz_gilt_cup | 鎏金银杯 | GUANZHONG | 2450 | 1 | TREASURE | 47 | [官方参考](https://www.metmuseum.org/art/collection/search/49566) |
| gz_gold_mount | 金饰片 | GUANZHONG | 2600 | 1 | TREASURE | 48 | [官方参考](https://www.metmuseum.org/art/collection/search/49566) |
| gz_silver_belt | 银带饰 | GUANZHONG | 1700 | 1 | RARE | 34 | [官方参考](https://www.metmuseum.org/art/collection/search/42180) |
| gz_jade_belt | 唐式玉带饰 | GUANZHONG | 1850 | 1 | RARE | 37 | [官方参考](https://www.metmuseum.org/art/collection/search/42180) |
| gz_floral_mirror | 唐式花纹铜镜 | GUANZHONG | 1300 | 1 | RARE | 28 | [官方参考](https://www.metmuseum.org/art/collection/search/42180) |
| gz_kaiyuan | 唐式开元通宝 | GUANZHONG | 220 | 1 | COMMON | 6 | [官方参考](https://www.britishmuseum.org/collection/object/C_1884-0511-909) |
| gz_guardian | 镇墓小兽俑 | GUANZHONG | 2300 | 2 | TREASURE | 45 | [官方参考](https://www.clevelandart.org/art/1955.295) |
| shared_jade_ring | 素面玉环 | LUOYANG/GUANZHONG | 680 | 1 | UNCOMMON | 14 | [官方参考](https://www.britishmuseum.org/collection/object/A_1945-1017-87) |
| shared_jade_bead | 玉珠 | LUOYANG/GUANZHONG | 260 | 1 | COMMON | 7 | [官方参考](https://dia.org/collection/cicada-3430) |
| shared_bronze_ring | 铜环 | LUOYANG/GUANZHONG | 160 | 1 | COMMON | 4 | [官方参考](https://www.metmuseum.org/fr/press/exhibitions/2016/age-of-empires) |
| shared_bronze_buckle | 铜扣 | LUOYANG/GUANZHONG | 580 | 1 | UNCOMMON | 12 | [官方参考](https://www.britishmuseum.org/collection/object/A_1945-1017-87) |
| shared_pottery_cup | 素面陶杯 | LUOYANG/GUANZHONG | 180 | 1 | COMMON | 5 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |
| shared_pottery_jar | 素面小陶罐 | LUOYANG/GUANZHONG | 240 | 1 | COMMON | 6 | [官方参考](https://umma.umich.edu/objects/model-of-a-granary-1993-1-76/) |

## 争议、限制与人工验收

两新增墓各两层，不等同晋北五层；已有敌人组合复用但空间和危险机制不同。地区/时期归属、金银构件具体形制、三彩小件尺寸、青瓷盏与个别铜灯/熏炉的直接类型出处需要人工史学审订，当前参考有些只提供类型家族/时代背景，不能冒充逐件考古定论。汉式五铢钱补用Smithsonian官方单枚实例作为类型参考；游戏定义仍独立，不复制其身份。全部新42为PLAYTEST_PENDING_HISTORICAL_REVIEW；500候选、1441真实研究与SQL数据不变，不自动APPROVED。

70/20/10是游戏提案，不是实际墓葬出土比例。高价值风险源重归一化有候选组；唐墓前代器采用明确架空再利用/传世解释，不能当成现实考古结论。自动战斗/统计不能证明最终难度或经济平衡，等待真人验证空间、机关预警、背包取舍、收藏价值与交易价格。没有新增运输玩法或大化石。

Godot JSON/资源为本地离线资料；发行二进制导出未作为本次交付，需包含本地JSON与纹理。日志/截图/存档不提交。测试中交易资金注入仅隔离事务夹具，正式新游戏仍空馆藏/零现金；完整拾取回馆布展主流程没有inventory.add替代。

## 五个阶段提交与交付

- 11B.1 洛阳：`9230f52808745934b6e5365f440aec92b61b0d82`
- 11B.2 关中：`898b1283582f340f3202ecdbfbf08d9c3134c2d7`
- 11B.3 42资源：`999ebd51d973fd4a272c09adbed7dfc2b216b438`
- 11B.4 地区池/馆藏：`1599bdd71e3ca2e7fd58c156932055c11480ce4d`
- 11B.5：包含最终验收文档的独立提交，实际SHA见交付消息或`git log -1 --format=%H`（自含文件无法写入自身最终hash）。

最终push codex/phase-11b-regional-tombs-loot，不合并main。打开正式GameFlow隔离试玩窗口停在地图，无赠送/不写用户档，用户可选择洛阳或关中；人工体验待验收。按最新用户确认，11B完成提交后才从此HEAD建独立11C数据分支，保留游戏分支与试玩窗口。
