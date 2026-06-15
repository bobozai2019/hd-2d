extends Node3D

const PROFILE_PERSPECTIVE_SHADED := &"perspective_shaded"
const PROFILE_PERSPECTIVE_UNSHADED := &"perspective_unshaded"
const PROFILE_ORTHOGONAL_SHADED := &"orthogonal_shaded"
const PROFILE_ORTHOGONAL_UNSHADED := &"orthogonal_unshaded"
const PROFILE_PERSPECTIVE_Y_BILLBOARD := &"perspective_y_billboard"
const PROFILE_PERSPECTIVE_FIXED_FACING := &"perspective_fixed_facing"

const ROUTE_ENTRY := &"entry_point"
const ROUTE_WALL_FRONT := &"wall_front"
const ROUTE_WALL_BACK := &"wall_back"
const ROUTE_FOREGROUND_COVER := &"foreground_cover"
const ROUTE_BRIDGE_TOP := &"bridge_top"
const ROUTE_TRANSPARENT_ZONE := &"transparent_zone"
const ROUTE_GLOW_SIDE := &"glow_side"
const ROUTE_SPRITE_SORTING := &"sprite_sorting"

@export var camera_move_speed := 4.8
@export var camera_rotate_sensitivity := 0.006
@export var camera_wheel_dolly_step := 0.9
@export var camera_min_pitch := -1.15
@export var camera_max_pitch := -0.12
@export var character_move_speed := 2.65
@export var character_fixed_rotation_degrees := Vector3(0.0, 180.0, 0.0)

@onready var _camera_rig: Node3D = $CameraRig
@onready var _camera: Camera3D = $CameraRig/Camera3D
@onready var _character_root: Node3D = $CharacterRoot
@onready var _player_sprite: AnimatedSprite3D = $CharacterRoot/PlayerCharacter
@onready var _comparison_sprites: Node3D = $CharacterRoot/ComparisonSprites
@onready var _fake_shadow: Node3D = $Stage/FakeShadow
@onready var _movement_route: Node3D = $Markers/MovementRoute
@onready var _camera_profiles: Node3D = $Markers/CameraProfiles
@onready var _vfx_root: Node3D = $VfxRoot
@onready var _ambient_particles_root: Node3D = $VfxRoot/AmbientParticles
@onready var _glow_sources_root: Node3D = $VfxRoot/GlowSources
@onready var _skill_samples_root: Node3D = $VfxRoot/SkillSamples
@onready var _fog_planes_root: Node3D = $VfxRoot/FogPlanes
@onready var _dynamic_lights_root: Node3D = $VfxRoot/DynamicLights

var _default_camera_rig_transform: Transform3D
var _default_camera_projection := Camera3D.PROJECTION_PERSPECTIVE
var _default_camera_fov := 34.0
var _default_camera_size := 12.0
var _default_player_pixel_size := 0.0024
var _default_player_billboard := BaseMaterial3D.BILLBOARD_ENABLED
var _default_player_shaded := true
var _player_base_height := 0.84
var _shadow_base_height := 0.018
var _camera_yaw := 0.0
var _camera_pitch := -0.55
var _mouse_rotating := false
var _active_profile: StringName = PROFILE_PERSPECTIVE_UNSHADED
var _active_route_marker: StringName = ROUTE_ENTRY


func _ready() -> void:
	_ensure_input_actions()
	_cache_scene_authored_defaults()
	_build_vfx_samples()
	move_player_to_route_marker(ROUTE_ENTRY)
	apply_validation_profile(PROFILE_PERSPECTIVE_Y_BILLBOARD)
	_play_character_stand()


