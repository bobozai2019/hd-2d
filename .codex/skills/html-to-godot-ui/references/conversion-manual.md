# HTML转Godot场景执行手册

版本：v0.2  
日期：2026-05-08  
适用范围：`html_ui/` 下的 HTML UI 原型转 Godot 4.7 原生 2D UI 场景。

本文用于约束 HTML 原型转 Godot 场景时的执行方式，避免出现“功能数据转了，但画面结构和素材丢失”“脚本动态生成过多，场景文件空壳化”“CSS 里的图像性质内容被误当成普通样式”的问题。

## 1. 转换总原则

HTML 原型不是只提供数据，也提供视觉结构、资产线索和交互状态。转换时必须同时保留三层内容：

```text
结构层：HTML DOM 对应的版面和节点层级
视觉层：CSS 布局、颜色、边框、阴影、图像化装饰
行为层：JS 数据、状态、事件、筛选、选中、购买、返回等逻辑
```

Godot 版本的目标不是嵌入 HTML，而是把原型翻译成原生 `Control` 场景：

- 场景文件负责稳定结构和可见元素。
- 场景文件、Theme 或 `.tres` 资源负责可序列化的固定 UI 属性。
- 脚本负责状态、数据绑定、交互和必要的动态列表。
- CSS 中具有图像性质的内容，按规则转为 PNG、NinePatch 或 Godot 样式。
- HTML 中的内联 SVG 不可直接丢失，必须逐项判断是否转资产。
- HTML 中承担图标、资源计量、状态表达的字符型符号，不能默认按普通文本处理；需要登记为视觉对象，并决定使用程序生成、贴图或稳定控件组合来还原。

新增强制约束：

- 不需要追求“看起来像 HTML”的视觉复刻；HTML 转 Godot 的首要目标是大小一致、布局一致。只要尺寸、容器顺序、分区关系、栅格关系一致，视觉风格可在后续阶段单独精修。
- 生成后的 UI 总体尺寸、主要面板尺寸、卡片尺寸、图标占位尺寸，必须与原始 HTML UI 一致；不能为了“更适合 Godot”自行改宽高比例。
- 容器类节点必须保留 HTML 中的摆放顺序；同级节点顺序、主轴排列方向、换行/分列关系都不能随意调整。
- HTML 使用栅格布局的区域，Godot 侧也必须保持栅格布局结果一致；不能改成看起来差不多的线性堆叠布局。
- 凡是可以直接写进 `.tscn`、Theme 或 `.tres` 的固定 UI 设置，不写进 `_ready()` 或 setup 脚本；脚本只处理数据驱动、状态驱动或运行时必须变化的值。

执行时优先级固定为：

```text
第一优先：页面设计尺寸、主面板尺寸、关键卡片尺寸一致
第二优先：主容器分区、同级顺序、grid 轨道和换行结果一致
第三优先：交互状态和数据行为一致
第四优先：视觉细节、装饰、光效、材质精修
```

禁止把“更像 HTML 视觉”作为修改尺寸、改动布局、打破容器顺序的理由。

## 1.1 尺寸一致性红线

HTML 转 Godot 时，尺寸保真不是参考项，而是硬性约束。凡是 HTML 中已经给出明确宽高、最小尺寸、网格轨道尺寸、卡片尺寸、图标框尺寸的内容，Godot 必须等值落地。

必须遵守：

- 页面根 UI 设计尺寸必须与 HTML 原型一致。
- 主要面板外框尺寸必须一致。
- 卡片、按钮、标签、图标槽位尺寸必须一致。
- 间距、padding、gap 在视觉结果上必须一致。
- 不允许只保证“相对比例差不多”，但实际尺寸变大或变小。

允许的弹性范围只适用于：

- 引擎字体渲染差异导致的 1-2 px 文本包围盒波动。
- 抗锯齿、边框取整带来的极小误差。

不允许的做法：

- 把 HTML 的固定宽度面板改成 `size_flags_horizontal = expand_fill` 后任意拉伸。
- 为了省事把多个不同尺寸的卡片统一成同一尺寸。
- 因为 Godot 容器默认行为导致子节点尺寸变化，却不加自定义最小尺寸、占位节点或额外包裹层修正。

## 1.2 布局顺序和栅格保真红线

HTML 中的容器顺序、网格轨道和单元格占位关系，必须在 Godot 中保留为等价结构。这里的“等价”不是大致摆在同一区域，而是指阅读顺序、分组关系、行列归属和视觉落点一致。

必须遵守：

- 同级节点顺序与 DOM 顺序一致，除非 HTML 本身通过 CSS `order` 明确改序。
- `grid-template-columns`、`grid-template-rows`、`gap`、`grid-column`、`grid-row` 对应的结果必须保留。
- 一个容器在 HTML 中是 2 列、3 列或多行网格时，Godot 中也必须是相同列数和相同换行结果。
- 详情区、侧栏、底栏、列表区的相对位置不能交换。

推荐落地方式：

- 规则网格优先使用 `GridContainer`。
- 需要固定单元尺寸时，给子项补 `custom_minimum_size`，避免 Godot 自动压缩导致列数变化。
- 需要更接近 HTML Grid 的复杂占位时，可用嵌套容器、额外包裹层或手工定位，但最终结果仍必须保持原网格关系。

