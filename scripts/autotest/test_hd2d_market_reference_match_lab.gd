extends SceneTree

const MARKET_REFERENCE_SCENE := preload("res://scenes/map3d/hd2d_market_reference_match_lab.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_reference_match.glb"), "combined market reference GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_crates.glb"), "crate prop GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_barrels.glb"), "barrel prop GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_tableware.glb"), "tableware prop GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_ladder.glb"), "ladder prop GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_hanging_cloth.glb"), "hanging cloth prop GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_signboard.glb"), "signboard prop GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_foreground_steps.glb"), "foreground steps prop GLB exists")

	var lab := MARKET_REFERENCE_SCENE.instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame

	_assert(lab.has_method("set_reference_profile"), "market reference lab exposes profile switch")
	_assert(lab.has_method("get_market_reference_profile_state"), "market reference lab exposes profile state")

	lab.call("set_reference_profile", "reference_match_v2")
	await process_frame
	var final_state := lab.call("get_market_reference_profile_state") as Dictionary
	_assert(String(final_state.get("reference_profile", "")) == "reference_match_v2", "default final profile applies")
	_assert(int(final_state.get("visible_real_local_light_count", -1)) <= 3, "final profile keeps real local lights within budget")
	_assert(bool(final_state.get("light_patches_visible", false)), "final profile keeps light patches visible")
	_assert(bool(final_state.get("glow", false)), "final profile keeps glow enabled")
	_assert(bool(final_state.get("fog", false)), "final profile keeps fog enabled")
	_assert(bool(final_state.get("dof", false)), "final profile keeps DOF enabled")
	_assert(_asset_visibility_passes(final_state), "final profile minimum asset visibility metadata passes")

	lab.call("set_reference_profile", "no_local_light")
	await process_frame
	var no_light_state := lab.call("get_market_reference_profile_state") as Dictionary
	_assert(int(no_light_state.get("visible_real_local_light_count", -1)) == 0, "no_local_light disables visible real local lights")

	lab.call("set_reference_profile", "no_patch")
	await process_frame
	var no_patch_state := lab.call("get_market_reference_profile_state") as Dictionary
	_assert(int(no_patch_state.get("visible_real_local_light_count", -1)) <= 3, "no_patch keeps real local lights within budget")
	_assert(not bool(no_patch_state.get("light_patches_visible", true)), "no_patch hides light patches")

	lab.call("set_reference_profile", "no_post")
	await process_frame
	var no_post_state := lab.call("get_market_reference_profile_state") as Dictionary
	_assert(int(no_post_state.get("visible_real_local_light_count", -1)) <= 3, "no_post keeps real local lights within budget")
	_assert(bool(no_post_state.get("light_patches_visible", false)), "no_post keeps light patches visible")
	_assert(not bool(no_post_state.get("glow", true)), "no_post disables glow")
	_assert(not bool(no_post_state.get("fog", true)), "no_post disables fog")
	_assert(not bool(no_post_state.get("dof", true)), "no_post disables DOF")

	if _failures.is_empty():
		print("PASS: hd2d_market_reference_match_lab profiles validated")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _asset_visibility_passes(state: Dictionary) -> bool:
	var visibility := state.get("minimum_asset_visibility", {}) as Dictionary
	return (
		bool(visibility.get("foreground_steps_or_low_wall", false))
		and bool(visibility.get("left_right_eaves", false))
		and bool(visibility.get("central_stalls", false))
		and int(visibility.get("small_props_instances", 0)) >= 8
		and int(visibility.get("small_props_categories", 0)) >= 3
		and bool(visibility.get("ladder_or_second_level", false))
		and int(visibility.get("rear_lantern_or_window_highlights", 0)) >= 4
	)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
