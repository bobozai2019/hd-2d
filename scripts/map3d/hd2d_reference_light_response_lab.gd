extends Node3D

const PROFILE_BASELINE := "baseline"
const PROFILE_ADJUSTED := "adjusted"
const PROFILE_NO_LOCAL_LIGHT := "no_local_light"
const PROFILE_CHARACTER_COMPARE := "character_compare"
const PROFILE_TOWN_SAMPLE_MATCH := "town_sample_match"
const SUPPORTED_PROFILES := [
	PROFILE_BASELINE,
	PROFILE_ADJUSTED,
	PROFILE_NO_LOCAL_LIGHT,
	PROFILE_CHARACTER_COMPARE,
	PROFILE_TOWN_SAMPLE_MATCH,
]

var reference_profile := PROFILE_BASELINE

var _pending_capture_args: Array[String] = []
var _material_targets: Array[MeshInstance3D] = []
var _torches: Dictionary = {}
var _lights: Dictionary = {}
var _character_profiles: Array[Dictionary] = []

@onready var _world_environment: WorldEnvironment = $WorldEnvironment
@onready var _moon_key: DirectionalLight3D = $Lighting/MoonKey
@onready var _warm_patches: Array[Node] = [
	$Stage/WarmLightPatchGround,
	$Stage/WarmLightPatchWall,
]
@onready var _edge_vignette: Array[Node] = [
	$Stage/EdgeDarkenLeft,
	$Stage/EdgeDarkenRight,
]
@onready var _hybrid_warm_patch: MeshInstance3D = $CharacterSamples/CharacterHybrid/HybridWarmFootLight


func _ready() -> void:
	_collect_material_targets()

	_torches["TorchKey"] = $VfxRoot/TorchKey
	_torches["TorchSecondary"] = $VfxRoot/TorchSecondary
	_torches["TorchFarAtmosphere"] = $VfxRoot/TorchFarAtmosphere
	_init_torch_lights()

	_character_profiles = [
		{"name": "CharacterUnshaded", "sprite_shaded": false, "hybrid_warm_patch": false},
		{"name": "CharacterShaded", "sprite_shaded": true, "hybrid_warm_patch": false},
		{"name": "CharacterHybrid", "sprite_shaded": false, "hybrid_warm_patch": true},
	]

	var startup_args := OS.get_cmdline_user_args()
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
	reference_profile = profile_name if SUPPORTED_PROFILES.has(profile_name) else PROFILE_BASELINE
	match reference_profile:
		PROFILE_ADJUSTED:
			_apply_adjusted_profile(false)
		PROFILE_NO_LOCAL_LIGHT:
			_apply_adjusted_profile(false)
			_set_local_lights_enabled(false)
			_set_warm_patches_visible(false)
			_set_torch_wall_patches_visible(false)
		PROFILE_CHARACTER_COMPARE:
			_apply_adjusted_profile(true)
		PROFILE_TOWN_SAMPLE_MATCH:
			_apply_town_sample_profile()
		_:
			_apply_baseline_profile()


func get_reference_light_response_profile() -> Dictionary:
	var light_profiles := []
	for key in _lights.keys():
		var light := _lights[key] as OmniLight3D
		if light == null or not light.visible:
			continue
		light_profiles.append({
			"name": light.name,
			"energy": light.light_energy,
			"range": light.omni_range,
			"shadow_enabled": light.shadow_enabled,
		})

	var material_profiles := []
	for target in _material_targets:
		var material := target.material_override as StandardMaterial3D
		material_profiles.append({
			"name": target.name,
			"shaded": material != null and material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED,
			"albedo": material.albedo_color if material != null else Color.BLACK,
			"roughness": material.roughness if material != null else -1.0,
			"metallic_specular": material.metallic_specular if material != null else -1.0,
		})

	return {
		"reference_profile": reference_profile,
		"supported_profiles": SUPPORTED_PROFILES,
		"dynamic_local_light_count": light_profiles.size(),
		"dynamic_local_light_budget": 3,
		"warm_patches_visible": _warm_patches.any(func(patch: Node) -> bool: return patch.visible),
		"edge_vignette_visible": _edge_vignette.any(func(node: Node) -> bool: return node.visible),
		"light_profiles": light_profiles,
		"material_targets": material_profiles,
		"character_profiles": _character_profiles,
	}