不允许的做法：

- 把 HTML 的 grid 区域简化成 `VBoxContainer` 或 `HBoxContainer`，只求“差不多摆出来”。
- 因 Godot 容器默认重排导致顺序变化，却不修正节点树。
- 为了适配脚本逻辑，把左中右三栏改成上下堆叠。

## 2. 标准执行流程

每次转换一个 HTML 页面时，按以下顺序执行。

1. 阅读 HTML 页面结构，列出主要区域。
2. 阅读 CSS，标记布局规则、装饰规则、图像性质规则，重点记录固定尺寸、gap、grid 轨道和节点顺序。
3. 阅读 JS 数据和事件，列出运行时状态。
4. 先建立 HTML 到 Godot 的尺寸/布局对照表，记录页面设计尺寸、主面板尺寸、关键卡片尺寸、grid 列数与顺序。
5. 拆分 Godot 子场景清单。
6. 先生成静态场景文件，把可见结构和固定控件属性落到 `.tscn`。
7. 先还原容器顺序和栅格关系，再补文本、样式和素材。
8. 为固定尺寸节点设置明确尺寸约束，避免被容器二次拉伸或压缩。
9. 再写脚本绑定节点，不把静态 UI 和固定控件属性塞进脚本。
10. 转换必要 CSS/SVG 素材到 `assets/ui/`。
11. 用 `TextureRect`、`StyleBoxTexture` 或 `NinePatchRect` 接入素材。
12. 运行 Godot headless 加载关键场景，确认无脚本和节点路径错误。
13. 阅读点击交互验收文档，逐项确认点击、拖动、选中、焦点切换是否真实可用。
14. 对照 HTML 原型逐项验收：尺寸、结构顺序、栅格关系、数据、素材、交互状态。

## 2.1 保真度阶段和阻断线

为了避免“临时占位”无限期保留，HTML 转 Godot 必须按阶段验收。不同阶段允许不同程度的近似，但进入下一阶段时必须清掉前一阶段的占位债。

| 阶段 | 目标 | 允许 | 阻断条件 |
|---|---|---|---|
| L0 可加载 | Godot 能加载页面和关键子场景 | 空数据、少量占位文本 | 主场景或关键子场景加载报错 |
| L1 结构/数据一致 | DOM 主要结构、JS 数据完整迁移 | 图标可用 Label 临时占位，复杂光效可近似 | 页面根场景空壳化、基础数据缺失、主要面板缺失 |
| L2 状态/交互一致 | hover、focus、selected、disabled、sold 等状态能刷新 | PNG 可仍未最终精修 | HTML 已有交互状态在 Godot 无对应表现 |
| L3 资产完整 | 必须 PNG/NinePatch 的资产全部接入 | 背景光效可继续近似 | 必须资产仍是文字占位、TextureRect 缺图、资源路径缺失 |
| L4 截图高保真 | 关键状态截图与 HTML 原型接近 | 允许引擎字体和抗锯齿存在小差异 | 布局比例、核心资产、状态视觉明显不像 |

旧计划中“第一版可以用 Label 占位”的表述，只适用于 L0-L1。进入 L3 后，分类图标、条目图标、角色立绘、页面徽记仍是 Label，应视为验收失败。

补充红线：

- 具有图标语义的字符型符号，例如 `♥`、`◆`、`★`、能量点、计数珠、资源菱形，不能因为来源不是 SVG 就跳过资产盘点。
- 如果这类符号在 HTML 中承担资源数量、状态槽位、视觉识别或主题装饰职责，Godot 侧必须用稳定方案还原。
- 稳定方案可以是程序绘制控件、静态节点组合、贴图资源，或确认可控的原生字符显示；不能只因为“当前字体刚好能显示”就视为完成。

补充说明：

- L1-L2 的验收基准仍然是“大小和布局一致”，不是“视觉像不像”。
- “大小一致”必须同时覆盖页面级和组件级；不能只因为左栏、右栏、底栏、手牌区这些大分区大致在对的位置，就默认内部小组件也通过。
- 页面级检查关注主要分区、主面板、卡带、侧栏、底栏的尺寸和位置关系。
- 组件级检查关注 `progress bar`、`badge`、`icon strip`、`counter`、符号行、标题/正文间距等小组件的长度、厚度、相对位置和视觉权重。
- 如果页面级尺寸接近，但组件级尺寸关系明显失真，应视为验收失败，而不是“样式还没精修”。
- L4 才讨论截图保真度；如果 L1-L3 还没稳定，不要提前用视觉细节掩盖尺寸和布局问题。

## 3. 子场景拆分原则

拆分的目的，是让 UI 能复用、能维护、能独立验证。不要为了拆而拆，也不要把整个页面塞进一个巨型场景。

## 3.1 应该拆成子场景的内容

满足以下任一条件，优先拆成独立 `.tscn + .gd`：

| 类型 | 拆分依据 | 示例 |
|---|---|---|
| 页面级模块 | 可作为完整界面打开/关闭 | `PageRoot.tscn`、`OverlayRoot.tscn` |
| 大面板 | 有明确职责和独立布局 | 左侧导航、内容区、卡片列表区、详情区 |
| 重复项 | 会按数据生成多个实例 | 分类按钮、表单行、卡片项 |
| 复合控件 | 有内部状态和输入逻辑 | 下拉选择、分段按钮、开关、滑条 |
| 浮层 | 出现/隐藏逻辑独立 | Toast、确认弹窗、提示框 |
| 可复用资产容器 | 多页面都会用 | 通用按钮、稀有度卡片、资源 chip |

