# Phase 10C 验收记录

基线eb88e87027df42232d93939a902cf0a44ca34b56，10B四提交齐全、远端一致、工作区干净，新分支codex/phase-10c-museum-quality。不合并main，不改正式玩法/八古董/Profile4。

## 10C.1 HTTP预览与真实浏览器

Python标准库服务只绑定127.0.0.1:8765，使用现有Codex浏览器Playwright与CDP。新增8个维度筛选、折叠筛选区、响应式换行、中文宽分类标签、安全textContent详情与中性无图占位；第四专题视图预留，10C.5接入。

实际打开HTTP页面，1280×720及390×844浏览器视口确认无水平溢出；真实PNG保存ignored logs/phase10c/c1_desktop_list.png与c1_mobile_list.png。截图由真实Chromium Page.captureScreenshot获取，不是DOM模拟图。viewport能力在IAB中未正确约束高度，改用用户授权的开发CDP设定精确尺寸，结束将恢复默认。

浏览器已实际切换图鉴并打开详情，中文、原文、机构、来源和无图占位存在。所有来源文字安全转义，页面不会请求第三方媒体。Python预览6项与DOM逻辑17项通过后提交；DOM测试不冒称视觉验收。最终含图片和专题的12张双尺寸截图将在10C.5补齐。

启动：python -m http.server 8765 --bind 127.0.0.1 --directory .
访问：http://127.0.0.1:8765/database/previews/index.html

## 10C.2 自然历史核查

122对象全覆盖：66化石、13矿物、13陨石、30稳定抽查岩石；1021条源字段核查证据，38对象有明确疑问。新Schema7将字段核验与专家审核分离，全部NEEDS_REVIEW；发现/命名年/精确年龄未知继续NULL。一般方解石配方/晶系仅存独立类型知识，不当作具体样本实测。

发现同USNM号多陨石分样名称/重量冲突，保留全部原始记录与1441身份，待人工解析，不合成整石质量。Unakite复合岩石材料宽分类需复核。专业矿物中文名不确定时保留英语待审；不下载Museum Wales有版权图片。详见NATURAL_HISTORY_QUALITY.md及122条audit_records.json。15项自然历史/迁移专项通过后提交。

## 10C.3 三十篇精修与审查工具

8中国青铜、7中国玉器/陶瓷、7世界文明、8自然史，30篇正文223～268字符；独立三段claims分别提供源字段、出处及需核验限制。推荐名、原文名、适用学名、命名依据与翻译可信度独立，全部DRAFT_PENDING_REVIEW。不是人工或专家审核通过。

Schema8保存60条v1/v2不可变快照与hash，展示逐段证据、名称来源、待确认项及unified diff。原官方名称不覆盖；基础重导不回退v2，pending人工锁也不会被覆盖。C3提交时人工锁夹具遇到嵌套事务错误（17通过/1错误）；未改写提交，随后用SAVEPOINT兼容外层事务并追加修正，18项编辑/预览与17项DOM逻辑均通过。没有新增正式图鉴UI或古董。

## 10C.4 开放图片管线

20/20 CMA实物照片成功，全部重新按单件API share_license_status=CC0及匹配web图片URL核验，20源SHA无重复；生成20缩略图与20详情图，320/1024边界保留比例（源893px不放大），5MB/25秒/0.4秒限速/HTTPS官方host与重定向检查。HTML伪图片、坏签名、像素炸弹、越界路径拒绝。

manifest.json与ATTRIBUTION.md逐张保留来源、许可、署名、源/输出SHA和尺寸。只提交2对象的4缩放样例约317KB，18件cache及原图ignored，可显式CLI重建。单元测试在新clone可离线使用2样例；实际20下载结果另有清单证明。Pillow12.3.0只用于策划。

预览使用media_allowed及local_asset/hash双校验，DENIED/UNKNOWN/CC_BY_NC/文件失效剔除；显式refresh-rights发现撤权或无法确认会禁用清单，重导不复活。数据CC0不替代图片授权，当前只CMA下载器接通。图片未写入media.local_asset_path，不加入正式游戏资源；20项管线/原发行专项0失败。


## 10C.5 四专题与最终回归

四个MuseumExhibitionDefinition各8真实对象：中国青铜文明（商周至战国）、古埃及文明（明确古埃及期，排除拜占庭/罗马发现地误归）、生命的远古印记（6三叶虫+古鱼/其它化石，来源阶元不冒充专家定种）、地球与天外来客（矿物/岩石/陨石）。对象关系只作策展比较，不推同一出土；阅读顺序、来源、核心主题与关联图鉴完整。分别关联6/4/1/6篇已有图鉴，缺少专属稿的展品明确保留缺口。全为DRAFT_PENDING_REVIEW，不改经营、门票、游客、奖励或运输玩法。

### 最终数量、状态和限制

1441对象/1447来源无丢失，1027原同名候选未擅自合并。自然史原数量66/13/13/157保持；检查122，1021条源字段证据、38对象疑问。发现/命名年/精确年龄未知、未定属/高阶分类、陨石同USNM分样冲突与Unakite宽分类仍待专业处理。图鉴100篇，其中30已v2精修，223～268字符、三段证据；全部待人工审核。500候选仍CANDIDATE，正式8件不变。

