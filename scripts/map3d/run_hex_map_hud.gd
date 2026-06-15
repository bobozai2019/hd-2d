extends Control

signal back_requested
signal zoom_in_requested
signal zoom_out_requested
signal reset_view_requested
signal focus_selected_requested
signal enter_selected_requested

@onready var _title_label: Label = $TopBar/Row/TitleLabel
@onready var _act_label: Label = $TopBar/Row/ActLabel
@onready var _hp_label: Label = $TopBar/Row/HpLabel
@onready var _gold_label: Label = $TopBar/Row/GoldLabel
@onready var _hover_id_label: Label = $InfoPanel/InfoList/HoverIdLabel
@onready var _hover_type_label: Label = $InfoPanel/InfoList/HoverTypeLabel
@onready var _hover_state_label: Label = $InfoPanel/InfoList/HoverStateLabel
@onready var _selected_id_label: Label = $InfoPanel/InfoList/SelectedIdLabel
@onready var _selected_type_label: Label = $InfoPanel/InfoList/SelectedTypeLabel
@onready var _selected_state_label: Label = $InfoPanel/InfoList/SelectedStateLabel
@onready var _selected_reward_label: Label = $InfoPanel/InfoList/SelectedRewardLabel
@onready var _camera_size_label: Label = $InfoPanel/InfoList/CameraSizeLabel
@onready var _message_label: Label = $BottomBar/Row/MessageLabel
@onready var _enter_selected_button: Button = $BottomBar/Row/EnterSelectedButton
@onready var _error_panel: PanelContainer = $ErrorPanel
@onready var _error_label: Label = $ErrorPanel/ErrorLabel


func _ready() -> void:
	$TopBar/Row/BackButton.pressed.connect(func() -> void: back_requested.emit())
	$TopBar/Row/ZoomInButton.pressed.connect(func() -> void: zoom_in_requested.emit())
	$TopBar/Row/ZoomOutButton.pressed.connect(func() -> void: zoom_out_requested.emit())
	$TopBar/Row/ResetViewButton.pressed.connect(func() -> void: reset_view_requested.emit())
	$TopBar/Row/FocusSelectedButton.pressed.connect(func() -> void: focus_selected_requested.emit())
	_enter_selected_button.pressed.connect(func() -> void: enter_selected_requested.emit())
	_title_label.text = "3D Run Map"
	set_hover_tile({})
	set_selected_tile({})
	show_message("Select a node")
	_error_panel.visible = false


func set_run_state(run_state: Variant) -> void:
	if run_state is Dictionary:
		_act_label.text = "Act: %s" % str(run_state.get("act_name", "Preview"))
		_hp_label.text = "HP: %s" % str(run_state.get("hp", 0))
		_gold_label.text = "Gold: %s" % str(run_state.get("gold", 0))
		return
	_act_label.text = "Act: Preview"
	_hp_label.text = "HP: -"
	_gold_label.text = "Gold: -"


func set_hover_tile(tile_info: Dictionary) -> void:
	if tile_info.is_empty():
		_hover_id_label.text = "Hover: -"
		_hover_type_label.text = ""
		_hover_state_label.text = ""
		return
	var node_id := String(tile_info.get("node_id", "-"))
	var node_type := StringName(tile_info.get("node_type", &"-"))
	var state_name := StringName(tile_info.get("state", &"-"))
	_hover_id_label.text = "Hover: %s" % node_id
	_hover_type_label.text = "Type: %s" % _format_node_type(node_type)
	_hover_state_label.text = "State: %s" % _format_state(state_name)


func set_selected_tile(tile_info: Dictionary) -> void:
	if tile_info.is_empty():
		_selected_id_label.text = "Selected: -"
		_selected_type_label.text = ""
		_selected_state_label.text = ""
		_selected_reward_label.text = "Reward: -"
		_enter_selected_button.disabled = true
		return
	var node_id := String(tile_info.get("node_id", "-"))
	var node_type := StringName(tile_info.get("node_type", &"-"))
	var state_name := StringName(tile_info.get("state", &"-"))
	_selected_id_label.text = "Selected: %s" % node_id
	_selected_type_label.text = "Type: %s" % _format_node_type(node_type)
	_selected_state_label.text = "State: %s" % _format_state(state_name)
	_selected_reward_label.text = "Reward: %s" % str(tile_info.get("reward", "-"))
	_enter_selected_button.disabled = state_name != &"available"


func set_camera_state(camera_state: Dictionary) -> void:
	var projection := int(camera_state.get("projection", Camera3D.PROJECTION_PERSPECTIVE))
	var projection_name := "Perspective" if projection == Camera3D.PROJECTION_PERSPECTIVE else "Orthogonal"
	var fov := float(camera_state.get("fov", 34.0))
	var size := float(camera_state.get("size", 12.0))
	_camera_size_label.text = "Camera: %s | FOV %.1f | Size %.1f" % [projection_name, fov, size]


func show_message(message: String) -> void:
	_message_label.text = message


func set_error(message: String) -> void:
	_error_label.text = message
	_error_panel.visible = not message.is_empty()


func is_enter_enabled() -> bool:
	return not _enter_selected_button.disabled


func get_message() -> String:
	return _message_label.text


func is_error_visible() -> bool:
	return _error_panel.visible


func _format_node_type(node_type: StringName) -> String:
	match node_type:
		&"battle":
			return "Battle"
		&"shop":
			return "Shop"
		&"rest":
			return "Rest"
		&"event":
			return "Event"
		&"boss":
			return "Boss"
		&"-":
			return "-"
		_:
			return str(node_type)


func _format_state(state_name: StringName) -> String:
	match state_name:
		&"available":
			return "Available"
		&"locked":
			return "Locked"
		&"current":
			return "Current"
		&"completed":
			return "Completed"
		&"-":
			return "-"
		_:
			return str(state_name)
