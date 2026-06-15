extends Control

const RunMapSceneRouterScript := preload("res://scripts/run/run_map_scene_router.gd")
const HEX_MAP_MVP_SCENE := preload("res://scenes/map3d/hex_map_mvp.tscn")
const HD2D_EFFECT_LAB_SCENE := preload("res://scenes/map3d/hd2d_effect_lab.tscn")

@onready var _start_run_button: Button = $UiLayer/MenuRoot/Panel/Content/ButtonColumn/StartRunButton
@onready var _hex_map_mvp_button: Button = $UiLayer/MenuRoot/Panel/Content/ButtonColumn/HexMapMvpButton
@onready var _hd2d_effect_lab_button: Button = $UiLayer/MenuRoot/Panel/Content/ButtonColumn/Hd2dEffectLabButton
@onready var _status_label: Label = $UiLayer/MenuRoot/Panel/Content/StatusLabel


func _ready() -> void:
	_start_run_button.pressed.connect(_open_run_map)
	_hex_map_mvp_button.pressed.connect(_open_hex_map_mvp)
	_hd2d_effect_lab_button.pressed.connect(_open_hd2d_effect_lab)
	_status_label.text = "Default Run Route: %s" % RunMapSceneRouterScript.get_run_map_scene_path()


func _open_run_map() -> void:
	get_tree().change_scene_to_file(RunMapSceneRouterScript.get_run_map_scene_path())


func _open_hex_map_mvp() -> void:
	get_tree().change_scene_to_packed(HEX_MAP_MVP_SCENE)


func _open_hd2d_effect_lab() -> void:
	get_tree().change_scene_to_packed(HD2D_EFFECT_LAB_SCENE)
