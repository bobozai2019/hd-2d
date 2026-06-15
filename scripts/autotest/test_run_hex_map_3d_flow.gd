extends SceneTree

const RUN_HEX_MAP_SCENE := preload("res://scenes/map3d/run_hex_map_3d.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var instance := RUN_HEX_MAP_SCENE.instantiate()
	get_root().add_child(instance)
	await process_frame
	await process_frame

	instance.debug_select_node(&"battle_2")
	_assert(instance.debug_get_selected_state() == &"completed", "completed node can be inspected")
	_assert(not instance.debug_is_enter_enabled(), "Enter disabled for completed node")
	instance.debug_enter_node(&"battle_2")
	_assert(instance.debug_get_message() == "Node already completed", "completed node reports completed message")

	instance.debug_select_node(&"shop_1")
	_assert(instance.debug_get_selected_state() == &"available", "available node can be selected")
	_assert(instance.debug_is_enter_enabled(), "Enter enabled for available node")
	instance.debug_enter_node(&"shop_1")
	_assert(instance.debug_get_message() == "Preview enter: shop_1", "available node enter goes through preview flow")

	var camera_target: Vector3 = instance.debug_get_camera_target()
	_assert(camera_target.length() > 0.1, "preview enter updates camera target")

	print("PASS test_run_hex_map_3d_flow")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
