@tool
extends EditorPlugin

const StatusPanelScript = preload("res://addons/renderdoc_bridge/ui/status_panel.gd")
const DebuggerScript = preload("res://addons/renderdoc_bridge/renderdoc_bridge_debugger.gd")

const AUTOLOAD_NAME := "RenderDocBridgeRuntime"
const RUNTIME_PATH := "res://addons/renderdoc_bridge/renderdoc_bridge_runtime.gd"
const ENTRY_CMD_PATH := "res://Start Godot RenderDoc.cmd"

const EDITOR_CAPTURE_PATH_SETTING := "renderdoc_bridge/editor_capture_path"
const GAME_CAPTURE_PATH_SETTING := "renderdoc_bridge/game_capture_path"
const RENDERDOC_CMD_SETTING := "renderdoc_bridge/renderdoccmd_path"
const AUTO_OPEN_SETTING := "renderdoc_bridge/auto_open_replay_ui"
const OVERLAY_ENABLED_SETTING := "renderdoc_bridge/overlay_enabled"
const CAPTURE_TIMEOUT_FRAMES := 120
const GAME_CAPTURE_TIMEOUT_SECONDS := 20.0
const AUTO_EDITOR_CAPTURE_ENV := "RENDERDOC_BRIDGE_AUTO_EDITOR_CAPTURE"
const AUTO_GAME_CAPTURE_ENV := "RENDERDOC_BRIDGE_AUTO_GAME_CAPTURE"
const UI_SELFTEST_ENV := "RENDERDOC_BRIDGE_UI_SELFTEST"
const SMOKE_QUIT_ENV := "RENDERDOC_BRIDGE_SMOKE_QUIT"
const GAME_SMOKE_TIMEOUT_FRAMES := 3600

var _wrapper: Object
var _editor_button: Button
var _game_button: Button
var _status_panel: Control
var _timer: Timer
var _game_timeout_timer: Timer
var _renderdoc_debugger
var _editor_capture_in_progress: bool = false
var _game_capture_in_progress: bool = false
var _selected_game_session_id: int = -1
var _pending_game_request_id: String = ""
var _editor_capture_verified: bool = false
var _last_editor_capture_path: String = ""
var _last_game_capture_path: String = ""
var _last_error: String = ""


func _enter_tree() -> void:
	_setup_project_settings()
	_create_wrapper()
	_setup_debugger()
	add_autoload_singleton(AUTOLOAD_NAME, RUNTIME_PATH)
	_setup_toolbar()
	_setup_bottom_panel()
	_setup_menu()
	_setup_timers()
	_regenerate_entrypoint(false)
	_try_load_renderdoc()
	_refresh_status()
	if OS.get_environment(AUTO_EDITOR_CAPTURE_ENV) == "1":
		_run_editor_capture_smoke.call_deferred()
	elif OS.get_environment(AUTO_GAME_CAPTURE_ENV) == "1":
		_run_game_capture_smoke.call_deferred()
	elif OS.get_environment(UI_SELFTEST_ENV) == "1":
		_run_ui_selftest.call_deferred()


func _exit_tree() -> void:
	remove_tool_menu_item("RenderDoc: Editor RDC")
	remove_tool_menu_item("RenderDoc: Game RDC")
	remove_tool_menu_item("RenderDoc: Regenerate Entry")

	if _timer:
		_timer.stop()
		_timer.queue_free()
		_timer = null

	if _game_timeout_timer:
		_game_timeout_timer.stop()
		_game_timeout_timer.queue_free()
		_game_timeout_timer = null

	if _status_panel:
		remove_control_from_bottom_panel(_status_panel)
		_status_panel.queue_free()
		_status_panel = null

	if _editor_button:
		remove_control_from_container(CONTAINER_TOOLBAR, _editor_button)
		_editor_button.queue_free()
		_editor_button = null

	if _game_button:
		remove_control_from_container(CONTAINER_TOOLBAR, _game_button)
		_game_button.queue_free()
		_game_button = null

	remove_autoload_singleton(AUTOLOAD_NAME)

	if _renderdoc_debugger:
		remove_debugger_plugin(_renderdoc_debugger)
		_renderdoc_debugger = null

	_wrapper = null


