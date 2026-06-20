extends SceneTree

const LAB_SCENE := preload("res://scenes/map3d/hd2d_reference_light_response_lab.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := LAB_SCENE.instantiate()
	get_root().add_child(lab)
	await process_frame
	await process_frame

	var profile: Dictionary = lab.call("get_reference_light_response_profile")
	_assert(String(profile.get("reference_profile", "")) == "baseline", "reference lab defaults to baseline")
	_assert(int(profile.get("dynamic_local_light_budget", 0)) == 3, "reference lab exposes three-light budget")
	_assert(int(profile.get("dynamic_local_light_count", 0)) <= 3, "baseline stays inside dynamic local-light budget")
	_assert(not bool(profile.get("warm_patches_visible", true)), "baseline hides painted warm patches")

	var material_targets: Array = profile.get("material_targets", [])
	_assert(material_targets.size() >= 10, "reference lab exposes enough ground, wall and rock material targets")
	for target in material_targets:
		_assert(bool(target.get("shaded", false)), "%s remains shaded" % String(target.get("name", "")))
		_assert(float(target.get("roughness", -1.0)) >= 0.88, "%s keeps matte roughness" % String(target.get("name", "")))

	var character_profiles: Array = profile.get("character_profiles", [])
	_assert(character_profiles.size() == 3, "reference lab exposes three character light profiles")
	_assert(_has_character_profile(character_profiles, "CharacterUnshaded", false, false), "character compare includes unshaded sample")
	_assert(_has_character_profile(character_profiles, "CharacterShaded", true, false), "character compare includes shaded sample")
	_assert(_has_character_profile(character_profiles, "CharacterHybrid", false, true), "character compare includes hybrid sample")

	lab.call("set_reference_profile", "adjusted")
	await process_frame
	var adjusted_profile: Dictionary = lab.call("get_reference_light_response_profile")
	_assert(String(adjusted_profile.get("reference_profile", "")) == "adjusted", "adjusted profile applies")
	_assert(bool(adjusted_profile.get("warm_patches_visible", false)), "adjusted shows warm light patches")
	_assert(int(adjusted_profile.get("dynamic_local_light_count", 99)) <= 3, "adjusted stays inside dynamic local-light budget")

	lab.call("set_reference_profile", "no_local_light")
	await process_frame
	var no_local_profile: Dictionary = lab.call("get_reference_light_response_profile")
	_assert(String(no_local_profile.get("reference_profile", "")) == "no_local_light", "no-local-light profile applies")
	_assert(int(no_local_profile.get("dynamic_local_light_count", 99)) == 0, "no-local-light disables all dynamic local lights")
	_assert(not bool(no_local_profile.get("warm_patches_visible", true)), "no-local-light disables painted warm patches")

	lab.call("set_reference_profile", "town_sample_match")
	await process_frame
	var town_profile: Dictionary = lab.call("get_reference_light_response_profile")
	_assert(String(town_profile.get("reference_profile", "")) == "town_sample_match", "town sample profile applies")
	_assert(bool(town_profile.get("warm_patches_visible", false)), "town sample keeps central warm patch")
	_assert(bool(town_profile.get("edge_vignette_visible", false)), "town sample keeps edge darkening")
	_assert(int(town_profile.get("dynamic_local_light_count", 99)) <= 3, "town sample stays inside dynamic local-light budget")

	var audit: Array = town_profile.get("asset_audit", [])
	_assert(audit.size() == 6, "reference lab records the first-pass asset audit")

	print("PASS test_hd2d_reference_light_response_lab")
	lab.queue_free()
	await process_frame
	quit(0)


func _has_character_profile(profiles: Array, expected_name: String, expected_shaded: bool, expected_hybrid: bool) -> bool:
	for profile in profiles:
		if String(profile.get("name", "")) != expected_name:
			continue
		if bool(profile.get("sprite_shaded", false)) != expected_shaded:
			return false
		return bool(profile.get("hybrid_warm_patch", false)) == expected_hybrid
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
