extends Node3D

const HD2D_TORCH_EFFECT_SCENE := preload("res://scenes/map3d/vfx/hd2d_torch_effect.tscn")
const DEFAULT_DYNAMIC_LIGHT_COUNT := 3
const SUPPORTED_DYNAMIC_LIGHT_COUNTS := [1, 3, 6]
const TORCH_SPECS := [
	{"name": "CenterFloorTorch", "phase": 1.7, "energy": 0.58, "profile_rank": 1},
	{"name": "LeftWallTorch", "phase": 0.0, "energy": 0.74, "profile_rank": 3},
	{"name": "RightWallTorch", "phase": 3.1, "energy": 0.68, "profile_rank": 3},
	{"name": "RearLeftPressureTorch", "phase": 4.2, "energy": 0.44, "profile_rank": 6},
	{"name": "RearRightPressureTorch", "phase": 5.4, "energy": 0.44, "profile_rank": 6},
	{"name": "FrontPressureTorch", "phase": 6.2, "energy": 0.42, "profile_rank": 6},
]

@onready var _phase6_torches_root: Node3D = $VfxRoot/Torches
@onready var _phase7_torches_root: Node3D = $VfxRoot/Phase7Torches
@onready var _dynamic_lights_root: Node3D = $VfxRoot/DynamicLights
@onready var _material_targets_root: Node3D = $ValidationTargets/MaterialTargets

var _torch_runtime: Array[Dictionary] = []
var _pending_capture_args: Array[String] = []
var _active_dynamic_light_count := DEFAULT_DYNAMIC_LIGHT_COUNT
var _torch_variant := "phase7"
var _time := 0.0


func _ready() -> void:
	_collect_scene_torches()
	set_dynamic_light_profile(DEFAULT_DYNAMIC_LIGHT_COUNT)

	var startup_args := OS.get_cmdline_user_args()
	for arg in startup_args:
		if arg.begins_with("lighting_profile=") or arg.begins_with("light_count=") or arg.begins_with("torch_variant="):
			_pending_capture_args.append(arg)
	if _pending_capture_args.size() > 0:
		_apply_profile_args(_pending_capture_args)
		_pending_capture_args.clear()


func _process(delta: float) -> void:
	_time += delta
	for entry in _torch_runtime:
		var torch := entry.get("torch") as Node3D
		if torch != null and torch.has_method("get_torch_light"):
			continue
		var phase := float(entry.get("phase", 0.0))
		var base_energy := float(entry.get("base_energy", 0.6))
		var light := entry.get("light") as OmniLight3D
		var flame := entry.get("flame") as Node3D
		var halo := entry.get("halo") as Node3D
		var pulse := 0.5 + 0.5 * sin(_time * 7.4 + phase)
		var slow_wave := 0.5 + 0.5 * sin(_time * 2.1 + phase * 0.7)
		if light != null:
			light.light_energy = base_energy * lerpf(0.72, 1.18, pulse)
		if flame != null:
			var flame_scale := lerpf(0.9, 1.14, pulse)
			flame.scale = Vector3(flame_scale, lerpf(0.92, 1.2, slow_wave), flame_scale)
		if halo != null:
			var halo_scale := lerpf(0.9, 1.18, slow_wave)
			halo.scale = Vector3(halo_scale, lerpf(0.94, 1.1, pulse), halo_scale)


func get_lighting_validation_profile() -> Dictionary:
	var material_targets := []
	for child in _material_targets_root.get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			var material := mesh_instance.material_override as StandardMaterial3D
			material_targets.append({
				"name": child.name,
				"shaded": material != null and material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED,
				"roughness": material.roughness if material != null else -1.0,
				"metallic_specular": material.metallic_specular if material != null else -1.0,
			})

	var light_profiles := []
	var torch_profiles := []
	for entry in _torch_runtime:
		var torch := entry.get("torch") as Node3D
		if torch != null and torch.has_method("get_torch_validation_profile"):
			torch_profiles.append(torch.call("get_torch_validation_profile"))
		var light := entry.get("light") as OmniLight3D
		if light == null or not light.visible:
			continue
		light_profiles.append({
			"name": light.name,
			"torch": torch.name if torch != null else "",
			"energy": light.light_energy,
			"range": light.omni_range,
			"shadow_enabled": light.shadow_enabled,
		})

	return {
		"torch_count": _get_active_torch_count(),
		"dynamic_light_count": light_profiles.size(),
		"default_dynamic_light_count": DEFAULT_DYNAMIC_LIGHT_COUNT,
		"active_dynamic_light_count": _active_dynamic_light_count,
		"supported_dynamic_light_counts": SUPPORTED_DYNAMIC_LIGHT_COUNTS,
		"profile_role": _get_profile_role(),
		"pressure_profile": _active_dynamic_light_count == 6,
		"torch_variant": _torch_variant,
		"texture_based_torch": _has_texture_based_torch_nodes(),
		"template_scene": HD2D_TORCH_EFFECT_SCENE.resource_path,
		"torch_profiles": torch_profiles,
		"material_targets": material_targets,
		"light_profiles": light_profiles,
		"target_extent": "Phase 7: reusable native 3D torch template, 3 default dynamic torches, shaded wall/floor materials, visible warm-light gradient",
	}


