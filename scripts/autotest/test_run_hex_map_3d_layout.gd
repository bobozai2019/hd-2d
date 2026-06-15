extends SceneTree

const RunHexMapLayoutScript := preload("res://scripts/map3d/run_hex_map_layout.gd")

const SAMPLE_MAP := [
	{"node_id": "entry", "node_type": "current", "layer_index": 0, "lane_index": 0, "layer_width": 1},
	{"node_id": "battle_1", "node_type": "battle", "layer_index": 1, "lane_index": 0, "layer_width": 2},
	{"node_id": "shop_1", "node_type": "shop", "layer_index": 1, "lane_index": 1, "layer_width": 2},
]


func _init() -> void:
	var layout: Dictionary = RunHexMapLayoutScript.build_layout(SAMPLE_MAP)
	_assert(layout.size() == SAMPLE_MAP.size(), "layout contains every sample node")
	for node in SAMPLE_MAP:
		var node_id := StringName(node.get("node_id", ""))
		_assert(layout.has(node_id), "layout has node %s" % String(node_id))
		var entry: Dictionary = layout[node_id]
		_assert(entry.has("axial"), "layout entry has axial")
		_assert(entry.has("world"), "layout entry has world")
		_assert(entry.has("node"), "layout entry has node")
	var bounds := RunHexMapLayoutScript.get_map_bounds(layout)
	_assert(bounds.size.length() > 0.0, "layout bounds are non-zero")
	print("PASS test_run_hex_map_3d_layout")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
