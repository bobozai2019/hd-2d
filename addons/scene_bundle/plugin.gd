@tool
extends EditorPlugin

const LOGIC_PATH := "res://addons/scene_bundle/editor/editor_logic.gd"
const EXPORT_SERVICE_PATH := "res://addons/scene_bundle/core/bundle/export_service.gd"
const IMPORT_SERVICE_PATH := "res://addons/scene_bundle/core/importer/import_service.gd"
const FS_CONTEXT_PLUGIN_PATH := "res://addons/scene_bundle/editor/filesystem_context_menu_plugin.gd"
const IMPORT_REPORT_LOGGER_PATH := "res://addons/scene_bundle/editor/import_report_logger.gd"

var _logic: RefCounted
var _export_service: RefCounted
var _import_service: RefCounted
var _import_report_logger: RefCounted

var _fs_context_plugin: EditorContextMenuPlugin
var _import_button: Button
var _export_dialog: FileDialog
var _import_dialog: FileDialog

var _warning_panel: PanelContainer
var _warning_label: RichTextLabel
var _warning_close_button: Button

var _pending_scene_path := ""


func _enter_tree() -> void:
	_logic = load(LOGIC_PATH).new()
	_export_service = load(EXPORT_SERVICE_PATH).new()
	_import_service = load(IMPORT_SERVICE_PATH).new()
	_import_report_logger = load(IMPORT_REPORT_LOGGER_PATH).new()

	_setup_warning_dialog()
	_setup_export_dialog()
	_setup_import_dialog()
	_setup_toolbar_button()
	_setup_filesystem_context_menu_plugin()


func _exit_tree() -> void:
	if _fs_context_plugin != null:
		remove_context_menu_plugin(_fs_context_plugin)
		_fs_context_plugin = null
	if _import_button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, _import_button)
		_import_button.queue_free()
		_import_button = null
	if _export_dialog != null:
		_export_dialog.queue_free()
		_export_dialog = null
	if _import_dialog != null:
		_import_dialog.queue_free()
		_import_dialog = null
	if _warning_panel != null:
		_warning_panel.queue_free()
		_warning_panel = null


func _setup_toolbar_button() -> void:
	_import_button = Button.new()
	_import_button.text = "Import Scene Bundle"
	_import_button.tooltip_text = "Import a scene bundle (.zip) into this project"
	_import_button.pressed.connect(_on_import_button_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, _import_button)


func _setup_export_dialog() -> void:
	_export_dialog = FileDialog.new()
	_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog.title = "Export Scene Bundle"
	_export_dialog.add_filter("*.zip ; Scene Bundle ZIP")
	_export_dialog.file_selected.connect(_on_export_file_selected)
	get_editor_interface().get_base_control().add_child(_export_dialog)


func _setup_import_dialog() -> void:
	_import_dialog = FileDialog.new()
	_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog.title = "Import Scene Bundle"
	_import_dialog.add_filter("*.zip ; Scene Bundle ZIP")
	_import_dialog.file_selected.connect(_on_import_file_selected)
	get_editor_interface().get_base_control().add_child(_import_dialog)


func _setup_filesystem_context_menu_plugin() -> void:
	if not ClassDB.class_exists("EditorContextMenuPlugin"):
		return
	var script := load(FS_CONTEXT_PLUGIN_PATH)
	if script == null:
		return
	_fs_context_plugin = script.new(self, _logic)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _fs_context_plugin)


func _begin_export_scene(scene_path: String) -> void:
	if scene_path == "":
		_report_status("Export Failed", "Please select exactly one .tscn scene in the FileSystem dock.", true)
		return
	_pending_scene_path = scene_path
	_export_dialog.current_file = _logic.suggest_bundle_filename(scene_path)
	_export_dialog.popup_centered_ratio(0.5)


func _on_export_file_selected(path: String) -> void:
	if _export_dialog != null and _export_dialog.visible:
		_export_dialog.hide()
	if _pending_scene_path == "":
		_report_status("Export Failed", "No scene selected for export.", true)
		return
	if not _logic.is_zip_path(path):
		path += ".zip"
	var result: Dictionary = _export_service.export_scene_bundle(_pending_scene_path, path)
	if bool(result.get("ok", false)):
		_report_status("Export Complete", "Bundle exported to: %s" % path, false)
	else:
		_report_status("Export Failed", JSON.stringify(result, "\t"), true)


func _on_import_button_pressed() -> void:
	_import_dialog.popup_centered_ratio(0.5)


