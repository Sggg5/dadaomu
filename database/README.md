# Global Museum Collection Database

独立离线SQLite资料库，Python标准库，无Godot插件。真实馆藏资料是游戏策划参考，不直接进入掉落池。无需网络即可重建已核验的1441条真实馆藏记录。

在仓库根目录运行：

```powershell
python -m database.cli init_db --db database/work/catalog.sqlite
python -m database.rebuild_catalog --db database/work/catalog.sqlite
python -m database.cli validate_db
python -m database.cli build_index
python -m database.cli search_catalog --keyword jade --culture China
python -m database.cli search_catalog --category FOSSIL_SPECIMEN --geological-period JURASSIC
python -m database.cli search_catalog --category METEORITE
python -m database.cli report_licenses
python -m unittest discover -s database/tests -v
```

所有命令使用`--db`指定数据库，默认database/work/catalog.sqlite（被忽略）。重建是幂等重放，不删除现有数据库，不覆盖editor_locked对象、curator_locked名称、游戏定义。需要干净重建时指定一个新的文件路径。

官方公开数据补充：

```powershell
python -m database.importers.fetch_source CMA database/work/new_cma.jsonl --query bronze --limit 20
python -m database.cli import_source --source CMA --file database/work/new_cma.jsonl
```

fetch_source严格限于公开官方元数据端点，最大100条/20MB，无图片下载。其它机构使用已有Adapter接收带来源/许可的官方JSONL导出；不是任意URL爬虫。原始供应者格式始终经独立Adapter→CollectionRecord→事务存储，不能直接变成内部Schema。

参见docs/ARCHITECTURE.md、docs/SOURCES_AND_LICENSES.md；最终导出见下方及docs/PHASE_10A_VERIFICATION.md。语言缺失仍pending，原文不会被自动翻译成“官方中文”。

审核策划与稳定导出（独立于原始资料导入）：

```powershell
python -m database.exports.curation --db database/work/catalog.sqlite
python -m database.cli export_godot_catalog --db database/work/catalog.sqlite --output data/catalog/global_catalog.json --report database/work/export_report.json --world-year 1933
godot --headless --path . --script tests/phase_10a_smoke.gd
```

Schema v6前向迁移不修改已应用SQL；NORMALIZER_VERSION5支持适配规则升级后重放源记录，不覆盖人工锁。编辑映射JSON不会重写数据库里已有游戏策划，策划修改应由明确审核流程更新该层。


Phase10B 内容层与离线预览（无需联网，不会扩充正式掉落）：

```powershell
python -m database.preview --db database/work/catalog.sqlite
node database/tests/preview_dom_test.cjs
```

打开previews/index.html可筛选文明、器物类别、地质年代、查看图鉴、来源和候选状态。previews/planning_preview.json是500提案，不能作为正式发行目录。100篇AI草稿与80词表都待人工审订。完整质量统计见docs/phase10b_quality_report.json；人工流程见docs/CONTENT_REVIEW_WORKFLOW.md。内置浏览器file协议验证受限，HTML文件可由用户本地浏览器打开；DOM逻辑测试不能替代外观验收。


Phase10C 本地照片与专题预览：

```powershell
python -m database.preview --db database/work/catalog.sqlite
python -m http.server 8765 --bind 127.0.0.1 --directory .
```

访问http://127.0.0.1:8765/database/previews/index.html。无需外网阅读已生成的本地图鉴；来源链接单独需要联网。新clone只有2对象图片样例，其他18照片需显式`python -m database.media_pipeline download`重建（详见media_pipeline/README.md）。Pillow==12.3.0只用于策划工具，无Godot依赖。专题全部DRAFT_PENDING_REVIEW，未接门票/游客/正式掉落。
