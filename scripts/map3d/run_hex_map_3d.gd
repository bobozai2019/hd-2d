extends Node3D

const RunHexMapLayoutScript := preload("res://scripts/map3d/run_hex_map_layout.gd")
const RunManagerScript := preload("res://scripts/run/run_manager.gd")
const BattleLaunchConfigScript := preload("res://scripts/battle/battle_launch_config.gd")
const HD2D_CHARACTER_TEMPLATE := preload("res://scenes/map3d/characters/hd2d_character_template.tscn")
const MAT_GROUND := preload("res://assets/generated/map3d/materials/mat_hd2d_ground.tres")
const MAT_WALL := preload("res://assets/generated/map3d/materials/mat_hd2d_wall.tres")
const MAT_FOREGROUND := preload("res://assets/generated/map3d/materials/mat_hd2d_foreground.tres")
const MAT_BACKGROUND := preload("res://assets/generated/map3d/materials/mat_hd2d_background.tres")
const MAT_EMISSION_WARM := preload("res://assets/generated/map3d/materials/mat_hd2d_emission_warm.tres")
const MAT_EMISSION_COOL := preload("res://assets/generated/map3d/materials/mat_hd2d_emission_cool.tres")
const HD2D_TORCH_EFFECT_SCENE := preload("res://scenes/map3d/vfx/hd2d_torch_effect.tscn")

const PREVIEW_NODES := [
	{"node_id": "entry", "node_type": "current", "state": "current", "layer_index": 0, "lane_index": 0, "layer_width": 1, "reward": "Start"},
	{"node_id": "battle_1", "node_type": "battle", "state": "available", "layer_index": 1, "lane_index": 0, "layer_width": 2, "reward": "Battle"},
	{"node_id": "shop_1", "node_type": "shop", "state": "available", "layer_index": 1, "lane_index": 1, "layer_width": 2, "reward": "Shop"},
	{"node_id": "event_1", "node_type": "event", "state": "locked", "layer_index": 2, "lane_index": 0, "layer_width": 3, "reward": "Event"},
	{"node_id": "rest_1", "node_type": "rest", "state": "locked", "layer_index": 2, "lane_index": 1, "layer_width": 3, "reward": "Rest"},
	{"node_id": "battle_2", "node_type": "battle", "state": "completed", "layer_index": 2, "lane_index": 2, "layer_width": 3, "reward": "Completed"},
	{"node_id": "boss_1", "node_type": "boss", "state": "locked", "layer_index": 3, "lane_index": 1, "layer_width": 1, "reward": "Boss"},
]

const PREVIEW_EDGES := [
	["entry", "battle_1"],
	["entry", "shop_1"],
	["battle_1", "event_1"],
	["battle_1", "rest_1"],
	["shop_1", "battle_2"],
	["event_1", "boss_1"],
	["rest_1", "boss_1"],
	["battle_2", "boss_1"],
]

@onready var _tile_root: Node3D = $StageRoot/TileRoot
@onready var _connection_root: Node3D = $StageRoot/ConnectionRoot
@onready var _landmark_root: Node3D = $StageRoot/LandmarkRoot
@onready var _background_layer: Node3D = $StageRoot/BackgroundLayer
@onready var _foreground_layer: Node3D = $StageRoot/ForegroundLayer
@onready var _atmosphere_root: Node3D = $StageRoot/AtmosphereRoot
@onready var _character_root: Node3D = $CharacterRoot
@onready var _camera_rig: Node3D = $CameraRig
@onready var _camera: Camera3D = $CameraRig/Camera3D
@onready var _hud = $HudLayer/RunHexMapHud
@onready var _vfx_root: Node3D = $VfxRoot
@onready var _ambient_particles_root: Node3D = $VfxRoot/AmbientParticles
@onready var _glow_sources_root: Node3D = $VfxRoot/GlowSources
@onready var _skill_samples_root: Node3D = $VfxRoot/SkillSamples
@onready var _fog_planes_root: Node3D = $VfxRoot/FogPlanes
@onready var _dynamic_lights_root: Node3D = $VfxRoot/DynamicLights

