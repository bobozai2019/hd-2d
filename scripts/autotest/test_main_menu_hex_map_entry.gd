extends SceneTree

const MAIN_SCENE := preload("res://scenes/main/main.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_hex_map_entry_button_changes_scene()
	await _test_hd2d_effect_lab_button_changes_scene()
	await _test_start_run_button_changes_scene()
	print("PASS test_main_menu_hex_map_entry")
	quit(0)


func _test_hex_map_entry_button_changes_scene() -> void:
	var instance := await _spawn_main_scene()
	var button := instance.get_node_or_null("UiLayer/MenuRoot/Panel/Content/ButtonColumn/HexMapMvpButton") as Button
	_assert(button != null, "HexMapMvpButton exists")
	_assert(not button.disabled, "HexMapMvpButton is clickable")
	button.emit_signal("pressed")
	await process_frame
	var loaded_scene := get_current_scene()
	_assert(loaded_scene != null and loaded_scene.scene_file_path == "res://scenes/map3d/hex_map_mvp.tscn", "HexMapMvpButton opens MVP scene")
	_cleanup_current_scene()


func _test_hd2d_effect_lab_button_changes_scene() -> void:
	var instance := await _spawn_main_scene()
	var button := instance.get_node_or_null("UiLayer/MenuRoot/Panel/Content/ButtonColumn/Hd2dEffectLabButton") as Button
	_assert(button != null, "Hd2dEffectLabButton exists")
	_assert(not button.disabled, "Hd2dEffectLabButton is clickable")
	button.emit_signal("pressed")
	await process_frame
	var loaded_scene := get_current_scene()
	_assert(loaded_scene != null and loaded_scene.scene_file_path == "res://scenes/map3d/hd2d_effect_lab.tscn", "Hd2dEffectLabButton opens HD2D effect lab scene")
	_cleanup_current_scene()


func _test_start_run_button_changes_scene() -> void:
	var instance := await _spawn_main_scene()
	var button := instance.get_node_or_null("UiLayer/MenuRoot/Panel/Content/ButtonColumn/StartRunButton") as Button
	_assert(button != null, "StartRunButton exists")
	_assert(not button.disabled, "StartRunButton is clickable")
	button.emit_signal("pressed")
	await process_frame
	var loaded_scene := get_current_scene()
	_assert(loaded_scene != null and loaded_scene.scene_file_path == "res://scenes/map3d/run_hex_map_3d.tscn", "StartRunButton opens routed run map scene")
	_cleanup_current_scene()


func _spawn_main_scene() -> Node:
	_cleanup_current_scene()
	change_scene_to_packed(MAIN_SCENE)
	await process_frame
	await process_frame
	return get_current_scene()


func _cleanup_current_scene() -> void:
	var loaded_scene := get_current_scene()
	if loaded_scene != null:
		loaded_scene.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
