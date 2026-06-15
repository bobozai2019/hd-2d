---
name: requesting-code-review
description: 在完成任务、实现主要功能或合并前使用，用于验证工作是否符合要求
---

# 请求代码审查

派遣代码审查子代理，在问题扩散之前捕获它们。审查者会收到精心构建的评估上下文 -- 绝不是你当前会话的历史记录。这能让审查者专注于工作产出而非你的思维过程，同时保留你自己的上下文以继续工作。

**核心原则：** 早审查，勤审查。

## 何时请求审查

**强制要求：**
- 在子代理驱动开发中每个任务完成后
- 完成主要功能后
- 合并到 main 分支前

**可选但有价值：**
- 卡住时（获得新视角）
- 重构前（基线检查）
- 修复复杂 bug 后

## 如何请求

**1. 获取 git SHA：**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # 或 origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. 派遣代码审查子代理：**

使用 Task 工具，类型为 `general-purpose`，填写 `code-reviewer.md` 中的模板

**占位符：**
- `{DESCRIPTION}` - 你构建内容的简要概述
- `{PLAN_OR_REQUIREMENTS}` - 它应该做什么
- `{BASE_SHA}` - 起始提交
- `{HEAD_SHA}` - 结束提交

**3. 根据反馈行动：**
- 立即修复严重问题
- 继续之前修复重要问题
- 记录次要问题留待后续处理
- 如果审查者有误，提出反驳（附上理由）

## 示例

```
[刚完成任务 2：添加验证函数]

You: 继续之前先请求代码审查。

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[派遣代码审查子代理]
  DESCRIPTION: 添加了 verifyIndex() 和 repairIndex()，包含 4 种问题类型
  PLAN_OR_REQUIREMENTS: 来自 docs/superpowers/plans/deployment-plan.md 的任务 2
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[子代理返回]:
  优点: 架构清晰，测试真实
  问题:
    重要: 缺少进度指示器
    次要: 报告间隔使用了魔法数字 (100)
  评估: 可以继续

You: [修复进度指示器]
[继续任务 3]
```

## 与工作流集成

**子代理驱动开发：**
- 每个任务后审查
- 在问题复合之前捕获
- 继续下一个任务前修复

**执行计划：**
- 每个任务后或在自然检查点审查
- 获取反馈，应用，继续

**临时开发：**
- 合并前审查
- 卡住时审查

## 红线

**绝不：**
- 因为"很简单"就跳过审查
- 忽略严重问题
- 在未修复重要问题的情况下继续
- 与有效的技术反馈争论

**如果审查者有误：**
- 用技术理由反驳
- 展示代码/测试证明其有效
- 请求澄清

模板位置：requesting-code-review/code-reviewer.md
