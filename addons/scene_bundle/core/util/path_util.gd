extends RefCounted

const BUNDLE_FILES_ROOT := "files/"

func to_bundle_path(res_path: String) -> String:
	if not res_path.begins_with("res://"):
		return ""
	return BUNDLE_FILES_ROOT + res_path.trim_prefix("res://")

func to_res_path(bundle_path: String) -> String:
	if not bundle_path.begins_with(BUNDLE_FILES_ROOT):
		return ""
	return "res://" + bundle_path.trim_prefix(BUNDLE_FILES_ROOT)
