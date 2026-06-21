extends Node3D

const PROFILE_BASELINE_MARKET := "baseline_market"
const PROFILE_ASSET_DENSITY_V2 := "asset_density_v2"
const PROFILE_REFERENCE_MATCH_V2 := "reference_match_v2"
const PROFILE_NO_LOCAL_LIGHT := "no_local_light"
const PROFILE_NO_PATCH := "no_patch"
const PROFILE_NO_POST := "no_post"
const PROFILE_CHARACTER_SCALE_CHECK := "character_scale_check"
const SUPPORTED_PROFILES: Array[String] = [
	PROFILE_BASELINE_MARKET,
	PROFILE_ASSET_DENSITY_V2,
	PROFILE_REFERENCE_MATCH_V2,
	PROFILE_NO_LOCAL_LIGHT,
	PROFILE_NO_PATCH,
	PROFILE_NO_POST,
	PROFILE_CHARACTER_SCALE_CHECK,
]

var reference_profile := PROFILE_REFERENCE_MATCH_V2

var _pending_capture_args: Array[String] = []
var _imported_light_names: Array[String] = []

@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _cool_ambient_moon: DirectionalLight3D = $Lighting/CoolAmbientMoon
@onready var _center_warm_key: OmniLight3D = $Lighting/CenterWarmKey
@onready var _left_shop_warm: OmniLight3D = $Lighting/LeftShopWarm
@onready var _right_shop_warm: OmniLight3D = $Lighting/RightShopWarm
@onready var _market_reference_match: Node3D = $Stage/MarketReferenceMatch
@onready var _reference_floor_overlay: Node3D = $Stage/ReferenceFloorOverlay
@onready var _reference_additive_props: Node3D = $Stage/ReferenceAdditiveProps
@onready var _generated_reference_glb: Node3D = $Stage/ReferenceAdditiveProps/GeneratedMarketReferenceGlb
@onready var _light_patches: Node3D = $Stage/LightPatches
@onready var _edge_shadow_helpers: Node3D = $Stage/EdgeShadowHelpers
@onready var _vfx_root: Node3D = $VfxRoot
@onready var _characters: Node3D = $Characters


func _ready() -> void:
	_disable_imported_runtime_lights()
	_disable_torch_runtime_lights()

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
	if _world_environment == null:
		_pending_capture_args.append_array(args)
		return
	_apply_profile_args(args)


func set_reference_profile(profile_name: String) -> void:
	reference_profile = profile_name if SUPPORTED_PROFILES.has(profile_name) else PROFILE_REFERENCE_MATCH_V2
	_disable_imported_runtime_lights()
	_disable_torch_runtime_lights()
	_set_character_light_response(true)

	match reference_profile:
		PROFILE_BASELINE_MARKET:
			_apply_market_profile(false, false, false, true, true, true, true, Color(0.04, 0.032, 0.023), Color(0.72, 0.48, 0.28), 0.16, 0.72)
			_set_local_light_profile(true, true, true, 1.35, 0.65, 0.6)
		PROFILE_ASSET_DENSITY_V2:
			_apply_market_profile(true, true, false, true, true, true, true, Color(0.018, 0.024, 0.034), Color(0.17, 0.23, 0.3), 0.15, 0.8)
			_set_local_light_profile(true, true, true, 1.65, 0.62, 0.56)
		PROFILE_NO_LOCAL_LIGHT:
			_apply_market_profile(true, true, false, false, true, true, true, Color(0.012, 0.018, 0.027), Color(0.11, 0.17, 0.23), 0.1, 0.68)
			_set_local_light_profile(false, false, false, 0.0, 0.0, 0.0)
		PROFILE_NO_PATCH:
			_apply_market_profile(true, true, false, false, true, true, true, Color(0.014, 0.019, 0.027), Color(0.16, 0.20, 0.19), 0.18, 0.84)
			_set_local_light_profile(true, true, true, 1.62, 0.58, 0.52)
		PROFILE_NO_POST:
			_apply_market_profile(true, true, true, true, false, false, false, Color(0.014, 0.019, 0.027), Color(0.16, 0.20, 0.19), 0.18, 0.84)
			_set_local_light_profile(true, true, true, 1.62, 0.58, 0.52)
		PROFILE_CHARACTER_SCALE_CHECK:
			_apply_market_profile(true, true, true, true, true, true, true, Color(0.014, 0.019, 0.027), Color(0.16, 0.20, 0.19), 0.18, 0.84)
			_set_local_light_profile(true, true, true, 1.62, 0.58, 0.52)
		_:
			_apply_market_profile(true, true, true, true, true, true, true, Color(0.014, 0.019, 0.027), Color(0.16, 0.20, 0.19), 0.18, 0.84)
			_set_local_light_profile(true, true, true, 1.62, 0.58, 0.52)