拆出来的子场景必须有清晰职责。一个子场景最好只做一件事：显示一个面板、一个重复项、一个控件，或者一个浮层。

## 3.2 不应该拆成子场景的内容

以下内容通常不拆，直接作为父场景内部节点：

| 类型 | 不拆原因 | 示例 |
|---|---|---|
| 纯布局容器 | 没有独立行为 | `HBoxContainer`、`VBoxContainer`、`MarginContainer` |
| 单个静态文本 | 只服务当前面板 | 标题、副标题、说明文字 |
| 简单装饰线 | 没有复用价值 | 分隔线、角标里的单个 `ColorRect` |
| 一次性背景层 | 只属于当前页面 | 页面底色、当前页面专属暗色遮罩 |
| 过小的按钮内部元素 | 拆分会增加维护成本 | 按钮里的文字、箭头、价格 Label |

判断标准：如果这个节点离开父场景就没有独立意义，通常不拆。

## 3.3 动态列表的拆分方式

动态列表应拆“列表项”，不拆每一条具体数据。

推荐：

```text
PageRoot.tscn
  ItemList / VBoxContainer

ListItemCard.tscn
  Layout
    Art / TextureRect
    Name / Label
    Price / Label
    Tags / Label
    Desc / Label
```

脚本只负责：

- 从数据表读取列表数组。
- 实例化 `ListItemCard.tscn`。
- 调用 `setup(item_data)`。
- 监听 `item_selected(item_id)`。

不推荐：

- 每个数据项都手写一个独立 `.tscn`。
- 用脚本动态创建列表项里的所有 Label、Panel、TextureRect。
- 把图标、名称、价格烘成一张整图。

## 4. 场景静态生成原则

Godot 场景文件必须承载主要可见结构和固定控件属性。脚本不是 HTML 模板引擎，也不是批量样式初始化器，不应该承担大部分静态节点创建或固定 UI 属性赋值。

## 4.1 必须静态写入 `.tscn` 的内容

以下节点应尽量在 `.tscn` 中生成：

- 页面主容器。
- 背景层。
- 主布局容器。
- 大面板。
- 标题区。
- 按钮容器。
- 列表容器。
- 详情面板结构。
- 列表项内部结构。
- 表单行内部结构。
- 控件内部结构。
- Toast 内部结构。
- 装饰角标、分隔线、固定徽章。
- `TextureRect` 资产占位节点。

以下固定属性也应优先直接写入 `.tscn`、Theme 或 `.tres`：

- `text`、`placeholder_text`、tooltip、按钮默认文案等静态文本。
- `custom_minimum_size`、anchors、offsets、grow direction、size flags、stretch mode。
- `visible`、`disabled`、`mouse_filter`、`focus_mode`、`clip_contents` 等默认状态。
- `texture`、`modulate`、`self_modulate`、alignment、autowrap、label settings。
- 字号、字体、颜色、StyleBox、Theme override、容器 separation 和 margin 常量。
- 静态进度条范围、默认值、滑条范围、勾选框默认值等固定控件参数。

这样做的好处：

- Godot 编辑器里能直接看到结构。
- 节点路径稳定，脚本更短。
- 后续调 UI 不需要读大段动态创建代码。
- 不容易漏掉 HTML 原型里的视觉元素。

## 4.2 脚本只控制必要部分

脚本主要负责这些工作：

- 数据绑定。
- 根据数据实例化重复项。
- 切换选中、悬停、禁用、售罄等状态。
- 响应输入和按钮事件。
- 控制动画、Toast、弹窗显示隐藏。
- 更新文本、数值、纹理、颜色。
- 保存和读取页面状态。

脚本只有在以下情况才应设置 UI 属性：

- 值来自 JS 数据表、玩家存档、接口返回或当前筛选条件。
- 值属于 hover、focus、selected、disabled、sold、resource_missing 等运行时状态。
- 值需要随动画、倒计时、拖拽、分页、语言切换或窗口尺寸变化更新。
- 节点数量由数据决定，必须在运行时实例化后调用 `setup(data)`。

脚本可以动态创建的节点：

- 数据驱动的重复项实例。
- 数量不固定的标签 chip。
- 分段按钮选项。
- 临时浮层效果。
- 运行时调试节点。

脚本不应动态创建的节点：

- 页面主结构。
- 页面级固定子场景实例。
- 固定按钮。
- 固定标题。
- 固定面板。
- 固定控件内部结构。
- 固定装饰节点。

脚本不应批量设置的固定属性：

- 固定 Label/Button 文案。
- 固定尺寸、锚点、offset、size flags、容器 separation。
- 固定颜色、字体、字号、StyleBox、Theme override。
- 固定纹理路径、默认可见性、默认禁用状态、默认焦点模式。
- 固定 progress/slider 范围和默认控件参数。

## 4.3 页面根场景静态化红线