func _collect_material_targets() -> void:
	_material_targets.clear()
	for child in $Stage.get_children():
		if child is MeshInstance3D:
			_material_targets.append(child as MeshInstance3D)


func _init_torch_lights() -> void:
	for key in _torches.keys():
		var torch := _torches[key] as Node3D
		if torch == null:
			continue
		var light := torch.get_node_or_null("TorchLight") as OmniLight3D
		if light != null:
			_lights[key] = light


func _apply_baseline_profile() -> void:
	_apply_environment(Color(0.021, 0.027, 0.05), Color(0.18, 0.23, 0.34), 0.28, 0.95, 0.24, 0.56, Color(0.18, 0.24, 0.33), 0.01)
	_moon_key.light_color = Color(0.54, 0.64, 0.9)
	_moon_key.light_energy = 0.2
	_set_material_response(Color(0.24, 0.27, 0.24), Color(0.26, 0.24, 0.22), Color(0.11, 0.12, 0.11), Color(0.19, 0.19, 0.17))
	_set_torch_light("TorchKey", true, 0.62, 3.4, true)
	_set_torch_light("TorchSecondary", true, 0.22, 2.2, false)
	_set_torch_light("TorchFarAtmosphere", false, 0.0, 2.0, false)
	_set_warm_patches_visible(false)
	_set_edge_vignette_visible(false)
	_set_torch_wall_patches_visible(true)
	_set_character_shading("CharacterUnshaded", false)
	_set_character_shading("CharacterShaded", true)
	_set_character_shading("CharacterHybrid", false)
	_hybrid_warm_patch.visible = false


func _apply_adjusted_profile(character_compare: bool) -> void:
	_apply_environment(Color(0.013, 0.018, 0.034), Color(0.1, 0.15, 0.26), 0.12, 0.84, 0.18, 0.42, Color(0.16, 0.19, 0.27), 0.012)
	_moon_key.light_color = Color(0.45, 0.58, 0.84)
	_moon_key.light_energy = 0.11
	_set_material_response(Color(0.17, 0.19, 0.18), Color(0.19, 0.18, 0.16), Color(0.075, 0.082, 0.08), Color(0.14, 0.14, 0.13))
	_set_torch_light("TorchKey", true, 1.32, 3.9, true)
	_set_torch_light("TorchSecondary", true, 0.42, 2.7, false)
	_set_torch_light("TorchFarAtmosphere", false, 0.0, 2.0, false)
	_set_warm_patches_visible(true)
	_set_edge_vignette_visible(character_compare)
	_set_torch_wall_patches_visible(true)
	_hybrid_warm_patch.visible = true


func _apply_town_sample_profile() -> void:
	_apply_environment(Color(0.04, 0.045, 0.06), Color(0.24, 0.28, 0.34), 0.31, 1.05, 0.17, 0.34, Color(0.34, 0.25, 0.16), 0.018)
	_moon_key.light_color = Color(0.62, 0.68, 0.82)
	_moon_key.light_energy = 0.19
	_set_material_response(Color(0.22, 0.22, 0.2), Color(0.24, 0.21, 0.18), Color(0.09, 0.095, 0.09), Color(0.17, 0.16, 0.14))
	_set_torch_light("TorchKey", true, 1.12, 4.2, true)
	_set_torch_light("TorchSecondary", true, 0.54, 3.0, false)
	_set_torch_light("TorchFarAtmosphere", false, 0.0, 2.0, false)
	_set_warm_patches_visible(true)
	_set_edge_vignette_visible(true)
	_set_torch_wall_patches_visible(true)
	_hybrid_warm_patch.visible = true


