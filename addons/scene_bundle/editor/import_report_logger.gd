extends RefCounted

const REPORT_DIR := "user://scene_bundle/import_logs"

func build_report(bundle_path: String, result: Dictionary) -> Dictionary:
	return {
		"created_at": Time.get_datetime_string_from_system(true, true),
		"bundle_path": bundle_path,
		"ok": bool(result.get("ok", false)),
		"entry_scene": String(result.get("entry_scene", "")),
		"written": int(result.get("written", 0)),
		"identical": int(result.get("identical", 0)),
		"skipped_conflicts": result.get("skipped_conflicts", PackedStringArray()),
		"overwritten_conflicts": result.get("overwritten_conflicts", PackedStringArray()),
		"raw_result": result
	}


func write_report(report: Dictionary) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(REPORT_DIR)
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace(" ", "_")
	var path := "%s/import_report_%s.json" % [REPORT_DIR, stamp]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return {"ok": false, "error": "open_failed", "path": path}
	f.store_string(JSON.stringify(report, "\t"))
	return {"ok": true, "path": path}
