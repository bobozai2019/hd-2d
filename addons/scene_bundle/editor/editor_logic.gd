extends RefCounted

func choose_scene_for_export(selected_paths: PackedStringArray) -> Dictionary:
	if selected_paths.size() != 1:
		return {"ok": false, "error": "select_exactly_one_scene"}
	var path := selected_paths[0]
	if not path.begins_with("res://") or not path.ends_with(".tscn"):
		return {"ok": false, "error": "selected_path_is_not_scene", "path": path}
	return {"ok": true, "scene_path": path}


func suggest_bundle_filename(scene_path: String) -> String:
	if scene_path == "":
		return "scene.bundle.zip"
	return "%s.bundle.zip" % scene_path.get_file().get_basename()


func is_zip_path(path: String) -> bool:
	return path.to_lower().ends_with(".zip")