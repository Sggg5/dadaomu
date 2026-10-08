# 开放实物图片管线

只下载逐媒体核验的CMA CC0照片，当前20样例全部成功；future MET/AIC/SI下载器尚未接入，不能绕过源host白名单。无AI替代图。Pillow==12.3.0是离线策划工具依赖，不进入Godot。

```powershell
python -m database.media_pipeline download --db database/work/catalog.sqlite
python -m database.media_pipeline refresh-rights --db database/work/catalog.sqlite
python -m database.preview --db database/work/catalog.sqlite
```

下载限制5MB、25秒超时、至少0.4秒请求间隔；官方HTTPS origin及每次重定向校验。先重新读取CMA单件记录share_license_status与web URL，再取893px级web照片（不取超大TIFF）。仅支持JPEG/PNG；核对Content-Type、签名、实际解码/尺寸/像素上限。源文件SHA去重；输出320/1024边界JPEG，保持比例、不裁剪、不放大。

manifest.json保留每张照片身份、源URL、许可证据、署名、hash、尺寸与本地路径。两件四图在previews/media/samples提交；18件预览cache及原图仅本地ignored。新clone直接有两件，重建其余需显式download；单元测试不要求网络。预览重导只读存在且hash正确、media_allowed及local_asset均通过的文件，不主动访问图片原站。

refresh-rights无法确认或不再CC0即DENIED并将清单revoked，重导排除，不删除旧缓存字节。数据重导不会复活清单撤权。外部许可更改需要显式刷新才能获知，离线缓存不假称永远最新。普通CC0的法律不可撤销性与这里保守处理来源更正/撤回的可用性策略是不同问题。

图片没有写入media.local_asset_path，不影响正式八件Godot导出；这里只用于策划预览。暂不处理3D。ATTRIBUTION.md列出全部20机构/图片链接，版权声明可在详情查看。
