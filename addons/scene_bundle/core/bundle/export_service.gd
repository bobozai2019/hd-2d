extends RefCounted

const PARSEABLE_TEXT_EXT := [".tscn", ".tres", ".res"]
const ATLAS_IMAGE_EXT := [".png", ".webp", ".jpg", ".jpeg", ".ktx", ".dds"]

func export_scene_bundle(entry_scene: String, out_zip: String) -> Dictionary:
	if not ResourceLoader.exists(entry_scene):
		return {"ok": false, "error": "entry_scene_not_found", "entry_scene": entry_scene}

	var deps_map: Dictionary = {}
	_collect_dependencies(entry_scene, deps_map)
	_collect_direct_script_literals(entry_scene, deps_map)

	var paths := deps_map.keys()
	paths.sort()

	var files: Array = []
	var packer := ZIPPacker.new()
	var open_err := packer.open(out_zip)
	if open_err != OK:
		return {"ok": false, "error": "zip_open_failed", "code": open_err}

	for p in paths:
		var src_path: String = p
		if not src_path.begins_with("res://"):
			continue
		var rel := src_path.trim_prefix("res://")
		var bundle_path := "files/%s" % rel
		var in_f := FileAccess.open(src_path, FileAccess.READ)
		if in_f == null:
			packer.close()
			return {"ok": false, "error": "copy_read_failed", "path": src_path}
		var start_err := packer.start_file(bundle_path)
		if start_err != OK:
			packer.close()
			return {"ok": false, "error": "zip_start_file_failed", "path": bundle_path, "code": start_err}
		packer.write_file(in_f.get_buffer(in_f.get_length()))
		packer.close_file()
		files.append({
			"src_path": src_path,
			"bundle_path": bundle_path,
			"status": "confirmed"
		})

	var manifest := {
		"bundle_format_version": "1.0",
		"bundle_name": entry_scene.get_file().get_basename(),
		"bundle_id": "scene_bundle.%s.%s" % [entry_scene.get_file().get_basename(), Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "")],
		"godot_version": Engine.get_version_info().get("string", ""),
		"created_at": Time.get_datetime_string_from_system(true, true),
		"entry_scene": entry_scene,
		"files": files,
		"warnings": []
	}
	var manifest_text := JSON.stringify(manifest, "\t")
	var manifest_err := packer.start_file("manifest.json")
	if manifest_err != OK:
		packer.close()
		return {"ok": false, "error": "zip_start_manifest_failed", "code": manifest_err}
	packer.write_file(manifest_text.to_utf8_buffer())
	packer.close_file()
	packer.close()

	return {
		"ok": true,
		"entry_scene": entry_scene,
		"out_zip": out_zip,
		"file_count": files.size()
	}


func _collect_dependencies(path: String, deps_map: Dictionary) -> void:
	if deps_map.has(path):
		return
	deps_map[path] = true
	_collect_import_sidecar(path, deps_map)
	_collect_atlas_page_dependencies(path, deps_map)
	_collect_text_resource_dependencies(path, deps_map)
	var deps := ResourceLoader.get_dependencies(path)
	for d in deps:
		var dep_path := String(d)
		if dep_path.find("::") != -1:
			dep_path = dep_path.split("::", false, 1)[0]
		if dep_path == "" or not dep_path.begins_with("res://"):
			continue
		if ResourceLoader.exists(dep_path):
			_collect_dependencies(dep_path, deps_map)


func _collect_atlas_page_dependencies(path: String, deps_map: Dictionary) -> void:
	if not path.ends_with(".atlas"):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var base_dir := path.get_base_dir()
	var lines := f.get_as_text().split("\n", false)
	for raw_line in lines:
		var line := raw_line.strip_edges()
		if line == "" or ":" in line:
			continue
		var lower := line.to_lower()
		var has_image_ext := false
		for ext in ATLAS_IMAGE_EXT:
			if lower.ends_with(ext):
				has_image_ext = true
				break
		if not has_image_ext:
			continue
		var img_path := ""
		if line.begins_with("res://"):
			img_path = line
		else:
			img_path = base_dir.path_join(line)
		if FileAccess.file_exists(img_path):
			_collect_dependencies(img_path, deps_map)


func _collect_import_sidecar(path: String, deps_map: Dictionary) -> void:
	if path.ends_with(".import"):
		return
	var sidecar := "%s.import" % path
	if FileAccess.file_exists(sidecar):
		deps_map[sidecar] = true
		_collect_import_outputs(sidecar, deps_map)


func _collect_import_outputs(import_file_path: String, deps_map: Dictionary) -> void:
	var f := FileAccess.open(import_file_path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	var re := RegEx.new()
	if re.compile("res://\\.godot/imported/[^\"]+") != OK:
		return
	for m: RegExMatch in re.search_all(text):
		var out_path := m.get_string(0)
		if out_path == "":
			continue
		if FileAccess.file_exists(out_path):
			deps_map[out_path] = true
		var md5_path := "%s.md5" % out_path
		if FileAccess.file_exists(md5_path):
			deps_map[md5_path] = true


func _collect_text_resource_dependencies(path: String, deps_map: Dictionary) -> void:
	var ext := "." + path.get_extension().to_lower()
	if ext not in PARSEABLE_TEXT_EXT:
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	var re := RegEx.new()
	if re.compile("path=\"(res://[^\"]+)\"") != OK:
		return
	for m: RegExMatch in re.search_all(text):
		var dep_path := m.get_string(1)
		if dep_path == "":
			continue
		if ResourceLoader.exists(dep_path):
			_collect_dependencies(dep_path, deps_map)


func _collect_direct_script_literals(entry_scene: String, deps_map: Dictionary) -> void:
	var packed := load(entry_scene) as PackedScene
	if packed == null:
		return
	var inst := packed.instantiate()
	if inst == null:
		return
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var script: Variant = node.get_script()
		if script is Script:
			var script_path := String((script as Script).resource_path)
			if script_path.begins_with("res://") and ResourceLoader.exists(script_path):
				deps_map[script_path] = true
				_scan_script_literal_paths(script_path, deps_map)
		for c in node.get_children():
			var child_node := c as Node
			if child_node != null:
				stack.append(child_node)
	inst.free()


func _scan_script_literal_paths(script_path: String, deps_map: Dictionary) -> void:
	var f := FileAccess.open(script_path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	var re := RegEx.new()
	if re.compile("(?:preload|load|ResourceLoader\\.load)\\(\\s*\"(res://[^\"]+)\"\\s*\\)") != OK:
		return
	for m: RegExMatch in re.search_all(text):
		var p := m.get_string(1)
		if ResourceLoader.exists(p):
			_collect_dependencies(p, deps_map)