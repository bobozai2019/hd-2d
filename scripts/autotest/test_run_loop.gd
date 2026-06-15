extends SceneTree

const MainScene := preload("res://scenes/main/main.tscn")
const RunManagerScript := preload("res://scripts/run/run_manager.gd")
const BattleLaunchConfigScript := preload("res://scripts/battle/battle_launch_config.gd")
const BattleControllerScript := preload("res://scripts/battle/battle_controller.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManagerScript.current_ctx = RunManagerScript.create_preview_ctx()
	BattleLaunchConfigScript.clear()

	change_scene_to_packed(MainScene)
	await process_frame
	await process_frame

	var menu := get_current_scene()
	var start_button := menu.get_node("UiLayer/MenuRoot/Panel/Content/ButtonColumn/StartRunButton") as Button
	start_button.emit_signal("pressed")
	await process_frame
	await process_frame

	var run_scene := get_current_scene()
	_assert(run_scene != null and run_scene.scene_file_path == "res://scenes/map3d/run_hex_map_3d.tscn", "start run opens 3D run map")

	run_scene.debug_enter_node(&"battle_1")
	await process_frame
	_assert(BattleLaunchConfigScript.current_config.get("map_node_id", "") == "battle_1", "battle node entry prepares launch config")

	var battle_controller := BattleControllerScript.new()
	get_root().add_child(battle_controller)
	battle_controller.return_to_run_map_after_victory()
	await process_frame
	await process_frame

	var returned_scene := get_current_scene()
	_assert(returned_scene != null and returned_scene.scene_file_path == "res://scenes/map3d/run_hex_map_3d.tscn", "battle victory returns to routed 3D run map")

	RunManagerScript.clear()
	BattleLaunchConfigScript.clear()
	print("PASS test_run_loop")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	RunManagerScript.clear()
	BattleLaunchConfigScript.clear()
	push_error(message)
	quit(1)