func _setup_project_settings() -> void:
	if not ProjectSettings.has_setting(EDITOR_CAPTURE_PATH_SETTING):
		ProjectSettings.set_setting(EDITOR_CAPTURE_PATH_SETTING, "captures/renderdoc/editor/editor")
	if not ProjectSettings.has_setting(GAME_CAPTURE_PATH_SETTING):
		ProjectSettings.set_setting(GAME_CAPTURE_PATH_SETTING, "captures/renderdoc/game/game")
	if not ProjectSettings.has_setting(RENDERDOC_CMD_SETTING):
		ProjectSettings.set_setting(RENDERDOC_CMD_SETTING, "")
	if not ProjectSettings.has_setting(AUTO_OPEN_SETTING):
		ProjectSettings.set_setting(AUTO_OPEN_SETTING, true)
	if not ProjectSettings.has_setting(OVERLAY_ENABLED_SETTING):
		ProjectSettings.set_setting(OVERLAY_ENABLED_SETTING, true)


func _create_wrapper() -> void:
	if not ClassDB.class_exists("RenderDocWrapper"):
		_wrapper = null
		_last_error = "RenderDocWrapper GDExtension is not loaded."
		return
	_wrapper = ClassDB.instantiate("RenderDocWrapper")


func _setup_debugger() -> void:
	_renderdoc_debugger = DebuggerScript.new()
	_renderdoc_debugger.runtime_ready_changed.connect(_on_runtime_ready_changed)
	_renderdoc_debugger.capture_result_received.connect(_on_game_capture_result)
	add_debugger_plugin(_renderdoc_debugger)


func _setup_toolbar() -> void:
	_editor_button = Button.new()
	_editor_button.name = "RenderDocBridgeEditorRdcButton"
	_editor_button.text = "Editor RDC"
	_editor_button.tooltip_text = "Capture the current editor window through RenderDoc"
	_editor_button.pressed.connect(_capture_editor_frame)
	add_control_to_container(CONTAINER_TOOLBAR, _editor_button)

	_game_button = Button.new()
	_game_button.name = "RenderDocBridgeGameRdcButton"
	_game_button.text = "Game RDC"
	_game_button.tooltip_text = "Capture the selected debug game session through RenderDoc"
	_game_button.pressed.connect(_request_game_capture)
	add_control_to_container(CONTAINER_TOOLBAR, _game_button)


func _setup_bottom_panel() -> void:
	_status_panel = StatusPanelScript.new()
	_status_panel.wrapper = _wrapper
	_status_panel.editor_capture_requested.connect(_capture_editor_frame)
	_status_panel.game_capture_requested.connect(_request_game_capture)
	_status_panel.regenerate_entry_requested.connect(_on_regenerate_entry_requested)
	_status_panel.session_selected.connect(_on_session_selected)
	add_control_to_bottom_panel(_status_panel, "RenderDoc")


func _setup_menu() -> void:
	add_tool_menu_item("RenderDoc: Editor RDC", _capture_editor_frame)
	add_tool_menu_item("RenderDoc: Game RDC", _request_game_capture)
	add_tool_menu_item("RenderDoc: Regenerate Entry", _on_regenerate_entry_requested)


func _setup_timers() -> void:
	_timer = Timer.new()
	_timer.wait_time = 0.5
	_timer.autostart = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	_game_timeout_timer = Timer.new()
	_game_timeout_timer.one_shot = true
	_game_timeout_timer.wait_time = GAME_CAPTURE_TIMEOUT_SECONDS
	_game_timeout_timer.timeout.connect(_on_game_capture_timeout)
	add_child(_game_timeout_timer)