var _tiles_by_id := {}
var _ctx: Dictionary = {}
var _selected_tile: Area3D
var _hovered_tile: Area3D
var _preview_layout: Dictionary = {}
var _preview_bounds := AABB()
var _camera_target := Vector3.ZERO
var _camera_height := 6.2
var _camera_distance := 9.25
var _has_camera_bounds := false
var _skill_feedback_mesh: MeshInstance3D
var _feedback_light: OmniLight3D
var _torch_samples_root: Node3D


func _ready() -> void:
	_connect_hud()
	if _bind_run_context():
		_hud.set_error("")
		_build_context_scene()
	else:
		_hud.set_run_state({"act_name": "Preview", "hp": 48, "gold": 123})
		_hud.set_error("No active run context - preview fallback active")
		_build_preview_scene()
	_build_vfx_samples()
	_apply_default_camera()
	_hud.set_camera_state({
		"projection": _camera.projection,
		"fov": _camera.fov,
		"size": _camera.size,
	})


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var tile := _pick_tile((event as InputEventMouseButton).position)
		if tile != null:
			_select_tile(tile)


func refresh() -> void:
	if _has_context_map_system():
		_build_context_scene()
	else:
		_build_preview_scene()


func debug_get_tile_count() -> int:
	return _tiles_by_id.size()


func debug_get_connection_count() -> int:
	return _connection_root.get_child_count()


func debug_enter_node(node_id: StringName) -> void:
	_enter_node(node_id)


func debug_select_node(node_id: StringName) -> void:
	var tile := _tiles_by_id.get(node_id) as Area3D
	if tile != null:
		_select_tile(tile)


func debug_get_message() -> String:
	return _hud.get_message()


func debug_get_selected_state() -> StringName:
	if _selected_tile == null:
		return &""
	return StringName(_selected_tile.get_meta("state", &""))


func debug_is_enter_enabled() -> bool:
	return _hud.is_enter_enabled()


func debug_get_camera_target() -> Vector3:
	return _camera_target


func debug_get_camera_fov() -> float:
	return _camera.fov


func debug_focus_node(node_id: StringName) -> void:
	var tile := _tiles_by_id.get(node_id) as Area3D
	if tile != null:
		_focus_world(tile.global_position + Vector3(0.0, 0.4, 0.0))


func debug_get_vfx_counts() -> Dictionary:
	return {
		"ambient_particles": _ambient_particles_root.get_child_count(),
		"glow_sources": _glow_sources_root.get_child_count(),
		"skill_samples": _skill_samples_root.get_child_count(),
		"fog_planes": _fog_planes_root.get_child_count(),
		"dynamic_lights": _dynamic_lights_root.get_child_count(),
		"torch_samples": _torch_samples_root.get_child_count() if _torch_samples_root != null else 0,
		"torch_dynamic_lights": _count_torch_dynamic_lights(),
	}


func _connect_hud() -> void:
	_hud.back_requested.connect(_return_to_main_menu)
	_hud.zoom_in_requested.connect(func() -> void:
		_camera.fov = maxf(24.0, _camera.fov - 3.0)
		_push_camera_state()
	)
	_hud.zoom_out_requested.connect(func() -> void:
		_camera.fov = minf(42.0, _camera.fov + 3.0)
		_push_camera_state()
	)
	_hud.reset_view_requested.connect(_apply_default_camera)
	_hud.focus_selected_requested.connect(func() -> void:
		if _selected_tile != null:
			_focus_world(_selected_tile.global_position + Vector3(0.0, 0.4, 0.0))
	)
	_hud.enter_selected_requested.connect(_try_enter_selected)


func _build_preview_scene() -> void:
	_ctx.clear()
	_clear_node_children(_tile_root)
	_clear_node_children(_connection_root)
	_clear_node_children(_landmark_root)
	_clear_node_children(_character_root)
	_clear_node_children(_background_layer)
	_clear_node_children(_foreground_layer)
	_clear_node_children(_atmosphere_root)
	_tiles_by_id.clear()

	_preview_layout = RunHexMapLayoutScript.build_layout(PREVIEW_NODES)
	_preview_bounds = RunHexMapLayoutScript.get_map_bounds(_preview_layout)
	_has_camera_bounds = true
	_build_tiles(_preview_layout)
	_build_connections(_preview_layout)
	_build_background_layers()
	_build_foreground_layers()
	_build_atmosphere_layers()
	_build_character()
	_build_vfx_samples()
	_hud.set_hover_tile({})
	_hud.set_selected_tile({})
	_hud.show_message("Select a node")