页面级场景不能只是一个空根节点。凡是固定存在的页面结构，都必须作为 `.tscn` 里的静态节点或子场景实例存在。

推荐：

```text
PageRoot / Control
  BackgroundLayer / Control
  PageShell / PageShell.tscn instance
  PageToast / PageToast.tscn instance
```

```text
PageRoot / Control
  BackgroundLayer / Control
  PageTopbar / PageTopbar.tscn instance
  MainGrid / HBoxContainer
    LeftPanel / LeftPanel.tscn instance
    CenterPanel / CenterPanel.tscn instance
    DetailPanel / DetailPanel.tscn instance
  PageFooter / PageFooter.tscn instance
  PageToast / PageToast.tscn instance
```

控制器脚本只做：

- `@onready` 绑定这些节点。
- 调用子场景公开方法。
- 连接信号。
- 更新数据和状态。

不允许用“总控负责组装”为理由，在 `_ready()` 中动态创建背景层、主外框、Toast、固定大面板。只有数据数量不固定的重复项，才由脚本运行时实例化。

## 4.4 推荐脚本绑定方式

优先使用 `@onready` 绑定 `.tscn` 里的节点：

```gdscript
@onready var _title: Label = $Header/Title
@onready var _list: VBoxContainer = $Body/List
@onready var _confirm_button: Button = $Footer/ConfirmButton
```

推荐公开方法：

```gdscript
func setup(data: Dictionary) -> void
func set_selected(value: bool) -> void
func refresh() -> void
```

不推荐在 `_ready()` 里大量写：

```gdscript
var title := Label.new()
add_child(title)
var button := Button.new()
add_child(button)
```

只有在节点数量由数据决定时，才这么做。

也不推荐在 `_ready()` 里大量写：

```gdscript
$Header/Title.text = "Shop"
$Body.custom_minimum_size = Vector2(860, 520)
$Footer/ConfirmButton.add_theme_font_size_override("font_size", 22)
$Body/Grid.add_theme_constant_override("h_separation", 12)
```

这些值若是固定设计值，应直接保存在对应 `.tscn` 节点或 Theme/StyleBox 资源里。脚本可以调用 `set_selected(value)`、`refresh(data)` 等方法改运行时状态，但不应承担场景初始化表。

## 4.5 页面级推荐拆分模板

任何包含顶部信息区、主内容区、详情区、底部操作区和浮层的复杂页面，都不应长期维持为单个巨型场景。建议按职责拆分：

| 场景 | 职责 | 脚本 |
|---|---|---|
| `PageRoot.tscn` | 页面总控、信号汇总、当前选中项、全局状态 | `page_root.gd` |
| `PageTopbar.tscn` | 标题、资源栏、返回按钮 | `page_topbar.gd` |
| `PageSidePanel.tscn` | 说明区、立绘区、图例区或过滤区 | `page_side_panel.gd` |
| `PageListPanel.tscn` | 页签、列表容器、刷新逻辑 | `page_list_panel.gd` |
| `ListItemCard.tscn` | 单个列表项、图标、文本、状态 | `list_item_card.gd` |
| `PageDetailPanel.tscn` | 当前选中项详情、主图、主操作按钮状态 | `page_detail_panel.gd` |
| `PageFooter.tscn` | 辅助操作、手柄提示、分页提示 | `page_footer.gd` |
| `PageToast.tscn` | 短提示显示 | `page_toast.gd` |

其中 `PageRoot` 不直接管理列表项内部样式，不直接创建列表项内部 Label，也不直接绘制具体图标资产。

## 5. CSS素材转换原则

CSS 里的内容分为四类：布局、样式、图像资产、运行时状态。转换时必须先分类，再决定落地方式。

## 5.1 必须转 PNG 的内容

具有“图片性质”的内容必须转为 PNG，不能用普通 Label 或简单 Panel 代替。

判断依据：

- HTML 中是内联 SVG，并且代表具体物件、角色、图标。
- CSS 形状组合后形成明确图案。
- HTML 字符符号或计数标记承担了图标、资源槽位、状态珠、主题徽记等视觉对象职责。
- 该内容是用户会识别的视觉对象。
- 丢失后页面主题或功能识别明显下降。
- 需要在多个尺寸下复用，例如缩略图和详情大图。

标准示例：

| 来源 | 内容 | 建议路径 |
|---|---|---|
| 分类型页面 SVG | 分类图标、模式图标、页签图标 | `assets/ui/<module>/icons/*.png` |
| 列表型页面 SVG | 条目图标、卡片插画、徽记 | `assets/ui/<module>/items/*.png` |
| 角色型装饰 SVG | 角色立绘、头像、主题装饰 | `assets/ui/<module>/characters/*.png` |
| 页面主视觉 | 页面徽记、阵营标识、章节印记 | `assets/ui/<module>/marks/*.png` |
| 详情面板资产 | 选中项详情大图 | 可复用 `items/*.png`，必要时单独导出大图 |

接入方式：

- 小图标用 `TextureRect`。
- 条目图标用 `TextureRect`，保持等比缩放。
- 立绘用 `TextureRect`，`stretch_mode = keep_aspect_centered`。
- 需要像素风时关闭过滤；当前 UI 偏高清，可先开启默认过滤。

不应遗漏的非 SVG 资产：

