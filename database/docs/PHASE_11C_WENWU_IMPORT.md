# Phase 11C — Wenwu Fork增量导入验收

## 基线与来源

11B 已完成并推送 `58ba98a2019e844caf7e5ce116a26c0160a07f35`。本分支 `codex/phase-11c-wenwu-import` 从该提交建立；不合并main。上游只读稀疏检出 `1804cd81c3f9bdaed8ca325f37d37d8c0b244001`，未执行其脚本、未修改其JSON、未下载媒体。README称50,792，实际JSON为50,794。

## 真实数量与分类

首批均衡抽样1,000条覆盖11个馆源：新增1,000索引、356标准化对象、8条链接原官方对象、0拒绝。完成全量后共50,794索引，累计新增15,257标准化对象，568条链接既有官方资料，总标准化记录16,698（基线1,441）。不能将馆藏记录、成套藏品或汇总品种直接等同于独立实物数量。

全量再次重放：50,794 duplicate，0新增、0更新、0拒绝；SQLite integrity_check=ok，foreign_key_check=0。

| 馆源 | 索引数 |
|---|---:|
| AIC | 802 |
| CLE | 2804 |
| GPM | 624 |
| HAM | 5392 |
| HN | 96 |
| MET | 10581 |
| NMC | 1317 |
| NPM | 11298 |
| SMI | 1638 |
| SXHM | 1515 |
| VA | 14727 |

| 原始类别 | 数量 |
|---|---:|
| 瓷器 | 13516 |
| 书画 | 8573 |
| 陶器 | 889 |
| 金银器 | 587 |
| 青铜器 | 2912 |
| 织绣 | 1937 |
| 玉器 | 3052 |
| 雕塑 | 619 |
| 宗教造像 | 122 |
| 漆器 | 480 |
| 玻璃器 | 595 |
| 竹木牙角 | 828 |
| 杂器 | 9039 |
| 钱币 | 7290 |
| 碑帖拓本 | 99 |
| 建筑构件 | 5 |
| 历史影像 | 151 |
| 文房用具 | 89 |
| 甲骨 | 11 |

## 身份、来源和质量边界

1,497条SXHM钱币汇总明确为COIN_TYPE，不生成CollectionObject；其余49,297条为MUSEUM_RECORD来源记录。3,024组同名项不按名称合并；144组稳定标识重复保留来源引用。AIC/HN共898条API编号不冒充馆藏号。使用机构+真实馆藏号或经规范化的官方对象URL去重；歧义进入审核索引。

原始ID、名称、朝代、材质、馆名、原inventory、URL、原许可和媒体声明保留。FieldEvidence记录具体源字段，未知材质14,963、无year_range 6,444均保留未知；42,784条时代分类待审。不会从收藏机构所在地推断文化起源，不将朝代自动视为发现年份。源year_range仅标记供应者有符号年代，尚未证明精确历法。

初次全量一条含空格的原始ID被误拒绝，已修正合法ID校验并复导，最终0拒绝。未篡改上游。原始长篇summary/history不复制进受限索引；保存事实投影和原始载荷哈希供复核。

## 数据许可与媒体分离

15,825条OPEN_METADATA；22,174条INDEX_ONLY；11,298条RIGHTS_CONFLICT_INDEX_ONLY；1,497条TYPE_INDEX_ONLY。全部50,794条审核状态PENDING，0自动批准。

