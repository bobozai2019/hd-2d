---
name: finishing-a-development-branch
description: 当实现完成、所有测试通过，且你需要决定如何集成工作时使用——通过展示合并、PR 或清理的结构化选项来引导完成开发工作
---

# 完成开发分支

## 概述

通过展示清晰的选项和处理所选工作流来引导完成开发工作。

**核心原则：** 验证测试 → 检测环境 → 展示选项 → 执行选择 → 清理。

**开始时宣布：** "我正在使用 finishing-a-development-branch 技能来完成这项工作。"

## 流程

### 步骤 1：验证测试

**在展示选项之前，验证测试通过：**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**如果测试失败：**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

停止。不要进入步骤 2。

**如果测试通过：** 继续步骤 2。

### 步骤 2：检测环境

**在展示选项之前确定工作空间状态：**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

这决定了显示哪个菜单以及清理如何工作：

| 状态 | 菜单 | 清理 |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON`（普通仓库） | 标准 4 个选项 | 无需清理 worktree |
| `GIT_DIR != GIT_COMMON`，命名分支 | 标准 4 个选项 | 基于来源（见步骤 6） |
| `GIT_DIR != GIT_COMMON`，分离 HEAD | 精简 3 个选项（无合并） | 无需清理（外部管理） |

### 步骤 3：确定基础分支

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

或询问："这个分支从 main 分出来的——对吗？"

### 步骤 4：展示选项

**普通仓库和命名分支 worktree — 展示以下 4 个选项：**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**分离 HEAD — 展示以下 3 个选项：**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**不要添加解释** — 保持选项简洁。

### 步骤 5：执行选择

#### 选项 1：本地合并

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
```

然后：清理 worktree（步骤 6），然后删除分支：

```bash
git branch -d <feature-branch>
```

#### 选项 2：推送并创建 PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**不要清理 worktree** — 用户需要它来迭代 PR 反馈。

#### 选项 3：保持原样

报告："保持分支 <name>。Worktree 保留在 <path>。"

**不要清理 worktree。**

#### 选项 4：丢弃

**先确认：**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

等待精确确认。

如果确认：
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

然后：清理 worktree（步骤 6），然后强制删除分支：
```bash
git branch -D <feature-branch>
```

### 步骤 6：清理工作空间

**仅对选项 1 和 4 执行。** 选项 2 和 3 始终保留 worktree。

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**如果 `GIT_DIR == GIT_COMMON`：** 普通仓库，无需清理 worktree。完成。

**如果 worktree 路径在 `.worktrees/`、`worktrees/` 或 `~/.config/superpowers/worktrees/` 下：** Superpowers 创建了这个 worktree——我们负责清理。

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**否则：** 宿主环境（harness）拥有这个工作空间。不要移除它。如果你的平台提供了 workspace-exit 工具，请使用它。否则，保留工作空间。

## 快速参考

| 选项 | 合并 | 推送 | 保留 Worktree | 清理分支 |
|--------|-------|------|---------------|----------------|
| 1. 本地合并 | 是 | - | - | 是 |
| 2. 创建 PR | - | 是 | 是 | - |
| 3. 保持原样 | - | - | 是 | - |
| 4. 丢弃 | - | - | - | 是（强制） |

## 常见错误

**跳过测试验证**
- **问题：** 合并损坏的代码，创建失败的 PR
- **修复：** 在提供选项之前始终验证测试

**开放式问题**
- **问题：** "我接下来该做什么？" 模糊不清
- **修复：** 精确展示 4 个结构化选项（分离 HEAD 为 3 个）

**对选项 2 清理 worktree**
- **问题：** 移除了用户需要用于 PR 迭代的 worktree
- **修复：** 仅对选项 1 和 4 清理

**在移除 worktree 之前删除分支**
- **问题：** `git branch -d` 失败，因为 worktree 仍然引用该分支
- **修复：** 先合并，移除 worktree，然后删除分支

**在 worktree 内部运行 git worktree remove**
- **问题：** 当 CWD 在被移除的 worktree 内部时命令静默失败
- **修复：** 在 `git worktree remove` 之前始终 `cd` 到主仓库根目录

**清理 harness 拥有的 worktree**
- **问题：** 移除 harness 创建的 worktree 导致幽灵状态
- **修复：** 仅清理 `.worktrees/`、`worktrees/` 或 `~/.config/superpowers/worktrees/` 下的 worktree

**丢弃时无确认**
- **问题：** 意外删除工作成果
- **修复：** 要求输入 "discard" 确认

## 红线

**绝不：**
- 在测试失败时继续
- 未在结果上验证测试就合并
- 未确认就删除工作成果
- 未明确要求就强制推送
- 未确认合并成功就移除 worktree
- 清理非你创建的 worktree（来源检查）
- 在 worktree 内部运行 `git worktree remove`

**始终：**
- 在提供选项之前验证测试
- 在展示菜单之前检测环境
- 精确展示 4 个选项（分离 HEAD 为 3 个）
- 对选项 4 获取输入确认
- 仅对选项 1 和 4 清理 worktree
- 在移除 worktree 前 `cd` 到主仓库根目录
- 移除后运行 `git worktree prune`
