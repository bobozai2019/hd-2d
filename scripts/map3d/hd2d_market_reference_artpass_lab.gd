extends Node3D

const PROFILE_BASELINE_8B_FINAL := "baseline_8b_final"
const PROFILE_ASSET_ARTPASS_ONLY := "asset_artpass_only"
const PROFILE_ARTPASS_REFERENCE_V1 := "artpass_reference_v1"
const PROFILE_NO_LOCAL_LIGHT := "no_local_light"
const PROFILE_NO_PATCH := "no_patch"
const PROFILE_NO_POST := "no_post"
const PROFILE_CHARACTER_SCALE_CHECK := "character_scale_check"
const SUPPORTED_PROFILES: Array[String] = [
	PROFILE_BASELINE_8B_FINAL,
	PROFILE_ASSET_ARTPASS_ONLY,
	PROFILE_ARTPASS_REFERENCE_V1,
	PROFILE_NO_LOCAL_LIGHT,
	PROFILE_NO_PATCH,
	PROFILE_NO_POST,
	PROFILE_CHARACTER_SCALE_CHECK,
]

const MAT_WALL_TRIM := preload("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_wall_trim.tres")
const MAT_CERAMIC := preload("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_ceramic.tres")
const MAT_FABRIC_RED := preload("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_fabric_red.tres")
const MAT_FABRIC_TEAL := preload("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_fabric_teal.tres")
const MAT_SHADOW_WOOD := preload("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_shadow_wood.tres")

var reference_profile := PROFILE_ARTPASS_REFERENCE_V1

var _pending_capture_args: Array[String] = []
var _material_override_count := 0

@onready var _base_lab: Node3D = $Base8BMarketReferenceLab
@onready var _artpass_details: Node3D = $ArtpassDetails
@onready var _artpass_light_patches: Node3D = $ArtpassLightPatches


func _ready() -> void:
	_apply_artpass_material_overrides()

	var startup_args: PackedStringArray = OS.get_cmdline_user_args()
	for arg in startup_args:
		if arg.begins_with("reference_profile="):
			_pending_capture_args.append(arg)

	if _pending_capture_args.size() > 0:
		_apply_profile_args(_pending_capture_args)
		_pending_capture_args.clear()
	else:
		set_reference_profile(reference_profile)


func apply_capture_args(args: Array[String]) -> void:
	if _base_lab == null:
		_pending_capture_args.append_array(args)
		return
	_apply_profile_args(args)


func set_reference_profile(profile_name: String) -> void:
	reference_profile = profile_name if SUPPORTED_PROFILES.has(profile_name) else PROFILE_ARTPASS_REFERENCE_V1

	match reference_profile:
		PROFILE_BASELINE_8B_FINAL:
			_apply_base_profile("reference_match_v2")
			_set_artpass_visible(false, false)
		PROFILE_ASSET_ARTPASS_ONLY:
			_apply_base_profile("no_post")
			_set_artpass_visible(true, false)
		PROFILE_NO_LOCAL_LIGHT:
			_apply_base_profile("no_local_light")
			_set_artpass_visible(true, true)
		PROFILE_NO_PATCH:
			_apply_base_profile("no_patch")
			_set_artpass_visible(true, false)
		PROFILE_NO_POST:
			_apply_base_profile("no_post")
			_set_artpass_visible(true, true)
		PROFILE_CHARACTER_SCALE_CHECK:
			_apply_base_profile("character_scale_check")
			_set_artpass_visible(true, true)
		_:
			_apply_base_profile("reference_match_v2")
			_set_artpass_visible(true, true)