func _process(delta: float) -> void:
	apply_character_move_input(_get_character_move_input(), delta)
	apply_camera_move_input(_get_camera_move_input(), delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_camera_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _mouse_rotating:
		rotate_camera_drag((event as InputEventMouseMotion).relative)


func reset_view() -> void:
	_camera_rig.transform = _default_camera_rig_transform
	_camera.projection = _default_camera_projection
	_camera.fov = _default_camera_fov
	_camera.size = _default_camera_size
	_sync_camera_angles_from_transform()


func reset_validation_state() -> void:
	reset_view()
	_player_sprite.pixel_size = _default_player_pixel_size
	_player_sprite.billboard = _default_player_billboard
	_player_sprite.shaded = _default_player_shaded
	_player_sprite.rotation_degrees = Vector3.ZERO
	move_player_to_route_marker(ROUTE_ENTRY)
	_active_profile = PROFILE_PERSPECTIVE_Y_BILLBOARD
	_active_route_marker = ROUTE_ENTRY


func apply_camera_move_input(move_input: Vector2, delta: float) -> void:
	if move_input.length_squared() == 0.0 or delta <= 0.0:
		return
	var forward := -_camera_rig.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := _camera_rig.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var direction := right * move_input.x + forward * move_input.y
	if direction.length_squared() == 0.0:
		return
	_camera_rig.global_position += direction.normalized() * camera_move_speed * delta


func apply_character_move_input(move_input: Vector2, delta: float) -> void:
	if move_input.length_squared() == 0.0 or delta <= 0.0:
		return
	var movement := Vector3(move_input.x, 0.0, move_input.y).normalized() * character_move_speed * delta
	var target_position := _player_sprite.position + movement
	target_position.x = clampf(target_position.x, -3.4, 2.8)
	target_position.z = clampf(target_position.z, -2.2, 2.8)
	target_position.y = _player_base_height + _sample_stage_height(target_position)
	_player_sprite.position = target_position
	_active_route_marker = &"manual"
	_sync_fake_shadow_to_player()


func rotate_camera_drag(mouse_delta: Vector2) -> void:
	if mouse_delta.length_squared() == 0.0:
		return
	_camera_yaw -= mouse_delta.x * camera_rotate_sensitivity
	_camera_pitch = clampf(_camera_pitch - mouse_delta.y * camera_rotate_sensitivity, camera_min_pitch, camera_max_pitch)
	_apply_camera_angles()


func dolly_camera_wheel(direction: float) -> void:
	if is_zero_approx(direction):
		return
	var forward := -_camera_rig.global_transform.basis.z.normalized()
	_camera_rig.global_position += forward * camera_wheel_dolly_step * direction


func is_camera_mouse_rotating() -> bool:
	return _mouse_rotating


func apply_validation_profile(profile_name: StringName) -> void:
	_active_profile = profile_name
	_apply_camera_profile(profile_name)
	match profile_name:
		PROFILE_PERSPECTIVE_SHADED:
			_apply_character_visual_profile(true, BaseMaterial3D.BILLBOARD_ENABLED)
		PROFILE_PERSPECTIVE_UNSHADED:
			_apply_character_visual_profile(false, BaseMaterial3D.BILLBOARD_ENABLED)
		PROFILE_ORTHOGONAL_SHADED:
			_apply_character_visual_profile(true, BaseMaterial3D.BILLBOARD_ENABLED)
		PROFILE_ORTHOGONAL_UNSHADED:
			_apply_character_visual_profile(false, BaseMaterial3D.BILLBOARD_ENABLED)
		PROFILE_PERSPECTIVE_Y_BILLBOARD:
			_apply_character_visual_profile(false, BaseMaterial3D.BILLBOARD_FIXED_Y)
		PROFILE_PERSPECTIVE_FIXED_FACING:
			_apply_character_visual_profile(false, BaseMaterial3D.BILLBOARD_DISABLED)
			_player_sprite.rotation_degrees = character_fixed_rotation_degrees
		_:
			_apply_character_visual_profile(false, BaseMaterial3D.BILLBOARD_FIXED_Y)


func move_player_to_route_marker(marker_name: StringName) -> void:
	var marker := _movement_route.get_node_or_null(String(marker_name)) as Node3D
	if marker == null:
		return
	_active_route_marker = marker_name
	var target_position := marker.position
	target_position.y = _player_base_height + _sample_stage_height(target_position)
	_player_sprite.position = target_position
	_sync_fake_shadow_to_player()


func get_debug_profile() -> Dictionary:
	return {
		"active_profile": _active_profile,
		"active_route_marker": _active_route_marker,
		"camera_position": _camera_rig.position,
		"camera_projection": _camera.projection,
		"camera_size": _camera.size,
		"camera_fov": _camera.fov,
		"camera_yaw": _camera_yaw,
		"camera_pitch": _camera_pitch,
		"camera_move_speed": camera_move_speed,
		"camera_rotate_sensitivity": camera_rotate_sensitivity,
		"camera_wheel_dolly_step": camera_wheel_dolly_step,
		"character_count": 1 + _comparison_sprites.get_child_count(),
		"comparison_sprite_count": _comparison_sprites.get_child_count(),
		"player_position": _player_sprite.position,
		"player_pixel_size": _player_sprite.pixel_size,
		"player_billboard": _player_sprite.billboard,
		"player_shaded": _player_sprite.shaded,
		"sampled_stage_height": _sample_stage_height(_player_sprite.position),
		"vfx_counts": get_vfx_sample_counts(),
	}


func get_vfx_sample_counts() -> Dictionary:
	return {
		"ambient_particles": _ambient_particles_root.get_child_count(),
		"glow_sources": _glow_sources_root.get_child_count(),
		"skill_samples": _skill_samples_root.get_child_count(),
		"fog_planes": _fog_planes_root.get_child_count(),
		"dynamic_lights": _dynamic_lights_root.get_child_count(),
	}


func get_profile_capture_specs() -> Array[Dictionary]:
	return [
		{"profile": PROFILE_PERSPECTIVE_SHADED, "marker": ROUTE_SPRITE_SORTING, "suffix": "perspective-shaded"},
		{"profile": PROFILE_PERSPECTIVE_UNSHADED, "marker": ROUTE_SPRITE_SORTING, "suffix": "perspective-unshaded"},
		{"profile": PROFILE_ORTHOGONAL_SHADED, "marker": ROUTE_SPRITE_SORTING, "suffix": "orthogonal-shaded"},
		{"profile": PROFILE_ORTHOGONAL_UNSHADED, "marker": ROUTE_SPRITE_SORTING, "suffix": "orthogonal-unshaded"},
		{"profile": PROFILE_PERSPECTIVE_Y_BILLBOARD, "marker": ROUTE_SPRITE_SORTING, "suffix": "perspective-y-billboard"},
		{"profile": PROFILE_PERSPECTIVE_FIXED_FACING, "marker": ROUTE_SPRITE_SORTING, "suffix": "perspective-fixed-facing"},
	]


func get_occlusion_capture_specs() -> Array[Dictionary]:
	return [
		{"profile": PROFILE_PERSPECTIVE_Y_BILLBOARD, "marker": ROUTE_WALL_FRONT, "suffix": "wall-front"},
		{"profile": PROFILE_PERSPECTIVE_Y_BILLBOARD, "marker": ROUTE_WALL_BACK, "suffix": "wall-back"},
		{"profile": PROFILE_PERSPECTIVE_Y_BILLBOARD, "marker": ROUTE_FOREGROUND_COVER, "suffix": "foreground-cover"},
		{"profile": PROFILE_PERSPECTIVE_Y_BILLBOARD, "marker": ROUTE_BRIDGE_TOP, "suffix": "bridge-top"},
		{"profile": PROFILE_PERSPECTIVE_Y_BILLBOARD, "marker": ROUTE_TRANSPARENT_ZONE, "suffix": "transparent-zone"},
		{"profile": PROFILE_PERSPECTIVE_Y_BILLBOARD, "marker": ROUTE_GLOW_SIDE, "suffix": "glow-side"},
	]


func _cache_scene_authored_defaults() -> void:
	_default_camera_rig_transform = _camera_rig.transform
	_default_camera_projection = _camera.projection
	_default_camera_fov = _camera.fov
	_default_camera_size = _camera.size
	_default_player_pixel_size = _player_sprite.pixel_size
	_default_player_billboard = _player_sprite.billboard
	_default_player_shaded = _player_sprite.shaded
	_player_base_height = _player_sprite.position.y
	_shadow_base_height = _fake_shadow.position.y
	_sync_camera_angles_from_transform()


func _play_character_stand() -> void:
	for child in _character_root.get_children():
		if child is AnimatedSprite3D:
			var sprite := child as AnimatedSprite3D
			sprite.play(&"stand")
	for child in _comparison_sprites.get_children():
		if child is AnimatedSprite3D:
			var comparison := child as AnimatedSprite3D
			comparison.play(&"stand")


func _get_character_move_input() -> Vector2:
	return Input.get_vector("hd2d_character_left", "hd2d_character_right", "hd2d_character_backward", "hd2d_character_forward")


func _get_camera_move_input() -> Vector2:
	return Input.get_vector("hd2d_camera_left", "hd2d_camera_right", "hd2d_camera_backward", "hd2d_camera_forward")


func _handle_camera_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_RIGHT:
			_mouse_rotating = event.pressed
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_MIDDLE:
			_mouse_rotating = event.pressed
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				dolly_camera_wheel(1.0)
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				dolly_camera_wheel(-1.0)
				get_viewport().set_input_as_handled()


func _sync_camera_angles_from_transform() -> void:
	var forward := -_camera_rig.transform.basis.z.normalized()
	_camera_yaw = atan2(forward.x, forward.z)
	_camera_pitch = asin(clampf(forward.y, -1.0, 1.0))


func _apply_camera_angles() -> void:
	var basis := Basis(Vector3.UP, _camera_yaw) * Basis(Vector3.RIGHT, _camera_pitch)
	_camera_rig.transform.basis = basis.orthonormalized()


func _ensure_input_actions() -> void:
	_add_key_action("hd2d_character_forward", KEY_W)
	_add_key_action("hd2d_character_backward", KEY_S)
	_add_key_action("hd2d_character_left", KEY_A)
	_add_key_action("hd2d_character_right", KEY_D)
	_add_key_action("hd2d_camera_forward", KEY_UP)
	_add_key_action("hd2d_camera_backward", KEY_DOWN)
	_add_key_action("hd2d_camera_left", KEY_LEFT)
	_add_key_action("hd2d_camera_right", KEY_RIGHT)


func _add_key_action(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventKey and input_event.keycode == keycode:
			return
	var key := InputEventKey.new()
	key.keycode = keycode
	InputMap.action_add_event(action_name, key)


func _apply_camera_profile(profile_name: StringName) -> void:
	var marker_name := "PerspectiveCapture"
	var projection := Camera3D.PROJECTION_PERSPECTIVE
	var fov := 34.0
	var size := 12.0
	match profile_name:
		PROFILE_PERSPECTIVE_SHADED, PROFILE_PERSPECTIVE_UNSHADED, PROFILE_PERSPECTIVE_Y_BILLBOARD, PROFILE_PERSPECTIVE_FIXED_FACING:
			marker_name = "PerspectiveCapture"
			projection = Camera3D.PROJECTION_PERSPECTIVE
			fov = 34.0
			size = 12.0
		PROFILE_ORTHOGONAL_SHADED, PROFILE_ORTHOGONAL_UNSHADED:
			marker_name = "OrthogonalCapture"
			projection = Camera3D.PROJECTION_ORTHOGONAL
			fov = 34.0
			size = 7.0
	var marker := _camera_profiles.get_node_or_null(marker_name) as Node3D
	if marker != null:
		_camera_rig.transform = marker.transform
	_sync_camera_angles_from_transform()
	_camera.projection = projection
	_camera.fov = fov
	_camera.size = size


func _apply_character_visual_profile(shaded_enabled: bool, billboard_mode: BaseMaterial3D.BillboardMode) -> void:
	_player_sprite.shaded = shaded_enabled
	_player_sprite.billboard = billboard_mode
	_player_sprite.pixel_size = 0.0024
	_player_sprite.rotation_degrees = Vector3.ZERO


func _sample_stage_height(position: Vector3) -> float:
	if position.x >= 0.35 and position.x <= 2.15 and position.z >= 0.95 and position.z <= 2.05:
		return 0.72
	if position.x >= -0.15 and position.x < 0.35 and position.z >= 0.95 and position.z <= 2.05:
		return 0.36
	return 0.0


func _sync_fake_shadow_to_player() -> void:
	var stage_height := _sample_stage_height(_player_sprite.position)
	_fake_shadow.position = Vector3(_player_sprite.position.x, _shadow_base_height + stage_height, _player_sprite.position.z + 0.12)


func _build_vfx_samples() -> void:
	if _ambient_particles_root.get_child_count() > 0:
		return

	var ambient := GPUParticles3D.new()
	ambient.name = "DustMotes"
	ambient.amount = 18
	ambient.lifetime = 3.2
	ambient.preprocess = 1.0
	ambient.draw_pass_1 = QuadMesh.new()
	var ambient_quad := ambient.draw_pass_1 as QuadMesh
	ambient_quad.size = Vector2(0.08, 0.08)
	var ambient_process := ParticleProcessMaterial.new()
	ambient_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ambient_process.emission_box_extents = Vector3(2.2, 0.8, 2.2)
	ambient_process.gravity = Vector3(0.0, 0.02, 0.0)
	ambient_process.initial_velocity_min = 0.05
	ambient_process.initial_velocity_max = 0.12
	ambient_process.scale_min = 0.6
	ambient_process.scale_max = 1.2
	ambient_process.color = Color(0.86, 0.82, 0.74, 0.16)
	ambient.process_material = ambient_process
	ambient.position = Vector3(0.25, 1.15, 0.1)
	_ambient_particles_root.add_child(ambient)

	var glow_source := MeshInstance3D.new()
	glow_source.name = "CrystalGlow"
	glow_source.mesh = CylinderMesh.new()
	var glow_mesh := glow_source.mesh as CylinderMesh
	glow_mesh.top_radius = 0.18
	glow_mesh.bottom_radius = 0.18
	glow_mesh.height = 0.74
	var glow_material := StandardMaterial3D.new()
	glow_material.albedo_color = Color(0.38, 0.58, 1.0, 1.0)
	glow_material.emission_enabled = true
	glow_material.emission = Color(0.42, 0.66, 1.0, 1.0)
	glow_material.emission_energy_multiplier = 1.05
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_source.material_override = glow_material
	glow_source.position = Vector3(1.95, 0.42, -1.18)
	_glow_sources_root.add_child(glow_source)

	var skill_sample := MeshInstance3D.new()
	skill_sample.name = "ClickPulse"
	skill_sample.mesh = QuadMesh.new()
	var skill_quad := skill_sample.mesh as QuadMesh
	skill_quad.size = Vector2(0.82, 0.82)
	var skill_material := StandardMaterial3D.new()
	skill_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	skill_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	skill_material.albedo_color = Color(1.0, 0.82, 0.28, 0.22)
	skill_material.emission_enabled = true
	skill_material.emission = Color(1.0, 0.82, 0.28, 1.0)
	skill_material.emission_energy_multiplier = 0.48
	skill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	skill_sample.material_override = skill_material
	skill_sample.position = Vector3(1.22, 0.36, 1.56)
	_skill_samples_root.add_child(skill_sample)

	var fog_sample := MeshInstance3D.new()
	fog_sample.name = "ForegroundFog"
	fog_sample.mesh = QuadMesh.new()
	var fog_quad := fog_sample.mesh as QuadMesh
	fog_quad.size = Vector2(1.6, 1.9)
	var fog_material := StandardMaterial3D.new()
	fog_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fog_material.albedo_color = Color(0.62, 0.7, 0.76, 0.18)
	fog_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fog_material.disable_receive_shadows = true
	fog_sample.material_override = fog_material
	fog_sample.position = Vector3(-0.62, 1.08, -0.78)
	_fog_planes_root.add_child(fog_sample)

	var dynamic_light := OmniLight3D.new()
	dynamic_light.name = "TorchPulse"
	dynamic_light.position = Vector3(1.85, 1.05, -1.15)
	dynamic_light.light_color = Color(1.0, 0.74, 0.42, 1.0)
	dynamic_light.light_energy = 0.46
	dynamic_light.omni_range = 3.6
	_dynamic_lights_root.add_child(dynamic_light)
