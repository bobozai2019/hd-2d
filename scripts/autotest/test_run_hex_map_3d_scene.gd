extends SceneTree

const RUN_HEX_MAP_SCENE := preload("res://scenes/map3d/run_hex_map_3d.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var instance := RUN_HEX_MAP_SCENE.instantiate()
	get_root().add_child(instance)
	await process_frame
	await process_frame

	_assert(instance.get_node_or_null("StageRoot/TileRoot") != null, "scene has TileRoot")
	_assert(instance.get_node_or_null("StageRoot/ConnectionRoot") != null, "scene has ConnectionRoot")
	_assert(instance.get_node_or_null("CameraRig/Camera3D") != null, "scene has CameraRig/Camera3D")
	_assert(instance.get_node_or_null("HudLayer/RunHexMapHud") != null, "scene has HUD")
	_assert(instance.get_node_or_null("HudLayer/SubScreenHost") != null, "scene has SubScreenHost")

	var script_instance = instance
	_assert(script_instance.has_method("debug_get_tile_count"), "scene controller exposes debug_get_tile_count")
	_assert(script_instance.has_method("debug_get_connection_count"), "scene controller exposes debug_get_connection_count")
	_assert(int(script_instance.call("debug_get_tile_count")) > 0, "preview scene builds tiles")
	_assert(int(script_instance.call("debug_get_connection_count")) > 0, "preview scene builds connections")
	_assert(script_instance.has_method("debug_get_vfx_counts"), "scene controller exposes debug_get_vfx_counts")
	var vfx_counts: Dictionary = script_instance.call("debug_get_vfx_counts")
	_assert(int(vfx_counts.get("torch_samples", 0)) == 2, "preview scene builds Phase 7 torch samples")
	_assert(int(vfx_counts.get("torch_dynamic_lights", 0)) == 1, "preview scene keeps torch dynamic lights below budget")

	print("PASS test_run_hex_map_3d_scene")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