func _build_context_scene() -> void:
	_clear_node_children(_tile_root)
	_clear_node_children(_connection_root)
	_clear_node_children(_landmark_root)
	_clear_node_children(_character_root)
	_clear_node_children(_background_layer)
	_clear_node_children(_foreground_layer)
	_clear_node_children(_atmosphere_root)
	_tiles_by_id.clear()

	var map_system = _ctx.get("map_system")
	var nodes: Array = map_system.get_visible_nodes()
	var edges: Array = map_system.get_visible_edges()
	_preview_layout = RunHexMapLayoutScript.build_layout(nodes)
	_preview_bounds = RunHexMapLayoutScript.get_map_bounds(_preview_layout)
	_has_camera_bounds = true
	_build_tiles_from_nodes(nodes, map_system)
	_build_connections_from_edges(edges)
	_build_background_layers()
	_build_foreground_layers()
	_build_atmosphere_layers()
	_build_character()
	_build_vfx_samples()
	_hud.set_run_state({
		"act_name": _ctx.get("act_name", "Act 1"),
		"hp": _ctx.get("hp", 0),
		"gold": _ctx.get("gold", 0),
	})
	_hud.set_hover_tile({})
	_hud.set_selected_tile({})
	_hud.show_message("Select a node")


func _build_tiles(layout: Dictionary) -> void:
	_build_tiles_from_nodes(PREVIEW_NODES, null)


func _build_tiles_from_nodes(nodes: Array, map_system: Variant) -> void:
	for node_variant in nodes:
		var node: Dictionary = node_variant
		var node_id := StringName(node.get("node_id", ""))
		var entry: Dictionary = _preview_layout.get(node_id, {})
		var world := entry.get("world", Vector3.ZERO) as Vector3
		var tile_node := node.duplicate(true)
		if map_system != null and map_system.has_method("get_node_state"):
			tile_node["state"] = String(map_system.get_node_state(node_id))
		var tile := _create_tile(tile_node, entry)
		tile.position = world
		_tile_root.add_child(tile)
		_landmark_root.add_child(_create_landmark(tile_node, world))
		_tiles_by_id[node_id] = tile


func _build_connections_from_edges(edges: Array) -> void:
	for edge in edges:
		var from_id := StringName(edge[0])
		var to_id := StringName(edge[1])
		var from_entry: Dictionary = _preview_layout.get(from_id, {})
		var to_entry: Dictionary = _preview_layout.get(to_id, {})
		if from_entry.is_empty() or to_entry.is_empty():
			continue
		var from_world := from_entry.get("world", Vector3.ZERO) as Vector3
		var to_world := to_entry.get("world", Vector3.ZERO) as Vector3
		var line_root := Node3D.new()
		line_root.name = "%s_to_%s" % [from_id, to_id]
		var body := MeshInstance3D.new()
		body.mesh = BoxMesh.new()
		var mesh := body.mesh as BoxMesh
		mesh.size = Vector3(0.18, 0.04, from_world.distance_to(to_world))
		body.material_override = _get_connection_material(_compute_connection_state(from_id, to_id))
		line_root.add_child(body)
		line_root.position = (from_world + to_world) * 0.5 + Vector3(0.0, 0.05, 0.0)
		_connection_root.add_child(line_root)
		line_root.look_at(to_world + Vector3(0.0, 0.05, 0.0), Vector3.UP)


func _build_connections(layout: Dictionary) -> void:
	_build_connections_from_edges(PREVIEW_EDGES)


func _build_background_layers() -> void:
	var silhouette := MeshInstance3D.new()
	silhouette.mesh = BoxMesh.new()
	var box := silhouette.mesh as BoxMesh
	box.size = Vector3(6.8, 2.1, 0.4)
	silhouette.material_override = MAT_BACKGROUND
	silhouette.position = Vector3(_preview_bounds.get_center().x, 1.35, _preview_bounds.position.z - 2.6)
	_background_layer.add_child(silhouette)