- 顶栏生命心、AP 菱形、能量珠、威胁标记等字符型图标条。
- 由 `border`、`clip-path`、多层渐变或多个节点叠出的可识别徽记。
- 视觉上承担“这是一个资源槽/状态槽”的重复符号，而非普通正文文字。

## 5.1.1 SVG/PNG导出规格

每个必须 PNG 化的 SVG，都要保留源文件和导出文件。

推荐源文件目录：

```text
assets/ui/<module>/icons_src/*.svg
assets/ui/<module>/items_src/*.svg
assets/ui/<module>/characters_src/*.svg
```

推荐 PNG 目录：

```text
assets/ui/<module>/icons/*.png
assets/ui/<module>/items/*.png
assets/ui/<module>/characters/*.png
assets/ui/<module>/marks/*.png
```

导出规格：

| 资产类型 | 建议尺寸 | 透明边距 | 命名依据 | Godot节点 |
|---|---:|---:|---|---|
| 分类图标 | `64x64` | 6-8 px | 分类 id | `TextureRect` |
| 条目小图标 | `128x128` | 10-14 px | 条目 `art` key | `TextureRect` |
| 条目详情大图 | `256x256` | 16-24 px | 条目 `art` key，可复用小图 | `TextureRect` |
| 角色立绘 | `384x420` 或按原型比例 | 0-16 px | 角色 `art` key 或稳定语义名 | `TextureRect` |
| 页面徽记 | `64x64` | 6-8 px | 页面语义名 | `TextureRect` |

命名规则：

- 资源文件名优先跟数据里的 `art` key 对齐，例如 `piercing.png`，而不是条目 `id` `piercing-arrow`。
- 如果一个资产没有 `art` key，则使用稳定语义名，例如 `page_mark.png`、`main_character.png`。
- 同一个 SVG 的源文件和 PNG 文件同名，只改扩展名。
- 若需要不同状态，追加状态后缀：`sniper_normal.png`、`sniper_sold.png`。优先用 Godot `modulate` 做禁用态，除非 CSS 滤镜效果无法接受。

Godot import 验收：

- PNG 必须能被 Godot 导入为 `Texture2D`。
- UI 图标默认不需要 mipmaps。
- 高清 UI 可保留过滤；像素风 UI 关闭过滤。
- `TextureRect` 默认使用 `keep_aspect_centered` 或 `keep_aspect`，不得拉伸变形。
- 所有必须资产路径必须能被 `load()` 或 Inspector 正常解析。
- `.svg` 源文件应保留，便于后续重新导出。

## 5.2 建议转 NinePatch 或 StyleBoxTexture 的内容

如果 CSS 里的边框或面板已经是强风格化视觉，而 Godot `StyleBoxFlat` 难以还原，应考虑转 NinePatch。

判断依据：

- 有斜切角、复杂边框、特殊纹理。
- 多处复用同一种框。
- 尺寸会变化，不能普通拉伸。
- 选中/稀有度状态依赖边框视觉。

标准示例：

| 来源 | 内容 | 建议 |
|---|---|---|
| 页面外框伪元素 | 斜切主框、异形外边框 | `page_shell_frame.9.png` |
| 角标伪元素 | 四角装饰、边角徽记 | 可先静态节点，必要时 PNG |
| 列表项边框 | 普通/稀有/史诗边框和高光 | 可先 `StyleBoxFlat`，后续转 9-slice |
| 详情框外观 | 大卡面边框和内发光 | 可先 `StyleBoxFlat`，高保真阶段转 9-slice |

NinePatch/StyleBoxTexture 规格：

- 文件名使用组件和状态：`list_item_card_common.9.png`、`list_item_card_rare_selected.9.png`。
- 必须记录 patch margin：left/top/right/bottom。
- 切片区域不能覆盖斜切角、边框花纹、角标。
- 每种状态至少明确 `normal`、`hover`、`selected`、`disabled`，列表项卡片额外明确 `sold` 或等价禁用态。
- 稀有度边框如果只是颜色变化，优先一张纹理加 `modulate`；如果纹理和光效不同，再拆 common/rare/epic 三套。
- 最小显示尺寸不得小于切片安全尺寸，避免边框挤压变形。

## 5.2.1 CSS伪元素盘点规则

遇到 `::before`、`::after` 必须逐项登记，不能默认忽略。登记后再决定是静态节点、PNG/NinePatch、Shader，还是可接受省略。

标准示例：

| 页面 | CSS来源 | 处理建议 |
|---|---|---|
| 通用页面 | `.shell::before` | 背景辉光层，L2 可用 ColorRect/Shader 近似 |
| 通用页面 | `.shell::after` | 异形边框，L3 建议 NinePatch |
| 详情模块 | `.detail-card::before` | 详情卡高光，L2 可静态 ColorRect，L4 可 Shader |
| 徽章模块 | `.glow-emblem::before/after` | 徽章装饰，L2 静态节点，L3 评估 PNG |
| Toast 模块 | `.toast::before` | Toast 装饰线，L2 静态节点 |
| 列表页根节点 | `.page-root::before/after` | 根面板角光/边缘装饰，L2 可近似 |
| 通用面板 | `.panel::after` | 面板内框，L2 StyleBox，L4 可 NinePatch |
| 列表项 | `.item-card::before` | 条目卡斜向高光，L2 静态节点，L4 可 Shader/PNG |
| 状态条 | `.sold-ribbon` / `.disabled-ribbon` | 状态斜角条，L2 必须有 Godot 节点或 PNG |

