# 全球藏品资料库

Python标准库+SQLite，独立于Godot运行；database/.gdignore防止原始资料成为运行资源。数据库生成物不提交，版本化SQL、受控词表、合法小型种子快照和工具可重建。

CollectionObject统一身份，文化遗产与自然历史扩展表分开。Human chronology使用天文年编号（1 BCE=0，206 BCE=-205），保留原文日期/历法/不确定性；Geological timescale独立保存Ma、rank、版本，绝不复用中国朝代。ICS 2024-12是显式固定词表版本，非声称最新版本；标本年代未知时NULL，不从地层名称伪造精确年龄。

Taxon是分类单位，Occurrence是来源出现记录，FossilSpecimen是有真实馆藏身份的实物，Formation/Location是地层/地点；相同物种可有多标本。矿物/陨石/岩石/生物各有独立扩展，未知机构/尺寸/发现年保持NULL。

source_records保存机构来源、记录ID/URL、数据许可证/声明、抓取/核验时间、payload hash与原始JSON。field_evidence保留逐字段来源值与核验状态。media单独存图片/模型权利，数据CC0不能推导媒体CC0。CC BY-NC、UNKNOWN、CONFIRM禁止发行；CC BY必须附署名；对图片仅保存链接，不下载、不自动打包。

稳定ID与语言显示分开，object_names记录简体/繁体/英语/原文/学名/别名/旧称及翻译状态和人工锁；词表有父子关系和同义名。进口只操作自身来源，不自动覆盖人工锁定字段或游戏策划。

迁移有SHA256锁、事务和未知版本检查，禁止改已应用迁移/重置用户数据库。SQL FK/CHECK/类型触发器保护边界；更多类别可以添加受控词表，不将外部JSON当内部Schema。检索索引/FTS与运行导出是独立职责。
