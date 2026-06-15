# AGENTS.MD

本文件为在此 Godot 项目中工作的 AI 编码代理提供仓库级别的指引。

## 项目概述

这是一个 Godot 4.6 HD-2D 技术验证项目。目标是在 Godot 中复刻八方旅人风格的 HD-2D 渲染效果（3D 地图 + 2D 像素角色 + 光影后处理）。

当前处于早期阶段：已完成基础相机控制和角色动画 Sprite3D。

完整架构参考请见 `CLAUDE.md`。本文件是日常代理工作的简明操作指南。

## 仓库目录

- `project.godot` — Godot 项目配置。主场景为 `res://scenes/map3d/hd2d_effect_lab.tscn`。
- `scripts/map3d/` — HD-2D 相关脚本（相机控制、角色动画等）。
- `scenes/map3d/` — HD-2D 场景文件。
- `scenes/map3d/characters/` — 角色 Sprite3D 场景。
- `assets/generated/` — 生成的美术资源（角色动画帧等）。
- `docs/` — 技术文档和参考。
- `tasks/` — 任务计划和 PRD。
- `addons/` — Godot 插件（godotiq、godot_editor_logger、scene_bundle）。
- `.codex/skills/` 和 `.agents/skills/` — 项目本地代理工作流。当任务匹配其触发条件时使用。

## 代理工作流要求

- 编辑前先阅读相关已有代码。匹配本地模式，不要引入新风格。
- 保留用户的工作区变更。工作树可能有未提交的改动；除非明确要求，不要 reset、checkout 或还原文件。
- 保持编辑聚焦于所请求的行为变更。除非正确性需要，否则避免大范围重构。
- 优先使用 `rg` / `rg --files` 进行仓库搜索。
- 宣称完成之前，运行最小范围的有效验证命令并报告执行结果。
- 遇到 bug 或测试失败时，先定位根因再修改代码。
- 创意性功能开发或较大规模的实现工作，应使用 `.agents/skills/` 或 `.codex/skills/` 中匹配的项目技能。
- 当前仓库禁用所有 `superpowers` 相关 skills。凡是来源于 `obra/superpowers` 或名称包含 `using-superpowers`、`test-driven-development`、`systematic-debugging`、`writing-plans`、`executing-plans`、`subagent-driven-development`、`verification-before-completion`、`finishing-a-development-branch`、`using-git-worktrees`、`requesting-code-review`、`receiving-code-review`、`dispatching-parallel-agents`、`brainstorming`、`writing-skills` 的工作流，一律不要在本项目中触发或引用。

## 开发命令

在仓库根目录运行：

```bash
# 打开编辑器
godot -e

# Headless 项目加载检查
godot --headless --quit

# 使用 GodotIQ 工具验证场景
# godotiq_check_errors / godotiq_verify_project_runs
```

没有单独的构建步骤、包管理器或 lint 命令。验证方式主要是 Godot headless 加载检查、项目脚本、截图以及针对性的手动场景检查。

## GDScript 规范

- 使用兼容 Godot 4.6 的 GDScript。
- 文件名和变量使用 `snake_case`。
- 有 `class_name` 的命名类使用 `PascalCase`。
- 场景私有节点引用使用 `@onready var _name: Type = $Path/To/Node`。
- 私有辅助方法和字段以 `_` 前缀命名。
- 信号命名使用过去式或与附近代码一致的事件风格，如 `position_changed`、`animation_finished`。
- 跨文件类型引用**必须**用 `preload()` 常量，禁止直接用 `class_name` 作类型注解。
- 注释保持简洁有用。解释非显而易见的规则交互，而非常规赋值。
- 仅在 Godot 确实需要或属于已编辑资源流程时，才保留生成的 `.uid` / `.import` 文件。

## 验证指引

根据修改范围选择验证方式：

- 项目整体完整性：`godot --headless --quit`
- 脚本编译/运行时错误：使用 GodotIQ `godotiq_check_errors` / `godotiq_verify_project_runs`
- 调试阶段报错：优先读取 `logs/godot.log`

如果因环境中 PATH 未配置 Godot 或缺少依赖而无法运行命令，请在最终回复中如实说明。

## 文件和 Git 卫生

- 除非用户要求，否则不要提交。
- 除非任务明确涉及，否则不要将 `.godot/`、日志、截图或生成的 import 文件作为代码变更的一部分修改。
- 不要仅因为看起来未使用就删除文档或资源文件。
- 新的项目文档保持简洁和可操作。
