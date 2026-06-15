---
name: receiving-code-review
description: 收到代码审查反馈后、实施建议之前使用，特别是当反馈不清楚或技术上可疑时——要求技术严谨和验证，而不是表演性同意或盲目实施
---

# 代码审查接收

## 概述

代码审查需要技术评估，而不是情感表演。

**核心原则：** 实施前验证。假设前询问。技术正确性高于社交舒适度。

## 响应模式

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## 禁止的响应

**绝不：**
- "你说得完全对！"（明确违反 CLAUDE.md）
- "好观点！" / "优秀的反馈！"（表演性的）
- "让我现在就实施"（验证之前）

**应该：**
- 重述技术需求
- 提出澄清问题
- 如果错误则用技术理由反驳
- 直接开始工作（行动 > 言语）

## 处理不清楚的反馈

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**示例：**
```
你的人类搭档: "修复 1-6"
你理解 1,2,3,6。对 4,5 不清楚。

❌ 错误：现在实施 1,2,3,6，稍后再问 4,5
✅ 正确："我理解了 1,2,3,6 项。在继续之前需要对 4 和 5 进行澄清。"
```

## 不同来源的处理

### 来自你的人类搭档
- **可信** - 理解后实施
- **范围不清楚时仍要询问**
- **不要表演性同意**
- **直接行动** 或技术性确认

### 来自外部审查者
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with your human partner's prior decisions:
  Stop and discuss with your human partner first
```

**你的人类搭档的规则：** "外部反馈——保持怀疑，但仔细检查"

## 对"专业"功能的 YAGNI 检查

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**你的人类搭档的规则：** "你和审查者都向我汇报。如果我们不需要这个功能，就不要添加。"

## 实施顺序

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## 何时反驳

在以下情况反驳：
- 建议破坏现有功能
- 审查者缺乏完整上下文
- 违反 YAGNI（未使用的功能）
- 对此技术栈技术上不正确
- 存在遗留/兼容性原因
- 与你的人类搭档的架构决策冲突

**如何反驳：**
- 使用技术推理，而不是防御性
- 提出具体问题
- 引用正在工作的测试/代码
- 如果是架构问题则让你的人类搭档参与

**如果不方便公开反驳，发出信号：** "Strange things are afoot at the Circle K"

## 确认正确的反馈

当反馈确实正确时：
```
✅ "已修复。[简要描述更改内容]"
✅ "好发现 - [具体问题]。已在 [位置] 修复。"
✅ [直接修复并在代码中展示]

❌ "你说得完全对！"
❌ "好观点！"
❌ "感谢发现！"
❌ "感谢 [任何东西]"
❌ 任何感恩表达
```

**为什么不表达感谢：** 行动说明一切。直接修复。代码本身表明你听到了反馈。

**如果你发现自己即将写出"感谢"：** 删除它。改为陈述修复内容。

## 优雅地纠正你的反驳

如果你反驳了但错了：
```
✅ "你是对的 - 我检查了 [X] 它确实 [Y]。现在实施。"
✅ "验证了这个，你是正确的。我最初的理解是错的，因为 [原因]。正在修复。"

❌ 长篇道歉
❌ 为你反驳的原因辩护
❌ 过度解释
```

事实性地陈述纠正然后继续。

## 常见错误

| 错误 | 修复 |
|---------|-----|
| 表演性同意 | 陈述需求或直接行动 |
| 盲目实施 | 先对照代码库验证 |
| 批量处理不测试 | 一次一个，每个都测试 |
| 假设审查者正确 | 检查是否破坏现有功能 |
| 避免反驳 | 技术正确性 > 舒适度 |
| 部分实施 | 先澄清所有项目 |
| 无法验证但仍继续 | 说明限制，请求指导 |

## 真实示例

**表演性同意（错误）：**
```
审查者: "移除遗留代码"
❌ "你说得完全对！让我移除那个..."
```

**技术验证（正确）：**
```
审查者: "移除遗留代码"
✅ "检查中... 构建目标是 10.15+，这个 API 需要 13+。需要遗留代码以保持向后兼容。当前实现的 bundle ID 错误 - 修复它还是放弃 13 之前的支持？"
```

**YAGNI（正确）：**
```
审查者: "实现带有数据库、日期过滤器、CSV 导出的完整指标跟踪"
✅ "搜索了代码库 - 没有任何地方调用这个端点。移除它（YAGNI）？还是有我遗漏的用法？"
```

**不清楚的项目（正确）：**
```
你的人类搭档: "修复 1-6 项"
你理解 1,2,3,6。对 4,5 不清楚。
✅ "理解了 1,2,3,6。在实施前需要对 4 和 5 进行澄清。"
```

## GitHub 话题回复

在 GitHub 上回复内联审查评论时，在评论话题中回复（`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`），而不是作为顶层 PR 评论。

## 底线

**外部反馈 = 需要评估的建议，不是需要服从的命令。**

验证。质疑。然后实施。

不要表演性同意。始终保持技术严谨。
