extends SceneTree

const LAB_SCENE := preload("res://scenes/map3d/hd2d_effect_lab.tscn")
const RUN_SCENE := preload("res://scenes/map3d/run_hex_map_3d.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab = LAB_SCENE.instantiate()
	get_root().add_child(lab)
	await process_frame
	var lab_profile: Dictionary = lab.call("get_debug_profile")
	var lab_vfx: Dictionary = lab_profile.get("vfx_counts", {})
	_assert(int(lab_vfx.get("ambient_particles", 0)) > 0, "lab has ambient particles")
	_assert(int(lab_vfx.get("glow_sources", 0)) > 0, "lab has glow source")
	_assert(int(lab_vfx.get("skill_samples", 0)) > 0, "lab has skill sample")
	_assert(int(lab_vfx.get("fog_planes", 0)) > 0, "lab has fog plane")
	_assert(int(lab_vfx.get("dynamic_lights", 0)) > 0, "lab has dynamic light")
	lab.queue_free()

	await process_frame
	var run_map = RUN_SCENE.instantiate()
	get_root().add_child(run_map)
	await process_frame
	await process_frame
	var run_vfx: Dictionary = run_map.call("debug_get_vfx_counts")
	_assert(int(run_vfx.get("ambient_particles", 0)) > 0, "run map has ambient particles")
	_assert(int(run_vfx.get("glow_sources", 0)) > 0, "run map has glow source")
	_assert(int(run_vfx.get("skill_samples", 0)) > 0, "run map has skill sample")
	_assert(int(run_vfx.get("fog_planes", 0)) > 0, "run map has fog plane")
	_assert(int(run_vfx.get("dynamic_lights", 0)) > 0, "run map has dynamic light")

	print("PASS test_hd2d_phase4_vfx_samples")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
