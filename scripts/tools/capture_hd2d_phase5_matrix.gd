extends SceneTree

const RunManagerScript := preload("res://scripts/run/run_manager.gd")
const BattleControllerScript := preload("res://scripts/battle/battle_controller.gd")


func _initialize() -> void:
	call_deferred("_capture_from_args")


func _capture_from_args() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("Usage: godot -s res://scripts/tools/capture_hd2d_phase5_matrix.gd <scenario> <scene_path> <output_path> [width] [height]")
		quit(1)
		return

	var scenario := args[0]
	var scene_path := args[1]
	var output_path := args[2]
	var width := int(args[3]) if args.size() >= 4 else 1280
	var height := int(args[4]) if args.size() >= 5 else 720

	if DisplayServer.get_name() == "headless":
		push_error("capture_hd2d_phase5_matrix.gd requires a real display driver.")
		quit(6)
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Failed to load scene: %s" % scene_path)
		quit(2)
		return

	if scenario == "run_hex_map_3d_node_selected" or scenario == "run_hex_map_3d_return_from_battle":
		RunManagerScript.current_ctx = RunManagerScript.create_preview_ctx()
	else:
		RunManagerScript.clear()

	var instance := packed.instantiate()
	var viewport := SubViewport.new()
	viewport.name = "CaptureViewport"
	viewport.size = Vector2i(width, height)
	viewport.transparent_bg = false
	viewport.disable_3d = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	root.add_child(viewport)
	viewport.add_child(instance)

	await process_frame
	await process_frame
	await process_frame

	match scenario:
		"run_hex_map_3d_node_selected":
			instance.debug_select_node(&"battle_1")
			await process_frame
		"run_hex_map_3d_return_from_battle":
			instance.debug_enter_node(&"battle_1")
			await process_frame
			await process_frame
			var battle_controller := BattleControllerScript.new()
			root.add_child(battle_controller)
			battle_controller.return_to_run_map_after_victory()
			await process_frame
			await process_frame
			viewport.remove_child(instance)
			instance.queue_free()
			instance = packed.instantiate()
			viewport.add_child(instance)
			await process_frame
			await process_frame
		_:
			pass

	await create_timer(0.35).timeout

	var texture := viewport.get_texture()
	if texture == null:
		push_error("Failed to get viewport texture for scene: %s" % scene_path)
		quit(3)
		return

	var image := texture.get_image()
	if image == null:
		push_error("Failed to capture image for scene: %s" % scene_path)
		quit(4)
		return

	var absolute_output := ProjectSettings.globalize_path(output_path)
	var output_dir := absolute_output.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		DirAccess.make_dir_recursive_absolute(output_dir)

	var save_error := image.save_png(absolute_output)
	if save_error != OK:
		push_error("Failed to save png: %s (%s)" % [absolute_output, error_string(save_error)])
		quit(5)
		return

	RunManagerScript.clear()
	quit(0)
