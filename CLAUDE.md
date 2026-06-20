# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4.6 项目 — HD-2D 技术验证项目。目标是在 Godot 中复刻八方旅人风格的 HD-2D 渲染效果（3D 地图 + 2D 像素角色 + 光影后处理）。

**当前阶段**：早期技术验证。已完成基础相机控制和角色动画 Sprite3D。

## Dev Commands

```bash
# 启动 Godot 编辑器（需要 Godot 4.6 在 PATH 中）
godot -e

# Headless 运行主场景（用于验证场景加载）
godot --headless --quit

# 使用 GodotIQ 工具验证场景
# godotiq_check_errors / godotiq_verify_project_runs
```

无构建步骤、无测试套件、无 lint。项目在 Godot 编辑器内通过 F5 运行。使用 GodotIQ MCP 工具进行编译检查和验证。

## 仓库目录

- `project.godot` — Godot 项目配置。主场景为 `res://scenes/map3d/hd2d_effect_lab.tscn`。
- `scripts/map3d/` — HD-2D 相关脚本（相机控制、角色动画等）。
- `scenes/map3d/` — HD-2D 场景文件。
- `scenes/map3d/characters/` — 角色 Sprite3D 场景。
- `assets/generated/` — 生成的美术资源（角色动画帧等）。
- `docs/` — 技术文档和参考。
- `docs/production/` — 量产规范（代码、UI、资产、仓库卫生）。
- `tasks/` — 任务计划和 PRD。
- `addons/` — Godot 插件（godotiq、godot_editor_logger、scene_bundle）。
- `.codex/skills/` 和 `.agents/skills/` — 项目本地代理工作流。当任务匹配其触发条件时使用。

### 文档规范

docs/ 目录结构：`hd2d/`（HD-2D 技术文档）、`production/`（量产规范）。

命名规则：
- 设计文档：`数字-中文标题.md`
- 计划文档：`YYYY-MM-DD-英文描述.md`

## 代理工作流要求

- 编辑前先阅读相关已有代码。匹配本地模式，不要引入新风格。
- 保留用户的工作区变更。工作树可能有未提交的改动；除非明确要求，不要 reset、checkout 或还原文件。
- 保持编辑聚焦于所请求的行为变更。除非正确性需要，否则避免大范围重构。
- 宣称完成之前，运行最小范围的有效验证命令并报告执行结果。
- 遇到 bug 或测试失败时，先定位根因再修改代码。
- 创意性功能开发、UI 转换或较大规模的实现工作，应使用 `.agents/skills/` 或 `.codex/skills/` 中匹配的项目技能。
- 当前仓库禁用所有 `superpowers` 相关 skills。凡是来源于 `obra/superpowers` 或名称包含 `using-superpowers`、`test-driven-development`、`systematic-debugging`、`writing-plans`、`executing-plans`、`subagent-driven-development`、`verification-before-completion`、`finishing-a-development-branch`、`using-git-worktrees`、`requesting-code-review`、`receiving-code-review`、`dispatching-parallel-agents`、`brainstorming`、`writing-skills` 的工作流，一律不要在本项目中触发或引用。

## Godot Project Config

- Renderer: **Forward Plus** (`rendering/renderer/rendering_method`)
- Physics: **Jolt Physics**
- Display: `canvas_items` stretch mode, `expand` aspect
- Window driver: `d3d12` (Windows)
- Main scene: `scenes/map3d/hd2d_effect_lab.tscn`
- Plugins: godotiq, godot_editor_logger, scene_bundle

## 代码规范

进入量产后，详细规范以 `docs/production/` 为准。以下是精简速查。

### 文件与目录命名

| 类型 | 规范 | 示例 |
|------|------|------|
| GDScript (.gd) | snake_case | `hd2d_effect_lab.gd` |
| 场景 (.tscn) | snake_case | `hd2d_effect_lab.tscn` |
| 数据 (.tres) | snake_case | `some_resource.tres` |
| 目录 | snake_case | `scripts/map3d/`, `scenes/map3d/` |

### 类声明

- **逻辑层**：根据需要声明 `class_name`，PascalCase
- **UI 脚本**（场景根节点）：不声明 `class_name`，匿名类 `extends Control`
- **工具脚本**：不声明 `class_name`，匿名类 `extends SceneTree`
- 跨文件类型引用**必须**用 `preload()` 常量，禁止直接用 `class_name` 作类型注解

```gdscript
# 正确
const SomeModuleScript = preload("res://scripts/some_module.gd")
var _module: SomeModuleScript

# 错误 — 循环引用
var _module: SomeModule
```

后缀约定：`Def`（资源定义）、`State`（可变状态）、`System`（逻辑系统）、`Context`（DI 容器）、`Events`（信号总线）、`Manager`（生命周期管理器）

### 变量命名