20照片全部成功且源SHA唯一，20缩略图+20详情图，保留比例，不取巨大原图；源尺寸并不全同，详情1024只是最大边界。每张来源/CC0/署名/版权/hash见下表和media_pipeline/manifest.json。只2对象4缩放图提交约317KB，其余cache可重建。仅CMA下载器接通，未声称MET/AIC/Smithsonian媒体都已自动支持；没有3D下载。外部许可变化需显式refresh-rights后重导，离线检查只代表清单核验日期，不能声称实时。人工/专家内容审订尚未发生。

### 真实浏览器结果

本地HTTP，真实Chromium通过现有浏览器Playwright与CDP；13 PNG（12场景+长名/注入）。桌面1280×720、手机390×844，实际文件尺寸由Pillow复验。列表、图片详情、中文图鉴、无图占位、CC0版权/署名、专题各双尺寸，broken=0、remoteImages=0、无横向溢出。还真实检查机构234、白垩纪6、中国570、南极10、汉规范筛选28、UNKNOWN媒体9。窗口console无错误。注入fixture显示恶意标签为纯文本、无脚本执行/无伪图片节点；约600字符英文长名正常换行。

手机缩略图挤压文字、展开筛选超长选项溢出在实际检查中发现并修正，不把DOM模拟17项当成截图。截图为ignored logs/phase10c，未提交截图/用户存档/日志。逐场景尺寸/hash见phase10c_browser_report.json。CDP测试尺寸结束恢复默认，HTTP预览保留供查看。

|场景|桌面截图|手机截图|
|---|---|---|
|列表|[PNG](../../logs/phase10c/final_desktop_list.png)|[PNG](../../logs/phase10c/final_mobile_list.png)|
|实物详情|[PNG](../../logs/phase10c/final_desktop_detail.png)|[PNG](../../logs/phase10c/final_mobile_detail.png)|
|图鉴阅读|[PNG](../../logs/phase10c/final_desktop_article.png)|[PNG](../../logs/phase10c/final_mobile_article.png)|
|无图占位|[PNG](../../logs/phase10c/final_desktop_placeholder.png)|[PNG](../../logs/phase10c/final_mobile_placeholder.png)|
|授权署名|[PNG](../../logs/phase10c/final_desktop_license.png)|[PNG](../../logs/phase10c/final_mobile_license.png)|
|专题|[PNG](../../logs/phase10c/final_desktop_exhibition.png)|[PNG](../../logs/phase10c/final_mobile_exhibition.png)|

### 每张合法照片样例