- [Cleveland官方开放数据说明](https://www.clevelandart.org/open-access)：元数据CC0。
- [Met官方Open Access](https://www.metmuseum.org/hubs/open-access)：基本元数据CC0。
- [AIC官方API许可](https://api.artic.edu/docs/)：数据与图像权利分别处理。
- [Smithsonian官方FAQ](https://www.si.edu/openaccess/faq)：适用开放元数据范围。
- [故宫官方图像文字授权规范](https://theme.npm.edu.tw/opendata/%E6%95%85%E5%AE%AEOpen%20Data%E5%B0%88%E5%8D%80%E5%9C%96%E5%83%8F%E8%88%87%E6%96%87%E5%AD%97%E6%8E%88%E6%AC%8A%E8%A6%8F%E7%AF%84.pdf)：当前CC BY4.0与Fork CC0声明冲突未解决，因此仅作来源索引。

其它来源不以API可访问或根目录MIT推导商业授权。76,832条媒体链接均effective UNKNOWN、UNVERIFIED、download_allowed=false；图片下载0。

## 增量同步与本地审核保护

追加Schema迁移010，不修改001～009。wenwu_entries保存来源索引，wenwu_versions保存事实投影版本，wenwu_sync_runs保存批次报告，复用现有SourceRecord/FieldEvidence/CollectionObject。以raw哈希+投影版本识别更新；固定上游commit可复现。人工锁、CURATED证据、人工名称、审核状态及本地笔记不被上游重写，既有更权威官方对象不被聚合源覆盖。缺失条目只在无错误完整扫描后标记inactive，不删除馆藏或审核内容。

后续同步：只读更新上游检出→先limit1000→检查报告和许可变化→完整导入→完整幂等复导。新来源前缀或非官方链接拒绝；上游许可变化不自动获得媒体许可。许可冲突需实际人工确认来源范围。

## 离线研究目录

python -m database.wenwu_catalog --db database/work/phase11c_verified.sqlite --export database/previews/wenwu

204个静态分页，每页250条；首页离线名称/朝代/机构/类别/类型/授权搜索，每页50条。SQLite查询支持museum/category/kind/rights和页码，mode=ro。HTML转义与textContent阻止注入；不依赖网络或外部JS，不向Godot加载50kJSON。生成数据库和预览被忽略，不提交上游缓存。官方链接只在用户点击时联网。

## 游戏隔离与测试

11C相对11B没有scripts/data/scenes/project.godot修改，不改50件试玩古董、原8件数值、正式catalog、MuseumProfile VERSION5/v4迁移、战斗、Boss或掉落。500个策划候选不自动批准。

测试命令：python -m unittest discover -s database/tests -v；历史33套Godot smoke按原阶段运行（详见11B验收命令）；Godot --headless --editor --path . --import；隔离tests/phase_11b_playtest.gd图形启动。结果见下方最终记录。

## 新增真实索引样例

- AIC-101076 · Sugar Bowl with Cover · [OPEN_METADATA](https://www.artic.edu/artworks/101076)
- AIC-103302 · Landscape: Beautiful Scenery Frozen in Mist · [OPEN_METADATA](https://www.artic.edu/artworks/103302)
- AIC-103303 · Architectural Brick with Ogre Mask · [OPEN_METADATA](https://www.artic.edu/artworks/103303)
- AIC-10393 · Deep Dish with Peony, Pine Branches, Plum Blossoms, Chrysanthemum, Cherry, and Lotus Flowers · [OPEN_METADATA](https://www.artic.edu/artworks/10393)
- AIC-103961 · Ovoid Jar · [OPEN_METADATA](https://www.artic.edu/artworks/103961)
- AIC-104483 · Cloud-Shaped Pillow · [OPEN_METADATA](https://www.artic.edu/artworks/104483)
- AIC-10495 · Woman's Changfu (Informal Court Robe) · [OPEN_METADATA](https://www.artic.edu/artworks/10495)
- AIC-10522 · Mirror with "TLV" Pattern · [OPEN_METADATA](https://www.artic.edu/artworks/10522)
- AIC-105528 · Birds on a Tree with Fruit and Autumn Foliage · [OPEN_METADATA](https://www.artic.edu/artworks/105528)
- AIC-105529 · Lobed Pillow with Deer · [OPEN_METADATA](https://www.artic.edu/artworks/105529)
- AIC-105530 · Rectangular Pillow with Mandarin Ducks in a Lily Pond · [OPEN_METADATA](https://www.artic.edu/artworks/105530)
- AIC-105549 · Beaker · [OPEN_METADATA](https://www.artic.edu/artworks/105549)
- AIC-105591 · Jar with Eight Immortals and Peonies · [OPEN_METADATA](https://www.artic.edu/artworks/105591)
- AIC-105595 · Vessel in Form of a Bird · [OPEN_METADATA](https://www.artic.edu/artworks/105595)
- AIC-105786 · Water Pavilion by Twin Pines · [OPEN_METADATA](https://www.artic.edu/artworks/105786)
- AIC-105937 · Immortals Riding Dragons: Sections of a Tomb Pediment · [OPEN_METADATA](https://www.artic.edu/artworks/105937)
- AIC-107593 · Plate · [OPEN_METADATA](https://www.artic.edu/artworks/107593)
- AIC-107912 · Musical Chime · [OPEN_METADATA](https://www.artic.edu/artworks/107912)
- AIC-108586 · Sheath with Bird and Feline or Dragon · [OPEN_METADATA](https://www.artic.edu/artworks/108586)
- AIC-109223 · Beaker · [OPEN_METADATA](https://www.artic.edu/artworks/109223)

## 最终执行结果

- Python全部107项通过（原92项+本次15项），0失败/错误。包含幂等、同名不合并、跨源引用、人工字段保护、媒体隔离、原ID空格、离线分页/只读/注入防护。
- Godot历史33套共336,947 checks，0 failures，退出码全部0，所有日志SCRIPT ERROR/ERROR为0。既有预期坏档WARNING仍保留。
- Godot导入成功，无解析错误。
- 图形正式GameFlow隔离启动成功。第一次使用试玩脚本加--quit-after强制终止出现ObjectDB/资源退出错误，未将其报为无错误；随后独立启动真实game_flow.tscn，正常queue_free并等待帧后退出，0错误/泄漏。未修改生产代码掩盖结果。
- 11B真人试玩窗口仍保持打开（隔离档、情报地图）；11C不更改游戏场景。
- 首次全量有1条校验误拒绝，修复后最终全量和重放均0拒绝。最初迁移夹具遗漏010导致旧迁移测试失败，修正夹具复制范围后，篡改拒绝和失败回滚原断言均通过。
- 工作区仅本次数据库工具、迁移、测试、报告及生成目录忽略规则；没有提交缓存、数据库、日志、截图、存档、受限图片。
- 提交与push分支：codex/phase-11c-wenwu-import。实际最终SHA在交付回复及git log中核对；不合并main，不批准候选，不开展后续内容。

### 待人工审核

当前授权判定针对已核实的基本元数据范围，不意味着Fork所有翻译和衍生解释已获原机构认证。朝代、源year_range、中文译名、材质和馆藏身份仍需审订。NPM授权冲突尚未解决；其它来源未提供充分许可证明，保持索引用途。所有媒体待独立审核。没有将50,794索引宣称为50,794件经专家审核实物。
