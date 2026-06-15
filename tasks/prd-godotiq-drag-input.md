# PRD: GodotIQ Timed Drag Input

## 简介

GodotIQ 当前 `godotiq_input` 支持 action、key、mouse motion、click 和 tap，但缺少能表达真实拖拽节奏的输入命令。新增 `drag_at` 让测试和代理可以模拟玩家从一个 viewport 坐标按下、等待、拖动到另一个坐标、停顿并释放，且不绑定任何游戏业务。

## 目标

- 在 `godotiq_input` 中支持 viewport 坐标拖拽。
- 通过 Godot 引擎输入接口触发真实输入分发链路。
- 支持按下前后等待和拖动耗时，默认节奏为 100ms + 500ms + 100ms。
- 提供端到端测试证明 MCP 链路和 Godot 输入链路可用。

## 用户故事

### US-001: 发送业务无关拖拽输入
**描述：** 作为 GodotIQ 使用者，我想用 viewport 坐标发送拖拽，以便测试任意 Godot 项目的拖拽交互。

**验收标准：**
- [ ] `godotiq_input(commands=[{"drag_at": {"from": [120, 180], "to": [520, 420]}}])` 返回 `success: true`。
- [ ] 返回结果包含 `type: "drag_at"`、起点、终点、按钮、时间参数和步数。
- [ ] 实现不调用任何业务专用方法或信号。

### US-002: 控制拖拽节奏
**描述：** 作为测试作者，我想控制按下等待、拖动耗时和释放前等待，以便复现需要长按或平滑移动的交互。

**验收标准：**
- [ ] 默认 `hold_before_ms=100`、`duration_ms=500`、`hold_after_ms=100`、`button="left"`。
- [ ] 调用方可以覆盖 `hold_before_ms`、`duration_ms`、`hold_after_ms`、`button`、`steps`。
- [ ] 负数时间、无效坐标和未知按钮返回单条 command 失败结果，不导致 runtime 崩溃。
- [ ] `from == to`（零距离拖拽）时行为正确：按下→等待→释放，不产生 motion 事件。
- [ ] `steps=0` 时被 clampi 修正为 1，不报错。
- [ ] `duration_ms=0` 时每步走 `await process_frame` 分支，语义为即时拖拽。
- [ ] `hold_before_ms=0` 和 `hold_after_ms=0` 时跳过对应等待。
- [ ] `from` 或 `to` 为 `null` 或缺失时返回失败，不崩溃。
- [ ] `steps` 超过上限 240 时被静默截断到 240。

### US-003: 端到端验证真实输入链路
**描述：** 作为维护者，我想用 MCP E2E 测试验证拖拽确实进入 Godot 输入事件系统，以便后续重构不会悄悄绕过引擎接口。

**验收标准：**
- [ ] E2E 测试启动探针场景后，通过 `godotiq_input drag_at` 完成拖拽。
- [ ] 探针记录到一次 press、一次 release 和多次 motion。
- [ ] 探针记录的 press 起点和 release 终点与请求坐标一致。
- [ ] **降级策略：** 如果 headless 模式下 `_gui_input` 未收到事件（`press_count == 0`），则 E2E 退化为只验证 `godotiq_input` 返回结构正确（`ok: true`、`type: "drag_at"`、坐标正确），探针验证改为在编辑器 Play 模式下手动执行。在 PRD 和测试中标注此降级条件。

## 功能需求

- FR-1: `godotiq_input` 的 `commands` 必须支持 `{"drag_at": {"from": [x, y], "to": [x, y]}}`。
- FR-2: `drag_at.button` 必须复用现有 `"left" | "right" | "middle"` 解析。
- FR-3: runtime 必须使用 `Input.parse_input_event(...)` 注入 `InputEventMouseMotion` 和 `InputEventMouseButton`。
- FR-4: 拖拽事件顺序必须为：移动到起点、按下、等待、插值移动、等待、释放。
- FR-5: `track_side_effects`、`continue_on_error` 和 `wait_for` 必须继续按现有 `godotiq_input` 行为工作。
- FR-6: `steps` 参数上限为 240，超过时静默截断；`clampi` 行为应在技术考量中记录。
- FR-7: `from == to` 时执行按下→等待→释放流程，不产生 motion 事件。
- FR-8: `duration_ms=0` 时每步走 `await get_tree().process_frame` 分支，语义为即时拖拽。
- FR-9: `from` 或 `to` 为 `null` 或缺失时返回错误结果，不崩溃。

## 非目标

- 不新增 `godotiq_drag` 独立 MCP tool。
- 不新增 `drag_at_world`。
- 不提供按节点名拖拽或业务对象拖拽。
- 不修改项目现有业务逻辑。

## 技术考量

- `addons/godotiq/godotiq_runtime.gd` 和 `addons/godotiq/godotiq/addon/godotiq_runtime.gd` 必须同步修改。
- E2E 使用最小探针场景验证 Godot 输入事件，不依赖业务 UI。
- Python tool 当前已透传 `commands`，主要需要更新 docstring 和提示文档。
- **Headless 降级风险：** `Input.parse_input_event()` 注入的事件在 headless 模式下能否触发 `Control._gui_input` 未被 Godot 官方文档保证（`DisplayServerHeadless` 不影响 `Viewport::_gui_input_event` 但属于实现细节）。实现时先做最小 headless 验证；如果不分发，E2E 探针验证降级为只检查返回结构。

## 成功指标

- Headless drag helper 测试通过。
- MCP E2E drag input 测试通过。
- 现有拖拽回归测试通过。
- `godot --headless --quit` 项目加载通过。