func _capture_editor_frame() -> bool:
	if _editor_capture_in_progress:
		_set_message("Editor RDC is already in progress.")
		return false

	if not _is_launched_by_bridge():
		_last_error = "Editor RDC is disabled for ordinary Godot launches. Use Start Godot RenderDoc.cmd."
		_set_message(_last_error)
		_refresh_status()
		return false

	var window_handle := _get_editor_window_handle()
	if window_handle == 0:
		_last_error = "Editor window handle is unavailable; Editor RDC is disabled."
		_set_message(_last_error)
		_refresh_status()
		return false

	if not _try_load_renderdoc():
		_set_message("RenderDoc API is not available. Launch with Start Godot RenderDoc.cmd.")
		_refresh_status()
		return false

	_editor_capture_in_progress = true
	_set_message("Capturing editor frame...")
	_refresh_status()

	_apply_common_capture_options()
	var path_template := _resolve_capture_template(
			ProjectSettings.get_setting(EDITOR_CAPTURE_PATH_SETTING, ""),
			"captures/renderdoc/editor/editor")
	var count_before: int = _wrapper.get_num_captures()
	_wrapper.set_capture_path(path_template)

	await get_tree().process_frame
	if not _wrapper.start_capture(window_handle):
		_editor_capture_in_progress = false
		_last_error = _get_wrapper_error("Editor RDC failed to start.")
		_set_message(_last_error)
		_refresh_status()
		return false

	await get_tree().process_frame
	if not _wrapper.end_capture(window_handle):
		_editor_capture_in_progress = false
		_last_error = _get_wrapper_error("Editor RDC failed to end.")
		_set_message(_last_error)
		_refresh_status()
		return false

	var capture_info := await _wait_for_capture(count_before)
	_editor_capture_in_progress = false
	if not capture_info.has("path"):
		_last_error = "Editor RDC ended but RenderDoc did not report a new .rdc path."
		_set_message(_last_error)
		_refresh_status()
		return false

	_editor_capture_verified = true
	_last_editor_capture_path = str(capture_info["path"])
	_last_error = ""
	_set_message("Editor RDC saved: %s" % _last_editor_capture_path)
	_maybe_open_capture(_last_editor_capture_path)
	_refresh_status()
	return true


func _run_editor_capture_smoke() -> void:
	for _frame_index in range(30):
		await get_tree().process_frame
	var ok := await _wait_for_editor_button_capture()
	if OS.get_environment(SMOKE_QUIT_ENV) == "1":
		get_tree().quit(0 if ok else 1)


func _wait_for_editor_button_capture() -> bool:
	if _editor_button == null:
		_last_error = "Editor RDC toolbar button is unavailable."
		return false
	_last_editor_capture_path = ""
	_last_error = ""
	_editor_button.pressed.emit()
	for _frame_index in range(CAPTURE_TIMEOUT_FRAMES + 30):
		if not _editor_capture_in_progress and not _last_editor_capture_path.is_empty():
			return true
		if not _editor_capture_in_progress and not _last_error.is_empty():
			return false
		await get_tree().process_frame
	_last_error = "Timed out waiting for Editor RDC button smoke capture."
	return false


func _run_game_capture_smoke() -> void:
	for _frame_index in range(30):
		await get_tree().process_frame

	var ok := false
	if not _is_launched_by_bridge():
		_last_error = "Game RDC smoke requires the RenderDoc project entry."
	elif not _try_load_renderdoc():
		_last_error = _get_wrapper_error("RenderDoc API is not available for Game RDC smoke.")
	elif not _wrapper.configure_child_injection(true):
		_last_error = _get_wrapper_error("Failed to enable child hook for Game RDC smoke.")
	else:
		get_editor_interface().play_main_scene()
		ok = await _wait_for_game_runtime_and_button_capture()

	if get_editor_interface().is_playing_scene():
		get_editor_interface().stop_playing_scene()
	if OS.get_environment(SMOKE_QUIT_ENV) == "1":
		get_tree().quit(0 if ok else 1)


