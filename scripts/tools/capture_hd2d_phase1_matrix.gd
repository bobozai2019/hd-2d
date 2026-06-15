extends SceneTree

const LAB_SCENE_PATH := "res://scenes/map3d/hd2d_effect_lab.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		push_error("Usage: godot -s res://scripts/tools/capture_hd2d_phase1_matrix.gd <output_dir> [width] [height]")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("capture_hd2d_phase1_matrix.gd requires a real display driver.")
		quit(6)
		return

	var output_dir := args[0]
	var width := int(args[1]) if args.size() >= 2 else 1280
	var height := int(args[2]) if args.size() >= 3 else 720

	var packed := load(LAB_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load lab scene: %s" % LAB_SCENE_PATH)
		quit(2)
		return

	var lab := packed.instantiate()
	root.add_child(lab)
	get_root().size = Vector2i(width, height)

	await process_frame
	await process_frame
	await create_timer(0.25).timeout

	if not lab.has_method("get_profile_capture_specs") or not lab.has_method("get_occlusion_capture_specs"):
		push_error("Lab scene does not expose capture specs")
		quit(3)
		return

	var all_specs: Array = []
	all_specs.append_array(lab.call("get_profile_capture_specs"))
	all_specs.append_array(lab.call("get_occlusion_capture_specs"))

	for spec_variant in all_specs:
		var spec := spec_variant as Dictionary
		lab.call("apply_validation_profile", spec.get("profile", &""))
		lab.call("move_player_to_route_marker", spec.get("marker", &""))
		await process_frame
		await process_frame
		await create_timer(0.15).timeout
		var image := root.get_texture().get_image()
		if image == null:
			push_error("Failed to capture image for spec: %s" % spec)
			quit(4)
			return
		var suffix := String(spec.get("suffix", "capture"))
		var output_path := "%s/hd2d-phase1-%s-%sx%s.png" % [output_dir, suffix, width, height]
		var absolute_output := ProjectSettings.globalize_path(output_path)
		var output_base_dir := absolute_output.get_base_dir()
		if not DirAccess.dir_exists_absolute(output_base_dir):
			DirAccess.make_dir_recursive_absolute(output_base_dir)
		var save_error := image.save_png(absolute_output)
		if save_error != OK:
			push_error("Failed to save png: %s (%s)" % [absolute_output, error_string(save_error)])
			quit(5)
			return

	quit(0)
