@tool
extends EditorContextMenuPlugin

const CALLBACK_UTIL_PATH := "res://addons/scene_bundle/editor/context_callback_util.gd"

var _owner_plugin: EditorPlugin
var _logic: RefCounted
var _callback_util: GDScript


func _init(owner_plugin: EditorPlugin, logic: RefCounted) -> void:
	_owner_plugin = owner_plugin
	_logic = logic
	_callback_util = load(CALLBACK_UTIL_PATH)


func _popup_menu(paths: PackedStringArray) -> void:
	if _owner_plugin == null or _logic == null:
		return
	var choice: Dictionary = _logic.choose_scene_for_export(paths)
	if not bool(choice.get("ok", false)):
		return
	var scene_path := String(choice.get("scene_path", ""))
	add_context_menu_item(
		"Export Scene Bundle...",
		Callable(self, "_on_export_pressed").bind(scene_path)
	)


func _on_export_pressed(arg0: Variant = null, arg1: Variant = null) -> void:
	var scene_path := ""
	if _callback_util != null and _callback_util.has_method("extract_scene_path"):
		scene_path = String(_callback_util.call("extract_scene_path", arg0, arg1))
	if _owner_plugin != null and _owner_plugin.has_method("_begin_export_scene"):
		_owner_plugin.call("_begin_export_scene", scene_path)
