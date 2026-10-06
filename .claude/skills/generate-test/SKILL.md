---
name: generate-test
description: 在为 GDScript 文件生成测试脚本、请求测试覆盖率或描述需要验证的业务场景时使用。结合 GodotIQ MCP 分析与现有测试模式
---

# 生成测试

## 概述

使用 GodotIQ MCP 分析自动为 Godot GDScript 文件生成测试脚本。支持两种模式：代码驱动（白盒测试）和业务驱动（场景测试）。

## 何时使用

- 新的 `.gd` 文件添加到 `scripts/systems/` 或 `scripts/state/`
- 现有 `.gd` 文件有大量功能变更（3+ 个函数被添加或修改）
- 用户请求为特定文件或目录生成测试
- 用户描述需要测试覆盖率的业务场景

## 命令格式

```bash
# 基本用法
/generate-test scripts/systems/card_resolution_system.gd

# 指定测试类型
/generate-test scripts/systems/deck_system.gd --type unit,integration

# 批量生成
/generate-test scripts/battle/ --all

# 业务驱动模式
/generate-test --business "Player AP decreases after card use"
```

## 模式

### 模式 A：代码驱动（白盒测试）

**触发：** 新增/修改的 `.gd` 或 `.tscn` 文件

**流程：**
0. **Pre-flight 验证** — 运行 Stage A 基础设施检查。A1/A2 BLOCKER → 停止并报告。
1. 使用 `godotiq_file_context` 获取函数列表 → 运行 Stage B 检查（B1/B2/B4）。BLOCKER → 报告并提供替代方案。
2. 使用 `godotiq_dependency_graph` 识别依赖 → 运行 Stage B 检查（B3/B5/B6）。BLOCKER → 报告。
3. 使用 `godotiq_signal_map` 获取信号连接
4. 基于函数签名生成测试用例（仅对未被 BLOCKER 的测试类型）
5. 使用 `godotiq_validate` 验证生成的脚本

### 模式 B：业务驱动（场景测试）

**触发：** 用户描述业务场景

**流程：**
0. **Pre-flight 验证** — 运行 Stage A 基础设施检查（A1 必须通过）。
1. 用户描述场景（例如"玩家使用卡牌后 AP 减少"）
2. 使用 `godotiq_run` 启动游戏 → B7 检查：游戏已在运行则 WARNING 继续，无法启动则停止并报告
3. 使用 `godotiq_input` 模拟玩家操作
4. 使用 `godotiq_state_inspect` 检查运行时状态
5. 使用 `godotiq_screenshot` 捕获截图
6. 基于结果生成测试用例
7. 使用 `godotiq_run(action='stop')` 停止游戏

## Pre-flight 验证

在生成测试之前，执行 Pre-flight 检查以检测客观阻塞项。**核心原则：绝不生成缺流程或 mock 主逻辑的不合格测试。**

### Stage A — 基础设施检查（运行一次）

| ID | 检查项 | 方法 | 严重度 |
|----|--------|------|--------|
| A1 | GodotIQ MCP 工具可用 | 检查 `godotiq_file_context` 是否在 MCP 工具列表中 | BLOCKER |
| A2 | 目标文件存在 | 验证 `.gd`/`.tscn` 文件在磁盘上存在 | BLOCKER |
| A3 | 输出目录可写 | 验证 `scripts/tools/` 存在或可创建 | WARNING |

**A1/A2 失败 → 立即停止，不进入 Stage B。**

### Stage B — 文件结构检查（逐文件，复用分析数据，不增加 MCP 调用）

| ID | 检查项 | 检测方法 | 严重度 |
|----|--------|----------|--------|
| B1 | 有可测试 API | `godotiq_file_context`：≥1 个公共函数（非 `_` 前缀），或 Resource 子类有 `@export` 属性 | BLOCKER |
| B2 | Node 基类依赖 | 检查 `extends` 行：**排除法**——如果 `extends` 的类型不是 RefCounted/Resource/Object/SceneTree，则为 Node 派生类型（unit/integration 模板均调用 `.new()` 且无场景树，对 Node 派生类型均会失败） | BLOCKER(unit+integration) / WARNING(runtime+visual) |
| B3 | Autoload 依赖 | 解析 `project.godot` 的 `[autoload]` 获取名称 → **word-boundary 匹配**目标文件（避免子串误匹配）+ 检查 `get_node("/root/{name}")` 模式。如 autoload 是 `.tscn`，需解析场景根脚本检查 `create_default()`；无法解析时降级为 WARNING | BLOCKER(unit) / WARNING(integration) |
| B4 | DisplayServer 依赖 | 检查文件是否引用 `DisplayServer`/`RenderingServer`。如有 headless fallback 逻辑则仅为 WARNING | WARNING |
| B5 | 循环 import | 从 `godotiq_dependency_graph` 输出构建有向图，DFS 检测环路 | BLOCKER |
| B6 | 依赖可解析 | 枚举目标文件中所有 `preload("res://...")`、`load("res://...")`、`ResourceLoader.load("res://...")` 字面路径，验证每个文件存在。非字面路径（变量/拼接）无法验证，发出 WARNING | BLOCKER |
| B7 | 游戏可启动（仅 Mode B） | `godotiq_run(action="play")` → 等待 3-5 秒 → 检查 `godotiq_state_inspect` 有无致命错误 → 立即 `godotiq_run(action="stop")` | BLOCKER |