func get_market_reference_profile_state() -> Dictionary:
	var local_lights: Array[String] = []
	_collect_visible_local_light_names(self, local_lights)
	return {
		"reference_profile": reference_profile,
		"supported_profiles": SUPPORTED_PROFILES,
		"visible_real_local_light_count": local_lights.size(),
		"visible_real_local_lights": local_lights,
		"dynamic_local_light_budget": 3,
		"imported_runtime_lights_disabled": _imported_light_names.duplicate(),
		"light_patches_visible": _light_patches.visible,
		"edge_shadow_helpers_visible": _edge_shadow_helpers.visible,
		"glow": _world_environment.environment.glow_enabled,
		"fog": _world_environment.environment.fog_enabled,
		"dof": _get_dof_enabled(),
		"characters_shaded": _characters_are_shaded(),
		"minimum_asset_visibility": _get_minimum_asset_visibility(),
		"player_height_target_ratio": "10% ~ 14%",
	}


func _apply_market_profile(
	additive_props_visible: bool,
	floor_overlay_visible: bool,
	light_patches_visible: bool,
	edge_helpers_visible: bool,
	glow_enabled: bool,
	fog_enabled: bool,
	dof_enabled: bool,
	background: Color,
	ambient: Color,
	ambient_energy: float,
	exposure: float
) -> void:
	_reference_additive_props.visible = additive_props_visible
	_reference_floor_overlay.visible = floor_overlay_visible
	_light_patches.visible = light_patches_visible
	_edge_shadow_helpers.visible = edge_helpers_visible

	var environment: Environment = _world_environment.environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = background
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = ambient
	environment.ambient_light_energy = ambient_energy
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = exposure
	environment.tonemap_white = 1.55
	environment.glow_enabled = glow_enabled
	environment.glow_intensity = 0.2 if glow_enabled else 0.0
	environment.glow_strength = 0.44 if glow_enabled else 0.0
	environment.fog_enabled = fog_enabled
	environment.fog_light_color = Color(0.18, 0.18, 0.2)
	environment.fog_density = 0.0038 if fog_enabled else 0.0
	environment.fog_height = 1.65
	environment.fog_height_density = 0.035 if fog_enabled else 0.0

	_cool_ambient_moon.light_color = Color(0.50, 0.58, 0.62)
	_cool_ambient_moon.light_energy = 0.16
	_set_dof_enabled(dof_enabled)


func _set_local_light_profile(center_enabled: bool, left_enabled: bool, right_enabled: bool, center_energy: float, left_energy: float, right_energy: float) -> void:
	_center_warm_key.light_color = Color(1.0, 0.66, 0.38)
	_left_shop_warm.light_color = Color(1.0, 0.58, 0.34)
	_right_shop_warm.light_color = Color(1.0, 0.60, 0.36)
	_configure_local_light(_center_warm_key, center_enabled, center_energy, 5.8, true)
	_configure_local_light(_left_shop_warm, left_enabled, left_energy, 3.7, true)
	_configure_local_light(_right_shop_warm, right_enabled, right_energy, 3.4, false)


func _configure_local_light(light: OmniLight3D, enabled: bool, energy: float, light_range: float, shadows_enabled: bool) -> void:
	light.visible = enabled
	light.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = enabled and shadows_enabled


