# 代码规范

版本：v0.1
日期：2026-06-15

## GDScript 基本规则

- 文件、变量、函数使用 `snake_case`。
- 有 `class_name` 的类使用 `PascalCase`。
- 公共函数必须声明返回类型，公共参数尽量声明类型。
- 私有字段和私有辅助方法使用 `_` 前缀。
- 场景节点引用使用 `@onready var _name: Type = $Path/To/Node`。
- 常量资源脚本使用 `const XxxScript = preload("res://...")`。
- 类成员变量使用显式类型标注，例如 `var _drag_start_x: float = 0.0`，避免 `:=` 在算术链中传播 `Variant`。
- 给 `RefCounted`、`Node` 或 `Resource` 实例写入新字段前，必须先在对应脚本中声明 `var`。
- 生产逻辑避免裸 `print()`；需要长期保留的调试输出统一走 `DevLog.debug()`。
- 注释解释规则原因，不解释普通赋值。

## UI/场景静态配置硬规则

- 能直接放在 `.tscn` 里的 UI 元素、场景节点、容器层级、装饰节点，不要改成脚本动态创建。
- 能直接在编辑器里配置好的属性，不要放到脚本里二次赋值，例如文本占位、颜色、尺寸、锚点、偏移、主题、纹理、最小尺寸、`mouse_filter`、可见性默认值。
- 严禁把静态初始化塞进 `_ready()`。`_ready()` 不是场景编辑器的替代品。
- 只有当某个值依赖运行时上下文、玩家状态、配置注入或节点实例化结果时，才允许在 `_ready()` 或其他运行时逻辑中设置。
- 如果一个值在大多数运行中都是固定的，只是个别情况下需要变化，默认值仍应先写在场景里，脚本只处理那部分动态覆盖。
- 审查 UI 脚本时，凡是"可以提前烘焙进场景"的节点创建和属性赋值，都应视为需要迁移回 `.tscn` 的实现债务。

## 开发日志

AI 可观测性和人工排查都使用 `scripts/utils/dev_log.gd`：

- 生产脚本不直接调用 `print()`。
- `DevLog.debug(channel, message, fields)` 是唯一长期保留的运行时调试入口。
- 默认只在 editor 环境启用，导出包关闭。
- 临时测试脚本仍可直接 `print()` 汇报 PASS/诊断信息。
- 新增日志字段优先用简单标量，避免把大型对象整包写入日志。
- 插件或工具遇到可预期降级状态时，用普通状态输出，不使用 `push_error()` / `push_warning()` 制造长期错误噪音。

## Headless 脚本

`scripts/autotest/` 下的 headless 测试脚本通常 `extends SceneTree`：

- 成功退出使用 `quit(0)`。
- 失败退出使用 `quit(1)`。
- 不调用 `set_exit_code()`；`SceneTree` 没有该方法。

## `class_name` 策略

量产目标：

- 逻辑层脚本声明 `class_name`：`System`、`State`、`Def`、`Context`、`Events`、`Manager`、通用工具。
- 页面或组件根 UI 脚本不新增 `class_name`，由场景路径和 `preload()` 引用。
- 测试/工具脚本不声明 `class_name`。

UI 仍然要尽量强类型。需要引用 UI 根脚本类型时，在使用方局部声明脚本类型：

```gdscript
const MapScreenScript := preload("res://scripts/ui/map_screen.gd")

var screen: MapScreenScript = MapScreenScene.instantiate() as MapScreenScript
if current_screen is MapScreenScript:
    pass
```

这种写法不注册全局类名，适合页面导航、局部组件协作和测试。只有真正作为跨系统稳定公共 API 的 UI 类，才允许声明 `class_name`，并在本规范中记录例外。

## 信号规范

- 信号命名使用过去式或请求式事件名，保持附近代码风格：`position_changed`、`back_requested`、`item_selected`。
- 系统间通知通过明确的信号总线或局部 UI 信号，不让无关系统互相硬引用。
- 新增跨系统事件时，必须同时补：
  - 信号声明。
  - 触发位置。
  - 监听接线。
  - 最小验证脚本。

## 新系统接入

新增系统必须满足：

- 只保存必要的上下文引用和局部缓存。
- 暴露 `setup(ctx) -> void`。
- 状态写入 `scripts/state/`，静态配置写入 `scripts/resources/`。
- 在上下文容器中声明引用。
- 在控制器/管理器中创建并调用 `setup()`。

## 量产迁移清单

当前已知迁移项：

- UI 根脚本里已有 `class_name`，后续分批移除或明确例外。
- 生产脚本里存在无返回类型函数，后续分批补齐。
- 继续把新增可观测性接入 `DevLog`，避免恢复散落 `print()`。
