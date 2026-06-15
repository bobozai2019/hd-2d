extends Node3D

@export var light_base_energy := 0.6
@export var light_flicker_strength := 0.16
@export var light_flicker_speed := 7.4
@export var light_range := 3.8
@export var glow_base_scale := 1.0
@export var glow_flicker_strength := 0.12
@export var flame_base_scale := 1.0
@export var sparks_enabled := true
@export var shadows_enabled := true
@export var light_enabled := true
@export var flicker_phase := -1.0
@export var profile_rank := 3

var _time := 0.0
var _phase := 0.0
var _flame_effect: Node3D
var _flame_halo: Node3D
var _sparks: GPUParticles3D
var _torch_light: OmniLight3D


func _ready() -> void:
	_phase = flicker_phase if flicker_phase >= 0.0 else randf() * TAU
	_ensure_nodes()
	_apply_parameters()


func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * light_flicker_speed + _phase)
	var slow_wave := 0.5 + 0.5 * sin(_time * 2.1 + _phase * 0.7)
	var sway := sin(_time * 3.4 + _phase) * 0.035

	if _torch_light != null and light_enabled:
		var flicker := lerpf(1.0 - light_flicker_strength, 1.0 + light_flicker_strength, pulse)
		_torch_light.light_energy = light_base_energy * flicker

	if _flame_effect != null:
		var flame_xz := flame_base_scale * lerpf(0.9, 1.12, pulse)
		var flame_y := flame_base_scale * lerpf(0.94, 1.22, slow_wave)
		_flame_effect.scale = Vector3(flame_xz, flame_y, flame_xz)
		_flame_effect.rotation.z = sway

	if _flame_halo != null:
		var halo_xz := glow_base_scale * lerpf(1.0 - glow_flicker_strength, 1.0 + glow_flicker_strength, slow_wave)
		var halo_y := glow_base_scale * lerpf(0.96, 1.08, pulse)
		_flame_halo.scale = Vector3(halo_xz, halo_y, halo_xz)


func set_active(active: bool, active_shadows_enabled: bool = true) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if _torch_light != null:
		_torch_light.visible = active and light_enabled
		_torch_light.shadow_enabled = active and light_enabled and shadows_enabled and active_shadows_enabled
	if _sparks != null:
		_sparks.emitting = active and sparks_enabled


func get_torch_light() -> OmniLight3D:
	return _torch_light


func get_torch_validation_profile() -> Dictionary:
	return {
		"name": name,
		"profile_rank": profile_rank,
		"has_prop": get_node_or_null("TorchProp") != null,
		"has_flame": _flame_effect != null,
		"has_halo": _flame_halo != null,
		"has_sparks": _sparks != null and sparks_enabled,
		"light_enabled": light_enabled,
		"texture_based": _node_uses_texture(self),
	}


