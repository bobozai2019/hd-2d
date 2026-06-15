---
name: test-driven-development
description: 在实现任何功能或修复 bug 时使用，在编写实现代码之前
---

# 测试驱动开发 (TDD)

## 概述

先写测试。看它失败。写最少的代码让它通过。

**核心原则：** 如果你没看到测试失败，你就不知道它是否测试了正确的东西。

**违反规则的字面意思就是违反规则的精神。**

## 何时使用

**始终：**
- 新功能
- Bug 修复
- 重构
- 行为变更

**例外（询问你的人类伙伴）：**
- 一次性原型
- 生成的代码
- 配置文件

想着"就这一次跳过 TDD"？停下。那是合理化。

## 铁律

```
没有失败的测试，就不能写生产代码
```

在测试之前写了代码？删掉它。从头开始。

**无例外：**
- 不要保留作为"参考"
- 不要在写测试时"适配"它
- 不要看它
- 删除就是删除

从测试中全新实现。就这样。

## 红-绿-重构

```dot
digraph tdd_cycle {
    rankdir=LR;
    red [label="RED\nWrite failing test", shape=box, style=filled, fillcolor="#ffcccc"];
    verify_red [label="Verify fails\ncorrectly", shape=diamond];
    green [label="GREEN\nMinimal code", shape=box, style=filled, fillcolor="#ccffcc"];
    verify_green [label="Verify passes\nAll green", shape=diamond];
    refactor [label="REFACTOR\nClean up", shape=box, style=filled, fillcolor="#ccccff"];
    next [label="Next", shape=ellipse];

    red -> verify_red;
    verify_red -> green [label="yes"];
    verify_red -> red [label="wrong\nfailure"];
    green -> verify_green;
    verify_green -> refactor [label="yes"];
    verify_green -> green [label="no"];
    refactor -> verify_green [label="stay\ngreen"];
    verify_green -> next;
    next -> red;
}
```

### RED - 编写失败的测试

