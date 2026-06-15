extends SceneTree

const RunHexMapScene := preload("res://scenes/map3d/run_hex_map_3d.tscn")
const RunManagerScript := preload("res://scripts/run/run_manager.gd")
const BattleLaunchConfigScript := preload("res://scripts/battle/battle_launch_config.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManagerScript.current_ctx = RunManagerScript.create_preview_ctx()
	BattleLaunchConfigScript.clear()

	var instance := RunHexMapScene.instantiate()
	get_root().add_child(instance)
	await process_frame
	await process_frame

	_assert(instance.debug_get_tile_count() == 7, "formal ctx scene builds expected tile count")
	_assert(instance.debug_get_connection_count() == 8, "formal ctx scene builds expected connection count")

	instance.debug_enter_node(&"shop_1")
	await process_frame
	_assert(instance.debug_get_message() == "Completed: shop_1", "shop node completes through formal ctx flow")

	instance.debug_enter_node(&"battle_1")
	await process_frame
	_assert(instance.debug_get_message() == "Battle launch: battle_1", "battle node triggers formal battle launch flow")
	_assert(BattleLaunchConfigScript.current_config.get("map_node_id", "") == "battle_1", "battle launch config stores entered node id")

	RunManagerScript.clear()
	BattleLaunchConfigScript.clear()
	print("PASS test_run_hex_map_3d_formal_ctx")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	RunManagerScript.clear()
	BattleLaunchConfigScript.clear()
	push_error(message)
	quit(1)
