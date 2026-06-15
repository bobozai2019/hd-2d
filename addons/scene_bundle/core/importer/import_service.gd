extends RefCounted

func import_bundle(bundle_zip: String, target_root: String = "res://", preserve_original_paths: bool = true, allow_script_errors: bool = true, strip_csharp_scripts: bool = true, overwrite_conflicts: bool = false) -> Dictionary:
	var reader := ZIPReader.new()
	var err := reader.open(bundle_zip)
	if err != OK:
		return {"ok": false, "error": "zip_open_failed", "code": err}
	var files := reader.get_files()
	if not files.has("manifest.json"):
		reader.close()
		return {"ok": false, "error": "manifest_missing"}
	var manifest_text := reader.read_file("manifest.json").get_string_from_utf8()
	var manifest = JSON.parse_string(manifest_text)
	if not (manifest is Dictionary):
		reader.close()
		return {"ok": false, "error": "manifest_parse_failed"}

	var mapping := {}
	for rec in manifest.get("files", []):
		if not (rec is Dictionary):
			continue
		var src_path := String(rec.get("src_path", ""))
		if not src_path.begins_with("res://"):
			continue
		mapping[src_path] = _map_target_path(src_path, target_root, preserve_original_paths)

	var write_count := 0
	var identical_count := 0
	var skipped_conflicts: PackedStringArray = []
	var overwritten_conflicts: PackedStringArray = []
	var written_paths: PackedStringArray = []
	for zpath in files:
		if zpath == "manifest.json":
			continue
		if not zpath.begins_with("files/"):
			continue
		var rel := zpath.trim_prefix("files/")
		var dst_res := _join_res_path(target_root, rel)
		if preserve_original_paths:
			dst_res = "res://%s" % rel
		var payload := reader.read_file(zpath)
		if FileAccess.file_exists(dst_res):
			var before := _read_all_bytes(dst_res)
			if before.size() == payload.size() and before == payload:
				identical_count += 1
				continue
			if not overwrite_conflicts:
				skipped_conflicts.append(dst_res)
				continue
			overwritten_conflicts.append(dst_res)
		DirAccess.make_dir_recursive_absolute(dst_res.get_base_dir())
		var out_f := FileAccess.open(dst_res, FileAccess.WRITE)
		if out_f == null:
			reader.close()
			return {"ok": false, "error": "write_failed", "path": dst_res}
		out_f.store_buffer(payload)
		write_count += 1
		written_paths.append(dst_res)
	reader.close()

	var rewritten := _rewrite_imported_text_files(target_root, mapping)
	var stripped_scripts := 0
	if strip_csharp_scripts:
		stripped_scripts = _strip_csharp_script_references(written_paths)

	var entry_old := String(manifest.get("entry_scene", ""))
	var entry_new := String(mapping.get(entry_old, ""))
	if entry_new == "":
		return {"ok": false, "error": "entry_mapping_missing", "entry_old": entry_old}
	if not FileAccess.file_exists(entry_new):
		return {"ok": false, "error": "entry_file_missing_after_import", "entry_new": entry_new}

	var check = _check_non_script_resources_strict(entry_new)
	if not PackedStringArray(check.get("missing", PackedStringArray())).is_empty():
		return {
			"ok": false,
			"error": "missing_non_script_resources",
			"entry_new": entry_new,
			"missing": check.get("missing", PackedStringArray())
		}
	if not PackedStringArray(check.get("unloadable", PackedStringArray())).is_empty():
		return {
			"ok": false,
			"error": "unloadable_non_script_resources",
			"entry_new": entry_new,
			"unloadable": check.get("unloadable", PackedStringArray())
		}

	var loaded = load(entry_new)
	if loaded == null:
		return {"ok": false, "error": "entry_load_failed", "entry_new": entry_new}
	var packed := loaded as PackedScene
	if packed == null:
		return {"ok": false, "error": "entry_not_packed_scene", "entry_new": entry_new}
	var inst = packed.instantiate()
	if inst == null:
		if allow_script_errors:
			return {
				"ok": true,
				"entry_scene": entry_new,
				"written": write_count,
				"identical": identical_count,
				"rewritten": rewritten,
				"target_root": target_root,
				"warnings": ["instantiate_failed_but_ignored_by_allow_script_errors"],
				"stripped_scripts": stripped_scripts,
				"skipped_conflicts": skipped_conflicts,
				"overwritten_conflicts": overwritten_conflicts
			}
		return {"ok": false, "error": "entry_instantiate_failed", "entry_new": entry_new}
	inst.free()

	return {
		"ok": true,
		"entry_scene": entry_new,
		"written": write_count,
		"identical": identical_count,
		"rewritten": rewritten,
		"target_root": target_root,
		"stripped_scripts": stripped_scripts,
		"skipped_conflicts": skipped_conflicts,
		"overwritten_conflicts": overwritten_conflicts
	}


