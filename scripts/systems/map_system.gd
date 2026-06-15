class_name MapSystem
extends RefCounted

const DEFAULT_NODES := [
	{"node_id": "entry", "node_type": "entry", "layer_index": 0, "lane_index": 0, "layer_width": 1, "reward": "Start"},
	{"node_id": "battle_1", "node_type": "battle", "layer_index": 1, "lane_index": 0, "layer_width": 2, "reward": "Battle"},
	{"node_id": "shop_1", "node_type": "shop", "layer_index": 1, "lane_index": 1, "layer_width": 2, "reward": "Shop"},
	{"node_id": "event_1", "node_type": "event", "layer_index": 2, "lane_index": 0, "layer_width": 3, "reward": "Event"},
	{"node_id": "rest_1", "node_type": "rest", "layer_index": 2, "lane_index": 1, "layer_width": 3, "reward": "Rest"},
	{"node_id": "battle_2", "node_type": "battle", "layer_index": 2, "lane_index": 2, "layer_width": 3, "reward": "Battle+"},
	{"node_id": "boss_1", "node_type": "boss", "layer_index": 3, "lane_index": 1, "layer_width": 1, "reward": "Boss"},
]

const DEFAULT_EDGES := [
	["entry", "battle_1"],
	["entry", "shop_1"],
	["battle_1", "event_1"],
	["battle_1", "rest_1"],
	["shop_1", "battle_2"],
	["event_1", "boss_1"],
	["rest_1", "boss_1"],
	["battle_2", "boss_1"],
]

var _map_def: Dictionary
var _node_states: Dictionary = {}
var _nodes_by_id: Dictionary = {}
var _current_node_id: StringName = &"entry"


func _init(map_def: Variant = {}) -> void:
	if map_def is Dictionary and not map_def.is_empty():
		_map_def = map_def
	else:
		_map_def = {
			"act_name": "Act 1",
			"nodes": DEFAULT_NODES.duplicate(true),
			"edges": DEFAULT_EDGES.duplicate(true),
		}
	for node_variant in _map_def.get("nodes", []):
		var node: Dictionary = node_variant
		var node_id := StringName(node.get("node_id", ""))
		_nodes_by_id[node_id] = node
		_node_states[node_id] = &"locked"
	_node_states[&"entry"] = &"current"
	_unlock_successors(&"entry")


func get_map_def() -> Dictionary:
	return _map_def


func get_visible_nodes() -> Array:
	return _map_def.get("nodes", [])


func get_visible_edges() -> Array:
	return _map_def.get("edges", [])


func get_node_state(node_id: StringName) -> StringName:
	return StringName(_node_states.get(node_id, &"locked"))


func can_enter_node(node_id: StringName) -> bool:
	return get_node_state(node_id) == &"available"


func enter_node(node_id: StringName) -> Dictionary:
	if not can_enter_node(node_id):
		return {"success": false}
	if _current_node_id != &"" and _node_states.get(_current_node_id, &"") == &"current":
		_node_states[_current_node_id] = &"completed"
	_unlock_successors(_current_node_id)
	_node_states[node_id] = &"current"
	_current_node_id = node_id
	return {
		"success": true,
		"node": _nodes_by_id.get(node_id, {}),
	}


func complete_node(node_id: StringName) -> void:
	if not _nodes_by_id.has(node_id):
		return
	_node_states[node_id] = &"completed"
	if _current_node_id == node_id:
		_current_node_id = &""
	_unlock_successors(node_id)


func get_available_node_ids() -> Array:
	var available: Array = []
	for node_id_variant in _node_states.keys():
		var node_id := StringName(node_id_variant)
		if _node_states[node_id] == &"available":
			available.append(node_id)
	return available


func get_current_node_id() -> StringName:
	return _current_node_id


func get_node(node_id: StringName) -> Dictionary:
	return _nodes_by_id.get(node_id, {})


func _unlock_successors(node_id: StringName) -> void:
	for edge_variant in _map_def.get("edges", []):
		var edge: Array = edge_variant
		if StringName(edge[0]) != node_id:
			continue
		var to_id := StringName(edge[1])
		if _node_states.get(to_id, &"locked") == &"locked":
			_node_states[to_id] = &"available"
