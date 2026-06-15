class_name RunHexMapLayout
extends RefCounted

const TILE_SIZE := 0.72
const LAYER_SPACING_Z := 1.55
const LANE_SPACING_X := 1.35


static func build_layout(map_def: Variant) -> Dictionary:
	var nodes: Array = []
	if map_def is Array:
		nodes = map_def
	elif map_def is Dictionary:
		nodes = map_def.get("nodes", [])
	var layout: Dictionary = {}
	for node_variant in nodes:
		var node: Dictionary = node_variant
		var lane_index := int(node.get("lane_index", 0))
		var layer_index := int(node.get("layer_index", 0))
		var layer_width: int = maxi(1, int(node.get("layer_width", 1)))
		var centered_lane: int = lane_index - int(floor(float(layer_width) * 0.5))
		var q: int = centered_lane
		var r: int = layer_index
		layout[StringName(node.get("node_id", ""))] = {
			"axial": Vector2i(q, r),
			"world": Vector3(centered_lane * LANE_SPACING_X, 0.0, -layer_index * LAYER_SPACING_Z),
			"node": node,
		}
	return layout


static func get_map_bounds(layout: Dictionary) -> AABB:
	if layout.is_empty():
		return AABB(Vector3(-1.0, -0.5, -1.0), Vector3(2.0, 1.0, 2.0))
	var min_point := Vector3(INF, INF, INF)
	var max_point := Vector3(-INF, -INF, -INF)
	for entry_variant in layout.values():
		var entry: Dictionary = entry_variant
		var world := entry.get("world", Vector3.ZERO) as Vector3
		min_point.x = minf(min_point.x, world.x)
		min_point.y = minf(min_point.y, world.y)
		min_point.z = minf(min_point.z, world.z)
		max_point.x = maxf(max_point.x, world.x)
		max_point.y = maxf(max_point.y, world.y)
		max_point.z = maxf(max_point.z, world.z)
	var padding := Vector3(1.8, 1.4, 1.8)
	return AABB(min_point - padding * 0.5, (max_point - min_point) + padding)