func _run_ui_selftest() -> void:
	for _frame_index in range(10):
		await get_tree().process_frame

	var ok := _button_has_pressed_connection(_editor_button, "_capture_editor_frame")
	ok = ok and _button_has_pressed_connection(_game_button, "_request_game_capture")
	ok = ok and _selftest_game_session_resolution()
	ok = ok and _status_panel != null
	if ok:
		ok = ok and _status_panel.has_method("selftest_connections")
		ok = ok and bool(_status_panel.call("selftest_connections"))

	if OS.get_environment(SMOKE_QUIT_ENV) == "1":
		get_tree().quit(0 if ok else 1)


func _button_has_pressed_connection(button: Button, method_name: String) -> bool:
	if button == null:
		return false
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable")
		if callable.is_valid() and callable.get_object() == self and callable.get_method() == method_name:
			return true
	return false


func _selftest_game_session_resolution() -> bool:
	return (
			_resolve_game_session_for_capture([1], -1) == 1
			and _resolve_game_session_for_capture([1, 2], -1) == -1
			and _resolve_game_session_for_capture([1, 2], 2) == 2
			and _resolve_game_session_for_capture([1, 2], 9) == -1
	)


func _wait_for_game_runtime_and_button_capture() -> bool:
	if _game_button == null:
		_last_error = "Game RDC toolbar button is unavailable."
		return false

	var requested := false
	for _frame_index in range(GAME_SMOKE_TIMEOUT_FRAMES):
		if not requested and not _get_ready_game_sessions().is_empty():
			_last_game_capture_path = ""
			_last_error = ""
			_game_button.pressed.emit()
			requested = true
		if requested and not _game_capture_in_progress:
			return not _last_game_capture_path.is_empty()
		await get_tree().process_frame
	_last_error = "Timed out waiting for Game RDC smoke capture."
	return false


func _request_game_capture() -> bool:
	if _game_capture_in_progress:
		_set_message("Game RDC is already in progress.")
		return false

	if not _try_load_renderdoc():
		_set_message("RenderDoc API is not available in the editor; child hook cannot be configured.")
		_refresh_status()
		return false

	if not _wrapper.configure_child_injection(true):
		_last_error = _get_wrapper_error("Failed to enable RenderDoc child-process hook.")
		_set_message(_last_error)
		_refresh_status()
		return false

	var ready_sessions := _get_ready_game_sessions()
	if ready_sessions.is_empty():
		_set_message("No debug game runtime is ready. Click Play after launching through the RenderDoc entry.")
		_refresh_status()
		return false

	var target_session_id := _resolve_game_session_for_capture(ready_sessions, _selected_game_session_id)
	if target_session_id < 0:
		_set_message("Multiple debug sessions are ready; select one before Game RDC.")
		_refresh_status()
		return false

	_selected_game_session_id = target_session_id

	var path_template := _resolve_capture_template(
			ProjectSettings.get_setting(GAME_CAPTURE_PATH_SETTING, ""),
			"captures/renderdoc/game/game")
	_pending_game_request_id = "%d" % Time.get_ticks_msec()
	_game_capture_in_progress = true
	_set_message("Requesting Game RDC for session %d..." % _selected_game_session_id)
	_refresh_status()

	var sent: bool = _renderdoc_debugger.send_capture_request(_selected_game_session_id, {
		"request_id": _pending_game_request_id,
		"path_template": path_template,
	})
	if not sent:
		_game_capture_in_progress = false
		_last_error = "Failed to send Game RDC request to session %d." % _selected_game_session_id
		_set_message(_last_error)
		_refresh_status()
		return false

	_game_timeout_timer.start()
	return true