func _ensure_nodes() -> void:
	if get_node_or_null("TorchProp") != null:
		_flame_effect = get_node_or_null("FlameEffect") as Node3D
		_flame_halo = get_node_or_null("FlameHalo") as Node3D
		_sparks = get_node_or_null("Sparks") as GPUParticles3D
		_torch_light = get_node_or_null("TorchLight") as OmniLight3D
		return

	var torch_prop := Node3D.new()
	torch_prop.name = "TorchProp"
	add_child(torch_prop)

	var stand := _create_mesh_instance("Stand", _create_cylinder_mesh(0.045, 0.045, 0.68, 8), _create_prop_material(Color(0.055, 0.048, 0.045, 1.0), 0.24, 0.72))
	stand.position = Vector3(0.0, 0.34, 0.0)
	torch_prop.add_child(stand)

	var bracket := _create_mesh_instance("Bracket", _create_box_mesh(Vector3(0.46, 0.055, 0.085)), _create_prop_material(Color(0.075, 0.064, 0.055, 1.0), 0.26, 0.68))
	bracket.position = Vector3(0.0, 0.63, 0.12)
	torch_prop.add_child(bracket)

	var cup := _create_mesh_instance("TorchCup", _create_cylinder_mesh(0.18, 0.115, 0.18, 10), _create_prop_material(Color(0.12, 0.075, 0.045, 1.0), 0.3, 0.62))
	cup.position = Vector3(0.0, 0.73, 0.25)
	torch_prop.add_child(cup)

	var rim := _create_mesh_instance("CupRim", _create_cylinder_mesh(0.205, 0.19, 0.045, 10), _create_prop_material(Color(0.19, 0.12, 0.065, 1.0), 0.34, 0.58))
	rim.position = Vector3(0.0, 0.83, 0.25)
	torch_prop.add_child(rim)

	var coal := _create_mesh_instance("CoalBed", _create_cylinder_mesh(0.145, 0.12, 0.035, 8), _create_prop_material(Color(0.035, 0.025, 0.018, 1.0), 0.14, 0.9))
	coal.position = Vector3(0.0, 0.86, 0.25)
	torch_prop.add_child(coal)

	_flame_effect = Node3D.new()
	_flame_effect.name = "FlameEffect"
	_flame_effect.position = Vector3(0.0, 0.86, 0.25)
	add_child(_flame_effect)

	var outer_tongue := _create_mesh_instance("OuterTongue", _create_cylinder_mesh(0.0, 0.18, 0.5, 7), _create_additive_material(Color(1.0, 0.24, 0.045, 0.8), 1.2))
	outer_tongue.position = Vector3(0.0, 0.22, 0.0)
	outer_tongue.rotation = Vector3(deg_to_rad(5.0), 0.0, deg_to_rad(-8.0))
	_flame_effect.add_child(outer_tongue)

	var middle_tongue := _create_mesh_instance("MiddleTongue", _create_cylinder_mesh(0.0, 0.125, 0.42, 7), _create_additive_material(Color(1.0, 0.56, 0.11, 0.9), 1.55))
	middle_tongue.position = Vector3(0.045, 0.23, 0.01)
	middle_tongue.rotation = Vector3(deg_to_rad(-4.0), 0.0, deg_to_rad(10.0))
	_flame_effect.add_child(middle_tongue)

	var inner_tongue := _create_mesh_instance("InnerTongue", _create_cylinder_mesh(0.0, 0.072, 0.3, 7), _create_additive_material(Color(1.0, 0.86, 0.3, 0.98), 1.8))
	inner_tongue.position = Vector3(-0.025, 0.2, -0.01)
	inner_tongue.rotation = Vector3(0.0, 0.0, deg_to_rad(-4.0))
	_flame_effect.add_child(inner_tongue)

	_flame_halo = Node3D.new()
	_flame_halo.name = "FlameHalo"
	_flame_halo.position = Vector3(0.0, 1.07, 0.25)
	add_child(_flame_halo)

	var outer_glow := _create_mesh_instance("OuterGlowVolume", _create_sphere_mesh(0.46, 0.76), _create_additive_material(Color(1.0, 0.34, 0.08, 0.12), 0.5))
	_flame_halo.add_child(outer_glow)

	var inner_glow := _create_mesh_instance("InnerGlowVolume", _create_sphere_mesh(0.25, 0.42), _create_additive_material(Color(1.0, 0.68, 0.2, 0.2), 0.75))
	inner_glow.position = Vector3(0.0, 0.045, 0.0)
	_flame_halo.add_child(inner_glow)

	_sparks = GPUParticles3D.new()
	_sparks.name = "Sparks"
	_sparks.amount = 10
	_sparks.lifetime = 0.72
	_sparks.preprocess = 0.2
	_sparks.position = Vector3(0.0, 1.12, 0.25)
	var spark_process := ParticleProcessMaterial.new()
	spark_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_process.emission_sphere_radius = 0.12
	spark_process.initial_velocity_min = 0.08
	spark_process.initial_velocity_max = 0.23
	spark_process.gravity = Vector3(0.0, 0.32, 0.0)
	spark_process.scale_min = 0.35
	spark_process.scale_max = 0.8
	spark_process.color = Color(1.0, 0.62, 0.24, 0.34)
	_sparks.process_material = spark_process
	var spark_quad := QuadMesh.new()
	spark_quad.size = Vector2(0.04, 0.04)
	_sparks.draw_pass_1 = spark_quad
	add_child(_sparks)

	_torch_light = OmniLight3D.new()
	_torch_light.name = "TorchLight"
	_torch_light.light_color = Color(1.0, 0.62, 0.28, 1.0)
	_torch_light.position = Vector3(0.0, 1.16, 0.28)
	add_child(_torch_light)


func _apply_parameters() -> void:
	if _torch_light != null:
		_torch_light.visible = light_enabled
		_torch_light.light_energy = light_base_energy
		_torch_light.omni_range = light_range
		_torch_light.shadow_enabled = light_enabled and shadows_enabled
	if _sparks != null:
		_sparks.emitting = sparks_enabled


func _create_mesh_instance(node_name: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	return mesh_instance


func _create_cylinder_mesh(top_radius: float, bottom_radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh


func _create_box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


func _create_sphere_mesh(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	return mesh


func _create_prop_material(color: Color, metallic_specular: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic_specular = metallic_specular
	material.roughness = roughness
	return material


func _create_additive_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = emission_energy
	material.disable_receive_shadows = true
	return material


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
