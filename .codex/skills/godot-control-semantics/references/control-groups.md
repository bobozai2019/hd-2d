# 控件分组

在打开任何详细参考文件之前，先用本文件对当前 HTML 区块进行分类。

## `container-family.md`

当 HTML 区块主要回答以下问题时读取：

- 子元素如何排列？
- Godot 侧是否需要自动布局？
- 问题是否可能由 `Container` 接管子布局引起？

典型 HTML 线索：

- `display: flex`
- `display: grid`
- 内部有内容流的外壳
- 由 `gap`、padding 或行列驱动的间距

## `background-and-shells.md`

当 HTML 区块主要是以下内容时读取：

- 卡片框
- 面板壳
- 带装饰的包裹层
- 不应管理子布局的外壳层

典型 HTML 线索：

- 以边框/背景/阴影为主的包裹层
- 绝对定位的装饰
- 内部布局属于另一个子区块

## `content-and-assets.md`

当 HTML 区块主要涉及以下内容时读取：

- 美术槽位
- 文本承载
- 徽记
- 计数器
- 进度填充
- 图标条
- 标记、字形或装饰性状态指示器

典型 HTML 线索：

- 重复的小符号
- 类图像内容
- 外壳内的填充元素
- 节点用于显示内容而非排列兄弟节点

## `interactive-controls.md`

当 HTML 区块主要涉及以下内容时读取：

- 可点击元素
- focus/hover/pressed 状态
- 开关、标签页、选择器
- 输入行为影响布局决策
