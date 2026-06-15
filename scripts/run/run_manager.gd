class_name RunManager
extends RefCounted

const MapSystemScript := preload("res://scripts/systems/map_system.gd")

static var current_ctx: Dictionary = {}


static func create_preview_ctx() -> Dictionary:
	var map_system = MapSystemScript.new()
	return {
		"act_name": "Act 1",
		"hp": 52,
		"gold": 140,
		"map_system": map_system,
		"map_def": map_system.get_map_def(),
	}


static func clear() -> void:
	current_ctx = {}
