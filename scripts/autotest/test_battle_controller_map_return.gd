extends SceneTree

const BattleControllerScript := preload("res://scripts/battle/battle_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var controller := BattleControllerScript.new()
	get_root().add_child(controller)
	await process_frame

	_assert(
		controller.get_victory_return_scene_path() == "res://scenes/map3d/run_hex_map_3d.tscn",
		"battle victory return uses routed 3D run map path"
	)

	controller.return_to_run_map_after_victory()
	await process_frame
	await process_frame

	var loaded_scene := get_current_scene()
	_assert(
		loaded_scene != null and loaded_scene.scene_file_path == "res://scenes/map3d/run_hex_map_3d.tscn",
		"battle victory return changes scene to routed run map"
	)

	print("PASS test_battle_controller_map_return")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
