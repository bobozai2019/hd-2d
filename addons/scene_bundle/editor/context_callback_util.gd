extends RefCounted

static func extract_scene_path(arg0: Variant, arg1: Variant = null) -> String:
	if arg1 is String and String(arg1) != "":
		return String(arg1)
	if arg0 is String and String(arg0) != "":
		return String(arg0)
	return ""
