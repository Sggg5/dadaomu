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
