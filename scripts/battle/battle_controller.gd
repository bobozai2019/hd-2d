extends Node

const RunMapSceneRouterScript := preload("res://scripts/run/run_map_scene_router.gd")


func get_victory_return_scene_path() -> String:
	return RunMapSceneRouterScript.get_run_map_scene_path()


func return_to_run_map_after_victory() -> void:
	get_tree().change_scene_to_file(get_victory_return_scene_path())
