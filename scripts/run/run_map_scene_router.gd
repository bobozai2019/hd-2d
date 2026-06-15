class_name RunMapSceneRouter
extends RefCounted

const USE_3D_RUN_MAP := true
const RUN_3D_MAP_SCENE := "res://scenes/map3d/run_hex_map_3d.tscn"
const LEGACY_2D_MAP_SCENE := "res://scenes/map/map_screen.tscn"
const MVP_MAP_SCENE := "res://scenes/map3d/hex_map_mvp.tscn"


static func get_run_map_scene_path() -> String:
	return RUN_3D_MAP_SCENE if USE_3D_RUN_MAP else LEGACY_2D_MAP_SCENE


static func get_legacy_map_scene_path() -> String:
	return LEGACY_2D_MAP_SCENE


static func get_mvp_map_scene_path() -> String:
	return MVP_MAP_SCENE
