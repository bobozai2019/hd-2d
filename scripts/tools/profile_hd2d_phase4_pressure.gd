extends SceneTree

const LAB_SCENE_PATH := "res://scenes/map3d/hd2d_effect_lab.tscn"
const CHARACTER_TEMPLATE_PATH := "res://scenes/map3d/characters/hd2d_character_template.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var output_path := "res://output/phase4/hd2d-phase4-pressure-report.json"
	if args.size() >= 1:
		output_path = args[0]

	var packed := load(LAB_SCENE_PATH) as PackedScene
	var character_template := load(CHARACTER_TEMPLATE_PATH) as PackedScene
	if packed == null or character_template == null:
		push_error("Failed to load phase4 profiling dependencies")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var character_root := scene.get_node("CharacterRoot") as Node3D
	var vfx_root := scene.get_node("VfxRoot") as Node3D
	var dynamic_lights_root := vfx_root.get_node("DynamicLights") as Node3D
	var fog_planes_root := vfx_root.get_node("FogPlanes") as Node3D
	var ambient_particles_root := vfx_root.get_node("AmbientParticles") as Node3D
	var glow_sources_root := vfx_root.get_node("GlowSources") as Node3D

	for index in range(29):
		var instance := character_template.instantiate()
		instance.position = Vector3(-3.0 + float(index % 6) * 1.2, 0.0, -1.0 - float(index / 6) * 0.82)
		character_root.add_child(instance)

	for index in range(7):
		var light := OmniLight3D.new()
		light.position = Vector3(-2.4 + float(index) * 0.9, 1.2, -0.6 - float(index % 3) * 1.3)
		light.light_energy = 0.28
		light.omni_range = 3.2
		light.light_color = Color(1.0, 0.76, 0.42, 1.0) if index % 2 == 0 else Color(0.46, 0.72, 1.0, 1.0)
		dynamic_lights_root.add_child(light)

	for index in range(2):
		var fog_plane := MeshInstance3D.new()
		fog_plane.mesh = QuadMesh.new()
		var quad := fog_plane.mesh as QuadMesh
		quad.size = Vector2(2.0, 2.0)
		var fog_material := StandardMaterial3D.new()
		fog_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fog_material.albedo_color = Color(0.62, 0.68, 0.74, 0.14)
		fog_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fog_material.disable_receive_shadows = true
		fog_plane.material_override = fog_material
		fog_plane.position = Vector3(-1.4 + float(index) * 2.4, 1.15, -1.4 - float(index) * 0.9)
		fog_planes_root.add_child(fog_plane)

	for index in range(2):
		var particles := GPUParticles3D.new()
		particles.amount = 14
		particles.lifetime = 2.6
		particles.preprocess = 1.0
		particles.draw_pass_1 = QuadMesh.new()
		var particle_quad := particles.draw_pass_1 as QuadMesh
		particle_quad.size = Vector2(0.08, 0.08)
		var process := ParticleProcessMaterial.new()
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		process.emission_box_extents = Vector3(1.4, 0.8, 1.4)
		process.color = Color(0.92, 0.88, 0.76, 0.18)
		process.initial_velocity_min = 0.03
		process.initial_velocity_max = 0.08
		process.gravity = Vector3(0.0, 0.02, 0.0)
		particles.process_material = process
		particles.position = Vector3(-1.5 + float(index) * 3.0, 1.2, -2.0)
		ambient_particles_root.add_child(particles)

	for index in range(2):
		var glow := MeshInstance3D.new()
		glow.mesh = CylinderMesh.new()
		var glow_mesh := glow.mesh as CylinderMesh
		glow_mesh.top_radius = 0.18
		glow_mesh.bottom_radius = 0.18
		glow_mesh.height = 0.74
		var glow_material := StandardMaterial3D.new()
		glow_material.albedo_color = Color(1.0, 0.78, 0.36, 1.0)
		glow_material.emission_enabled = true
		glow_material.emission = Color(1.0, 0.78, 0.36, 1.0)
		glow_material.emission_energy_multiplier = 0.92
		glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.material_override = glow_material
		glow.position = Vector3(-0.8 + float(index) * 2.6, 0.42, -2.8)
		glow_sources_root.add_child(glow)

	var fps_samples: Array[float] = []
	for _frame in range(90):
		await process_frame
		fps_samples.append(Engine.get_frames_per_second())

	var avg_fps := 0.0
	var min_fps := INF
	for sample in fps_samples:
		avg_fps += sample
		min_fps = minf(min_fps, sample)
	if not fps_samples.is_empty():
		avg_fps /= fps_samples.size()

	var report := {
		"character_count": character_root.get_child_count(),
		"tile_count": 20,
		"local_light_count": dynamic_lights_root.get_child_count(),
		"particle_group_count": ambient_particles_root.get_child_count(),
		"transparent_layer_count": fog_planes_root.get_child_count() + scene.get_node("Stage/TransparentSamples").get_child_count(),
		"glow_source_count": glow_sources_root.get_child_count(),
		"average_fps": avg_fps,
		"minimum_fps": min_fps if min_fps != INF else 0.0,
	}

	var absolute_output := ProjectSettings.globalize_path(output_path)
	var output_dir := absolute_output.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)
	var file := FileAccess.open(absolute_output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()

	print(JSON.stringify(report))
	quit(0)