func _apply_environment(background: Color, ambient: Color, ambient_energy: float, exposure: float, glow_intensity: float, glow_strength: float, fog_color: Color, fog_density: float) -> void:
	var environment := _world_environment.environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = background
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = ambient
	environment.ambient_light_energy = ambient_energy
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = exposure
	environment.tonemap_white = 1.35
	environment.glow_enabled = true
	environment.glow_intensity = glow_intensity
	environment.glow_strength = glow_strength
	environment.fog_enabled = true
	environment.fog_light_color = fog_color
	environment.fog_density = fog_density

	var attributes := _world_environment.camera_attributes as CameraAttributesPractical
	if attributes != null:
		attributes.dof_blur_far_enabled = true
		attributes.dof_blur_far_distance = 11.0
		attributes.dof_blur_far_transition = 2.4
		attributes.dof_blur_amount = 0.06


func _set_material_response(ground: Color, wall: Color, foreground: Color, rock: Color) -> void:
	for target in _material_targets:
		var material := target.material_override as StandardMaterial3D
		if material == null:
			continue
		var target_name := String(target.name)
		if target_name.begins_with("Ground"):
			material.albedo_color = ground
			material.roughness = 0.94
			material.metallic_specular = 0.08
		elif target_name.begins_with("BackWall") or target_name.begins_with("WallPier"):
			material.albedo_color = wall
			material.roughness = 0.9
			material.metallic_specular = 0.08
		elif target_name.begins_with("RaisedRock"):
			material.albedo_color = rock
			material.roughness = 0.96
			material.metallic_specular = 0.06
		else:
			material.albedo_color = foreground
			material.roughness = 0.95
			material.metallic_specular = 0.05


func _set_torch_light(torch_name: String, enabled: bool, energy: float, light_range: float, shadows_enabled: bool) -> void:
	var torch := _torches.get(torch_name) as Node3D
	if torch != null:
		torch.set("light_enabled", enabled)
		torch.set("light_base_energy", energy)
		torch.set("light_range", light_range)
		torch.set("shadows_enabled", shadows_enabled)
		if torch.has_method("set_active"):
			torch.call("set_active", true, shadows_enabled)
	var light := _lights.get(torch_name) as OmniLight3D
	if light != null:
		light.visible = enabled
		light.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		light.light_energy = energy
		light.omni_range = light_range
		light.shadow_enabled = enabled and shadows_enabled


func _set_local_lights_enabled(enabled: bool) -> void:
	for key in _lights.keys():
		var light := _lights[key] as OmniLight3D
		if light == null:
			continue
		light.visible = enabled
		light.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED


func _set_warm_patches_visible(is_visible: bool) -> void:
	for patch in _warm_patches:
		patch.visible = is_visible


func _set_torch_wall_patches_visible(is_visible: bool) -> void:
	for key in _torches.keys():
		var torch := _torches[key] as Node3D
		if torch == null:
			continue
		var wall_patch := torch.get_node_or_null("FlameHalo/WallLightPatch") as Node3D
		if wall_patch != null:
			wall_patch.visible = is_visible


func _set_edge_vignette_visible(is_visible: bool) -> void:
	for node in _edge_vignette:
		node.visible = is_visible


func _set_character_shading(character_name: String, shaded: bool) -> void:
	var character := $CharacterSamples.get_node_or_null(character_name) as Node3D
	if character == null:
		return
	var sprite := character.get_node_or_null("Visual") as AnimatedSprite3D
	if sprite != null:
		sprite.shaded = shaded


func _apply_profile_args(args: Array[String]) -> void:
	for arg in args:
		if arg.begins_with("reference_profile="):
			set_reference_profile(arg.get_slice("=", 1))