func _build_foreground_layers() -> void:
	var pillar := MeshInstance3D.new()
	pillar.mesh = BoxMesh.new()
	var pillar_box := pillar.mesh as BoxMesh
	pillar_box.size = Vector3(0.42, 1.85, 0.42)
	pillar.material_override = MAT_FOREGROUND
	pillar.position = Vector3(-3.1, 0.92, 1.25)
	_foreground_layer.add_child(pillar)

	var canopy := MeshInstance3D.new()
	canopy.mesh = BoxMesh.new()
	var canopy_box := canopy.mesh as BoxMesh
	canopy_box.size = Vector3(1.5, 0.18, 0.85)
	canopy.material_override = MAT_FOREGROUND
	canopy.position = Vector3(-2.55, 1.7, 1.22)
	_foreground_layer.add_child(canopy)


func _build_atmosphere_layers() -> void:
	var fog_plane := MeshInstance3D.new()
	fog_plane.mesh = QuadMesh.new()
	var quad := fog_plane.mesh as QuadMesh
	quad.size = Vector2(8.4, 3.2)
	var fog_material := StandardMaterial3D.new()
	fog_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_material.albedo_color = Color(0.62, 0.68, 0.74, 0.16)
	fog_material.disable_receive_shadows = true
	fog_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fog_plane.material_override = fog_material
	fog_plane.position = Vector3(0.0, 1.0, -1.7)
	_atmosphere_root.add_child(fog_plane)


func _build_character() -> void:
	var character := HD2D_CHARACTER_TEMPLATE.instantiate()
	var current_node_id := &"entry"
	if _has_context_map_system():
		current_node_id = _ctx.get("map_system").get_current_node_id()
		if current_node_id == &"":
			var available_ids: Array = _ctx.get("map_system").get_available_node_ids()
			current_node_id = StringName(available_ids[0]) if not available_ids.is_empty() else &"entry"
	var current_entry: Dictionary = _preview_layout.get(current_node_id, {})
	var current_world := current_entry.get("world", Vector3.ZERO) as Vector3
	character.position = current_world + Vector3(0.0, 0.02, 0.0)
	_character_root.add_child(character)


func _create_tile(node: Dictionary, entry: Dictionary) -> Area3D:
	var root := Area3D.new()
	root.name = "Tile_%s" % String(node.get("node_id", ""))
	root.input_ray_pickable = true
	root.set_meta("node_id", StringName(node.get("node_id", "")))
	root.set_meta("node_type", StringName(node.get("node_type", "")))
	root.set_meta("state", StringName(node.get("state", "")))
	root.set_meta("reward", node.get("reward", "-"))
	root.set_meta("axial", entry.get("axial", Vector2i.ZERO))

	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = CylinderMesh.new()
	var tile_mesh := body.mesh as CylinderMesh
	tile_mesh.top_radius = 0.95
	tile_mesh.bottom_radius = 0.95
	tile_mesh.height = 0.16
	tile_mesh.radial_segments = 6
	body.material_override = _get_tile_material(StringName(node.get("state", "")))
	body.position.y = 0.08
	root.add_child(body)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.95
	cylinder.height = 0.18
	collision.shape = cylinder
	collision.position.y = 0.09
	root.add_child(collision)

	var selection_ring := MeshInstance3D.new()
	selection_ring.name = "SelectionRing"
	selection_ring.mesh = CylinderMesh.new()
	var ring_mesh := selection_ring.mesh as CylinderMesh
	ring_mesh.top_radius = 1.08
	ring_mesh.bottom_radius = 1.08
	ring_mesh.height = 0.02
	ring_mesh.radial_segments = 6
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.95, 0.74, 0.24, 0.92)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.95, 0.74, 0.24, 1.0)
	ring_material.emission_energy_multiplier = 0.38
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selection_ring.material_override = ring_material
	selection_ring.visible = StringName(node.get("state", "")) == &"current"
	selection_ring.position.y = 0.17
	root.add_child(selection_ring)

	var state_accent := _create_state_accent(StringName(node.get("state", "")))
	if state_accent != null:
		root.add_child(state_accent)

	return root


func _create_landmark(node: Dictionary, world: Vector3) -> MeshInstance3D:
	var landmark := MeshInstance3D.new()
	landmark.name = "Landmark_%s" % String(node.get("node_id", ""))
	landmark.mesh = CylinderMesh.new()
	var landmark_mesh := landmark.mesh as CylinderMesh
	landmark_mesh.top_radius = 0.24
	landmark_mesh.bottom_radius = 0.24
	landmark_mesh.height = 0.78
	landmark_mesh.radial_segments = 8
	landmark.position = world + Vector3(0.0, 0.49, 0.0)
	landmark.material_override = _get_landmark_material(StringName(node.get("node_type", "")))
	return landmark


