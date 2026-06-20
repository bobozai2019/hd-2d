@tool
extends Control

signal editor_capture_requested
signal game_capture_requested
signal regenerate_entry_requested
signal session_selected(session_id: int)

var wrapper: Object

var _message_label: Label
var _api_label: Label
var _launch_label: Label
var _load_source_label: Label
var _hook_label: Label
var _editor_label: Label
var _game_label: Label
var _session_option: OptionButton
var _last_editor_label: Label
var _last_game_label: Label
var _error_label: Label
var _entry_label: Label
var _renderdoc_cmd_label: Label
var _editor_button: Button
var _game_button: Button


func _ready() -> void:
	custom_minimum_size = Vector2(0, 220)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "RenderDoc Bridge"
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	_message_label = _add_label(vbox, "Message: -")
	_launch_label = _add_label(vbox, "Launch: -")
	_api_label = _add_label(vbox, "API: -")
	_load_source_label = _add_label(vbox, "Load source: -")
	_hook_label = _add_label(vbox, "Hook children: -")
	_editor_label = _add_label(vbox, "Editor RDC: -")
	_game_label = _add_label(vbox, "Game RDC: -")

	var session_row := HBoxContainer.new()
	vbox.add_child(session_row)
	var session_label := Label.new()
	session_label.text = "Debug session:"
	session_row.add_child(session_label)
	_session_option = OptionButton.new()
	_session_option.custom_minimum_size = Vector2(180, 0)
	_session_option.item_selected.connect(_on_session_item_selected)
	session_row.add_child(_session_option)

	_last_editor_label = _add_label(vbox, "Last editor capture: -")
	_last_game_label = _add_label(vbox, "Last game capture: -")
	_error_label = _add_label(vbox, "Last error: -")
	_entry_label = _add_label(vbox, "Entry: -")
	_renderdoc_cmd_label = _add_label(vbox, "RenderDoc command: -")

	var buttons := HBoxContainer.new()
	vbox.add_child(buttons)

	_editor_button = Button.new()
	_editor_button.name = "RenderDocBridgePanelEditorRdcButton"
	_editor_button.text = "Editor RDC"
	_editor_button.pressed.connect(func(): editor_capture_requested.emit())
	buttons.add_child(_editor_button)

	_game_button = Button.new()
	_game_button.name = "RenderDocBridgePanelGameRdcButton"
	_game_button.text = "Game RDC"
	_game_button.pressed.connect(func(): game_capture_requested.emit())
	buttons.add_child(_game_button)

	var regenerate_button := Button.new()
	regenerate_button.name = "RenderDocBridgePanelRegenerateEntryButton"
	regenerate_button.text = "Regenerate Entry"
	regenerate_button.pressed.connect(func(): regenerate_entry_requested.emit())
	buttons.add_child(regenerate_button)


func update_state(state: Dictionary) -> void:
	if not is_inside_tree():
		return

	_launch_label.text = "Launch: %s" % ("RenderDoc entry" if state.get("launched_by_bridge", false) else "ordinary Godot")
	_api_label.text = "API: %s" % state.get("api_version", "-")
	_load_source_label.text = "Load source: %s" % _dash(state.get("load_source", ""))
	_hook_label.text = "Hook children: %s" % _bool_text(state.get("hook_children_enabled", false))
	_editor_label.text = "Editor RDC: %s" % state.get("editor_status", "-")
	_game_label.text = "Game RDC: %s" % state.get("game_status", "-")
	_last_editor_label.text = "Last editor capture: %s" % _dash(state.get("last_editor_capture_path", ""))
	_last_game_label.text = "Last game capture: %s" % _dash(state.get("last_game_capture_path", ""))
	_error_label.text = "Last error: %s" % _dash(state.get("last_error", ""))
	_entry_label.text = "Entry: %s" % _dash(state.get("entry_cmd_path", ""))
	_renderdoc_cmd_label.text = "RenderDoc command: %s" % _dash(state.get("renderdoccmd_path", ""))

	_editor_button.disabled = not bool(state.get("editor_capture_available", false)) or bool(state.get("editor_capture_in_progress", false))
	_game_button.disabled = not bool(state.get("game_capture_available", false)) or bool(state.get("game_capture_in_progress", false))
	_editor_button.text = "Editor RDC..." if state.get("editor_capture_in_progress", false) else "Editor RDC"
	_game_button.text = "Game RDC..." if state.get("game_capture_in_progress", false) else "Game RDC"
	_update_session_options(state)


func set_message(message: String) -> void:
	if _message_label:
		_message_label.text = "Message: %s" % message


func selftest_connections() -> bool:
	return (
			_button_has_local_connection(_editor_button)
			and _button_has_local_connection(_game_button)
	)


func _add_label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _update_session_options(state: Dictionary) -> void:
	var active: Array = state.get("active_debug_sessions", [])
	var ready: Array = state.get("ready_debug_sessions", [])
	var selected_id: int = int(state.get("selected_debug_session", -1))

	_session_option.clear()
	if active.is_empty():
		_session_option.add_item("None", -1)
		_session_option.disabled = true
		return

	_session_option.disabled = active.size() <= 1
	for session_id in active:
		var id := int(session_id)
		var label := "Session %d" % id
		if ready.has(id):
			label += " ready"
		else:
			label += " starting"
		_session_option.add_item(label, id)
		if id == selected_id:
			_session_option.select(_session_option.get_item_count() - 1)


func _on_session_item_selected(index: int) -> void:
	if index < 0:
		return
	session_selected.emit(_session_option.get_item_id(index))


func _bool_text(value: bool) -> String:
	return "true" if value else "false"


func _dash(value) -> String:
	var text := str(value)
	return text if not text.is_empty() else "-"


func _button_has_local_connection(button: Button) -> bool:
	if button == null:
		return false
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable")
		if callable.is_valid() and callable.get_object() == self:
			return true
	return false
