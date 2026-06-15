extends SceneTree

const MAP_SCREEN_SCENE := preload("res://scenes/map/map_screen.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var instance := MAP_SCREEN_SCENE.instantiate()
	get_root().add_child(instance)
	await process_frame

	_assert(instance.get_node_or_null("Margin/Panel/Content/TitleLabel") != null, "map screen has title label")
	_assert(instance.get_node_or_null("Margin/Panel/Content/RouteLabel") != null, "map screen has route label")
	_assert(instance.has_method("set_run_state"), "map screen exposes set_run_state")
	_assert(instance.has_method("set_selected_node"), "map screen exposes set_selected_node")

	instance.set_run_state({"act_name": "FallbackPreview", "gold": 88})
	instance.set_selected_node(&"entry", &"available")
	await process_frame

	var route_label := instance.get_node("Margin/Panel/Content/RouteLabel") as Label
	var selected_label := instance.get_node("Margin/Panel/Content/SelectedLabel") as Label
	_assert(route_label.text.contains("res://scenes/map3d/run_hex_map_3d.tscn"), "route label reflects current 3D target")
	_assert(selected_label.text.contains("entry"), "selected node label updates")

	print("PASS test_map_screen")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
