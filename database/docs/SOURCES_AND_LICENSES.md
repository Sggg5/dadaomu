# 来源及授权检查（2026-10-08）

仅使用公开元数据接口/官方公开文件。未下载图片或模型；不绕登录、403或限速。元数据许可不推导媒体许可，原始链接、版权声明、核验日期和许可保存在每条source_record/media。来源注册表不是游戏发行的媒体白名单。

|来源|本阶段状态|数据/媒体边界|核验依据|
|---|---|---|---|
|Cleveland Museum of Art|官方API，120条真实种子|元数据CC0；图片仅share_license_status=CC0|https://www.clevelandart.org/open-access 、https://www.clevelandart.org/terms-and-conditions|
|Metropolitan Museum of Art|官方API，1条真实种子|Open Access数据CC0；图片另查isPublicDomain|https://metmuseum.github.io/ 、https://www.metmuseum.org/about-the-met/policies-and-documents/open-access|
|Art Institute of Chicago|官方API，1条真实种子|API元数据CC0；图片另查is_public_domain|https://api.artic.edu/docs/|
|Smithsonian/NMNH|官方S3公开EDAN，24条真实种子|逐条metadata_usage.access=CC0；图片/模型逐条usage.access|https://www.si.edu/openaccess/faq 、https://naturalhistory.si.edu/research/idsc/data-access 、https://github.com/Smithsonian/OpenAccess|
|GBIF（NHMUK发布数据）|官方API，15条真实馆藏化石|只选逐条CC0；其它CC BY需要署名，CC BY-NC不能发行|https://www.gbif.org/terms?preview=true 、原记录datasetKey链接|
|NHM London直接门户|Darwin Core本地适配器；公开查询403未继续|数据集单独许可；collection-specimens元数据CC0已由package_show核验，图片不得继承|https://data.nhm.ac.uk/sr/terms-conditions 、https://data.nhm.ac.uk/about/download|
|Paleobiology Database|Occurrence/Taxon上下文适配器，未计入161藏品|实例collection 123976标CC0不代表整个服务所有资料；无实物馆藏编号不创建Specimen|https://paleobiodb.org/classic/basicCollectionSearch?collection_no=123976|
|台北故宫|许可明确的官方本地导出适配器；未导入真实种子|当前文字/中阶图像CC BY4，必须按官方格式署名；早期CC0范围须另证，不能全库CC0|https://digitalarchive.npm.gov.tw/opendata 、https://theme.npm.edu.tw/opendata/故宮Open%20Data專區圖像與文字授權規範.pdf|
|FlamingoCheers/wenwu-database|研究/严格来源证明适配器，无真实种子导入|聚合CC0与copyrighted来源；代码许可证不授予图片或第三方数据许可，优先原机构API|https://github.com/FlamingoCheers/wenwu-database|

适配器9个，真实在线获取5个来源。NHM科学鉴定/GBIF清洗issues原样保留：15件化石目前NEEDS_REVIEW，馆藏号、来源和CC0可以核验，但不声称物种鉴定已经人工审订。无学名候选从首批策划快照剔除，不补编物种。三叶虫10件；另外5件来源分类含脊椎/恐龙上下文，不能把高阶Chordata冒充已鉴定的恐龙物种。菊石Ammonoidea查询返回多重分类匹配，未强行选一个；保留缺口。

矿物8、陨石8、岩石8均为真实USNM/NMNH馆藏编号，化学组成/晶系/质量/发现时间若原记录未提供则NULL。年代词表使用ICS 2024-12固定版本，来源https://stratigraphy.org/ICSchart/ChronostratChart2024-12.pdf，只收录事实性单位名/数值和出处，不复制整张图像；并未声称这是2026年的最新图表。

种子原始快照用于离线重建、核验，位于database/samples，所有元数据CC0；少量明确合法快照和纯文本版权声明可提交，生成SQLite/批量缓存/媒体文件全部忽略。重新导入不会重写人工锁定名称、描述或后续游戏策划。