func _read_all_bytes(path: String) -> PackedByteArray:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return PackedByteArray()
	return f.get_buffer(f.get_length())


func _map_target_path(src_path: String, target_root: String, preserve_original_paths: bool) -> String:
	if preserve_original_paths:
		return src_path
	return _join_res_path(target_root, src_path.trim_prefix("res://"))


func _join_res_path(root: String, rel: String) -> String:
	var clean_root := root
	if clean_root == "":
		clean_root = "res://"
	if clean_root == "res://":
		return "res://%s" % rel
	if not clean_root.begins_with("res://"):
		clean_root = "res://%s" % clean_root.trim_prefix("/")
	clean_root = clean_root.trim_suffix("/")
	return "%s/%s" % [clean_root, rel]


func _strip_csharp_script_references(dst_paths: Array) -> int:
	var changed_count := 0
	var ext_id_re := RegEx.new()
	if ext_id_re.compile("\\[ext_resource\\s+type=\"Script\"[^\\n]*path=\"res://[^\"]+\\.cs\"[^\\n]*id=\"([^\"]+)\"[^\\n]*\\]") != OK:
		return 0
	for raw_path in dst_paths:
		var path := String(raw_path)
		if not path.ends_with(".tscn"):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var text := f.get_as_text()
		var ids_to_remove: PackedStringArray = []
		for m: RegExMatch in ext_id_re.search_all(text):
			ids_to_remove.append(m.get_string(1))
		if ids_to_remove.is_empty():
			continue
		text = ext_id_re.sub(text, "", true)
		for id in ids_to_remove:
			var assign_re := RegEx.new()
			if assign_re.compile("(?m)^\\s*script\\s*=\\s*ExtResource\\(\"" + id + "\"\\)\\s*$") == OK:
				text = assign_re.sub(text, "", true)
		var out_f := FileAccess.open(path, FileAccess.WRITE)
		if out_f == null:
			continue
		out_f.store_string(text)
		changed_count += 1
	return changed_count


func _check_non_script_resources_strict(entry_scene: String) -> Dictionary:
	var missing: PackedStringArray = []
	var unloadable: PackedStringArray = []
	var visited: Dictionary = {}
	_scan_non_script_from_text_resource(entry_scene, visited, missing, unloadable)
	return {
		"missing": missing,
		"unloadable": unloadable
	}


func _scan_non_script_from_text_resource(path: String, visited: Dictionary, missing: PackedStringArray, unloadable: PackedStringArray) -> void:
	if visited.has(path):
		return
	visited[path] = true
	var ext := "." + path.get_extension().to_lower()
	if ext not in [".tscn", ".tres", ".res"]:
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		if path not in missing:
			missing.append(path)
		return
	var text := f.get_as_text()
	var re := RegEx.new()
	if re.compile("path=\"(res://[^\"]+)\"") != OK:
		return
	for m: RegExMatch in re.search_all(text):
		var dep_path := m.get_string(1)
		if dep_path == "":
			continue
		var dep_ext := "." + dep_path.get_extension().to_lower()
		if dep_ext == ".cs":
			continue
		if not FileAccess.file_exists(dep_path):
			if dep_path not in missing:
				missing.append(dep_path)
			continue
		if dep_ext in [".tscn", ".tres", ".res"]:
			var dep_loaded = load(dep_path)
			if dep_loaded == null and dep_path not in unloadable:
				unloadable.append(dep_path)
		if dep_ext in [".tscn", ".tres", ".res"]:
			_scan_non_script_from_text_resource(dep_path, visited, missing, unloadable)


func _rewrite_imported_text_files(target_root: String, mapping: Dictionary) -> int:
	var all_files := _list_files_recursive(target_root)
	var count := 0
	for fpath in all_files:
		var ext := fpath.get_extension().to_lower()
		if ext not in ["tscn", "tres", "res", "gd"]:
			continue
		var file := FileAccess.open(fpath, FileAccess.READ)
		if file == null:
			continue
		var text := file.get_as_text()
		var changed := false
		for old_path in mapping.keys():
			var new_path := String(mapping[old_path])
			if text.find(old_path) != -1:
				text = text.replace(old_path, new_path)
				changed = true
		if changed:
			var out_f := FileAccess.open(fpath, FileAccess.WRITE)
			if out_f != null:
				out_f.store_string(text)
				count += 1
	return count


func _list_files_recursive(base: String) -> PackedStringArray:
	var out: PackedStringArray = []
	_walk(base, out)
	return out


func _walk(dir_path: String, out: PackedStringArray) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	while true:
		var name := d.get_next()
		if name == "":
			break
		if name == "." or name == "..":
			continue
		var child := "%s/%s" % [dir_path, name]
		if d.current_is_dir():
			_walk(child, out)
		else:
			out.append(child)
	d.list_dir_end()
