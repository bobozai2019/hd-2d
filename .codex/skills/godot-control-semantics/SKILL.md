---
name: godot-control-semantics
description: 在将 HTML/CSS/JS UI 转为原生 Godot 场景时，选择正确的 Godot 4.x Control 节点。当 HTML 区块需要 Godot 节点角色决策、Container 家族误用可能导致挤压/错位/布局偏移、或页面级尺寸大致正确但组件级结构/比例/视觉权重仍有问题时使用。
---

# Godot 控件语义

## 核心规则

先确定 Godot 节点角色，再选择具体节点。对于每个 HTML 区块，先判断它是背景壳、布局容器、内容承载还是交互控件，然后选择与该角色匹配的 Godot 节点。

不要仅因为"看起来像"就选节点。在本 skill 中，正确性意味着语义优先，视觉相似其次。

## 使用场景

在以下情况使用本 skill：

- 你正在将 HTML/CSS/JS UI 转为 Godot `Control` 场景，需要将 DOM 区域映射到 Godot 节点类型。
- Godot UI 在从 HTML 转换后出现挤压、意外重叠或比例偏移。
- 你需要在 `Control`、`Panel`、`PanelContainer`、`HBoxContainer`、`VBoxContainer`、`GridContainer`、`MarginContainer`、`ScrollContainer`、`TextureRect`、`Label` 或 `Button` 之间做选择。
- 页面级布局大致正确，但进度条、徽记、图标条、计数器或标题/正文间距在结构上有问题。

以下情况不应使用本 skill：

- 你只需要运行 headless 加载检查、截图或点击探测。
- 你只修改业务数据/状态，不涉及节点结构。
- 你已经知道确切的 Godot 节点结构，只需要实现它。

## 加载协议

保持上下文精简。

按以下顺序读取：

1. 先读 [`references/control-groups.md`](references/control-groups.md)。
2. 根据当前 HTML 区块选择一个主分组文件。
3. 仅在需要时读取一个辅助文件：
   `references/common-failure-patterns.md` 或 `references/acceptance-checks.md`。

每次用户任务的默认预算：

- `SKILL.md`
- `control-groups.md`
- `1` 个主分组文件
- `1` 个辅助文件

如果页面明显包含第二个不同的控件家族，可以额外读取一个主分组文件，但必须先说明第一个分组为何不足。

## 决策流程

对于每个 HTML 区块：

1. 识别 HTML 角色：
   背景壳、布局容器、内容承载或交互控件。
2. 判断 Godot 侧是否需要自动布局行为。
3. 路由到正确的控件家族参考文件。
4. 选择最终节点或节点组合。
5. 记录为什么拒绝了相近的替代方案。
6. 只补充与本次控件选择直接相关的组件检查项。

## 参考路由

使用以下路由表：

| 情况 | 读取 |
|---|---|
| 需要先分类当前区块 | `references/control-groups.md` |
| 怀疑 `Container` 或布局家族不匹配 | `references/container-family.md` |
| 区块主要是壳、包裹层、卡片框或视觉外壳 | `references/background-and-shells.md` |
| 区块主要是美术、文本、计数器、进度条、标记或填充元素 | `references/content-and-assets.md` |
| 区块由按钮/focus/hover/pressed 驱动 | `references/interactive-controls.md` |
| 在 Godot 中结构已经明显异常 | `references/common-failure-patterns.md` |
| 需要对高风险组件做最终本地检查 | `references/acceptance-checks.md` |

## 红线

- 不要把 `Container` 子类当作纯视觉空壳使用。
- 不要仅因为节点默认外观与 HTML 相似就选它。
- 不要只停留在页面级相似性，当风险点在小组件时必须深入。
- 不要把短进度条、徽记、图标条或计数器等辅助元素变成主导视觉块。
- 不要认为"可以定位"就等于控件语义正确。

## 必须产出

对于构建/决策任务，至少产出：

`HTML 证据 -> DOM 区块 -> 节点角色 -> 候选控件 -> 最终选择 -> 为什么不用替代方案 -> Godot 节点草图 -> 父子拆分 -> 预期布局行为 -> 风险 -> 组件检查`

对于审查/诊断任务，至少产出：

`当前问题 -> HTML/Godot 不匹配证据 -> 根因语义不匹配 -> 更安全的结构 -> 父子修复草图 -> 后续组件检查`
