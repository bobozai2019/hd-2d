# 阶段 4：HUD 精修和玩家反馈

## 目标

把 Phase 3 的可运行 3D Run 地图打磨到玩家可以理解、可验证、可回退的状态。重点是 HUD 信息、不可点击反馈、相机限制、节点状态可读性和手动截图验收。

## 文件计划

修改：

- `scenes/map3d/run_hex_map_hud.tscn`
- `scripts/map3d/run_hex_map_hud.gd`
- `scripts/map3d/run_hex_map_3d.gd`
- `scripts/map3d/hex_map_camera.gd`
- `scripts/map3d/hex_tile_3d.gd`
- `scripts/map3d/hex_connection_3d.gd`

创建或修改测试：

- `scripts/autotest/test_run_hex_map_3d_hud.gd`
- `scripts/autotest/test_run_hex_map_3d_camera.gd`

## 任务 4.1：HUD 信息层级

Run HUD 采用 CanvasLayer + Control，不放入 3D 世界。

建议结构：

```text
RunHexMapHud Control
├─ TopBar PanelContainer
│  └─ Row HBoxContainer
│     ├─ TitleLabel
│     ├─ ActLabel
│     ├─ HpLabel
│     ├─ GoldLabel
│     ├─ ZoomOutButton
│     ├─ ZoomInButton
│     ├─ ResetViewButton
│     ├─ FocusSelectedButton
│     └─ BackButton
├─ InfoPanel PanelContainer
│  └─ InfoList VBoxContainer
│     ├─ HoverTitle
│     ├─ HoverIdLabel
│     ├─ HoverTypeLabel
│     ├─ HoverStateLabel
│     ├─ SelectedTitle
│     ├─ SelectedIdLabel
│     ├─ SelectedTypeLabel
│     ├─ SelectedStateLabel
│     ├─ SelectedRewardLabel
│     └─ CameraSizeLabel
├─ BottomBar PanelContainer
│  └─ Row HBoxContainer
│     ├─ MessageLabel
│     └─ EnterSelectedButton
└─ ErrorPanel PanelContainer
   └─ ErrorLabel
```

显示文案：

- Title：`3D Run Map`
- 无 hover：`Hover: -`
- 无 selected：`Selected: -`
- locked 点击提示：`Node is locked`
- completed 点击提示：`Node already completed`
- current 点击提示：`Node already active`
- available selected：`Ready to enter`
- ctx 缺失：`No active run context`

## 任务 4.2：节点类型和状态标签统一

在 `run_hex_map_hud.gd` 内部实现小型格式化方法：

```gdscript
func _format_node_type(node_type: StringName) -> String:
	match node_type:
		&"battle":
			return "Battle"
		&"shop":
			return "Shop"
		&"rest":
			return "Rest"
		&"event":
			return "Event"
		&"boss":
			return "Boss"
		_:
			return str(node_type)

func _format_state(state_name: StringName) -> String:
	match state_name:
		&"available":
			return "Available"
		&"locked":
			return "Locked"
		&"current":
			return "Current"
		&"completed":
			return "Completed"
		_:
			return str(state_name)
```

如需中文 UI，可统一改为中文，但同一场景内不能混用中英文状态。

## 任务 4.3：相机边界限制

扩展 `scripts/map3d/hex_map_camera.gd`，支持地图边界：

```gdscript
var _bounds := AABB(Vector3(-8, -1, -8), Vector3(16, 2, 16))
var _has_bounds := false

func set_bounds(bounds: AABB, padding: float = 2.0) -> void:
	_bounds = bounds.grow(padding)
	_has_bounds = true
	_clamp_center()
	_apply_transform()

func _clamp_center() -> void:
	if not _has_bounds:
		return
	_center.x = clampf(_center.x, _bounds.position.x, _bounds.position.x + _bounds.size.x)
	_center.z = clampf(_center.z, _bounds.position.z, _bounds.position.z + _bounds.size.z)
```

在 `move_plane()`、`pan()`、`focus_world()` 更新 `_center` 后调用 `_clamp_center()`。

