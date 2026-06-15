---
name: generate-test
description: 在为 GDScript 文件生成测试脚本、请求测试覆盖率或描述需要验证的业务场景时使用。结合 GodotIQ MCP 分析与现有测试模式
---

# 生成测试

## 概述

使用 GodotIQ MCP 分析自动为 Godot GDScript 文件生成测试脚本。支持两种模式：代码驱动（白盒测试）和业务驱动（场景测试）。

## 何时使用

- 新的 `.gd` 文件添加到项目脚本目录
- 现有 `.gd` 文件有大量功能变更（3+ 个函数被添加或修改）
- 用户请求为特定文件或目录生成测试
- 用户描述需要测试覆盖率的业务场景

## 命令格式

```bash
# 基本用法
/generate-test scripts/systems/some_system.gd

# 指定测试类型
/generate-test scripts/systems/my_system.gd --type unit,integration

# 批量生成
/generate-test scripts/battle/ --all

# 业务驱动模式
/generate-test --business "Player health decreases after enemy attack"
```

## 模式

### 模式 A：代码驱动（白盒测试）

**触发：** 新增/修改的 `.gd` 或 `.tscn` 文件

**流程：**
1. 使用 `godotiq_file_context` 获取函数列表
2. 使用 `godotiq_dependency_graph` 识别依赖
3. 使用 `godotiq_signal_map` 获取信号连接
4. 基于函数签名生成测试用例
5. 使用 `godotiq_validate` 验证生成的脚本

### 模式 B：业务驱动（场景测试）

**触发：** 用户描述业务场景

**流程：**
1. 用户描述场景（例如"玩家移动角色后位置更新"）
2. 使用 `godotiq_run` 启动游戏
3. 使用 `godotiq_input` 模拟玩家操作
4. 使用 `godotiq_state_inspect` 检查运行时状态
5. 使用 `godotiq_screenshot` 捕获截图
6. 基于结果生成测试用例
7. 使用 `godotiq_run(action='stop')` 停止游戏

## 测试类型选择

| 文件模式 | 测试类型 |
|----------|----------|
| `scripts/**/*.gd` | 单元 + 集成 |
| `scenes/**/*.tscn` | 视觉 |

使用 `--type` 选项覆盖。

## 缓存系统

分析结果缓存到 `.claude/knowledge/test_context/`：

```json
{
  "file": "scripts/systems/my_system.gd",
  "functions": ["draw_cards", "shuffle_discard"],
  "dependencies": ["GameContext", "PlayerState"],
  "signals": ["item_added", "state_changed"],
  "last_analyzed": "2026-05-15"
}
```

**缓存失效：**
- 当文件在 `last_analyzed` 之后被修改时自动刷新
- 当依赖变更时标记为过期
- 使用 `--force-refresh` 强制刷新

## 输出

测试脚本保存到 `scripts/autotest/`：
- 单元：`test_{system_name}.gd`
- 集成：`test_{system_name}_integration.gd`
- 视觉：`test_{scene_name}_visual.gd`
- 业务：`test_{description}.gd`

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

输出：`scripts/autotest/test_new_system.gd`

### 示例 2：生成集成测试

```bash
/generate-test scripts/systems/some_system.gd --type integration
```

输出：`scripts/autotest/test_some_system_integration.gd`

### 示例 3：业务驱动测试

```bash
/generate-test --business "When player takes damage, health decreases"
```

输出：`scripts/autotest/test_card_ap_cost.gd`

### 示例 4：批量生成

```bash
/generate-test scripts/state/ --all
```

输出：`scripts/autotest/` 中的多个测试文件

## 常见错误

1. **没有先检查缓存** - 在调用 GodotIQ 之前始终检查分析是否已缓存
2. **文件的测试类型错误** - 使用文件模式表选择适当的类型
3. **缺失依赖** - 使用 `godotiq_dependency_graph` 识别所有依赖
4. **缓存过期** - 检查 `last_analyzed` 与文件修改时间

## 故障排除

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
   godotiq_file_context(file="scripts/systems/my_system.gd", detail="full")
   ```
   返回：公共 API、依赖、信号、安全信息

2. **依赖图**
   ```
   godotiq_dependency_graph(file="scripts/systems/my_system.gd", depth=2)
   ```
   返回：导入、监听器、autoloads

3. **信号映射**
   ```
   godotiq_signal_map(scope="file:res://scripts/systems/my_system.gd")
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

1. 使用 `godotiq_validate(target="scripts/autotest/test_{name}.gd")`
2. 修复任何验证错误
3. 重新验证直到干净

---

参见 `templates/` 目录获取测试脚本模板。
参见 `examples/` 目录获取完整示例。
参见 `test_procedures.md` 了解验证流程。