func set_dynamic_light_profile(light_count: int) -> void:
	var normalized_count := _normalize_light_count(light_count)
	_active_dynamic_light_count = normalized_count
	_prepare_torch_variant_nodes()
	for entry in _torch_runtime:
		var torch := entry.get("torch") as Node3D
		var light := entry.get("light") as OmniLight3D
		var profile_rank := int(entry.get("profile_rank", DEFAULT_DYNAMIC_LIGHT_COUNT))
		var active := profile_rank <= normalized_count
		if torch != null:
			if torch.has_method("set_active"):
				torch.call("set_active", active, normalized_count <= DEFAULT_DYNAMIC_LIGHT_COUNT or profile_rank <= DEFAULT_DYNAMIC_LIGHT_COUNT)
			else:
				torch.visible = active
				torch.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		if light != null:
			light.visible = active
			light.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
			light.light_energy = float(entry.get("base_energy", 0.6))
			light.shadow_enabled = active and (normalized_count <= DEFAULT_DYNAMIC_LIGHT_COUNT or profile_rank <= DEFAULT_DYNAMIC_LIGHT_COUNT)


func apply_capture_args(args: Array[String]) -> void:
	if _torch_runtime.is_empty():
		_pending_capture_args.append_array(args)
		return
	_apply_profile_args(args)


func set_torch_variant(variant: String) -> void:
	_torch_variant = "phase6" if variant == "phase6" else "phase7"
	_collect_scene_torches()
	set_dynamic_light_profile(_active_dynamic_light_count)


func _collect_scene_torches() -> void:
	_torch_runtime.clear()
	var root := _get_active_torch_root()
	for spec in TORCH_SPECS:
		var torch_name := String(spec.get("name", "Torch"))
		var torch := root.get_node_or_null(torch_name) as Node3D
		var light := _get_torch_light(torch)
		if light == null or _torch_variant == "phase6":
			light = _dynamic_lights_root.get_node_or_null(torch_name + "Light") as OmniLight3D
		if torch == null:
			push_warning("Missing %s torch node: %s" % [_torch_variant, torch_name])
			continue
		_torch_runtime.append({
			"phase": float(spec.get("phase", 0.0)),
			"base_energy": float(spec.get("energy", 0.6)),
			"profile_rank": int(spec.get("profile_rank", DEFAULT_DYNAMIC_LIGHT_COUNT)),
			"torch": torch,
			"light": light,
			"flame": torch.get_node_or_null("FlameEffect"),
			"halo": torch.get_node_or_null("FlameHalo"),
		})


func _apply_profile_args(args: Array[String]) -> void:
	var requested_count := _active_dynamic_light_count
	var requested_variant := _torch_variant
	for arg in args:
		if arg.begins_with("lighting_profile="):
			requested_count = int(arg.get_slice("=", 1))
		elif arg.begins_with("light_count="):
			requested_count = int(arg.get_slice("=", 1))
		elif arg.begins_with("torch_variant="):
			requested_variant = arg.get_slice("=", 1)
	if requested_variant != _torch_variant:
		_torch_variant = "phase6" if requested_variant == "phase6" else "phase7"
		_collect_scene_torches()
	set_dynamic_light_profile(requested_count)


func _normalize_light_count(light_count: int) -> int:
	if light_count <= 1:
		return 1
	if light_count <= DEFAULT_DYNAMIC_LIGHT_COUNT:
		return DEFAULT_DYNAMIC_LIGHT_COUNT
	return 6


func _get_active_torch_count() -> int:
	var count := 0
	var root := _get_active_torch_root()
	for child in root.get_children():
		if child is Node3D and (child as Node3D).visible:
			count += 1
	return count


func _get_profile_role() -> String:
	if _active_dynamic_light_count == 1:
		return "minimum"
	if _active_dynamic_light_count == DEFAULT_DYNAMIC_LIGHT_COUNT:
		return "recommended_default"
	return "pressure_boundary"


func _has_texture_based_torch_nodes() -> bool:
	var root := _get_active_torch_root()
	for torch in root.get_children():
		if _node_uses_texture(torch):
			return true
	return false


func _prepare_torch_variant_nodes() -> void:
	_phase6_torches_root.visible = _torch_variant == "phase6"
	_phase7_torches_root.visible = _torch_variant == "phase7"
	for spec in TORCH_SPECS:
		var torch_name := String(spec.get("name", "Torch"))
		var phase7_torch := _phase7_torches_root.get_node_or_null(torch_name) as Node3D
		var phase6_torch := _phase6_torches_root.get_node_or_null(torch_name) as Node3D
		var phase6_light := _dynamic_lights_root.get_node_or_null(torch_name + "Light") as OmniLight3D
		if phase7_torch != null:
			if phase7_torch.has_method("set_active"):
				phase7_torch.call("set_active", false, false)
			else:
				phase7_torch.visible = false
				phase7_torch.process_mode = Node.PROCESS_MODE_DISABLED
		if phase6_torch != null:
			phase6_torch.visible = false
			phase6_torch.process_mode = Node.PROCESS_MODE_DISABLED
		if phase6_light != null:
			phase6_light.visible = false
			phase6_light.process_mode = Node.PROCESS_MODE_DISABLED


func _get_torch_light(torch: Node3D) -> OmniLight3D:
	if torch == null:
		return null
	if torch.has_method("get_torch_light"):
		return torch.call("get_torch_light") as OmniLight3D
	return torch.get_node_or_null("TorchLight") as OmniLight3D


func _get_active_torch_root() -> Node3D:
	return _phase6_torches_root if _torch_variant == "phase6" else _phase7_torches_root


func _node_uses_texture(node: Node) -> bool:
	if node is Sprite3D:
		return true
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var material := mesh_instance.material_override as StandardMaterial3D
		if material != null and material.albedo_texture != null:
			return true
	for child in node.get_children():
		if _node_uses_texture(child):
			return true
	return false