func _pick_tile(screen_position: Vector2) -> Area3D:
	var origin := _camera.project_ray_origin(screen_position)
	var direction := _camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 100.0)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	return result.get("collider") as Area3D


func _update_hover(screen_position: Vector2) -> void:
	var tile := _pick_tile(screen_position)
	if tile == _hovered_tile:
		return
	_hovered_tile = tile
	if tile == null:
		_hud.set_hover_tile({})
		return
	_hud.set_hover_tile(_build_tile_info(tile))


func _select_tile(tile: Area3D) -> void:
	if _selected_tile != null and is_instance_valid(_selected_tile):
		var previous_ring := _selected_tile.get_node_or_null("SelectionRing") as MeshInstance3D
		if previous_ring != null:
			previous_ring.visible = StringName(_selected_tile.get_meta("state", &"")) == &"current"
	_selected_tile = tile
	var ring := tile.get_node_or_null("SelectionRing") as MeshInstance3D
	if ring != null:
		ring.visible = true
	_hud.set_selected_tile(_build_tile_info(tile))
	var state_name := StringName(tile.get_meta("state", &""))
	if state_name == &"available":
		_hud.show_message("Ready to enter")
		_play_select_feedback(tile)
	else:
		_hud.show_message(_get_blocked_message(state_name))


func _try_enter_selected() -> void:
	if _selected_tile == null:
		_hud.show_message("Select a node first")
		return
	var node_id := StringName(_selected_tile.get_meta("node_id", &""))
	_enter_node(node_id)


func _enter_node(node_id: StringName) -> void:
	var tile := _tiles_by_id.get(node_id) as Area3D
	if tile == null:
		_hud.show_message("Node cannot be entered")
		return
	if _has_context_map_system():
		var map_system = _ctx.get("map_system")
		if not map_system.can_enter_node(node_id):
			_hud.show_message("Node is not available")
			return
		var result: Dictionary = map_system.enter_node(node_id)
		if not bool(result.get("success", false)):
			_hud.show_message("Node cannot be entered")
			return
		var node: Dictionary = result.get("node", {})
		var node_type := StringName(node.get("node_type", ""))
		var result_message := "Entered: %s" % String(node_id)
		match node_type:
			&"battle", &"boss":
				BattleLaunchConfigScript.current_config = {
					"map_node_id": String(node_id),
					"node_type": String(node_type),
				}
				result_message = "Battle launch: %s" % String(node_id)
			&"shop", &"rest", &"event":
				map_system.complete_node(node_id)
				result_message = "Completed: %s" % String(node_id)
		_play_enter_feedback(tile)
		_focus_world(tile.global_position + Vector3(0.0, 0.4, 0.0))
		refresh()
		_hud.show_message(result_message)
		return
	var state_name := StringName(tile.get_meta("state", &""))
	if state_name != &"available":
		_hud.show_message(_get_blocked_message(state_name))
		return
	_hud.show_message("Preview enter: %s" % String(node_id))
	_play_enter_feedback(tile)
	_focus_world(tile.global_position + Vector3(0.0, 0.4, 0.0))


func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _bind_run_context() -> bool:
	var current_ctx: Dictionary = RunManagerScript.current_ctx
	if current_ctx.is_empty():
		return false
	if not current_ctx.has("map_system"):
		return false
	_ctx = current_ctx
	return true


func _has_context_map_system() -> bool:
	return not _ctx.is_empty() and _ctx.has("map_system")


func _apply_default_camera() -> void:
	_camera_target = _preview_bounds.get_center()
	_camera_target.y = 0.8
	_clamp_camera_target()
	_apply_camera_transform()
	_camera.fov = 34.0
	_push_camera_state()


func _build_tile_info(tile: Area3D) -> Dictionary:
	return {
		"node_id": tile.get_meta("node_id", "-"),
		"node_type": tile.get_meta("node_type", &"-"),
		"state": tile.get_meta("state", &"-"),
		"reward": tile.get_meta("reward", "-"),
	}


