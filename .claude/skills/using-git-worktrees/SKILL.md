---
name: using-git-worktrees
description: 在开始需要与当前工作空间隔离的功能开发或执行实施计划前使用 - 通过原生工具或 git worktree 回退确保隔离工作空间存在
---

# 使用 Git Worktree

确保工作在隔离的工作空间中进行。优先使用你平台的原生 worktree 工具。仅在没有原生工具可用时才回退到手动 git worktree。

**核心原则：** 先检测现有隔离。然后使用原生工具。然后回退到 git。不要与工具框架对抗。

**开始时声明：** "我正在使用 using-git-worktrees 技能来设置隔离工作空间。"

## 步骤 0：检测现有隔离

**在创建任何东西之前，检查你是否已在隔离工作空间中。**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**子模块守卫：** `GIT_DIR != GIT_COMMON` 在 git 子模块内部也为 true。在得出"已在 worktree 中"的结论前，验证你不在子模块中：

```bash
# 如果返回路径，说明你在子模块中，不是 worktree -- 视为普通仓库
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**如果 `GIT_DIR != GIT_COMMON`（且不是子模块）：** 你已在链接的 worktree 中。跳到步骤 3（项目设置）。不要创建另一个 worktree。

报告分支状态：
- 在分支上："已在隔离工作空间 `<path>`，分支 `<name>`。"
- 游离 HEAD："已在隔离工作空间 `<path>`（游离 HEAD，外部管理）。完成时需要创建分支。"

**如果 `GIT_DIR == GIT_COMMON`（或在子模块中）：** 你在普通仓库检出中。

用户是否已在你的指令中表明了 worktree 偏好？如果没有，创建 worktree 前先征求同意：

> "你希望我设置隔离的 worktree 吗？它可以保护你当前分支免受变更。"

尊重任何已声明的偏好，无需询问。如果用户拒绝同意，就在原地工作并跳到步骤 3。

## 步骤 1：创建隔离工作空间

**你有两种机制。按此顺序尝试。**

### 1a. 原生 Worktree 工具（首选）

用户要求了隔离工作空间（步骤 0 的同意）。你是否已有创建 worktree 的方式？它可能是一个名为 `EnterWorktree`、`WorktreeCreate` 的工具，或一个 `/worktree` 命令，或一个 `--worktree` 标志。如果有，使用它并跳到步骤 3。

原生工具自动处理目录放置、分支创建和清理。当你有原生工具时使用 `git worktree add` 会创建你的工具框架看不到或无法管理的幽灵状态。

仅在没有原生 worktree 工具可用时才进入步骤 1b。

### 1b. Git Worktree 回退

**仅在步骤 1a 不适用时使用** -- 你没有原生 worktree 工具可用。使用 git 手动创建 worktree。

#### 目录选择

遵循此优先级顺序。用户的明确偏好始终优先于观察到的文件系统状态。

1. **检查你的指令中是否有声明的 worktree 目录偏好。** 如果用户已指定，无需询问直接使用。

2. **检查是否存在项目本地 worktree 目录：**
   ```bash
   ls -d .worktrees 2>/dev/null     # 首选（隐藏）
   ls -d worktrees 2>/dev/null      # 备选
   ```
   如果找到，使用它。如果两者都存在，`.worktrees` 优先。

3. **检查是否存在全局目录：**
   ```bash
   project=$(basename "$(git rev-parse --show-toplevel)")
   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
   ```
   如果找到，使用它（与旧版全局路径的向后兼容）。

4. **如果没有其他可用指导**，默认使用项目根目录下的 `.worktrees/`。

#### 安全验证（仅项目本地目录）

**创建 worktree 前必须验证目录已被忽略：**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**如果未被忽略：** 添加到 .gitignore，提交更改，然后继续。

**为什么关键：** 防止意外将 worktree 内容提交到仓库。

全局目录（`~/.config/superpowers/worktrees/`）无需验证。

#### 创建 Worktree

```bash
project=$(basename "$(git rev-parse --show-toplevel)")

# 根据选择的位置确定路径
# 项目本地：path="$LOCATION/$BRANCH_NAME"
# 全局：path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**沙箱回退：** 如果 `git worktree add` 因权限错误（沙箱拒绝）失败，告诉用户沙箱阻止了 worktree 创建，你将在当前目录中工作。然后在原地运行设置和基线测试。

## 步骤 3：项目设置

自动检测并运行适当的设置：

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## 步骤 4：验证干净基线

运行测试确保工作空间从干净状态开始：

```bash
# 使用项目对应的命令
npm test / cargo test / pytest / go test ./...
```

**如果测试失败：** 报告失败，询问是继续还是调查。

**如果测试通过：** 报告就绪。

### 报告

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## 快速参考

| 情况 | 操作 |
|------|------|
| 已在链接的 worktree 中 | 跳过创建（步骤 0） |
| 在子模块中 | 视为普通仓库（步骤 0 守卫） |
| 原生 worktree 工具可用 | 使用它（步骤 1a） |
| 无原生工具 | Git worktree 回退（步骤 1b） |
| `.worktrees/` 存在 | 使用它（验证已忽略） |
| `worktrees/` 存在 | 使用它（验证已忽略） |
| 两者都存在 | 使用 `.worktrees/` |
| 都不存在 | 检查指令文件，然后默认 `.worktrees/` |
| 全局路径存在 | 使用它（向后兼容） |
| 目录未被忽略 | 添加到 .gitignore + 提交 |
| 创建时权限错误 | 沙箱回退，原地工作 |
| 基线测试失败 | 报告失败 + 询问 |
| 无 package.json/Cargo.toml | 跳过依赖安装 |

## 常见错误

### 与工具框架对抗

- **问题：** 当平台已提供隔离时使用 `git worktree add`
- **修复：** 步骤 0 检测现有隔离。步骤 1a 优先使用原生工具。

### 跳过检测

- **问题：** 在现有 worktree 内部创建嵌套 worktree
- **修复：** 创建任何东西前始终运行步骤 0

### 跳过忽略验证

- **问题：** Worktree 内容被跟踪，污染 git status
- **修复：** 创建项目本地 worktree 前始终使用 `git check-ignore`

### 假设目录位置

- **问题：** 造成不一致，违反项目约定
- **修复：** 遵循优先级：现有 > 全局旧版 > 指令文件 > 默认

### 在测试失败时继续

- **问题：** 无法区分新 bug 和已有问题
- **修复：** 报告失败，获得明确许可后再继续

## 红线

**绝不：**
- 当步骤 0 检测到现有隔离时创建 worktree
- 当你有原生 worktree 工具（如 `EnterWorktree`）时使用 `git worktree add`。这是第一大错误 -- 如果你有，就用它。
- 跳过步骤 1a 直接进入步骤 1b 的 git 命令
- 未验证目录已被忽略就创建 worktree（项目本地）
- 跳过基线测试验证
- 未询问就在测试失败时继续

**始终：**
- 先运行步骤 0 检测
- 优先使用原生工具而非 git 回退
- 遵循目录优先级：现有 > 全局旧版 > 指令文件 > 默认
- 为项目本地目录验证已被忽略
- 自动检测并运行项目设置
- 验证干净的测试基线
