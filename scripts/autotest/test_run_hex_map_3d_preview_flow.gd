extends SceneTree

const RUN_HEX_MAP_SCENE := preload("res://scenes/map3d/run_hex_map_3d.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var instance := RUN_HEX_MAP_SCENE.instantiate()
	get_root().add_child(instance)
	await process_frame
	await process_frame

	instance.debug_select_node(&"event_1")
	_assert(instance.debug_get_selected_state() == &"locked", "locked preview node can be selected")
	_assert(not instance.debug_is_enter_enabled(), "Enter disabled for locked preview node")
	instance.debug_enter_node(&"event_1")
	_assert(instance.debug_get_message() == "Node is locked", "locked preview node reports blocked message")

	instance.debug_select_node(&"battle_1")
	_assert(instance.debug_get_selected_state() == &"available", "available preview node can be selected")
	_assert(instance.debug_is_enter_enabled(), "Enter enabled for available preview node")
	instance.debug_enter_node(&"battle_1")
	_assert(instance.debug_get_message() == "Preview enter: battle_1", "available preview node reports enter message")

	var camera_target: Vector3 = instance.debug_get_camera_target()
	_assert(camera_target.x < 10.0 and camera_target.z > -20.0, "camera target stays within preview bounds")

	print("PASS test_run_hex_map_3d_preview_flow")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