func _on_import_file_selected(path: String) -> void:
	if _import_dialog != null and _import_dialog.visible:
		_import_dialog.hide()
	if not _logic.is_zip_path(path):
		_report_status("Import Failed", "Please select a .zip file.", true)
		return
	var result: Dictionary = _import_service.import_bundle(path, "res://", true, true, true, false)
	var log_info := _record_import_report(path, result)
	if bool(result.get("ok", false)):
		_report_status("Import Complete", JSON.stringify(result, "\t"), false)
		_maybe_warn_import_conflicts(result, log_info)
		_refresh_editor_filesystem()
	else:
		_report_status("Import Failed", JSON.stringify(result, "\t"), true)


func _refresh_editor_filesystem() -> void:
	var editor_fs: Variant = get_editor_interface().get_resource_filesystem()
	if editor_fs != null and editor_fs.has_method("scan"):
		editor_fs.call("scan")


func _report_status(title: String, body: String, is_error: bool) -> void:
	var line := "[SceneBundle] %s: %s" % [title, body]
	if is_error:
		push_error(line)
	else:
		print(line)


func _record_import_report(bundle_path: String, result: Dictionary) -> Dictionary:
	if _import_report_logger == null:
		return {"ok": false, "error": "logger_not_ready"}
	var report: Dictionary = _import_report_logger.build_report(bundle_path, result)
	var write_result: Dictionary = _import_report_logger.write_report(report)
	if bool(write_result.get("ok", false)):
		var user_path := String(write_result.get("path", ""))
		var abs_path := ProjectSettings.globalize_path(user_path)
		print("[SceneBundle] Import report written: %s" % abs_path)
		write_result["absolute_path"] = abs_path
	else:
		push_error("[SceneBundle] Failed to write import report: %s" % JSON.stringify(write_result))
	return write_result


func _maybe_warn_import_conflicts(result: Dictionary, log_info: Dictionary) -> void:
	var skipped: PackedStringArray = PackedStringArray(result.get("skipped_conflicts", PackedStringArray()))
	var overwritten: PackedStringArray = PackedStringArray(result.get("overwritten_conflicts", PackedStringArray()))
	if skipped.is_empty() and overwritten.is_empty():
		return
	var log_path := String(log_info.get("absolute_path", ""))
	var body := "Import finished with path conflicts.\n\nSkipped conflicts: %d\nOverwritten conflicts: %d" % [
		skipped.size(),
		overwritten.size()
	]
	if log_path != "":
		body += "\n\nLog file:\n%s" % log_path
	call_deferred("_show_warning_panel", body)


func _setup_warning_dialog() -> void:
	var base := get_editor_interface().get_base_control()
	_warning_panel = PanelContainer.new()
	_warning_panel.name = "SceneBundleWarningPanel"
	_warning_panel.custom_minimum_size = Vector2(640, 280)
	_warning_panel.visible = false
	_warning_panel.z_index = 100

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 12)
	outer.add_theme_constant_override("margin_top", 12)
	outer.add_theme_constant_override("margin_right", 12)
	outer.add_theme_constant_override("margin_bottom", 12)
	_warning_panel.add_child(outer)

	var vbox := VBoxContainer.new()
	outer.add_child(vbox)

	var title := Label.new()
	title.text = "Scene Bundle Import Warning"
	vbox.add_child(title)

	_warning_label = RichTextLabel.new()
	_warning_label.fit_content = true
	_warning_label.scroll_active = true
	_warning_label.custom_minimum_size = Vector2(600, 180)
	vbox.add_child(_warning_label)

	_warning_close_button = Button.new()
	_warning_close_button.text = "Close"
	_warning_close_button.pressed.connect(_on_warning_close_pressed)
	vbox.add_child(_warning_close_button)

	base.add_child(_warning_panel)
	if not base.resized.is_connected(_recenter_warning_panel):
		base.resized.connect(_recenter_warning_panel)


func _show_warning_panel(body: String) -> void:
	if _warning_panel == null or _warning_label == null:
		return
	_warning_label.clear()
	_warning_label.append_text(body)
	_warning_panel.show()
	_warning_panel.move_to_front()
	_recenter_warning_panel()


func _on_warning_close_pressed() -> void:
	if _warning_panel != null:
		_warning_panel.hide()


func _recenter_warning_panel() -> void:
	if _warning_panel == null:
		return
	var base := get_editor_interface().get_base_control()
	if base == null:
		return
	var vp_size := base.size
	var p_size := _warning_panel.size
	if p_size.x <= 0.0 or p_size.y <= 0.0:
		p_size = _warning_panel.custom_minimum_size
	_warning_panel.position = Vector2(
		maxf(0.0, (vp_size.x - p_size.x) * 0.5),
		maxf(0.0, (vp_size.y - p_size.y) * 0.22)
	)