**B1 细化：**
- Resource 子类无函数但有 `@export` 属性 → B1 通过，生成属性默认值测试
- 纯静态函数类 → B1 通过，模板适配为 `TargetScript.static_func()` 而非实例化
- 含 `await` 的公共函数 → B1 通过但附带 WARNING：异步行为无法用当前同步模板测试，仅生成同步方法的测试

**B7 注意事项：**
- 如游戏已在运行，视为 WARNING（"游戏已在运行，假定可以启动"），不触发 BLOCKER
- B7 有副作用（启动 Godot 运行时），仅在 Mode B 执行

### Blocker 报告格式

```
Preflight: {target}

BLOCKERS ({count}):
  [{ID}] {标题}
    证据: {在代码/分析中发现了什么}
    影响: {哪些测试类型被阻塞}
    建议: {具体下一步操作}

WARNINGS ({count}):
  [{ID}] {标题}
    {上下文}

{决策提示或采取的操作}
```

### 执行规则

1. Stage A 先执行。A1/A2 为 BLOCKER → 立即停止。
2. Stage B 逐文件执行，在分析数据可用后运行。
3. 单文件有 BLOCKER → 呈现报告，通过 AskUserQuestion 提供固定选项菜单。
4. 批量模式 → 跳过阻塞文件，生成其余。**若任意连续 3 个文件对所有请求的测试类型均为 BLOCKER（无可生成的测试类型），暂停询问用户是否继续。**
5. 业务模式 B7 失败 → 全部停止。
6. **绝不为 B1/B2/B5/B6 BLOCKER 的文件生成对应测试类型。**
7. **绝不静默 mock 核心逻辑来绕过 BLOCKER。** mock 分类见下表。
8. Pre-flight 通过时静默继续，不输出额外信息。

### Mock 分类规则

| 类别 | 示例 | 是否允许 | 注释要求 |
|------|------|----------|----------|
| 测试基础设施 | 工厂方法（`create_default()`）、默认值设置、helper 初始化 | 允许 | 无需注释 |
| 依赖替换 | 用本地实例替换 autoload、注入 mock 依赖 | 允许 | 必须标注：`# MOCK: autoload {name} 不可用，使用本地实例` |
| 行为绕过 | 跳过 `_ready()`、stub 信号连接 | 允许 | 必须标注：`# MOCK: {函数/行为} 被绕过，原因: {BLOCKER ID}` |
| 逻辑替换 | 用简化算法替换核心业务逻辑 | **禁止** | 必须报告 BLOCKER，不得生成测试 |

### AskUserQuestion 固定选项菜单

当单文件出现 BLOCKER 时，**只能**提供以下选项（不可自行扩展）：

- **选项 1**: 仅生成集成/运行时测试（跳过被阻塞的测试类型）——**仅当集成/运行时模板确实可用时才提供此选项**（B2 BLOCKER 时 integration 模板同样不可用，此时选项 1 应改为"仅生成运行时测试"；若所有模板均不可用则不提供此选项）
- **选项 2**: 跳过此文件
- **选项 3**: 展示详细阻塞分析

问题文本必须包含具体 BLOCKER ID（如 "B2: Node 基类依赖, B3: Autoload 无工厂方法"）。

### 缓存交互

Stage B 检查从缓存分析数据中重新推导，每次调用都执行。Blocker 状态不缓存（因为 blocker 判定取决于请求的测试类型）。

## 测试类型选择

| 文件模式 | 测试类型 |
|----------|----------|
| `scripts/systems/*.gd` | 单元 + 集成 |
| `scripts/state/*.gd` | 单元 |
| `scripts/battle/*.gd` | 集成 + 运行时 |
| `scenes/**/*.tscn` | 视觉 |
| `scripts/ui/*.gd` | 视觉 + 运行时 |

使用 `--type` 选项覆盖。

## 缓存系统

分析结果缓存到 `.claude/knowledge/test_context/`：

```json
{
  "file": "scripts/systems/deck_system.gd",
  "functions": ["draw_cards", "shuffle_discard"],
  "dependencies": ["BattleContext", "DeckState"],
  "signals": ["card_drawn", "deck_shuffled"],
  "last_analyzed": "2026-05-15"
}
```

**缓存失效：**
- 当文件在 `last_analyzed` 之后被修改时自动刷新
- 当依赖变更时标记为过期
- 使用 `--force-refresh` 强制刷新

## 输出

测试脚本保存到 `scripts/tools/`：
- 单元：`test_{system_name}.gd`
- 集成：`test_{system_name}_integration.gd`
- 视觉：`test_{scene_name}_visual.gd`
- 业务：`test_{description}.gd`

