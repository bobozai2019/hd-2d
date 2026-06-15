extends SceneTree

const RUN_HEX_MAP_HUD_SCENE := preload("res://scenes/map3d/run_hex_map_hud.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud := RUN_HEX_MAP_HUD_SCENE.instantiate()
	get_root().add_child(hud)
	await process_frame

	hud.set_run_state({"act_name": "Act 1", "hp": 55, "gold": 120})
	_assert(hud.get_node("TopBar/Row/ActLabel").text.contains("Act 1"), "HUD shows act")
	_assert(hud.get_node("TopBar/Row/HpLabel").text.contains("55"), "HUD shows hp")
	_assert(hud.get_node("TopBar/Row/GoldLabel").text.contains("120"), "HUD shows gold")

	hud.set_hover_tile({})
	hud.set_selected_tile({})
	_assert(hud.get_node("InfoPanel/InfoList/HoverIdLabel").text == "Hover: -", "HUD shows empty hover")
	_assert(hud.get_node("InfoPanel/InfoList/SelectedIdLabel").text == "Selected: -", "HUD shows empty selected")

	hud.set_selected_tile({"node_id": "boss_1", "node_type": &"boss", "state": &"locked", "reward": "Boss"})
	_assert(not hud.is_enter_enabled(), "Enter disabled for locked node")
	hud.set_selected_tile({"node_id": "battle_1", "node_type": &"battle", "state": &"available", "reward": "Battle"})
	_assert(hud.is_enter_enabled(), "Enter enabled for available node")

	hud.show_message("Node is locked")
	_assert(hud.get_message() == "Node is locked", "HUD updates message label")
	hud.set_error("No active run context")
	_assert(hud.is_error_visible(), "HUD shows error panel")

	print("PASS test_run_hex_map_3d_hud")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
