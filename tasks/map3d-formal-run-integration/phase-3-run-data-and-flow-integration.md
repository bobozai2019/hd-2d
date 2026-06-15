# 阶段 3：Run 数据和流程接入

## 目标

新建正式 3D Run 地图场景，消费当前 `RunManager.current_ctx`、`MapSystem` 和 `MapDef`，并让主菜单开始 Run、战斗胜利返回、商店/休息/事件完成返回都走统一地图路由。地图视觉层统一使用共享的六边形边线 overlay，保证格子边界清晰且和 MVP 口径一致。

## 文件计划

创建：

- `scripts/run/run_map_scene_router.gd`
- `scripts/map3d/run_hex_map_layout.gd`
- `scripts/map3d/hex_grid_overlay.gd`
- `scripts/map3d/run_hex_map_3d.gd`
- `scripts/map3d/run_hex_map_hud.gd`
- `scenes/map3d/hex_grid_overlay.tscn`
- `scenes/map3d/run_hex_map_3d.tscn`
- `scenes/map3d/run_hex_map_hud.tscn`
- `scripts/autotest/test_run_map_scene_router.gd`
- `scripts/autotest/test_run_hex_map_3d_layout.gd`
- `scripts/autotest/test_run_hex_map_3d_scene.gd`
- `scripts/autotest/test_run_hex_map_3d_flow.gd`

修改：

- `scripts/main/main.gd`
- `scripts/battle/battle_controller.gd`
- `scripts/ui/map_screen.gd`，仅在需要共享路由或测试钩子时做最小修改
- `docs/production/05-validation-matrix.md`

## 任务 3.1：实现 Run 地图场景路由

创建 `scripts/run/run_map_scene_router.gd`：

```gdscript
class_name RunMapSceneRouter
extends RefCounted

const USE_3D_RUN_MAP := true
const RUN_3D_MAP_SCENE := "res://scenes/map3d/run_hex_map_3d.tscn"
const LEGACY_2D_MAP_SCENE := "res://scenes/map/map_screen.tscn"
const MVP_MAP_SCENE := "res://scenes/map3d/hex_map_mvp.tscn"

static func get_run_map_scene_path() -> String:
	return RUN_3D_MAP_SCENE if USE_3D_RUN_MAP else LEGACY_2D_MAP_SCENE

static func get_legacy_map_scene_path() -> String:
	return LEGACY_2D_MAP_SCENE

static func get_mvp_map_scene_path() -> String:
	return MVP_MAP_SCENE
```

运行：

```bash
godot --headless --script scripts/autotest/test_run_map_scene_router.gd
```

预期：

- Phase 0 新增的 router 测试通过。

## 任务 3.2：把正式 Run 跳转改用 router

修改 `scripts/main/main.gd`：

- 新增 preload：`const RunMapSceneRouterScript := preload("res://scripts/run/run_map_scene_router.gd")`
- 正式开始 Run 后的 `change_scene_to_file("res://scenes/map/map_screen.tscn")` 改为：

```gdscript
get_tree().change_scene_to_file(RunMapSceneRouterScript.get_run_map_scene_path())
```

保留 `_open_hex_map_mvp()` 指向 `res://scenes/map3d/hex_map_mvp.tscn`，不要把实验按钮改成正式 Run 地图。

修改 `scripts/battle/battle_controller.gd`：

- 新增 preload：`const RunMapSceneRouterScript := preload("res://scripts/run/run_map_scene_router.gd")`
- 战斗胜利完成节点后，把返回 2D 地图的硬编码改为：

```gdscript
get_tree().change_scene_to_file(RunMapSceneRouterScript.get_run_map_scene_path())
```

运行：

```bash
godot --headless --script scripts/autotest/test_run_map_scene_router.gd
godot --headless --script scripts/autotest/test_run_loop.gd
```

预期：

- router 测试通过。
- Run loop 仍通过。

## 任务 3.3：实现 `run_hex_map_layout.gd`

创建纯逻辑布局器，避免把布局算法写死在场景脚本里。

接口：

```gdscript
class_name RunHexMapLayout
extends RefCounted

const TILE_SIZE := 0.72
const LAYER_SPACING_Z := 1.55
const LANE_SPACING_X := 1.35

static func build_layout(map_def) -> Dictionary:
	# 返回 node_id -> {"axial": Vector2i, "world": Vector3, "node": node}
	pass

static func get_map_bounds(layout: Dictionary) -> AABB:
	pass
```

布局规则：