## 5.3 不建议转 PNG 的内容

以下内容应优先保留为 Godot 原生样式：

| 内容 | 原因 |
|---|---|
| 文本 | 需要本地化、换行、字号和状态变化 |
| 价格、数值、标签 | 会被脚本频繁更新 |
| 普通按钮背景 | 有 hover、pressed、disabled 状态 |
| Tab 状态 | 用主题和脚本控制更灵活 |
| 大面积纯渐变背景 | 用 Godot 颜色层或 Shader 更易适配分辨率 |
| 普通阴影和内发光 | 可用 StyleBox、主题或后续 Shader 近似 |
| 布局间距 | 应转为 Container、锚点、size flags |

不要把整张 UI 截图当背景图。这样会导致：

- 按钮不可独立响应。
- 文本无法更新。
- 分辨率适配困难。
- 后续改数据和本地化成本极高。

## 5.4 CSS到Godot的映射建议

| CSS内容 | Godot落地 |
|---|---|
| `display: flex` | `HBoxContainer` / `VBoxContainer` |
| `display: grid` | 优先 `GridContainer`；若涉及跨列跨行或不规则区域，使用等价嵌套容器/手工定位，但最终栅格结果必须一致 |
| `grid-template-columns` / `grid-template-rows` | 必须先记录列数、行数、轨道尺寸，再映射为 Godot 容器和子节点尺寸约束 |
| `grid-column` / `grid-row` | 必须保留项目所属行列与视觉落点，不可默认忽略 |
| `gap` | Container 的 `theme_override_constants/separation` |
| `padding` | `MarginContainer` 或 `PanelContainer` 内边距 |
| `border-radius` | `StyleBoxFlat.corner_radius_*` |
| `border` | `StyleBoxFlat.border_width_*` |
| `background: rgba(...)` | `StyleBoxFlat.bg_color` |
| `linear-gradient` | 先近似为纯色/多层 ColorRect；高保真用 Shader 或 PNG |
| `radial-gradient` | 先近似为半透明光层；高保真用 Shader 或 PNG |
| `box-shadow` | 普通阶段可省略或用外层半透明 Panel；高保真用素材或 Shader |
| `clip-path` | 简单形状用节点组合；复杂面板转 PNG/NinePatch |
| `svg` 图标 | 导出 PNG 后用 `TextureRect` |
| `::before/::after` 装饰 | 独立静态节点；若图像性质强则转 PNG |
| `transition` | Godot `Tween` |
| `filter: saturate/grayscale` | 禁用态可用 `modulate`，复杂滤镜后续 Shader |

补充约束：

- 遇到 `width`、`height`、`min-width`、`min-height`、`aspect-ratio` 时，必须决定 Godot 的等价尺寸约束，不能直接丢掉。
- 遇到 grid/flex 混合布局时，先保结构和顺序，再做视觉微调；不能为了容器省事改布局类型。
- 如果 Godot 原生容器无法直接还原 HTML Grid 的跨列跨行结果，允许增加中间容器，但不允许更改最终阅读顺序和网格落点。

## 5.5 视觉状态矩阵

每个页面必须列出状态矩阵，并在 L2 之后逐项检查。

表单/配置型页面至少检查：

```text
[ ] 分类按钮 normal
[ ] 分类按钮 hover
[ ] 分类按钮 focused
[ ] 分类按钮 active
[ ] 表单行 normal
[ ] 表单行 hover
[ ] 表单行 focused
[ ] select 当前值和左右切换
[ ] segmented 当前值和切换
[ ] toggle on/off
[ ] slider 当前值和拖动/键盘调整
[ ] footer focus
[ ] toast show/hide
```

列表/卡片型页面至少检查：

```text
[ ] tab normal/hover/active
[ ] 列表项卡片 normal
[ ] 列表项卡片 hover 时详情同步
[ ] 列表项卡片 selected
[ ] 列表项卡片 disabled/sold
[ ] 列表项卡片 common/rare/epic 稀有度视觉
[ ] 详情可执行主操作
[ ] 详情不可执行主操作
[ ] 详情 disabled/sold
[ ] 主资源数值刷新
[ ] 执行主操作后条目状态刷新
[ ] toast visible
```

## 6. HTML数据转换原则

JS 中的数据要转成 Godot 可维护的数据源，不要散落在 UI 脚本里。

推荐：

```text
scripts/<module>/<module>_data.gd
scripts/<module>/<module>_state.gd
```

数据脚本负责：

- 分类定义。
- 条目定义。
- 默认值。
- 文本描述。
- 稀有度、价格、标签、效果说明。

UI 脚本负责：

- 读取数据。
- 实例化对应子场景。
- 更新选中态。
- 发出交互信号。

不要把条目、设置项、数据写死在 `.tscn` 节点文本里，除非它是永远不会变化的静态标题。

## 6.1 动态列表生命周期

动态列表刷新时必须检查节点生命周期，不只是“能重新显示”。

验收点：