## 部分成功规则

当 Pre-flight 阻塞项阻止完整测试生成时：

**单文件：**
- 仅单元测试被阻塞（B2/B3）→ 生成集成/运行时测试
- 所有测试类型被阻塞 → 报告阻塞项，不生成任何文件
- **绝不静默降级**（不生成"名为单元测试但实际需要场景树"的测试）

**批量模式（--all）：**
- 为通过 Pre-flight 的文件生成测试
- 跳过阻塞文件，末尾汇总："已生成 N/M 文件，K 个文件被阻塞"
- 为阻塞文件提供逐文件建议和命令（如 `/generate-test card_ui.gd --type runtime`）

**业务驱动模式：**
- 无部分成功。游戏无法启动（B7）→ 全部停止。

## 快速参考

| 命令 | 描述 |
|------|------|
| `/generate-test file.gd` | 为单个文件生成测试 |
| `/generate-test dir/ --all` | 为目录批量生成 |
| `/generate-test --business "desc"` | 从业务场景生成 |
| `/generate-test file.gd --type unit` | 强制指定测试类型 |
| `/generate-test file.gd --force-refresh` | 忽略缓存，重新分析 |

## 示例

### 示例 1：为新系统生成单元测试

```bash
/generate-test scripts/systems/new_system.gd
```

输出：`scripts/tools/test_new_system.gd`

### 示例 2：生成集成测试

```bash
/generate-test scripts/systems/card_resolution_system.gd --type integration
```

输出：`scripts/tools/test_card_resolution_system_integration.gd`

### 示例 3：业务驱动测试

```bash
/generate-test --business "When player plays a card, AP decreases by card cost"
```

输出：`scripts/tools/test_card_ap_cost.gd`

### 示例 4：批量生成

```bash
/generate-test scripts/state/ --all
```

输出：`scripts/tools/` 中的多个测试文件

## 常见错误

1. **没有先检查缓存** - 在调用 GodotIQ 之前始终检查分析是否已缓存
2. **文件的测试类型错误** - 使用文件模式表选择适当的类型
3. **缺失依赖** - 使用 `godotiq_dependency_graph` 识别所有依赖
4. **缓存过期** - 检查 `last_analyzed` 与文件修改时间

## 故障排除

> **注意：** Pre-flight 验证阶段会在测试生成之前捕获大部分以下问题。如看到 BLOCKER 报告，请按报告中的建议操作，无需参考本节。

### GodotIQ 工具不可用

**症状：** 调用 GodotIQ MCP 工具时出错

**解决方案：**
1. 检查 Godot 中 GodotIQ 插件是否启用
2. 验证 MCP 服务器是否正在运行
3. 检查 Claude Code MCP 配置

### 缓存未更新

**症状：** 尽管文件已变更仍使用过期缓存

**解决方案：**
1. 使用 `--force-refresh` 选项
2. 检查文件修改时间
3. 手动删除缓存文件

### 生成的测试失败

**症状：** 生成的测试脚本无法运行

**解决方案：**
1. 检查 `godotiq_validate` 输出
2. 验证 preload 路径是否正确
3. 检查是否有缺失的依赖

## 实现

### GodotIQ 集成详情

#### 分析目标文件

使用以下 GodotIQ 工具分析目标文件：

1. **文件上下文分析**
   ```
   godotiq_file_context(file="scripts/systems/deck_system.gd", detail="full")
   ```
   返回：公共 API、依赖、信号、安全信息

2. **依赖图**
   ```
   godotiq_dependency_graph(file="scripts/systems/deck_system.gd", depth=2)
   ```
   返回：导入、监听器、autoloads

3. **信号映射**
   ```
   godotiq_signal_map(scope="file:res://scripts/systems/deck_system.gd")
   ```
   返回：发出的信号、连接的监听器

#### 生成测试用例

基于分析结果：

1. **对于每个公共函数：**
   - 为默认/空状态生成测试
   - 为正常操作生成测试
   - 为边界情况生成测试（空输入、边界值）

2. **对于每个信号：**
   - 生成验证信号发出的测试
   - 生成验证信号数据的测试

3. **对于每个依赖：**
   - 生成与依赖的集成测试

#### 缓存管理

在调用 GodotIQ 之前检查缓存：

1. 读取 `.claude/knowledge/test_context/{filename}.json`
2. 检查 `last_analyzed` 是否大于文件修改时间
3. 如果缓存有效，使用缓存数据
4. 如果缓存过期或缺失，调用 GodotIQ 并更新缓存

#### 验证生成的脚本

生成测试脚本后：

1. 使用 `godotiq_validate(target="scripts/tools/test_{name}.gd")`
2. 修复任何验证错误
3. 重新验证直到干净

---

参见 `templates/` 目录获取测试脚本模板。
参见 `examples/` 目录获取完整示例。
参见 `test_procedures.md` 了解验证流程。