func _compute_connection_state(from_id: StringName, to_id: StringName) -> StringName:
	var from_tile := _tiles_by_id.get(from_id) as Area3D
	var to_tile := _tiles_by_id.get(to_id) as Area3D
	if from_tile == null or to_tile == null:
		return &"locked"
	var from_state := StringName(from_tile.get_meta("state", &"locked"))
	var to_state := StringName(to_tile.get_meta("state", &"locked"))
	if from_state == &"completed" and to_state == &"completed":
		return &"completed"
	if from_state == &"current":
		return &"available"
	if from_state == &"completed" and to_state == &"available":
		return &"available"
	return &"locked"


func _get_tile_material(state_name: StringName) -> Material:
	match state_name:
		&"available":
			return MAT_GROUND
		&"current":
			return MAT_EMISSION_WARM
		&"completed":
			return MAT_BACKGROUND
		&"locked":
			return MAT_WALL
		_:
			return MAT_GROUND


func _get_landmark_material(node_type: StringName) -> Material:
	match node_type:
		&"battle", &"boss", &"current":
			return MAT_EMISSION_WARM
		&"shop", &"rest":
			return MAT_EMISSION_COOL
		&"event":
			return MAT_FOREGROUND
		_:
			return MAT_BACKGROUND


func _get_connection_material(state_name: StringName) -> Material:
	match state_name:
		&"available":
			return MAT_EMISSION_WARM
		&"completed":
			return MAT_BACKGROUND
		_:
			return MAT_WALL


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


func _create_state_accent(state_name: StringName) -> Node3D:
	match state_name:
		&"available":
			var glow_ring := MeshInstance3D.new()
			glow_ring.name = "StateAccent"
			glow_ring.mesh = CylinderMesh.new()
			var glow_ring_mesh := glow_ring.mesh as CylinderMesh
			glow_ring_mesh.top_radius = 0.7
			glow_ring_mesh.bottom_radius = 0.7
			glow_ring_mesh.height = 0.1
			glow_ring_mesh.radial_segments = 6
			var glow_ring_material := StandardMaterial3D.new()
			glow_ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glow_ring_material.albedo_color = Color(1.0, 0.84, 0.36, 0.26)
			glow_ring_material.emission_enabled = true
			glow_ring_material.emission = Color(1.0, 0.84, 0.36, 1.0)
			glow_ring_material.emission_energy_multiplier = 0.45
			glow_ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			glow_ring.material_override = glow_ring_material
			glow_ring.position.y = 0.23
			return glow_ring
		&"completed":
			var history_marker := MeshInstance3D.new()
			history_marker.name = "StateAccent"
			history_marker.mesh = BoxMesh.new()
			var history_mesh := history_marker.mesh as BoxMesh
			history_mesh.size = Vector3(0.18, 0.46, 0.18)
			var history_material := StandardMaterial3D.new()
			history_material.albedo_color = Color(0.32, 0.38, 0.44, 0.92)
			history_material.roughness = 0.92
			history_material.metallic_specular = 0.08
			history_marker.material_override = history_material
			history_marker.position = Vector3(0.0, 0.42, 0.0)
			return history_marker
		&"locked":
			var lock_cap := MeshInstance3D.new()
			lock_cap.name = "StateAccent"
			lock_cap.mesh = SphereMesh.new()
			var lock_sphere := lock_cap.mesh as SphereMesh
			lock_sphere.radius = 0.18
			lock_sphere.height = 0.36
			var lock_material := StandardMaterial3D.new()
			lock_material.albedo_color = Color(0.18, 0.22, 0.28, 0.96)
			lock_material.roughness = 1.0
			lock_cap.material_override = lock_material
			lock_cap.position = Vector3(0.0, 0.34, 0.0)
			return lock_cap
		_:
			return null


func _focus_world(world_position: Vector3) -> void:
	_camera_target = world_position
	_clamp_camera_target()
	_apply_camera_transform()
	_push_camera_state()


func _clamp_camera_target() -> void:
	if not _has_camera_bounds:
		return
	var min_x := _preview_bounds.position.x
	var max_x := _preview_bounds.position.x + _preview_bounds.size.x
	var min_z := _preview_bounds.position.z
	var max_z := _preview_bounds.position.z + _preview_bounds.size.z
	_camera_target.x = clampf(_camera_target.x, min_x, max_x)
	_camera_target.z = clampf(_camera_target.z, min_z, max_z)


