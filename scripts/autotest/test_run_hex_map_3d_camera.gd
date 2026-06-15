extends SceneTree

const RUN_HEX_MAP_SCENE := preload("res://scenes/map3d/run_hex_map_3d.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var instance := RUN_HEX_MAP_SCENE.instantiate()
	get_root().add_child(instance)
	await process_frame
	await process_frame

	_assert(instance.has_method("debug_get_camera_target"), "scene exposes camera target debug hook")
	_assert(instance.has_method("debug_get_camera_fov"), "scene exposes camera fov debug hook")
	_assert(instance.has_method("debug_focus_node"), "scene exposes focus hook")

	var initial_target: Vector3 = instance.debug_get_camera_target()
	_assert(initial_target.distance_to(Vector3.ZERO) > 0.1, "default camera target is initialized from preview bounds")

	instance.debug_focus_node(&"battle_1")
	await process_frame
	var focused_target: Vector3 = instance.debug_get_camera_target()
	_assert(focused_target.distance_to(initial_target) > 0.1, "focus hook moves camera target")

	instance.debug_enter_node(&"battle_1")
	await process_frame
	await process_frame
	await process_frame
	var settled_fov := float(instance.debug_get_camera_fov())
	_assert(absf(settled_fov - 34.0) < 0.15, "enter feedback returns camera fov to default framing")

	print("PASS test_run_hex_map_3d_camera")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
