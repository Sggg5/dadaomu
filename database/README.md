# Global Museum Collection Database

独立离线SQLite资料库，Python标准库，无Godot插件。真实馆藏资料是游戏策划参考，不直接进入掉落池。无需网络即可重建已核验的161条种子记录。

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

Schema v3前向迁移不修改已应用SQL；NORMALIZER_VERSION2支持适配规则升级后重放源记录，不覆盖人工锁。编辑映射JSON不会重写数据库里已有游戏策划，策划修改应由明确审核流程更新该层。
