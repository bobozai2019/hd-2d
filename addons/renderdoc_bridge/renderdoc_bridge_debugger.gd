@tool
extends EditorDebuggerPlugin

signal runtime_ready_changed
signal capture_result_received(session_id: int, result: Dictionary)

var _connected_sessions: Dictionary = {}
var _active_sessions: Dictionary = {}
var _runtime_ready_sessions: Dictionary = {}


func _has_capture(prefix: String) -> bool:
	return prefix == "renderdoc_bridge"


func _capture(message: String, data: Array, session_id: int) -> bool:
	match message:
		"renderdoc_bridge:runtime_ready":
			_runtime_ready_sessions[session_id] = true
			runtime_ready_changed.emit()
			return true
		"renderdoc_bridge:capture_result":
			var result := _parse_payload(data)
			capture_result_received.emit(session_id, result)
			return true
		"renderdoc_bridge:error":
			var error_result := _parse_payload(data)
			error_result["ok"] = false
			capture_result_received.emit(session_id, error_result)
			return true
	return false


func _setup_session(session_id: int) -> void:
	if _connected_sessions.has(session_id):
		return

	var session := get_session(session_id)
	if session == null:
		return

	session.started.connect(_on_game_started.bind(session_id))
	session.stopped.connect(_on_game_stopped.bind(session_id))
	_connected_sessions[session_id] = true


func _on_game_started(session_id: int) -> void:
	_active_sessions[session_id] = true
	_runtime_ready_sessions.erase(session_id)
	runtime_ready_changed.emit()


func _on_game_stopped(session_id: int) -> void:
	_active_sessions.erase(session_id)
	_runtime_ready_sessions.erase(session_id)
	runtime_ready_changed.emit()


func get_active_session_ids() -> Array[int]:
	var ids: Array[int] = []
	for key in _active_sessions.keys():
		ids.append(int(key))
	ids.sort()
	return ids


func is_runtime_ready(session_id: int) -> bool:
	return _runtime_ready_sessions.has(session_id)


func get_ready_session_ids() -> Array[int]:
	var ids: Array[int] = []
	for key in _runtime_ready_sessions.keys():
		if _active_sessions.has(key):
			ids.append(int(key))
	ids.sort()
	return ids


func send_capture_request(session_id: int, params: Dictionary) -> bool:
	if not _active_sessions.has(session_id):
		return false
	if not _runtime_ready_sessions.has(session_id):
		return false

	var session := get_session(session_id)
	if session == null:
		_active_sessions.erase(session_id)
		_runtime_ready_sessions.erase(session_id)
		runtime_ready_changed.emit()
		return false

	session.send_message("renderdoc_bridge:capture", [JSON.stringify(params)])
	return true


func _parse_payload(data: Array) -> Dictionary:
	if data.is_empty():
		return {}
	if data[0] is Dictionary:
		return data[0]
	if data[0] is String:
		var parsed = JSON.parse_string(data[0])
		if parsed is Dictionary:
			return parsed
	return {"error": "Invalid RenderDoc bridge debugger payload."}