func _on_game_capture_result(session_id: int, result: Dictionary) -> void:
	if not _game_capture_in_progress:
		return
	if session_id != _selected_game_session_id:
		return
	if str(result.get("request_id", "")) != _pending_game_request_id:
		return

	_game_timeout_timer.stop()
	_game_capture_in_progress = false
	_pending_game_request_id = ""

	if not bool(result.get("ok", false)):
		_last_error = str(result.get("error", "Game RDC failed."))
		_set_message(_last_error)
		_refresh_status()
		return

	_last_game_capture_path = str(result.get("path", ""))
	_last_error = ""
	_set_message("Game RDC saved: %s" % _last_game_capture_path)
	_maybe_open_capture(_last_game_capture_path)
	_refresh_status()


func _on_game_capture_timeout() -> void:
	_game_capture_in_progress = false
	_pending_game_request_id = ""
	_last_error = "Game RDC timed out waiting for the debug runtime."
	_set_message(_last_error)
	_refresh_status()


func _on_runtime_ready_changed() -> void:
	_refresh_status()


func _on_session_selected(session_id: int) -> void:
	_selected_game_session_id = session_id
	_refresh_status()


func _on_regenerate_entry_requested() -> void:
	_regenerate_entrypoint(true)


func _on_timer_timeout() -> void:
	_try_load_renderdoc()
	_refresh_status()


func _try_load_renderdoc() -> bool:
	if _wrapper == null:
		return false
	if _wrapper.is_loaded():
		_wrapper.configure_child_injection(true)
		return true

	var explicit_cmd: String = ProjectSettings.get_setting(RENDERDOC_CMD_SETTING, "")
	var explicit_dll := _renderdoc_dll_from_cmd(explicit_cmd)
	var loaded := false
	if not explicit_dll.is_empty() and _wrapper.has_method("try_load_from_path"):
		loaded = _wrapper.try_load_from_path(explicit_dll)
	if not loaded:
		loaded = _wrapper.try_load()

	if loaded:
		_wrapper.configure_child_injection(true)
		_last_error = ""
	elif _wrapper.has_method("get_last_error"):
		_last_error = str(_wrapper.get_last_error())
	return loaded


func _apply_common_capture_options() -> void:
	if _wrapper == null or not _wrapper.is_loaded():
		return
	_wrapper.configure_child_injection(true)
	var overlay_enabled: bool = ProjectSettings.get_setting(OVERLAY_ENABLED_SETTING, true)
	if overlay_enabled:
		_wrapper.mask_overlay_bits(0xFFFFFFFF, 0xF)
	else:
		_wrapper.mask_overlay_bits(0xFFFFFFFF, 0)


func _refresh_status() -> void:
	var state := _build_state()
	if _editor_button:
		_editor_button.disabled = not state["editor_capture_available"] or _editor_capture_in_progress
		_editor_button.tooltip_text = state["editor_status"]
		_editor_button.modulate = Color.GREEN if state["editor_capture_available"] else Color.GRAY
	if _game_button:
		_game_button.disabled = not state["game_capture_available"] or _game_capture_in_progress
		_game_button.tooltip_text = state["game_status"]
		_game_button.modulate = Color.GREEN if state["game_capture_available"] else Color.GRAY
	if _status_panel and _status_panel.has_method("update_state"):
		_status_panel.update_state(state)


