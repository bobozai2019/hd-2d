# Debugging Knowledge

## 2026-06-07: 调试阶段报错优先看 logs/godot.log

**Symptom:** 用户在 Godot 调试/F5 流程中看到后台报错，但 `godotiq_read_debug_console` 返回 0 条 runtime/script errors。

**Investigation:** `logs/godot.log` 记录了 GodotIQ 控制台未捕获的真实运行时 backtrace。

**Root cause:** Debug/F5 运行阶段的部分后台错误可能只落到项目日志文件，不一定同步进入 GodotIQ 的调试控制台读取结果。

**How to apply:** 用户提到"点调试有报错""后台运行有报错"或 GodotIQ 日志为空但现象不对时，第一时间读取 `logs/godot.log`，用其中最新 backtrace 定位根因，再结合 GodotIQ/场景树验证。

## 2026-05-20: Resource.get() 不支持默认值参数

**Symptom:** `some_resource.get("property", "")` 崩溃：`Expected 1 argument(s)`。

**Investigation:**
- GDScript 的 `Dictionary.get()` 支持默认值参数，但 `Resource.get()` 不支持——它是 Godot 内核方法，只接受 1 个属性名参数。
- 继承自 `Resource` 的自定义资源类同样走 Resource.get() 路径。

**Root cause:** `Resource.get()` 签名是 `get(property: StringName) -> Variant`，不接受默认值参数。与 Dictionary.get(key, default) 行为不同。

**Fix:** 改用 `resource.get("property")` 单参数读取，再用 `if value == null` 处理缺失情况。

**How to apply:** 读取 Resource 属性时，永远只传 1 个参数给 `.get()`。需要默认值逻辑时，先 `.get()` 再判断 null。

## 2026-05-14: editor.log 是编译错误的权威来源

GodotIQ 调试控制台 (`godotiq_read_debug_console`) 只捕获运行时错误。所有 parse/compile 错误写入 `logs/editor.log`，且错误会重复出现（reload + check 各触发一次）。

**Why:** 编辑器日志包含 GodotIQ 控制台看不到的脚本解析错误，是排查 "为什么场景加载失败" 的第一步。

**How to apply:** 当 `check_errors` 报 0 错误但场景仍有问题时，读取 `logs/editor.log` 查找历史 parse error。注意同一个错误会因 reload/check 产生 2-4 条重复日志。

## 2026-05-14: RefCounted 动态属性赋值失败

试图给 `RefCounted` 子类赋值未声明的属性，Godot 4 运行时报 `Invalid assignment of property or key`。

**Why:** RefCounted 不像 GDScript 内部类那样允许动态属性扩展，必须在类脚本中显式声明 `var`。

**How to apply:** 当 controller 给 context 赋值新字段时，确保 context 脚本中已有对应 `var` 声明。报错信息格式：`Invalid assignment of property or key 'xxx' with value of type 'yyy' on a base object of type 'RefCounted (zzz.gd)'`。

## 2026-06-07: GodotIQ 会话残留导致验收探测卡住

**Symptom:** GodotIQ 交互验收探测可能卡在旧运行会话、旧场景或工具超时。

**Investigation:** GodotIQ/MCP 会话状态可能残留，`game_scene_tree` 等工具也可能超时。显式停止旧会话并从目标主场景重新启动后可恢复。

**Root cause:** GodotIQ/MCP 会话状态残留，未显式清理导致工具调用超时。

**How to apply:** 做 GodotIQ/MCP 交互验收前，优先显式停止旧会话并从目标主场景重新启动。遇到交互探测卡住时，三轮尝试中允许把完整路径拆成更小证据链，如按钮可触发、节点存在、日志无错。

## 2026-05-17: 插件可预期降级状态不要用 push_error

**Symptom:** `logs/editor.log` 出现 GodotIQ 端口绑定 `[ERROR]`，但项目脚本加载和场景测试都能通过。

**Investigation:** `6007` 端口被已有编辑器/GodotIQ 实例占用时，新实例启动失败属于可预期状态。GodotIQ 插件用 `push_error()` 上报，EditorLogger 因而写入 `[ERROR]`，污染真正需要处理的错误列表。

**Root cause:** 插件把可预期的降级场景用 `push_error()` 上报，而非普通状态信息。

**Fix:** 端口不可用时改成普通 `print()` 状态信息，状态栏显示 skipped，并 `set_process(false)` 停止当前 server 节点处理。

**How to apply:** 看到端口绑定 error 先确认是否已有 editor/GodotIQ 实例占用端口。对插件的"可预期降级状态"用普通状态输出，不要用 `push_error()` / `push_warning()`。

## 2026-05-14: 全屏 Control 叠层阻挡按钮点击

一个 `PRESET_FULL_RECT` 的 Control 用于 `draw_line` 绘制，添加在按钮节点之后（同级 sibling）。默认 `mouse_filter = MOUSE_FILTER_STOP` 导致该不可见 Control 拦截了所有鼠标输入，下方按钮完全无法点击。

**Why:** Godot 4 中同级节点后添加的渲染在上层，默认 STOP 模式会消费输入事件不再向下传递。

**How to apply:** 对仅用于绘制（draw_line/draw_circle 等）的 Control 覆盖层，必须设置 `mouse_filter = Control.MOUSE_FILTER_IGNORE`。同样适用于调试绘制、连线、覆盖装饰等场景。
