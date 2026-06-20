@tool
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
@export var sprite_frame_rate := 10.0

var _time := 0.0
var _phase := 0.0
var _flame_effect: Node3D
var _flame_halo: Node3D
var _outer_flame: Sprite3D
var _middle_flame: Sprite3D
var _core_flame: Sprite3D
var _top_wisp: Sprite3D
var _sparks: GPUParticles3D
var _torch_light: OmniLight3D


func _ready() -> void:
	_phase = flicker_phase if flicker_phase >= 0.0 else randf() * TAU
	_bind_scene_nodes()
	_apply_parameters()


func _process(delta: float) -> void:
	_bind_scene_nodes()
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * light_flicker_speed + _phase)
	var slow_wave := 0.5 + 0.5 * sin(_time * 2.1 + _phase * 0.7)
	var sway := sin(_time * 3.4 + _phase) * 0.035
	var lean := sin(_time * 2.7 + _phase * 0.5) * 0.028

	if _torch_light != null and light_enabled:
		var flicker := lerpf(1.0 - light_flicker_strength, 1.0 + light_flicker_strength, pulse)
		_torch_light.light_energy = light_base_energy * flicker

	if _flame_effect != null:
		var flame_xz := flame_base_scale * lerpf(0.9, 1.12, pulse)
		var flame_y := flame_base_scale * lerpf(0.94, 1.22, slow_wave)
		_flame_effect.scale = Vector3(flame_xz, flame_y, flame_xz)
		_flame_effect.rotation.z = sway + lean
		_update_flame_frames()

	if _flame_halo != null:
		var halo_xz := glow_base_scale * lerpf(1.0 - glow_flicker_strength, 1.0 + glow_flicker_strength, slow_wave)
		var halo_y := glow_base_scale * lerpf(0.96, 1.08, pulse)
		_flame_halo.scale = Vector3(halo_xz, halo_y, halo_xz)


func set_active(active: bool, active_shadows_enabled: bool = true) -> void:
	_bind_scene_nodes()
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if _torch_light != null:
		_torch_light.visible = active and light_enabled
		_torch_light.shadow_enabled = active and light_enabled and shadows_enabled and active_shadows_enabled
	if _sparks != null:
		_sparks.emitting = active and sparks_enabled


func get_torch_light() -> OmniLight3D:
	_bind_scene_nodes()
	return _torch_light


func get_torch_validation_profile() -> Dictionary:
	return {
		"name": name,
		"profile_rank": profile_rank,
		"has_prop": get_node_or_null("TorchProp") != null,
		"has_flame": get_node_or_null("FlameEffect") != null,
		"has_halo": get_node_or_null("FlameHalo") != null,
		"has_sparks": get_node_or_null("Sparks") != null and sparks_enabled,
		"uses_spark_particles": _sparks != null and _sparks.draw_pass_1 != null,
		"uses_spark_texture": _spark_draw_pass_uses_texture(),
		"uses_spark_particle_billboard": _spark_draw_pass_uses_particle_billboard(),
		"light_enabled": light_enabled,
		"uses_sprite_sheet_flame": _outer_flame != null and _middle_flame != null and _core_flame != null,
		"texture_based": _node_uses_texture(self),
	}


func _bind_scene_nodes() -> void:
	_flame_effect = get_node_or_null("FlameEffect") as Node3D
	_flame_halo = get_node_or_null("FlameHalo") as Node3D
	_outer_flame = get_node_or_null("FlameEffect/OuterFlame") as Sprite3D
	_middle_flame = get_node_or_null("FlameEffect/MiddleFlame") as Sprite3D
	_core_flame = get_node_or_null("FlameEffect/CoreFlame") as Sprite3D
	_top_wisp = get_node_or_null("FlameEffect/TopWisp") as Sprite3D
	_sparks = get_node_or_null("Sparks") as GPUParticles3D
	_torch_light = get_node_or_null("TorchLight") as OmniLight3D


func _apply_parameters() -> void:
	if _torch_light != null:
		_torch_light.visible = light_enabled
		_torch_light.light_energy = light_base_energy
		_torch_light.omni_range = light_range
		_torch_light.shadow_enabled = light_enabled and shadows_enabled
	if _sparks != null:
		_sparks.emitting = sparks_enabled


func _update_flame_frames() -> void:
	_set_sprite_frame(_outer_flame, 8, sprite_frame_rate, 0.0)
	_set_sprite_frame(_middle_flame, 8, sprite_frame_rate * 1.15, 2.0)
	_set_sprite_frame(_core_flame, 8, sprite_frame_rate * 1.35, 4.0)
	_set_sprite_frame(_top_wisp, 6, sprite_frame_rate * 0.8, 1.0)


func _set_sprite_frame(sprite: Sprite3D, frame_count: int, frame_rate: float, frame_offset: float) -> void:
	if sprite == null:
		return
	var index := int(floor(_time * frame_rate + _phase + frame_offset)) % frame_count
	sprite.frame = index


func _spark_draw_pass_uses_texture() -> bool:
	if _sparks == null or _sparks.draw_pass_1 == null:
		return false
	var mesh := _sparks.draw_pass_1 as PrimitiveMesh
	if mesh == null:
		return false
	var material := mesh.material as StandardMaterial3D
	return material != null and material.albedo_texture != null


func _spark_draw_pass_uses_particle_billboard() -> bool:
	if _sparks == null or _sparks.draw_pass_1 == null:
		return false
	var mesh := _sparks.draw_pass_1 as PrimitiveMesh
	if mesh == null:
		return false
	var material := mesh.material as StandardMaterial3D
	return material != null and material.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES


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