func _build_state() -> Dictionary:
	var renderdoc_loaded: bool = _wrapper != null and _wrapper.is_loaded()
	var window_handle := _get_editor_window_handle()
	var active_sessions := _get_active_game_sessions()
	var ready_sessions := _get_ready_game_sessions()
	_select_default_session(active_sessions, ready_sessions)

	var launched_by_bridge := _is_launched_by_bridge()
	var hook_children_enabled := false
	if renderdoc_loaded:
		hook_children_enabled = _wrapper.get_capture_option_u32(7) == 1

	var editor_status := "Ready: launched through RenderDoc project entry"
	var editor_available: bool = launched_by_bridge and renderdoc_loaded and window_handle != 0
	if not launched_by_bridge:
		editor_status = "Not ready: ordinary Godot launch"
	elif not renderdoc_loaded:
		editor_status = "Not ready: RenderDoc API unavailable"
	elif window_handle == 0:
		editor_status = "Not ready: editor capture target not resolved"
	elif not _editor_capture_verified:
		editor_status = "Ready to verify: first Editor RDC will smoke-test capture"

	var game_status := "Ready: selected debug game session %d" % _selected_game_session_id
	var game_available: bool = renderdoc_loaded and hook_children_enabled and ready_sessions.has(_selected_game_session_id)
	if not renderdoc_loaded:
		game_status = "Not ready: RenderDoc API unavailable in editor"
	elif not hook_children_enabled:
		game_status = "Not ready: child hook disabled"
	elif ready_sessions.is_empty():
		game_status = "Not ready: no debug game runtime ready"
	elif ready_sessions.size() > 1 and not ready_sessions.has(_selected_game_session_id):
		game_status = "Not ready: select a debug session"

	return {
		"launched_by_bridge": launched_by_bridge,
		"renderdoc_api_available": renderdoc_loaded,
		"load_source": _wrapper.get_load_source() if renderdoc_loaded and _wrapper.has_method("get_load_source") else "",
		"api_version": _format_api_version(_wrapper.get_api_version() if renderdoc_loaded else 0),
		"hook_children_enabled": hook_children_enabled,
		"editor_capture_verified": _editor_capture_verified,
		"editor_window_handle": window_handle,
		"editor_capture_available": editor_available,
		"editor_capture_in_progress": _editor_capture_in_progress,
		"editor_status": editor_status,
		"active_debug_sessions": active_sessions,
		"ready_debug_sessions": ready_sessions,
		"selected_debug_session": _selected_game_session_id,
		"game_runtime_ready": ready_sessions.has(_selected_game_session_id),
		"game_capture_available": game_available,
		"game_capture_in_progress": _game_capture_in_progress,
		"game_status": game_status,
		"last_editor_capture_path": _last_editor_capture_path,
		"last_game_capture_path": _last_game_capture_path,
		"last_error": _last_error,
		"entry_cmd_path": ProjectSettings.globalize_path(ENTRY_CMD_PATH),
		"renderdoccmd_path": ProjectSettings.get_setting(RENDERDOC_CMD_SETTING, ""),
	}


func _select_default_session(active_sessions: Array, ready_sessions: Array) -> void:
	if active_sessions.is_empty():
		_selected_game_session_id = -1
		return
	if active_sessions.has(_selected_game_session_id):
		return
	if ready_sessions.size() == 1:
		_selected_game_session_id = int(ready_sessions[0])
	elif active_sessions.size() == 1:
		_selected_game_session_id = int(active_sessions[0])
	else:
		_selected_game_session_id = -1


func _get_active_game_sessions() -> Array:
	if _renderdoc_debugger == null:
		return []
	return _renderdoc_debugger.get_active_session_ids()


func _get_ready_game_sessions() -> Array:
	if _renderdoc_debugger == null:
		return []
	return _renderdoc_debugger.get_ready_session_ids()


func _resolve_game_session_for_capture(ready_sessions: Array, selected_session_id: int) -> int:
	if ready_sessions.is_empty():
		return -1
	if ready_sessions.has(selected_session_id):
		return selected_session_id
	if ready_sessions.size() == 1:
		return int(ready_sessions[0])
	return -1


func _get_editor_window_handle() -> int:
	if DisplayServer.get_name() == "headless":
		return 0
	return int(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, DisplayServer.MAIN_WINDOW_ID))


func _is_launched_by_bridge() -> bool:
	return OS.get_environment("RENDERDOC_BRIDGE_BOOTSTRAPPED") == "1"


func _is_smoke_mode() -> bool:
	return OS.get_environment(AUTO_EDITOR_CAPTURE_ENV) == "1" or OS.get_environment(AUTO_GAME_CAPTURE_ENV) == "1"


