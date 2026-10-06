# Phase 0 验证记录

日期：2026-10-06（Asia/Shanghai）。执行引擎：Godot 4.6.2.stable.official.71f334935 标准版。

本机可执行文件：`C:\Users\atian\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`。此路径为验证环境记录，不是项目运行依赖。

| 检查 | 方法 | 结果 |
| --- | --- | --- |
| 导入与解析 | `--headless --path . --editor --quit` | 退出码 0，无解析错误 |
| 无窗口启动 | `--headless --path . --quit-after 10` | 退出码 0，输出 Phase 0 bootstrap ready |
| 图形模式启动 | `--path . --quit-after 60` | 退出码 0，OpenGL Compatibility 初始化成功，主场景就绪 |
| 退出按钮 | 临时 SceneTree 脚本延迟至树初始化后加载主场景，断言按钮存在与信号连接，发出 pressed | 退出码 0，正常结束，无运行错误 |

首次临时按钮检查过早在 SceneTree 的 `_initialize` 内触发，节点尚未进入树，出现空 get_tree 错误；修正验证脚本为延迟调用后通过。此问题来自测试时序，未修改项目脚本。临时脚本已删除。

图形启动验证确认渲染器和场景运行，不包含截图审核或人工鼠标点击；按钮通过信号调用验证。中文显示、不同分辨率和不同显卡的视觉兼容性尚未人工验收。

## 文件与范围

新增项目配置、占位主场景、入口脚本及其 Godot 生成 UID；README、项目计划、架构、游戏设计、协作规则、本记录；Git 忽略/文本规则；场景、脚本、数据、素材和测试目录的 `.gitkeep`。

当前只有一个 10 行入口脚本，无第三方插件、Autoload 或已实现玩法。Godot 缓存由 `.gitignore` 排除。未创建提交或推送。

Phase 0 完成。Phase 1 仍未开始，等待单独任务授权。