- 清理旧节点时不会留下重复信号连接。
- 刷新后当前选中项能恢复，或有明确默认选中项。
- `ScrollContainer` 滚动位置符合预期，切页时可回到顶部。
- 已完成、已售出、已禁用等状态不会因为重建节点丢失。
- 空列表要有占位状态，而不是空白面板。
- 焦点在键盘/手柄操作下能回到合理节点。

## 7. 命名和目录约定

推荐目录：

```text
res://
  scenes/
    <module_a>/
    <module_b>/
    common/
  scripts/
    <module_a>/
    <module_b>/
    common/
  assets/
    ui/
      <module_a>/
        icons/
        icons_src/
        frames/
      <module_b>/
        icons/
        items/
        items_src/
        frames/
        characters/
        characters_src/
        marks/
```

命名规则：

- 场景使用大驼峰：`ListItemCard.tscn`。
- 脚本使用小写下划线：`list_item_card.gd`。
- PNG 使用小写下划线：`piercing_arrow.png`。
- 有 `art` key 的条目资产名优先和 `art` 保持一致；无 `art` key 的资产名使用稳定语义名。
- 同一模块的场景和脚本放在对应目录，不混进其他模块。
- 资产目录统一使用模块优先：`assets/ui/<module>/icons`、`assets/ui/<module>/items`，不使用 `assets/ui/icons/<module>` 这种跨模块目录。
- 被外部脚本绑定的节点应使用语义名，例如 `PrimaryActionButton`、`ResourceValue`、`ItemGrid`；只有不被脚本引用的内部静态 Label 可以使用泛名。

## 7.1 样式和主题归属

固定视觉属性优先放在 `.tscn`、Theme 或 `.tres` 资源中。脚本只负责状态切换和少量运行时变化。

推荐：

- 通用 UI helper 放 `scripts/common/`。
- 模块脚本只使用本模块数据和通用 UI helper。
- 固定字号、固定尺寸、固定 panel 样式，优先落在场景或主题资源。
- hover、selected、disabled、sold 等状态，可由脚本切换 style 或 `modulate`。

不推荐：

- 模块脚本引用另一个模块专用的 UI factory。
- 页面总控脚本集中设置所有固定节点的尺寸、字体、颜色、边框。
- 每个模块复制一份近似但不同名的颜色常量。

## 7.2 输入映射约束

UI 场景不应在 `_ready()` 静默注册全局 `InputMap`。输入动作应写入 `project.godot`，或由项目级初始化脚本统一注册。

页面脚本可以读取这些动作：

```text
ui_up
ui_down
ui_left
ui_right
ui_accept
ui_cancel
ui_focus_prev
ui_focus_next
ui_page_prev
ui_page_next
```

如果需要 Q/E、LB/RB 切页，也应作为项目级动作存在，而不是由某个 UI 页面临时添加。

## 8. 验收清单

每完成一个 HTML 页面转换，至少检查以下项目：

```text
[ ] 页面根设计尺寸与 HTML 原型一致
[ ] 主要面板、卡片、图标槽位尺寸与 HTML 一致
[ ] gap、padding、主要留白关系与 HTML 一致
[ ] 页面级分区尺寸与位置关系已对照 HTML 逐项核对
[ ] 关键小组件尺寸已单独核对，不以页面级接近替代组件级验收
[ ] progress bar、badge、icon strip、counter、符号行、标题/正文间距等风险组件的长度、厚度、相对位置、视觉权重符合 HTML
[ ] 页面级场景存在
[ ] 大面板已拆成合理子场景
[ ] 重复项已拆成可实例化子场景
[ ] 主要可见结构已写入 .tscn
[ ] 固定文本、尺寸、纹理、默认状态、Theme/style 覆盖等可序列化属性已写入 .tscn 或资源
[ ] 容器同级顺序与 HTML DOM 顺序一致
[ ] HTML 的 grid 区域在 Godot 中仍是相同列数/换行结果的栅格布局
[ ] 没有把 grid 区域擅自改成线性堆叠布局
[ ] 脚本没有承担大量固定节点创建
[ ] 脚本没有在 _ready()/setup 中批量设置本可静态保存的 UI 属性
[ ] HTML 中的 JS 数据已完整迁移
[ ] HTML 中的 SVG 图标已逐项处理
[ ] HTML 中具有图标语义的字符型符号已逐项登记
[ ] 必须 PNG 化的资产没有遗漏
[ ] 不该 PNG 化的文本和按钮仍是 Godot 原生控件
[ ] 选中、悬停、禁用、售罄等状态可刷新
[ ] Godot headless 能加载主场景和关键子场景
[ ] 对照 HTML 原型检查布局、素材、文字、交互
[ ] 页面根场景不是空壳，固定子场景已静态实例化
[ ] 必须 PNG 化的资产已从 Label 占位替换为 TextureRect
[ ] 字符型图标条未依赖临时字体碰运气显示，已有稳定实现
[ ] PNG 源 SVG、导出尺寸、资源路径和 import 设置已记录
[ ] 伪元素资产已逐项登记并给出处理方式
[ ] 状态矩阵已逐项验收
[ ] 动态列表刷新后没有状态、焦点、信号问题
[ ] 关键状态已有 HTML/Godot 对照截图
```

推荐验证命令：

