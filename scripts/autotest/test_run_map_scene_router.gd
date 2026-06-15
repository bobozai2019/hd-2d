extends SceneTree

const RouterScript := preload("res://scripts/run/run_map_scene_router.gd")


func _init() -> void:
	_assert(RouterScript.get_run_map_scene_path() == "res://scenes/map3d/run_hex_map_3d.tscn", "default run map scene is 3D")
	_assert(RouterScript.get_legacy_map_scene_path() == "res://scenes/map/map_screen.tscn", "legacy map scene path is preserved")
	_assert(RouterScript.get_mvp_map_scene_path() == "res://scenes/map3d/hex_map_mvp.tscn", "mvp scene path is preserved")
	print("PASS test_run_map_scene_router")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