func _apply_camera_transform() -> void:
	_camera_rig.position = _camera_target + Vector3(0.0, _camera_height, _camera_distance)
	_camera.look_at(_camera_target, Vector3.UP)


func _push_camera_state() -> void:
	_hud.set_camera_state({"projection": _camera.projection, "fov": _camera.fov, "size": _camera.size})


func _clear_node_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _build_vfx_samples() -> void:
	if _ambient_particles_root.get_child_count() == 0:
		var ambient := GPUParticles3D.new()
		ambient.name = "Fireflies"
		ambient.amount = 16
		ambient.lifetime = 3.8
		ambient.preprocess = 1.2
		ambient.draw_pass_1 = QuadMesh.new()
		var ambient_quad := ambient.draw_pass_1 as QuadMesh
		ambient_quad.size = Vector2(0.08, 0.08)
		var ambient_process := ParticleProcessMaterial.new()
		ambient_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		ambient_process.emission_box_extents = Vector3(3.8, 1.2, 4.4)
		ambient_process.gravity = Vector3(0.0, 0.03, 0.0)
		ambient_process.initial_velocity_min = 0.02
		ambient_process.initial_velocity_max = 0.08
		ambient_process.scale_min = 0.55
		ambient_process.scale_max = 1.05
		ambient_process.color = Color(0.86, 0.92, 1.0, 0.18)
		ambient.process_material = ambient_process
		ambient.position = Vector3(0.0, 1.1, -2.0)
		_ambient_particles_root.add_child(ambient)

	if _glow_sources_root.get_child_count() == 0:
		for node_id in [&"battle_1", &"shop_1"]:
			var tile := _tiles_by_id.get(node_id) as Area3D
			if tile == null:
				continue
			var glow := MeshInstance3D.new()
			glow.name = "Glow_%s" % String(node_id)
			glow.mesh = CylinderMesh.new()
			var glow_mesh := glow.mesh as CylinderMesh
			glow_mesh.top_radius = 0.14
			glow_mesh.bottom_radius = 0.14
			glow_mesh.height = 0.72
			var glow_material := StandardMaterial3D.new()
			glow_material.albedo_color = Color(1.0, 0.82, 0.38, 1.0) if node_id == &"battle_1" else Color(0.46, 0.76, 1.0, 1.0)
			glow_material.emission_enabled = true
			glow_material.emission = glow_material.albedo_color
			glow_material.emission_energy_multiplier = 0.85
			glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			glow.material_override = glow_material
			glow.position = tile.position + Vector3(0.0, 0.38, 0.0)
			_glow_sources_root.add_child(glow)

	if _skill_feedback_mesh == null:
		_skill_feedback_mesh = MeshInstance3D.new()
		_skill_feedback_mesh.name = "NodePulse"
		_skill_feedback_mesh.mesh = QuadMesh.new()
		var pulse_quad := _skill_feedback_mesh.mesh as QuadMesh
		pulse_quad.size = Vector2(0.9, 0.9)
		var pulse_material := StandardMaterial3D.new()
		pulse_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pulse_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		pulse_material.albedo_color = Color(1.0, 0.8, 0.28, 0.0)
		pulse_material.emission_enabled = true
		pulse_material.emission = Color(1.0, 0.8, 0.28, 1.0)
		pulse_material.emission_energy_multiplier = 0.56
		pulse_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_skill_feedback_mesh.material_override = pulse_material
		_skill_feedback_mesh.visible = false
		_skill_samples_root.add_child(_skill_feedback_mesh)

	if _fog_planes_root.get_child_count() == 0:
		var fog_plane := MeshInstance3D.new()
		fog_plane.name = "RouteFog"
		fog_plane.mesh = QuadMesh.new()
		var fog_quad := fog_plane.mesh as QuadMesh
		fog_quad.size = Vector2(8.2, 3.0)
		var fog_material := StandardMaterial3D.new()
		fog_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fog_material.albedo_color = Color(0.62, 0.68, 0.74, 0.14)
		fog_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fog_material.disable_receive_shadows = true
		fog_plane.material_override = fog_material
		fog_plane.position = Vector3(0.0, 1.0, -2.0)
		_fog_planes_root.add_child(fog_plane)

	if _feedback_light == null:
		_feedback_light = OmniLight3D.new()
		_feedback_light.name = "SelectionFlash"
		_feedback_light.light_color = Color(1.0, 0.8, 0.34, 1.0)
		_feedback_light.light_energy = 0.0
		_feedback_light.omni_range = 3.5
		_dynamic_lights_root.add_child(_feedback_light)

	_build_torch_samples()