func _disable_imported_runtime_lights() -> void:
	_imported_light_names.clear()
	_disable_runtime_lights_below(_market_reference_match)
	_disable_runtime_lights_below(_generated_reference_glb)


func _disable_torch_runtime_lights() -> void:
	for child in _vfx_root.get_children():
		var torch := child as Node3D
		if torch == null:
			continue
		torch.set("light_enabled", false)
		if torch.has_method("set_active"):
			torch.call("set_active", true, false)
		var torch_light := torch.get_node_or_null("TorchLight") as OmniLight3D
		if torch_light != null:
			torch_light.visible = false
			torch_light.process_mode = Node.PROCESS_MODE_DISABLED
			torch_light.shadow_enabled = false


func _disable_runtime_lights_below(node: Node) -> void:
	if node is OmniLight3D or node is SpotLight3D:
		var local_light := node as Node3D
		local_light.visible = false
		local_light.process_mode = Node.PROCESS_MODE_DISABLED
		_imported_light_names.append(node.get_path())
	elif node is DirectionalLight3D:
		var directional := node as DirectionalLight3D
		directional.visible = false
		directional.process_mode = Node.PROCESS_MODE_DISABLED
		_imported_light_names.append(node.get_path())
	for child in node.get_children():
		_disable_runtime_lights_below(child)


func _collect_visible_local_light_names(node: Node, output: Array[String]) -> void:
	if node is OmniLight3D or node is SpotLight3D:
		var light_node := node as Node3D
		if light_node.visible and light_node.process_mode != Node.PROCESS_MODE_DISABLED:
			output.append(str(node.get_path()))
	for child in node.get_children():
		_collect_visible_local_light_names(child, output)


func _set_dof_enabled(enabled: bool) -> void:
	var attributes := _world_environment.camera_attributes as CameraAttributesPractical
	if attributes == null:
		return
	attributes.dof_blur_far_enabled = enabled
	attributes.dof_blur_near_enabled = enabled
	attributes.dof_blur_amount = 0.018 if enabled else 0.0


func _get_dof_enabled() -> bool:
	var attributes := _world_environment.camera_attributes as CameraAttributesPractical
	if attributes == null:
		return false
	return attributes.dof_blur_far_enabled or attributes.dof_blur_near_enabled


func _set_character_light_response(enabled: bool) -> void:
	for child in _characters.get_children():
		var sprite := child as AnimatedSprite3D
		if sprite == null:
			continue
		if String(sprite.name).contains("LightWrap"):
			continue
		sprite.shaded = enabled


func _characters_are_shaded() -> bool:
	for child in _characters.get_children():
		var sprite := child as AnimatedSprite3D
		if sprite == null:
			continue
		if String(sprite.name).contains("LightWrap"):
			continue
		if not sprite.shaded:
			return false
	return true


func _get_minimum_asset_visibility() -> Dictionary:
	return {
		"foreground_steps_or_low_wall": _count_visible_name_fragments(["ForegroundLowWall", "ForegroundStep"]) >= 1,
		"left_right_eaves": _count_visible_name_fragments(["LeftEave", "LeftFacadeWallLip"]) >= 1 and _count_visible_name_fragments(["RightEave", "RightFacadeWallLip"]) >= 1,
		"central_stalls": _count_visible_name_fragments(["CanopyStall"]) >= 2,
		"small_props_instances": _count_visible_name_fragments(["Crate", "Barrel", "Jar", "PlateStack", "FoldedCloth", "Shelf"]),
		"small_props_categories": 5,
		"ladder_or_second_level": _count_visible_name_fragments(["RightVisibleHighLadder", "RightBalconyShelf"]) >= 2,
		"rear_lantern_or_window_highlights": _count_visible_name_fragments(["RearWindowGlow", "RearLanternGlow"]),
	}


func _count_visible_name_fragments(fragments: Array[String]) -> int:
	return _count_visible_name_fragments_below(_reference_additive_props, fragments)


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
