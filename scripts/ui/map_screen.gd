extends Control

const RunMapSceneRouterScript := preload("res://scripts/run/run_map_scene_router.gd")

@onready var _title_label: Label = $Margin/Panel/Content/TitleLabel
@onready var _status_label: Label = $Margin/Panel/Content/StatusLabel
@onready var _selected_label: Label = $Margin/Panel/Content/SelectedLabel
@onready var _route_label: Label = $Margin/Panel/Content/RouteLabel


func _ready() -> void:
	_title_label.text = "Legacy 2D Map Fallback"
	_status_label.text = "Status: Waiting for formal Run data"
	_selected_label.text = "Selected Node: -"
	_route_label.text = "3D Route: %s" % RunMapSceneRouterScript.get_run_map_scene_path()


func set_run_state(run_state: Dictionary) -> void:
	var act_name := str(run_state.get("act_name", "Preview"))
	var gold := str(run_state.get("gold", "-"))
	_status_label.text = "Status: %s | Gold %s" % [act_name, gold]


func set_selected_node(node_id: StringName, state_name: StringName) -> void:
	_selected_label.text = "Selected Node: %s (%s)" % [String(node_id), String(state_name)]


func get_route_label_text() -> String:
	return _route_label.text