func _play_select_feedback(tile: Area3D) -> void:
	if _skill_feedback_mesh == null:
		return
	_skill_feedback_mesh.visible = true
	_skill_feedback_mesh.position = tile.position + Vector3(0.0, 0.28, 0.0)
	_skill_feedback_mesh.scale = Vector3.ONE
	var pulse_material := _skill_feedback_mesh.material_override as StandardMaterial3D
	pulse_material.albedo_color = Color(1.0, 0.8, 0.28, 0.22)
	var tween := create_tween()
	tween.tween_property(_skill_feedback_mesh, "scale", Vector3(1.3, 1.3, 1.0), 0.18)
	tween.parallel().tween_property(pulse_material, "albedo_color", Color(1.0, 0.8, 0.28, 0.0), 0.18)
	tween.finished.connect(func() -> void:
		_skill_feedback_mesh.visible = false
	)


func _build_torch_samples() -> void:
	_ensure_torch_samples_root()
	if _torch_samples_root.get_child_count() > 0:
		return

	var entry_tile := _tiles_by_id.get(&"entry") as Area3D
	var battle_tile := _tiles_by_id.get(&"battle_1") as Area3D
	var entry_position := Vector3(-1.4, 0.0, 0.8)
	var battle_position := Vector3(1.35, 0.0, -0.6)
	if entry_tile != null:
		entry_position = entry_tile.position + Vector3(-0.82, 0.0, 0.72)
	if battle_tile != null:
		battle_position = battle_tile.position + Vector3(0.82, 0.0, -0.68)

	_add_torch_sample("RunTorch_Key", entry_position, true, 0.46, 3.2, 0.4)
	_add_torch_sample("RunTorch_Atmosphere", battle_position, false, 0.0, 2.6, 3.2)


func _ensure_torch_samples_root() -> void:
	if _torch_samples_root != null and is_instance_valid(_torch_samples_root):
		return
	_torch_samples_root = _vfx_root.get_node_or_null("TorchSamples") as Node3D
	if _torch_samples_root == null:
		_torch_samples_root = Node3D.new()
		_torch_samples_root.name = "TorchSamples"
		_vfx_root.add_child(_torch_samples_root)


func _add_torch_sample(torch_name: String, torch_position: Vector3, enabled_light: bool, light_energy: float, light_range: float, flicker_phase: float) -> void:
	var torch := HD2D_TORCH_EFFECT_SCENE.instantiate() as Node3D
	torch.name = torch_name
	torch.position = torch_position
	torch.set("light_enabled", enabled_light)
	torch.set("light_base_energy", light_energy)
	torch.set("light_range", light_range)
	torch.set("flicker_phase", flicker_phase)
	torch.set("profile_rank", 3)
	torch.set("shadows_enabled", enabled_light)
	torch.set("sparks_enabled", enabled_light)
	_torch_samples_root.add_child(torch)


func _count_torch_dynamic_lights() -> int:
	if _torch_samples_root == null:
		return 0
	var count := 0
	for child in _torch_samples_root.get_children():
		if child.has_method("get_torch_light"):
			var light := child.call("get_torch_light") as OmniLight3D
			if light != null and light.visible:
				count += 1
	return count


func _play_enter_feedback(tile: Area3D) -> void:
	if _feedback_light == null:
		return
	_feedback_light.position = tile.position + Vector3(0.0, 1.0, 0.0)
	var tween := create_tween()
	tween.tween_property(_feedback_light, "light_energy", 0.75, 0.08)
	tween.tween_property(_feedback_light, "light_energy", 0.0, 0.18)
	tween.parallel().tween_property(_camera, "fov", 31.5, 0.1)
	tween.tween_property(_camera, "fov", 34.0, 0.2)
