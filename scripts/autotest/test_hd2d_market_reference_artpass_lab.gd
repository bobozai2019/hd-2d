extends SceneTree

const ARTPASS_SCENE := preload("res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn")
const BASE_8B_SCENE := preload("res://scenes/map3d/hd2d_market_reference_match_lab.tscn")
const MIGRATION_ENTRY_SCENE := preload("res://scenes/map3d/hd2d_market_artpass_candidate.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_reference_match_artpass.glb"), "art pass combined GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_wall_detail_set.glb"), "wall detail set GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_stall_detail_set.glb"), "stall detail set GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/models/hd2d_market_prop_right_tower_set.glb"), "right tower detail set GLB exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_wall_trim.tres"), "art pass wall trim material exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_ceramic.tres"), "art pass ceramic material exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_fabric_red.tres"), "art pass red fabric material exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_fabric_teal.tres"), "art pass teal fabric material exists")
	_assert(ResourceLoader.exists("res://assets/generated/map3d/materials/mat_hd2d_market_artpass_shadow_wood.tres"), "art pass shadow wood material exists")
	_assert(ResourceLoader.exists("res://assets/generated/hd2d/light_patches/alpha_market_artpass_center_pool.png"), "art pass center patch exists")
	_assert(ResourceLoader.exists("res://assets/generated/hd2d/light_patches/alpha_market_artpass_stall_bounce.png"), "art pass stall bounce patch exists")
	_assert(ResourceLoader.exists("res://assets/generated/hd2d/light_patches/alpha_market_artpass_back_lantern_haze.png"), "art pass lantern haze patch exists")
	_assert(ResourceLoader.exists("res://assets/generated/hd2d/light_patches/alpha_market_artpass_foreground_vignette.png"), "art pass foreground vignette patch exists")

	var base_lab := BASE_8B_SCENE.instantiate()
	root.add_child(base_lab)
	await process_frame
	await process_frame
	_assert(base_lab.has_method("get_market_reference_profile_state"), "8B lab still loads")
	base_lab.queue_free()

	var entry := MIGRATION_ENTRY_SCENE.instantiate()
	root.add_child(entry)
	await process_frame
	await process_frame
	_assert(entry != null, "migration entry scene loads")
	entry.queue_free()

	var lab := ARTPASS_SCENE.instantiate()
	root.add_child(lab)
	await process_frame
	await process_frame

	_assert(lab.has_method("set_reference_profile"), "art pass lab exposes profile switch")
	_assert(lab.has_method("get_market_reference_artpass_profile_state"), "art pass lab exposes profile state")

	var profiles: Array[String] = [
		"baseline_8b_final",
		"asset_artpass_only",
		"artpass_reference_v1",
		"no_local_light",
		"no_patch",
		"no_post",
		"character_scale_check",
	]
	for profile in profiles:
		lab.call("set_reference_profile", profile)
		await process_frame
		var state := lab.call("get_market_reference_artpass_profile_state") as Dictionary
		_assert(String(state.get("reference_profile", "")) == profile, "%s applies" % profile)
		_assert(int(state.get("visible_real_local_light_count", -1)) <= 3, "%s keeps real local lights within budget" % profile)

	lab.call("set_reference_profile", "artpass_reference_v1")
	await process_frame
	var final_state := lab.call("get_market_reference_artpass_profile_state") as Dictionary
	_assert(int(final_state.get("visible_real_local_light_count", -1)) <= 3, "final profile keeps real local lights within budget")
	_assert(bool(final_state.get("light_patches_visible", false)), "final profile keeps art pass patches visible")
	_assert(bool(final_state.get("glow", false)), "final profile keeps glow enabled")
	_assert(bool(final_state.get("fog", false)), "final profile keeps fog enabled")
	_assert(bool(final_state.get("dof", false)), "final profile keeps DOF enabled")
	_assert(bool(final_state.get("characters_shaded", false)), "final profile keeps market characters shaded")
	_assert(int(final_state.get("material_override_count", 0)) >= 12, "art pass material overrides are connected")
	_assert(_asset_visibility_passes(final_state), "final profile minimum asset visibility metadata passes")

	lab.call("set_reference_profile", "no_local_light")
	await process_frame
	var no_light_state := lab.call("get_market_reference_artpass_profile_state") as Dictionary
	_assert(int(no_light_state.get("visible_real_local_light_count", -1)) == 0, "no_local_light disables visible real local lights")

	lab.call("set_reference_profile", "no_patch")
	await process_frame
	var no_patch_state := lab.call("get_market_reference_artpass_profile_state") as Dictionary
	_assert(not bool(no_patch_state.get("light_patches_visible", true)), "no_patch hides art pass patches")

	lab.call("set_reference_profile", "no_post")
	await process_frame
	var no_post_state := lab.call("get_market_reference_artpass_profile_state") as Dictionary
	_assert(not bool(no_post_state.get("glow", true)), "no_post disables glow")
	_assert(not bool(no_post_state.get("fog", true)), "no_post disables fog")
	_assert(not bool(no_post_state.get("dof", true)), "no_post disables DOF")

	if _failures.is_empty():
		print("PASS: hd2d_market_reference_artpass_lab profiles validated")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _asset_visibility_passes(state: Dictionary) -> bool:
	var visibility := state.get("minimum_asset_visibility", {}) as Dictionary
	return (
		bool(visibility.get("RightTowerBalconyRail", false))
		and bool(visibility.get("RightTowerPlatform", false))
		and bool(visibility.get("RightVisibleHighLadder", false))
		and bool(visibility.get("RightHangingCloth", false))
		and bool(visibility.get("BackLanternShell", false))
		and bool(visibility.get("ForegroundStep", false))
		and bool(visibility.get("ForegroundLowWall", false))
		and bool(visibility.get("StallClusterA", false))
		and bool(visibility.get("StallClusterB", false))
		and bool(visibility.get("StallClusterC", false))
		and bool(visibility.get("WallTrim", false))
		and bool(visibility.get("WindowFrame", false))
		and bool(visibility.get("DoorFrame", false))
	)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