- `layer_index` 控制纵向推进，越大的 layer 越靠地图前方。
- `lane_index` 控制横向位置，同层节点围绕中心对齐。
- `axial` 用于 HUD 和测试，不要求完全还原程序半径地图；推荐：

```gdscript
var q := node.lane_index - int(floor(layer_width * 0.5))
var r := node.layer_index
```

- `world.x = centered_lane * LANE_SPACING_X`
- `world.z = -node.layer_index * LAYER_SPACING_Z`
- `world.y = 0.0`

测试 `scripts/autotest/test_run_hex_map_3d_layout.gd` 覆盖：

- `MapBuilder.build_act1()` 的所有节点都有 layout。
- 每个 layout entry 都包含 `axial`、`world`、`node`。
- 同一个 `node_id` 的位置稳定。
- `get_map_bounds()` 尺寸非零。
- 所有 connection 的目标节点都能在 layout 中找到。

运行：

```bash
godot --headless --script scripts/autotest/test_run_hex_map_3d_layout.gd
```

预期：

- 布局测试通过。

## 任务 3.4：创建正式 3D Run 地图场景

创建 `scenes/map3d/run_hex_map_3d.tscn`，结构：

```text
RunHexMap3D Node3D
├─ WorldEnvironment
├─ DirectionalLight3D
├─ Ground MeshInstance3D
├─ GridOverlay Node3D
├─ ConnectionRoot Node3D
├─ HexRoot Node3D
├─ CameraRig Node3D
│  └─ Camera3D
└─ HUDLayer CanvasLayer
   ├─ RunHexMapHud Control
   └─ SubScreenHost Control
```

挂载：

- `RunHexMap3D`：`scripts/map3d/run_hex_map_3d.gd`
- `CameraRig`：复用 `scripts/map3d/hex_map_camera.gd`
- `RunHexMapHud`：`scenes/map3d/run_hex_map_hud.tscn`

`SubScreenHost` 要覆盖全屏，供 shop/rest/event 子界面作为 Control 添加。它不负责布局，只作为 overlay 容器。

`GridOverlay` 作为整张地图共享的六边形边线层，负责把格子边界一次性画清楚，不在每个 tile 上重复做描边。

## 任务 3.5：实现 `run_hex_map_3d.gd` 场景控制器

核心职责：

- `_ready()` 读取 `RunManagerScript.current_ctx`。
- 如果 ctx 缺失，HUD 显示错误并提供返回主菜单。
- 从 `_ctx.map_system.get_visible_nodes()` 和 `RunHexMapLayout.build_layout(_map_def)` 生成 tile。
- 根据 `_ctx.map_system.get_visible_edges()` 生成连接线。
- hover/click 使用与 MVP 相同的相机射线。
- 点击 available 节点时调用 `_enter_node(node_id)`。
- locked/completed/current 节点只更新 selected 和 HUD，不进入流程。
- shop/rest/event 完成后调用 `_ctx.map_system.complete_node(node_id)` 并 `refresh()`。
- battle/boss 节点设置 `BattleLaunchConfigScript.current_config` 后跳转战斗。

建议保留的方法名：

```gdscript
func refresh() -> void
func _rebuild_map() -> void
func _build_tiles(layout: Dictionary) -> void
func _build_connections(layout: Dictionary) -> void
func _pick_tile(screen_position: Vector2) -> Node
func _update_hover(screen_position: Vector2) -> void
func _select_tile(tile: Node) -> void
func _enter_node(node_id: StringName) -> void
func _launch_battle(node) -> void
func _open_shop(node) -> void
func _open_rest(node) -> void
func _open_event(node) -> void
func _on_sub_screen_completed(node_id: StringName) -> void
func _return_to_main_menu() -> void
```

节点状态刷新：

```gdscript
var state_name: StringName = _ctx.map_system.get_node_state(node.node_id)
tile.setup_run_node(node.node_id, node.node_type, entry.axial, state_name, node)
tile.set_locked(state_name == &"locked")
tile.set_available(state_name == &"available")
tile.set_completed(state_name == &"completed")
```

进入节点：

```gdscript
if not _ctx.map_system.can_enter_node(node_id):
	_hud.show_message("Node is not available")
	return
var result := _ctx.map_system.enter_node(node_id)
if not bool(result.get("success", false)):
	_hud.show_message("Node cannot be entered")
	return
var node = result.get("node")
match node.node_type:
	&"battle", &"boss":
		_launch_battle(node)
	&"shop":
		_open_shop(node)
	&"rest":
		_open_rest(node)
	&"event":
		_open_event(node)
```