|名称|馆藏号|许可|机构记录 / 原图|
|---|---|---|---|
|Mirror|1926.248|CC0|[机构](https://clevelandart.org/art/1926.248) / [图片](https://openaccess-cdn.clevelandart.org/1926.248/1926.248_web.jpg)|
|Mirror with Paired Felines|1926.249|CC0|[机构](https://clevelandart.org/art/1926.249) / [图片](https://openaccess-cdn.clevelandart.org/1926.249/1926.249_web.jpg)|
|Wine Vessel (Hu)|1929.984|CC0|[机构](https://clevelandart.org/art/1929.984) / [图片](https://openaccess-cdn.clevelandart.org/1929.984/1929.984_web.jpg)|
|Finial|1930.730|CC0|[机构](https://clevelandart.org/art/1930.730) / [图片](https://openaccess-cdn.clevelandart.org/1930.730/1930.730_web.jpg)|
|Monster Face: Door Ring Holder (Pushou)|1930.731|CC0|[机构](https://clevelandart.org/art/1930.731) / [图片](https://openaccess-cdn.clevelandart.org/1930.731/1930.731_web.jpg)|
|Handle of a Jiangu Drum|1941.548|CC0|[机构](https://clevelandart.org/art/1941.548) / [图片](https://openaccess-cdn.clevelandart.org/1941.548/1941.548_web.jpg)|
|Tripod Cauldron (Ding)|1960.288|CC0|[机构](https://clevelandart.org/art/1960.288) / [图片](https://openaccess-cdn.clevelandart.org/1960.288/1960.288_web.jpg)|
|Wine vessel (Jue)|1960.42|CC0|[机构](https://clevelandart.org/art/1960.42) / [图片](https://openaccess-cdn.clevelandart.org/1960.42/1960.42_web.jpg)|
|Cup with Dragon Handles|1920.424|CC0|[机构](https://clevelandart.org/art/1920.424) / [图片](https://openaccess-cdn.clevelandart.org/1920.424/1920.424_web.jpg)|
|Amulet in the Form of a Seated Figure with Bovine Head|1953.628|CC0|[机构](https://clevelandart.org/art/1953.628) / [图片](https://openaccess-cdn.clevelandart.org/1953.628/1953.628_web.jpg)|
|Scepter (Gui) with Miscellaneous Poems by Tao Qian (365–427 CE)|1960.278|CC0|[机构](https://clevelandart.org/art/1960.278) / [图片](https://openaccess-cdn.clevelandart.org/1960.278/1960.278_web.jpg)|
|Dish with Incised Scroll Design|1921.644|CC0|[机构](https://clevelandart.org/art/1921.644) / [图片](https://openaccess-cdn.clevelandart.org/1921.644/1921.644_web.jpg)|
|Bowl with Ducks among Waves and Reeds|1929.995|CC0|[机构](https://clevelandart.org/art/1929.995) / [图片](https://openaccess-cdn.clevelandart.org/1929.995/1929.995_web.jpg)|
|Prunus Vase (Meiping) with Blossoming Lotus|1942.716|CC0|[机构](https://clevelandart.org/art/1942.716) / [图片](https://openaccess-cdn.clevelandart.org/1942.716/1942.716_web.jpg)|
|Trial Piece Worked on Both Sides|1920.1975|CC0|[机构](https://clevelandart.org/art/1920.1975) / [图片](https://openaccess-cdn.clevelandart.org/1920.1975/1920.1975_web.jpg)|
|Fragment of an Inlay Headdress|1920.1976|CC0|[机构](https://clevelandart.org/art/1920.1976) / [图片](https://openaccess-cdn.clevelandart.org/1920.1976/1920.1976_web.jpg)|
|Vulture Headdress Inlay|1920.1991|CC0|[机构](https://clevelandart.org/art/1920.1991) / [图片](https://openaccess-cdn.clevelandart.org/1920.1991/1920.1991_web.jpg)|
|Grave Stele|1924.1018|CC0|[机构](https://clevelandart.org/art/1924.1018) / [图片](https://openaccess-cdn.clevelandart.org/1924.1018/1924.1018_web.jpg)|
|Corinthian Helmet|1926.54|CC0|[机构](https://clevelandart.org/art/1926.54) / [图片](https://openaccess-cdn.clevelandart.org/1926.54/1926.54_web.jpg)|
|Statue of Gudea|1963.154|CC0|[机构](https://clevelandart.org/art/1963.154) / [图片](https://openaccess-cdn.clevelandart.org/1963.154/1963.154_web.jpg)|

### 完整自动测试

86 Python测试0失败，涵盖原63及自然6、精修5、媒体7、专题5；17 DOM单元0失败，只验证渲染逻辑。Godot Phase1～9B.3.3+Geometry+Softlock+Player baseline+10A共293691项0失败；10A graphical49项0失败，导入与正式隔离Profile入口正常，无SCRIPT ERROR/ERROR。旧8B/8C/8D/9A损坏Profile夹具的预期WARNING仍在。未删原断言。

原442游戏文件SHA断言、8古董ID/数值/发行目录逐结构相同；Profile4及迁移通过。相对eb88e87不修改scripts/scenes/data/project.godot，图片未写media.local_asset_path，正式掉落/地宫/Boss/遗物不受影响。新增Schema7～9，不改已应用SQL。

```powershell
python -m unittest discover -s database/tests -v
node database/tests/preview_dom_test.cjs
python -m database.preview --db database/work/catalog.sqlite
python -m database.media_pipeline download --db database/work/catalog.sqlite
python -m database.media_pipeline refresh-rights --db database/work/catalog.sqlite
python -m http.server 8765 --bind 127.0.0.1 --directory .

godot --headless --fixed-fps 60 --path . --script tests/phase_<phase>_smoke.gd
godot --headless --fixed-fps 60 --path . --script tests/phase_softlock_smoke.gd
godot --headless --fixed-fps 60 --path . --script tests/phase_player_baseline_smoke.gd
godot --path . --script tests/phase_10a_smoke.gd
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 10 -- --profile-path=user://tests/phase10c/startup.json --seed=33
```

Phase序列：1,2,3,4,5a,5b,6,6_5,7a,7b,8a,8b,8c,8d,9a,9b,9b2,9b3,9b32,9b33,geometry,10a。媒体测试不联网，新clone可只用两件Git样例，实际20照片由下载清单及本地验证证明。截图是当前真实环境验收，不是专家内容审批或经济平衡结论。

### 提交与交付

|阶段|完整SHA|
|---|---|
|10C.1|1623f41e30aea592ad1656cd3373bf6caeea060b|
|10C.2|dee629e0edc6153d22c8b457ded6d54049c42627|
|10C.3|46bba7043b0fa03643807cf7b338436b64489af5|
|C3事务追加修正|45059ba12c2b3963ec93fe6d431d6ade906a94ff|
|10C.4|3c832c309b7552b20e9836d41b4bc9ae25bd54da|
|10C.5|本文件所在最终提交，完整SHA见最终交付报告/git log|

五个阶段提交之外有一个明确追加修正，未改写历史。C3最初人工锁测试的事务错误在提交后发现，已记录并修复，最终全部通过。为避免自引用hash，本文件所在C5 SHA由`git rev-parse HEAD`和最终报告给出。提交push后核对本地/远端HEAD一致、工作区干净；不合并main，不继续下一阶段。