Phase 1 的 MVP 场景如果没有调用 `set_bounds()`，行为保持原样。

## 任务 4.4：选择和进入反馈

`run_hex_map_3d.gd` 点击逻辑：

- hover 只改变 hover 状态，不改变 selected。
- 左键点击任何 tile 都更新 selected 和 HUD。
- selected 是 available 时启用 `EnterSelectedButton`。
- 左键双击或点击底部 Enter 按钮都可以进入 available 节点。
- 点击 locked/completed/current 不进入节点，只显示消息。

实现建议：

```gdscript
func _try_enter_selected() -> void:
	if _selected_tile == null:
		_hud.show_message("Select a node first")
		return
	var node_id: StringName = _selected_tile.get_meta("node_id", &"")
	_enter_node(node_id)
```

不可进入原因：

```gdscript
func _get_blocked_message(state_name: StringName) -> String:
	match state_name:
		&"locked":
			return "Node is locked"
		&"completed":
			return "Node already completed"
		&"current":
			return "Node already active"
		_:
			return "Node cannot be entered"
```

## 任务 4.5：连接线状态刷新

连接线状态根据 from/to 节点状态计算：

- from completed 且 to available：`available`
- from completed 且 to completed：`completed`
- from current：`available`
- 其他：`locked`

刷新时不要增量猜测，直接清空 `ConnectionRoot` 后重建，保证商店/休息/事件完成后状态准确。

## 任务 4.6：HUD 自动化测试

创建 `scripts/autotest/test_run_hex_map_3d_hud.gd`。

覆盖：

- HUD 场景可加载。
- `set_run_state()` 后 Act/HP/Gold 标签有值。
- `set_hover_tile({})` 和 `set_selected_tile({})` 不报错并显示空状态。
- selected 为 locked 时 Enter 按钮 disabled。
- selected 为 available 时 Enter 按钮 enabled。
- `show_message("Node is locked")` 后 MessageLabel 文本更新。
- `set_error("No active run context")` 后 ErrorPanel 可见。

运行：

```bash
godot --headless --script scripts/autotest/test_run_hex_map_3d_hud.gd
```

预期：

- HUD 测试通过。

## 任务 4.7：相机自动化测试

创建 `scripts/autotest/test_run_hex_map_3d_camera.gd`。

覆盖：

- `hex_map_camera.gd` 在未设置 bounds 时 `move_plane()`、`pan()`、`zoom()` 正常。
- 设置 bounds 后，大幅 `focus_world(Vector3(999, 0, 999))` 会被 clamp 到 bounds 内。
- `zoom(-100)` 不低于 `MIN_ORTHOGRAPHIC_SIZE`。
- `zoom(100)` 不高于 `MAX_ORTHOGRAPHIC_SIZE`。
- MVP 场景加载后相机仍可 reset。

运行：

```bash
godot --headless --script scripts/autotest/test_run_hex_map_3d_camera.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_input.gd
```

预期：

- 相机测试通过。
- MVP 输入测试仍通过。

## 任务 4.8：截图验收

运行场景截图：

```bash
godot --headless --script scripts/tools/capture_scene.gd
```

如果现有 `capture_scene.gd` 只捕获固定场景，则先按项目已有模式增加对 `scenes/map3d/run_hex_map_3d.tscn` 的捕获参数或临时配置；不要提交 `output/` 截图，除非项目维护者明确要求。

截图验收口径：

- 节点和连接线在 1920x1080 下清晰可辨。
- HUD 不遮挡核心可点击节点。
- selected 状态明显区别于 hover。
- locked 与 available 状态一眼可区分。
- 相机默认视角能看到当前 act 的主要路径。
- 字体不溢出按钮或面板。

## 阶段完成标准

- HUD 能解释玩家当前 hover、selected、Act、HP、Gold 和可执行动作。
- 相机不能拖到地图完全不可见的位置。
- 节点不可进入原因有清晰反馈。
- 商店/休息/事件完成后连接线和节点状态立即刷新。
- HUD、相机、MVP 回归测试通过。
