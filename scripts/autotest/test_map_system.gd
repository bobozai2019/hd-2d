extends SceneTree

const MapSystemScript := preload("res://scripts/systems/map_system.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map_system = MapSystemScript.new()
	_assert(map_system.get_node_state(&"entry") == &"current", "entry node starts current")
	_assert(map_system.get_node_state(&"battle_1") == &"available", "first battle starts available")
	_assert(map_system.can_enter_node(&"battle_1"), "available node is enterable")

	var enter_result: Dictionary = map_system.enter_node(&"battle_1")
	_assert(bool(enter_result.get("success", false)), "entering available battle succeeds")
	_assert(map_system.get_node_state(&"battle_1") == &"current", "entered battle becomes current")
	_assert(map_system.get_node_state(&"entry") == &"completed", "previous current node becomes completed")

	map_system.complete_node(&"battle_1")
	_assert(map_system.get_node_state(&"battle_1") == &"completed", "completed battle remains completed")
	_assert(map_system.get_node_state(&"event_1") == &"available", "successor event unlocks after completion")
	_assert(map_system.get_node_state(&"rest_1") == &"available", "successor rest unlocks after completion")

	print("PASS test_map_system")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