func _wait_for_capture(count_before: int) -> Dictionary:
	for _frame_index in range(CAPTURE_TIMEOUT_FRAMES):
		var count_now: int = _wrapper.get_num_captures()
		if count_now > count_before:
			return _wrapper.get_capture(count_now - 1)
		await get_tree().process_frame
	return {}


func _resolve_capture_template(path: String, fallback: String) -> String:
	var template := path.strip_edges()
	if template.is_empty():
		template = fallback
	if template.ends_with("/") or template.ends_with("\\"):
		template = template.path_join(fallback.get_file())
	if not template.is_absolute_path():
		if template.begins_with("res://") or template.begins_with("user://"):
			template = ProjectSettings.globalize_path(template)
		else:
			template = ProjectSettings.globalize_path("res://%s" % template)

	var capture_dir := template.get_base_dir()
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
	return template


func _regenerate_entrypoint(show_message: bool) -> void:
	var cmd_path := ProjectSettings.globalize_path(ENTRY_CMD_PATH)
	var godot_exe := OS.get_executable_path()
	var project_root := ProjectSettings.globalize_path("res://")
	var renderdoc_cmd: String = ProjectSettings.get_setting(RENDERDOC_CMD_SETTING, "")
	var command_line := "powershell -NoProfile -ExecutionPolicy Bypass -File " + _cmd_quote("%~dp0tools\\renderdoc_bridge\\start_renderdoc_godot.ps1")
	command_line += " -GodotExe " + _cmd_quote(godot_exe)
	command_line += " -ProjectRoot " + _cmd_quote(project_root)
	if not renderdoc_cmd.strip_edges().is_empty():
		command_line += " -RenderDocCmd " + _cmd_quote(renderdoc_cmd)

	var lines := PackedStringArray([
		"@echo off",
		"setlocal",
		"set \"RENDERDOC_BRIDGE_BOOTSTRAPPED=1\"",
		"set \"RENDERDOC_BRIDGE_PROJECT=%~dp0\"",
		command_line,
		"endlocal",
	])

	var file := FileAccess.open(cmd_path, FileAccess.WRITE)
	if file == null:
		_last_error = "Failed to write RenderDoc entrypoint: %s" % cmd_path
		if show_message:
			_set_message(_last_error)
		return

	file.store_string("\r\n".join(lines) + "\r\n")
	file.close()
	if show_message:
		_set_message("Regenerated RenderDoc entrypoint: %s" % cmd_path)


func _renderdoc_dll_from_cmd(renderdoc_cmd: String) -> String:
	var cmd := renderdoc_cmd.strip_edges()
	if cmd.is_empty():
		return ""
	var dir := cmd
	if FileAccess.file_exists(cmd):
		dir = cmd.get_base_dir()
	if dir.is_empty():
		return ""
	var dll := dir.path_join("renderdoc.dll")
	if FileAccess.file_exists(dll):
		return dll
	return ""


func _cmd_quote(value: String) -> String:
	return "\"%s\"" % value.replace("\"", "\"\"")


func _maybe_open_capture(path: String) -> void:
	if path.is_empty():
		return
	if _is_smoke_mode():
		return
	if not ProjectSettings.get_setting(AUTO_OPEN_SETTING, true):
		return
	if _wrapper and _wrapper.is_loaded():
		_wrapper.launch_replay_ui(false, "\"%s\"" % path)


func _get_wrapper_error(fallback: String) -> String:
	if _wrapper and _wrapper.has_method("get_last_error"):
		var error := str(_wrapper.get_last_error())
		if not error.is_empty():
			return error
	return fallback


func _format_api_version(version: int) -> String:
	if version <= 0:
		return "-"
	var major: int = version / 10000
	var minor: int = (version % 10000) / 100
	var patch: int = version % 100
	return "%d.%d.%d" % [major, minor, patch]


func _set_message(message: String) -> void:
	if _status_panel and _status_panel.has_method("set_message"):
		_status_panel.set_message(message)