func get_market_reference_artpass_profile_state() -> Dictionary:
	var base_state := {}
	if _base_lab != null and _base_lab.has_method("get_market_reference_profile_state"):
		base_state = _base_lab.call("get_market_reference_profile_state") as Dictionary

	return {
		"reference_profile": reference_profile,
		"base_reference_profile": String(base_state.get("reference_profile", "")),
		"supported_profiles": SUPPORTED_PROFILES,
		"visible_real_local_light_count": int(base_state.get("visible_real_local_light_count", 0)),
		"visible_real_local_lights": base_state.get("visible_real_local_lights", []),
		"dynamic_local_light_budget": 3,
		"light_patches_visible": _artpass_light_patches.visible,
		"base_light_patches_visible": bool(base_state.get("light_patches_visible", false)),
		"glow": bool(base_state.get("glow", false)),
		"fog": bool(base_state.get("fog", false)),
		"dof": bool(base_state.get("dof", false)),
		"characters_shaded": bool(base_state.get("characters_shaded", false)),
		"material_override_count": _material_override_count,
		"minimum_asset_visibility": _get_minimum_asset_visibility(),
		"player_height_target_ratio": "10% ~ 13%",
	}


func _apply_base_profile(profile_name: String) -> void:
	if _base_lab != null and _base_lab.has_method("set_reference_profile"):
		_base_lab.call("set_reference_profile", profile_name)


func _set_artpass_visible(details_visible: bool, patches_visible: bool) -> void:
	_artpass_details.visible = details_visible
	_artpass_light_patches.visible = patches_visible


func _apply_artpass_material_overrides() -> void:
	_material_override_count = 0
	_apply_material_overrides_below(_artpass_details)


func _apply_material_overrides_below(node: Node) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.mesh.surface_get_material(surface_index)
			var override_material := _material_for_imported_slot(material)
			if override_material != null:
				mesh_instance.set_surface_override_material(surface_index, override_material)
				_material_override_count += 1
	for child in node.get_children():
		_apply_material_overrides_below(child)


func _material_for_imported_slot(material: Material) -> Material:
	if material == null:
		return null
	var name := String(material.resource_name)
	match name:
		"wall_trim":
			return MAT_WALL_TRIM
		"ceramic":
			return MAT_CERAMIC
		"fabric_red":
			return MAT_FABRIC_RED
		"fabric_teal":
			return MAT_FABRIC_TEAL
		"shadow_wood":
			return MAT_SHADOW_WOOD
		_:
			return null


func _get_minimum_asset_visibility() -> Dictionary:
	return {
		"RightTowerBalconyRail": _count_visible_name_fragments(["RightTowerBalconyRail"]) >= 4,
		"RightTowerPlatform": _count_visible_name_fragments(["RightTowerPlatform"]) >= 1,
		"RightVisibleHighLadder": _count_visible_name_fragments(["RightVisibleHighLadder"]) >= 4,
		"RightHangingCloth": _count_visible_name_fragments(["RightHangingCloth"]) >= 2,
		"BackLanternShell": _count_visible_name_fragments(["BackLanternShell"]) >= 6,
		"ForegroundStep": _count_visible_name_fragments(["ForegroundStep"]) >= 2,
		"ForegroundLowWall": _count_visible_name_fragments(["ForegroundLowWall"]) >= 1,
		"StallClusterA": _count_visible_name_fragments(["StallClusterA"]) >= 5,
		"StallClusterB": _count_visible_name_fragments(["StallClusterB"]) >= 5,
		"StallClusterC": _count_visible_name_fragments(["StallClusterC"]) >= 5,
		"WallTrim": _count_visible_name_fragments(["WallTrim"]) >= 8,
		"WindowFrame": _count_visible_name_fragments(["WindowFrame"]) >= 4,
		"DoorFrame": _count_visible_name_fragments(["DoorFrame"]) >= 3,
	}


func _count_visible_name_fragments(fragments: Array[String]) -> int:
	return _count_visible_name_fragments_below(_artpass_details, fragments)


func _count_visible_name_fragments_below(node: Node, fragments: Array[String]) -> int:
	if node is Node3D and not (node as Node3D).visible:
		return 0

	var count := 0
	var node_name := String(node.name)
	for fragment in fragments:
		if node_name.contains(fragment):
			count += 1
			break
	for child in node.get_children():
		count += _count_visible_name_fragments_below(child, fragments)
	return count


func _apply_profile_args(args: Array[String]) -> void:
	for arg in args:
		if arg.begins_with("reference_profile="):
			set_reference_profile(arg.get_slice("=", 1))