编写一个最小的测试来展示应该发生什么。

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
名称清晰，测试真实行为，只测一件事
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```
名称模糊，测试的是 mock 而不是代码
</Bad>

**要求：**
- 一个行为
- 清晰的名称
- 真实代码（除非不可避免，不用 mock）

### 验证 RED - 看它失败

**强制要求。绝不能跳过。**

```bash
npm test path/to/test.test.ts
```

确认：
- 测试失败（不是出错）
- 失败信息符合预期
- 因为功能缺失而失败（不是拼写错误）

**测试通过了？** 你在测试已有的行为。修改测试。

**测试出错了？** 修复错误，重新运行直到正确失败。

### GREEN - 最少代码

编写最简单的代码让测试通过。

<Good>
```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```
刚好够通过
</Good>

<Bad>
```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: {
    maxRetries?: number;
    backoff?: 'linear' | 'exponential';
    onRetry?: (attempt: number) => void;
  }
): Promise<T> {
  // YAGNI
}
```
过度工程
</Bad>

不要添加功能、重构其他代码或超出测试范围"改进"。

### 验证 GREEN - 看它通过

**强制要求。**

```bash
npm test path/to/test.test.ts
```

确认：
- 测试通过
- 其他测试仍然通过
- 输出干净（无错误、无警告）

**测试失败？** 修复代码，不是测试。

**其他测试失败？** 立即修复。

### REFACTOR - 清理

仅在绿灯后：
- 消除重复
- 改进命名
- 提取辅助函数

保持测试通过。不要添加行为。

### 重复

为下一个功能写下一个失败的测试。

## 好的测试

| 质量 | 好 | 坏 |
|------|-----|-----|
| **最小化** | 一件事。名称里有"and"？拆分它。 | `test('validates email and domain and whitespace')` |
| **清晰** | 名称描述行为 | `test('test1')` |
| **展示意图** | 演示期望的 API | 模糊代码应该做什么 |

## 为什么顺序很重要

**"我会在之后写测试来验证它能工作"**

在代码之后写的测试立即通过。立即通过证明不了什么：
- 可能测试了错误的东西
- 可能测试了实现而非行为
- 可能遗漏了你忘记的边界情况
- 你从未看到它捕获 bug

测试优先迫使你看到测试失败，证明它确实在测试什么。

**"我已经手动测试了所有边界情况"**

手动测试是临时性的。你以为你测试了一切但是：
- 没有测试内容的记录
- 代码变更时无法重新运行
- 压力下容易遗忘情况
- "我试的时候能工作" != 全面

自动化测试是系统性的。它们每次以相同方式运行。

**"删除 X 小时的工作是浪费"**

沉没成本谬误。时间已经过去了。你现在选择：
- 删除并用 TDD 重写（X 小时更多，高置信度）
- 保留并在之后添加测试（30 分钟，低置信度，可能有 bug）

"浪费"是保留你不信任的代码。没有真实测试的工作代码是技术债。

**"TDD 是教条主义，务实意味着灵活变通"**

TDD 就是务实的：
- 在提交前发现 bug（比之后调试更快）
- 防止回归（测试立即捕获破坏）
- 记录行为（测试展示如何使用代码）
- 启用重构（自由修改，测试捕获破坏）

"务实"的捷径 = 在生产环境调试 = 更慢。

**"之后的测试达到同样的目标 -- 重要的是精神不是仪式"**

不是。之后的测试回答"这做了什么？"优先的测试回答"这应该做什么？"

之后的测试受你的实现偏见影响。你测试了你构建的，而不是需要的。你验证了记住的边界情况，而不是发现的。

优先的测试在实现前强制发现边界情况。之后的测试验证你记住了一切（你没有）。

30 分钟的之后测试 != TDD。你获得了覆盖率，失去了测试有效的证明。

## 常见的合理化借口

| 借口 | 现实 |
|------|------|
| "太简单不用测试" | 简单代码也会坏。测试只需 30 秒。 |
| "我之后再测试" | 立即通过的测试证明不了什么。 |
| "之后的测试达到同样目标" | 之后的测试 = "这做了什么？"优先的测试 = "这应该做什么？" |
| "已经手动测试了" | 临时性 != 系统性。没有记录，无法重新运行。 |
| "删除 X 小时是浪费" | 沉没成本谬误。保留未验证的代码是技术债。 |
| "保留作为参考，先写测试" | 你会适配它。那就是之后测试。删除就是删除。 |
| "需要先探索" | 可以。丢弃探索成果，用 TDD 重新开始。 |
| "测试难写 = 设计不清晰" | 听测试的。难测试 = 难使用。 |
| "TDD 会让我变慢" | TDD 比调试更快。务实 = 测试优先。 |
| "手动测试更快" | 手动无法证明边界情况。每次改动都要重新测试。 |
| "现有代码没有测试" | 你在改进它。为现有代码添加测试。 |

## 红线 -- 停下并重新开始

- 在测试之前写代码
- 在实现之后写测试
- 测试立即通过
- 无法解释测试为何失败
- 测试"之后"才添加
- 合理化"就这一次"
- "我已经手动测试了"
- "之后的测试达到同样的目的"
- "重要的是精神不是仪式"
- "保留作为参考"或"适配现有代码"
- "已经花了 X 小时，删除是浪费"
- "TDD 是教条主义，我很务实"
- "这次不一样因为..."

**以上所有情况意味着：删除代码。用 TDD 从头开始。**

## 示例：Bug 修复

**Bug：** 接受了空邮箱

**RED**
```typescript
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});
```

**验证 RED**
```bash
$ npm test
FAIL: expected 'Email required', got undefined
```

**GREEN**
```typescript
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // ...
}
```

**验证 GREEN**
```bash
$ npm test
PASS
```

**REFACTOR**
如果需要，为多个字段提取验证逻辑。

## 验证清单

在标记工作完成前：

- [ ] 每个新函数/方法都有测试
- [ ] 实现前看到了每个测试失败
- [ ] 每个测试因预期原因失败（功能缺失，不是拼写错误）
- [ ] 编写了最少代码让每个测试通过
- [ ] 所有测试通过
- [ ] 输出干净（无错误、无警告）
- [ ] 测试使用真实代码（仅在不可避免时使用 mock）
- [ ] 覆盖了边界情况和错误

无法勾选所有项？你跳过了 TDD。从头开始。

## 卡住时

| 问题 | 解决方案 |
|------|----------|
| 不知道如何测试 | 编写期望的 API。先写断言。询问你的人类伙伴。 |
| 测试太复杂 | 设计太复杂。简化接口。 |
| 必须 mock 所有东西 | 代码耦合太紧。使用依赖注入。 |
| 测试设置代码太多 | 提取辅助函数。仍然复杂？简化设计。 |

## 调试集成

发现 bug？编写复现它的失败测试。遵循 TDD 循环。测试证明修复并防止回归。

永远不要在没有测试的情况下修复 bug。

## 测试反模式

在添加 mock 或测试工具时，阅读 @testing-anti-patterns.md 以避免常见陷阱：
- 测试 mock 行为而非真实行为
- 在生产类中添加仅测试用的方法
- 在不理解依赖的情况下 mock

## 最终规则

```
生产代码 --> 测试存在且先失败
否则 --> 不是 TDD
```

未经你的人类伙伴许可，无例外。