商店/休息/事件逻辑应与 `scripts/ui/map_screen.gd` 保持一致。可先复制最小逻辑，再在后续重构为共享 helper；本任务优先保证行为一致和测试可验证。

## 任务 3.6：实现 Run HUD 最小版本

创建 `scenes/map3d/run_hex_map_hud.tscn` 与 `scripts/map3d/run_hex_map_hud.gd`。

信号：

```gdscript
signal back_requested
signal zoom_in_requested
signal zoom_out_requested
signal reset_view_requested
signal focus_selected_requested
signal enter_selected_requested
```

公开方法：

```gdscript
func set_run_state(run_state) -> void
func set_hover_tile(tile_info: Dictionary) -> void
func set_selected_tile(tile_info: Dictionary) -> void
func set_camera_state(camera_state: Dictionary) -> void
func show_message(message: String) -> void
func set_error(message: String) -> void
```

HUD 显示：

- Act 名称。
- HP。
- Gold。
- hover 节点 id/type/state。
- selected 节点 id/type/state。
- selected 节点动作按钮：只有 available 节点启用，按钮文案为 `Enter`。
- camera orthographic size。
- Back、Zoom In、Zoom Out、Reset、Focus Selected。

## 任务 3.7：补正式 3D Run 地图场景测试

创建 `scripts/autotest/test_run_hex_map_3d_scene.gd`。

覆盖：

- `scenes/map3d/run_hex_map_3d.tscn` 可加载。
- 场景有 `HexRoot`、`ConnectionRoot`、`CameraRig/Camera3D`、`HUDLayer/RunHexMapHud`、`HUDLayer/SubScreenHost`。
- 场景有 `HexRoot`、`GridOverlay`、`ConnectionRoot`、`CameraRig/Camera3D`、`HUDLayer/RunHexMapHud`、`HUDLayer/SubScreenHost`。
- 准备 `RunManager.current_ctx` 后实例化场景，等待至少 2 帧。
- `HexRoot.get_child_count()` 等于 `ctx.map_system.get_visible_nodes().size()`。
- `ConnectionRoot.get_child_count()` 等于 `ctx.map_system.get_visible_edges().size()`。
- `GridOverlay` 场景可加载并生成非空边线网格。
- 至少一个 available 节点对应 tile state 为 `available`。

运行：

```bash
godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd
```

预期：

- 场景测试通过。

## 任务 3.8：补正式 3D Run 地图流程测试

创建 `scripts/autotest/test_run_hex_map_3d_flow.gd`。

覆盖：

- 启动 warrior Run，加载 act 1。
- 实例化 `run_hex_map_3d.tscn`。
- 找到第一个 available battle 节点。
- 直接调用场景控制器公开测试辅助或内部方法进入节点。
- 进入 battle 节点后，`BattleLaunchConfigScript.current_config.map_node_id` 等于节点 id。
- 对 shop/rest/event 节点，调用完成回调后该节点变为 completed，并刷新出新的 available 后继。
- locked 节点调用进入逻辑不会改变 current/completed 字典。

为了测试可控，允许在 `run_hex_map_3d.gd` 增加测试友好的公开方法：

```gdscript
func debug_enter_node(node_id: StringName) -> void:
	_enter_node(node_id)

func debug_get_tile_count() -> int:
	return _tiles_by_id.size()

func debug_get_connection_count() -> int:
	return _connection_root.get_child_count()
```

这些方法只能读取或走正式内部流程，不绕过 `MapSystem`。

运行：

```bash
godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd
```

预期：

- 流程测试通过。
- `BattleLaunchConfigScript.current_config` 在测试结束时清空，避免污染后续测试。

## 任务 3.9：保留并验证 2D 回退入口

运行：

```bash
godot --headless --script scripts/autotest/test_map_screen.gd
godot --headless --script scripts/autotest/test_map_node_click.gd
godot --headless --script scripts/autotest/test_career_to_map.gd
```

预期：

- 2D 地图仍能独立加载和测试。
- 如果测试依赖硬编码 `map_screen.tscn`，不需要改成 3D；这些测试用于保护 legacy 入口。

## 阶段完成标准

- 正式 Run 跳转和战斗胜利返回都通过 `RunMapSceneRouter`。
- 3D Run 地图能从正式 `MapSystem` 数据生成节点和连接。
- 3D Run 地图能进入 battle/shop/rest/event/boss 节点。
- 2D 地图仍可回退并通过原测试。
- 新增 3D Run 地图 layout、scene、flow 测试通过。
