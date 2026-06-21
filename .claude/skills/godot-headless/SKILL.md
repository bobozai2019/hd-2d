---
name: godot-headless
description: "Godot 无头模式场景加载、截图捕获和布局验证。用于通过 godot --headless 验证场景和运行截图流程。"
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Godot Headless

$ARGUMENTS

## 概述

本 skill 帮助在项目中执行可重复的 Godot headless 和运行时检查工作流：场景加载检查、截图捕获、将共享的 `capture_scene.gd` 辅助脚本同步到 `scripts/tools/`，以及在需要验证截图或点击时使用项目本地窗口化交互探测。

## 使用场景

在以下情况使用本 skill：

- 以 `--headless` 模式运行 Godot 场景以捕获加载或脚本初始化错误
- 将场景捕获为 PNG 用于布局对比
- 在项目中安装或刷新共享的 `capture_scene.gd` 辅助脚本
- 在构建更多自动化之前，组织 headless 相关的项目工具
- 运行或记录项目本地运行时交互辅助工具，验证 `--headless` 之外的真实点击

不要把 headless 成功当作点击、拖动或焦点交互正常工作的证明。关于这一边界，请阅读 [references/headless-boundaries.md](references/headless-boundaries.md)。

本项目和 Godot 构建的重要边界：

- `--headless` 适用于场景加载验证
- `capture_scene.gd` 应使用真实显示驱动运行
- 捆绑的包装脚本 `scripts/run_capture_scene.py` 是截图捕获的首选方式

## 快速开始

### 1. 将截图辅助脚本同步到项目

运行：

```powershell
python .codex/skill/godot-headless/scripts/sync_capture_scene.py --project-root . --force
```

这会将捆绑的资产 `assets/godot/scripts/tools/capture_scene.gd` 复制到：

```text
scripts/tools/capture_scene.gd
```

### 2. 验证场景在 headless 模式下加载

```powershell
godot --headless --path <项目根目录> --scene res://scenes/<Scene>.tscn --quit-after 1
```

### 3. 捕获截图

```powershell
python .codex/skill/godot-headless/scripts/run_capture_scene.py --project-root . --scene res://scenes/<Scene>.tscn --output res://output/<name>.png --width 1280 --height 720
```

## 工作流程

1. 确认项目根目录和目标场景路径。
2. 如果 `scripts/tools/capture_scene.gd` 缺失或过时，用 `scripts/sync_capture_scene.py` 同步。
3. 先运行 headless 场景加载。
4. 如果场景加载成功，运行截图捕获包装脚本。
5. 报告使用的命令以及 headless 证明了什么或没能证明什么。

## 捆绑资源

### `scripts/sync_capture_scene.py`

将捆绑的 `capture_scene.gd` 复制到当前项目。在项目启动或编辑辅助脚本后刷新时使用。

### `scripts/run_capture_scene.py`

使用真实显示驱动和指定分辨率运行捕获辅助脚本。导出截图时使用此脚本而非 `--headless`。

### `assets/godot/scripts/tools/capture_scene.gd`

共享的 Godot 截图脚本。它：

- 读取命令行参数
- 通过 `SubViewport` 渲染目标场景
- 等待第一个稳定帧
- 捕获视口纹理
- 将 PNG 写入磁盘

### 项目本地交互探测

如果项目在 `scripts/tools/` 下添加了用于真实点击验证的运行时辅助工具，请在本 skill 中记录，而不是在 HTML 转换 skill 中。在本项目中，`scripts/tools/test_combat_hud_interactions.gd` 是示例：它运行窗口化场景，分发鼠标事件，捕获截图，并写入简短的验收报告。

### `references/headless-boundaries.md`

当用户过度依赖 headless 结果，或需要关于 headless 能验证和不能验证什么的准确措辞时阅读。

## 检测报错

当 headless 运行出现错误或场景加载失败时，优先查看以下日志文件：

- **`logs/editor.log`** — 编辑器运行日志，包含场景加载、资源解析、脚本编译等错误
- **`logs/godot.log`** — Godot 引擎主日志，包含引擎级错误、渲染警告、物理引擎报错等

使用 `Read` 工具或 `tail` 命令查看最新日志内容，定位错误原因。日志路径相对于项目根目录。

## 报错/警告处理流程

当用户说"有报错"、"有 warning"、"日志里有警告"或报告运行时错误/警告时，按以下流程处理：

### 第一步：查看日志定位问题

同时读取两个日志文件，找到最新的报错信息：

```bash
# 查看 editor.log 尾部（最近 100 行）
tail -100 logs/editor.log

# 查看 godot.log 尾部（最近 100 行）
tail -100 logs/godot.log
```

重点关注：
- `SCRIPT ERROR` / `Parse Error` — 脚本语法或运行时错误
- `ERROR:` — 引擎级错误
- `WARNING:` — 警告（通常不阻塞但值得关注）
- 堆栈跟踪中的文件路径和行号

### 第二步：分析并修复问题

根据日志中的错误信息：
1. 定位出错的脚本文件和行号
2. 分析错误原因
3. 实施修复

### 第三步：验证修复

修复后重新运行 headless 验证：

```bash
godot --headless --path . --scene res://scenes/<Scene>.tscn --quit-after 1
```

或使用 GodotIQ 工具检查：

```
godotiq_check_errors(scope="project")
```

### 第四步：清理日志中的报错/警告

确认问题已修复后，清理日志文件中已解决的报错和警告：

```bash
# 清空 editor.log
> logs/editor.log

# 清空 godot.log
> logs/godot.log
```

> **重要**：只有在确认问题已真正修复后才清理日志。清理日志的目的是让下次报错/警告时能快速定位新问题，不被旧信息干扰。

### 完整流程示例

```
用户: "有报错"
→ 读取 logs/editor.log 和 logs/godot.log
→ 找到报错：scripts/systems/deck_system.gd:42 - 空引用
→ 分析代码，发现手牌为空时未做边界检查
→ 修复代码，添加空值保护
→ 运行 godotiq_verify_project_runs 验证
→ 确认无新报错后，清空两个日志文件
→ 报告修复结果

用户: "log 里有 warning"
→ 读取 logs/editor.log 和 logs/godot.log
→ 找到警告：res://data/cards/warrior/heavy_strike.tres - 资源加载过时
→ 分析原因，发现 .tres 格式需要更新
→ 修复资源文件
→ 重新运行验证
→ 确认警告消除后，清空两个日志文件
→ 报告修复结果
```
