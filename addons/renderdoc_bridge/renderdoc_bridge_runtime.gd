extends Node

const CAPTURE_TIMEOUT_FRAMES := 120

var _wrapper: Object
var _capture_in_progress: bool = false


func _ready() -> void:
	if not EngineDebugger.is_active():
		queue_free()
		return
	EngineDebugger.register_message_capture("renderdoc_bridge", _on_debugger_message)
	_send_json("renderdoc_bridge:runtime_ready", {
		"ok": true,
		"class_available": ClassDB.class_exists("RenderDocWrapper"),
	})


func _exit_tree() -> void:
	if EngineDebugger.is_active():
		EngineDebugger.unregister_message_capture("renderdoc_bridge")


func _on_debugger_message(message: String, data: Array) -> bool:
	if message != "capture":
		return false

	var params := _parse_payload(data)
	_capture_game_frame(params)
	return true


func _capture_game_frame(params: Dictionary) -> void:
	var request_id: String = str(params.get("request_id", ""))
	if _capture_in_progress:
		_send_capture_result(false, "", "A game RenderDoc capture is already in progress.", request_id)
		return

	if not ClassDB.class_exists("RenderDocWrapper"):
		_send_capture_result(false, "", "RenderDocWrapper GDExtension is not available in the game process.", request_id)
		return

	if _wrapper == null:
		_wrapper = ClassDB.instantiate("RenderDocWrapper")

	if _wrapper == null or not _wrapper.try_load():
		var load_error := ""
		if _wrapper and _wrapper.has_method("get_last_error"):
			load_error = str(_wrapper.get_last_error())
		_send_capture_result(false, "", "RenderDoc is not available in the game process. %s" % load_error, request_id)
		return

	_capture_in_progress = true
	var path_template := _resolve_capture_template(str(params.get("path_template", "captures/renderdoc/game/game")))
	var count_before: int = _wrapper.get_num_captures()
	_wrapper.set_capture_path(path_template)

	if _wrapper.has_method("configure_child_injection"):
		_wrapper.configure_child_injection(true)

	await get_tree().process_frame
	if not _wrapper.start_capture(0):
		_capture_in_progress = false
		_send_capture_result(false, "", _wrapper.get_last_error(), request_id)
		return

	await get_tree().process_frame
	if not _wrapper.end_capture(0):
		_capture_in_progress = false
		_send_capture_result(false, "", _wrapper.get_last_error(), request_id)
		return

	var capture_info := await _wait_for_capture(count_before)
	_capture_in_progress = false
	if not capture_info.has("path"):
		_send_capture_result(false, "", "RenderDoc ended the game capture but did not report a new .rdc path.", request_id)
		return

	_send_capture_result(true, str(capture_info["path"]), "", request_id)


func _wait_for_capture(count_before: int) -> Dictionary:
	for _frame_index in range(CAPTURE_TIMEOUT_FRAMES):
		var count_now: int = _wrapper.get_num_captures()
		if count_now > count_before:
			return _wrapper.get_capture(count_now - 1)
		await get_tree().process_frame
	return {}


func _send_capture_result(ok: bool, path: String, error: String, request_id: String) -> void:
	var payload := {
		"ok": ok,
		"path": path,
		"error": error,
		"request_id": request_id,
		"api_version": _wrapper.get_api_version() if _wrapper else 0,
		"load_source": _wrapper.get_load_source() if _wrapper and _wrapper.has_method("get_load_source") else "",
	}
	_send_json("renderdoc_bridge:capture_result", payload)


func _send_json(channel: String, payload: Dictionary) -> void:
	if EngineDebugger.is_active():
		EngineDebugger.send_message(channel, [JSON.stringify(payload)])


func _parse_payload(data: Array) -> Dictionary:
	if data.is_empty():
		return {}
	if data[0] is Dictionary:
		return data[0]
	if data[0] is String:
		var parsed = JSON.parse_string(data[0])
		if parsed is Dictionary:
			return parsed
	return {}


func _resolve_capture_template(path: String) -> String:
	var template := path.strip_edges()
	if template.is_empty():
		template = "captures/renderdoc/game/game"
	if template.ends_with("/") or template.ends_with("\\"):
		template = template.path_join("game")
	if not template.is_absolute_path():
		if template.begins_with("res://") or template.begins_with("user://"):
			template = ProjectSettings.globalize_path(template)
		else:
			template = ProjectSettings.globalize_path("res://%s" % template)

	var capture_dir := template.get_base_dir()
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
	return template
