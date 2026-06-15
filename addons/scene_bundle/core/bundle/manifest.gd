extends RefCounted

const SUPPORTED_FORMAT_VERSION := "1.0"

func to_json(data: Dictionary) -> String:
	var payload := data.duplicate(true)
	if not payload.has("bundle_format_version"):
		payload["bundle_format_version"] = SUPPORTED_FORMAT_VERSION
	return JSON.stringify(payload, "\t")

func from_json(text: String) -> Dictionary:
	var parsed := JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

func validate(data: Dictionary) -> Dictionary:
	var issues: PackedStringArray = []
	if data.get("bundle_format_version", "") != SUPPORTED_FORMAT_VERSION:
		issues.append("unsupported_bundle_format_version")
	if data.get("bundle_name", "") == "":
		issues.append("missing_bundle_name")
	if data.get("bundle_id", "") == "":
		issues.append("missing_bundle_id")
	if data.get("entry_scene", "") == "":
		issues.append("missing_entry_scene")
	return {
		"ok": issues.is_empty(),
		"issues": issues
	}