```powershell
godot --headless --path . --scene res://scenes/<module>/<PageRoot>.tscn --quit-after 1
godot --headless --path . --scene res://scenes/<module>/<KeySubScene>.tscn --quit-after 1
```

建议补充自动检查：

```text
[ ] 检查关键容器的尺寸约束是否已写入场景或主题
[ ] 检查 grid 容器子节点顺序是否与 HTML 对照表一致
[ ] 枚举 .tscn，确认关键节点类型为 TextureRect 而不是 Label
[ ] 检查必须资产路径存在
[ ] 检查页面脚本中固定节点 .new() 数量是否异常
[ ] 检查关键子场景是否以 instance 方式存在于页面根场景
[ ] 检查 L3 阶段不再存在 TODO/占位图标
```

## 8.1 截图验收

L4 前必须保留截图对照。

推荐目录：

```text
html_ui/screenshots/html/<page_name>/
html_ui/screenshots/godot/<page_name>/
```

截图矩阵：

- 默认打开状态。
- hover/focus 一个主要列表项。
- selected/active 状态。
- disabled/sold 状态。
- Toast 显示状态。
- 至少 1 张整页对照图。
- 至少 1 张高风险组件局部对照图，例如 `progress bar`、`badge`、`icon strip`、`counter`、符号行或标题/正文高密度区域。
- 1280x720。
- 1920x1080。

视觉验收不要求像素级完全一致，但核心布局比例、关键资产、状态表达、文字密度不能明显偏离 HTML 原型。
页面尺寸、主面板尺寸、网格列数和主要模块顺序也不能偏离；这些项应视为硬性通过条件，而不是“观感差不多即可”。
如果整页截图看起来接近，但局部高风险组件的长度、厚度、相对位置或视觉权重仍明显错误，也不能判定截图验收通过。

## 9. 常见错误

1. 只迁移 JS 数据，漏掉 CSS/SVG 资产。
2. `.tscn` 只有根节点，所有 UI 都在脚本里创建。
3. 把固定文本、尺寸、Theme override、纹理和默认状态集中写进 `_ready()`，而不是保存在 `.tscn` 或资源里。
4. 把条目图标、分类图标临时换成文字后忘记补 PNG。
5. 把整块 UI 截图当背景，导致后续无法交互。
6. 拆分过细，简单 Label 和容器都变成子场景。
7. 拆分过粗，一个脚本同时管页面、列表项、按钮、数据和保存。
8. 用硬编码节点路径但场景文件结构不稳定。
9. 未对照 HTML 的 `::before`、`::after`，漏掉关键装饰。
10. 未区分普通 CSS 样式和图像性质 CSS。
11. 没有跑 Godot 加载测试，节点路径错误留到运行时才暴露。
12. 没有截图对照，导致“能跑但不像”。
13. 把 `♥`、`◆` 这类符号当普通文本，漏掉图标语义和状态表达职责。
14. 让页面总控脚本承担子面板职责，最终变成巨型脚本。
15. hover/focus 行为只改样式，没有同步 HTML 中对应的数据变化。
16. 执行、售出、资源不足等状态只改文字，没有补齐禁用视觉。

## 10. 标准收尾动作

每次完成一页 HTML 转 Godot 后，建议按以下顺序收尾：

1. 导出并接入本页必须 PNG 化的 SVG 资产，替换所有文字占位。
2. 评估页面主框、列表项边框、详情框是否需要 NinePatch 或 StyleBoxTexture。
3. 保留文字、价格、描述、按钮为 Godot 原生控件。
4. 把页面固定背景、主框、Toast、固定大面板和固定控件属性静态落到场景文件或资源。
5. 为复杂页面补专项拆分计划，逐步拆出 Topbar、SidePanel、ListPanel、Footer、Toast 等模块。
6. 补齐 hover、focus、selected、disabled、sold 等状态联动。
7. 建立该页面的资产复原表和截图验收目录。
8. 在需要时补背景光效 Shader，但不要把它当作第一轮阻塞项。

## 11. 资产复原表模板

每个 HTML 页面应维护一张资产复原表，可以放在对应转换计划文档里。

| 源页面 | CSS选择器/SVG key | 内容 | 必须等级 | 导出源 | 导出PNG | Godot节点 | 处理方式 | 验收状态 |
|---|---|---|---|---|---|---|---|---|
| `<page_name>.html` | `icons.primary` | 主列表项图标 | L3 | `assets/ui/<module>/items_src/primary.svg` | `assets/ui/<module>/items/primary.png` | `ListItemCard/Art` | `TextureRect` | 未完成 |
| `<page_name>.html` | `.hero-art svg` | 角色立绘 | L3 | `assets/ui/<module>/characters_src/main_character.svg` | `assets/ui/<module>/characters/main_character.png` | `PageSidePanel/HeroArt` | `TextureRect` | 未完成 |
| `<page_name>.html` | `categoryIcons.display` | 分类图标 | L3 | `assets/ui/<module>/icons_src/display.svg` | `assets/ui/<module>/icons/display.png` | `CategoryButton/Icon` | `TextureRect` | 未完成 |

必须等级建议：

- `L2`：状态表达必须存在，可用 Godot 样式近似。
- `L3`：资产必须接入，不允许文字占位。
- `L4`：需要截图高保真对照。
