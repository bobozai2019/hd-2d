---
name: dispatching-parallel-agents
description: 面对 2 个以上可以在没有共享状态或顺序依赖的情况下独立处理的任务时使用
---

# 调度并行代理

## 概述

你将任务委派给具有隔离上下文的专用代理。通过精确地构建他们的指令和上下文，你确保他们保持专注并成功完成任务。他们不应该继承你当前会话的上下文或历史——你只构建他们需要的内容。这也为你自己的协调工作保留了上下文。

当你有多个不相关的故障（不同的测试文件、不同的子系统、不同的 bug）时，按顺序调查会浪费时间。每个调查都是独立的，可以并行进行。

**核心原则：** 每个独立问题域调度一个代理。让他们并发工作。

## 何时使用

```dot
digraph when_to_use {
    "Multiple failures?" [shape=diamond];
    "Are they independent?" [shape=diamond];
    "Single agent investigates all" [shape=box];
    "One agent per problem domain" [shape=box];
    "Can they work in parallel?" [shape=diamond];
    "Sequential agents" [shape=box];
    "Parallel dispatch" [shape=box];

    "Multiple failures?" -> "Are they independent?" [label="yes"];
    "Are they independent?" -> "Single agent investigates all" [label="no - related"];
    "Are they independent?" -> "Can they work in parallel?" [label="yes"];
    "Can they work in parallel?" -> "Parallel dispatch" [label="yes"];
    "Can they work in parallel?" -> "Sequential agents" [label="no - shared state"];
}
```

**适用场景：**
- 3 个以上测试文件因不同根本原因失败
- 多个子系统独立损坏
- 每个问题无需其他问题的上下文即可理解
- 调查之间没有共享状态

**不适用场景：**
- 故障相互关联（修复一个可能修复其他）
- 需要理解完整的系统状态
- 代理之间会相互干扰

## 模式

### 1. 识别独立域

按损坏内容对故障分组：
- 文件 A 测试：工具审批流程
- 文件 B 测试：批量完成行为
- 文件 C 测试：中止功能

每个域都是独立的——修复工具审批不会影响中止测试。

### 2. 创建聚焦的代理任务

每个代理获得：
- **具体范围：** 一个测试文件或子系统
- **清晰目标：** 让这些测试通过
- **约束条件：** 不要更改其他代码
- **预期输出：** 发现和修复内容的摘要

### 3. 并行调度

```typescript
// In Claude Code / AI environment
Task("Fix agent-tool-abort.test.ts failures")
Task("Fix batch-completion-behavior.test.ts failures")
Task("Fix tool-approval-race-conditions.test.ts failures")
// All three run concurrently
```

### 4. 审查和集成

代理返回时：
- 阅读每个摘要
- 验证修复不冲突
- 运行完整测试套件
- 集成所有更改

## 代理提示结构

好的代理提示是：
1. **聚焦的** - 一个清晰的问题域
2. **自包含的** - 理解问题所需的所有上下文
3. **输出明确的** - 代理应该返回什么？

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
3. "should properly track pendingToolCount" - expects 3 results but gets 0

These are timing/race condition issues. Your task:

1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do NOT just increase timeouts - find the real issue.

Return: Summary of what you found and what you fixed.
```

## 常见错误

**❌ 过于宽泛：** "修复所有测试" - 代理会迷失方向
**✅ 具体明确：** "修复 agent-tool-abort.test.ts" - 聚焦的范围

**❌ 缺乏上下文：** "修复竞态条件" - 代理不知道在哪里
**✅ 提供上下文：** 粘贴错误消息和测试名称

**❌ 没有约束：** 代理可能会重构所有内容
**✅ 设置约束：** "不要更改生产代码"或"只修复测试"

**❌ 输出模糊：** "修复它" - 你不知道改了什么
**✅ 输出明确：** "返回根本原因和更改内容的摘要"

## 何时不应使用

**相关故障：** 修复一个可能修复其他——先一起调查
**需要完整上下文：** 理解需要看到整个系统
**探索性调试：** 你还不知道什么坏了
**共享状态：** 代理会相互干扰（编辑相同文件、使用相同资源）

## 真实会话示例

**场景：** 重大重构后 3 个文件中有 6 个测试失败

**故障：**
- agent-tool-abort.test.ts：3 个失败（时序问题）
- batch-completion-behavior.test.ts：2 个失败（工具未执行）
- tool-approval-race-conditions.test.ts：1 个失败（执行计数 = 0）

**决策：** 独立域——中止逻辑独立于批量完成，独立于竞态条件

**调度：**
```
Agent 1 → Fix agent-tool-abort.test.ts
Agent 2 → Fix batch-completion-behavior.test.ts
Agent 3 → Fix tool-approval-race-conditions.test.ts
```

**结果：**
- 代理 1：用基于事件的等待替换了超时
- 代理 2：修复了事件结构 bug（threadId 位置错误）
- 代理 3：添加了等待异步工具执行完成的逻辑

**集成：** 所有修复独立，无冲突，完整测试套件通过

**节省的时间：** 3 个问题并行解决 vs 顺序解决

## 核心优势

1. **并行化** - 多个调查同时进行
2. **聚焦** - 每个代理范围狭窄，需要跟踪的上下文更少
3. **独立性** - 代理之间不相互干扰
4. **速度** - 3 个问题在 1 个问题的时间内解决

## 验证

代理返回后：
1. **审查每个摘要** - 了解改了什么
2. **检查冲突** - 代理是否编辑了相同的代码？
3. **运行完整套件** - 验证所有修复协同工作
4. **抽查** - 代理可能会犯系统性错误

## 实际影响

来自调试会话（2025-10-03）：
- 3 个文件中有 6 个失败
- 3 个代理并行调度
- 所有调查并发完成
- 所有修复成功集成
- 代理更改之间零冲突