| 作用域 | 规范 | 示例 |
|--------|------|------|
| 公共字段 | snake_case，无前缀 | `var speed: float = 5.0` |
| 私有/内部字段 | `_` 前缀 | `var _camera: Camera3D` |
| 场景节点引用 | `@onready var _name: Type = $Path` | `@onready var _sprite: Sprite3D = $Sprite` |
| 常量（类型别名） | PascalCase | `const SomeScript = preload(...)` |
| 常量（数值） | SCREAMING_SNAKE_CASE | `const MAX_SPEED: float = 10.0` |

### 函数命名

| 类型 | 规范 | 示例 |
|------|------|------|
| 公共函数 | snake_case，动词开头 | `func setup(config) -> void:` |
| 私有函数 | `_` 前缀 | `func _update_camera() -> void:` |
| 信号回调 | `_on_` 前缀 | `func _on_input_event() -> void:` |
| Godot 生命周期 | 标准命名 | `func _ready() -> void:` |

- 所有函数**必须**声明返回类型（`-> void:`、`-> bool:`、`-> int:` 等）
- 公共 API 参数应添加类型提示

### 信号命名

- **过去式动词短语**，snake_case
- 禁止 `_signal` 或 `on_` 前缀

```gdscript
signal position_changed(new_pos)    # 正确
signal animation_finished()          # 正确
signal on_position_changed()         # 错误 — on_ 前缀
signal position_change()             # 错误 — 非过去式
```

### 注释规范

允许：区域分隔（`# --- Section ---`）、类型补充、分组标题、关键逻辑说明（WHY 不是 WHAT）

禁止：`##` docstring、多行文档块、解释"做什么"的注释、注释掉的代码

## 硬规则

### 禁止直接读图

**Claude Code 不得直接识别任何图片。** 包括但不限于：

1. **禁止**使用内置多模态能力直接分析粘贴到消息中的图片（base64 inline image）
2. **禁止**使用 Read 工具读取图片文件路径
3. **必须**调用 `mcp__image-recognition__image_recognize` 工具来识别图片

支持的图片格式：`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.bmp`, `.svg`, `.ico`, `.tga`

```bash
# 禁止 — 直接分析粘贴的图片
# 禁止 — 用 Read 工具读图片

# 正确 — 通过 MCP 服务识别
mcp__image-recognition__image_recognize(image="screenshot.png", prompt="描述图片内容")
```

**当用户粘贴图片并提问时，正确流程：**
1. 忽略消息中嵌入的图片数据
2. 将图片保存到临时文件（如果需要）
3. 调用 `mcp__image-recognition__image_recognize` 识别
4. 基于 MCP 返回结果回答用户

## 语言规范

**所有文档、技能（Skill）、命令（Command）、Hook 文件必须使用中文编写。**

- 设计文档、计划文档、PRD 等：正文用中文
- `.agents/skills/*/SKILL.md`：description 字段和正文用中文，保留 `name` 字段为英文
- `.claude/commands/*.md`：description 字段和正文用中文
- `.claude/hooks/*.md`：正文用中文
- `.claude/knowledge/*.md`：正文用中文
- 代码块（GDScript、bash、JSON 等）内容保持原样，不翻译
- 技术术语（如 HD-2D、MCP、TDD 等）保持英文
- 文件路径保持英文

## Knowledge Base

项目知识沉淀系统，从开发会话中捕获有价值的洞察，按领域分类存储在 `.claude/knowledge/`。

开始某领域工作前，检查对应分类文件获取先验知识：

- `.claude/knowledge/ui.md` — UI 模式、Control 节点决策
- `.claude/knowledge/conventions.md` — 代码风格和架构决策
- `.claude/knowledge/debugging.md` — 陷阱和调试技巧
- `.claude/knowledge/godot.md` — 引擎怪癖和 workaround
- `.claude/knowledge/INDEX.md` — 知识库索引

使用 `/remember` 捕获新洞察，`/recall` 按关键词搜索知识库。

## 验证指引

根据修改范围选择验证方式：

- 项目整体完整性：`godot --headless --quit`
- 脚本编译/运行时错误：使用 GodotIQ `godotiq_check_errors` / `godotiq_verify_project_runs`
- 调试阶段报错：优先读取 `logs/godot.log`。GodotIQ 调试控制台可能漏掉 Debug/F5 运行时的后台错误，尤其是用户说"点调试有报错"时，先看此日志再下结论。
- UI 布局/视觉验证：headless 场景加载或截图捕获

如果因环境中 PATH 未配置 Godot 或缺少依赖而无法运行命令，请在最终回复中如实说明。

## 文件和 Git 卫生

- 除非用户要求，否则不要提交。
- 除非任务明确涉及，否则不要将 `.godot/`、日志、截图或生成的 import 文件作为代码变更的一部分修改。
- 不要仅因为看起来未使用就删除文档或资源文件。
- 新的项目文档保持简洁和可操作。
- 仅在 Godot 确实需要或属于已编辑资源流程时，才保留生成的 `.uid` / `.import` 文件。
