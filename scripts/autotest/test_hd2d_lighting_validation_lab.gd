extends SceneTree

const LAB_SCENE := preload("res://scenes/map3d/hd2d_lighting_validation_lab.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lab := LAB_SCENE.instantiate()
	get_root().add_child(lab)
	await process_frame
	await process_frame

	var profile: Dictionary = lab.call("get_lighting_validation_profile")
	_assert(int(profile.get("torch_count", 0)) == 3, "lighting lab has three torches")
	_assert(int(profile.get("dynamic_light_count", 0)) == 3, "lighting lab keeps dynamic lights inside P0 budget")
	_assert(int(profile.get("default_dynamic_light_count", 0)) == 3, "lighting lab default dynamic light count is three")
	_assert(String(profile.get("profile_role", "")) == "recommended_default", "lighting lab default profile is recommended default")
	_assert(String(profile.get("torch_variant", "")) == "phase7", "lighting lab defaults to Phase 7 torch template")
	_assert(String(profile.get("template_scene", "")) == "res://scenes/map3d/vfx/hd2d_torch_effect.tscn", "lighting lab exposes the reusable torch template scene")
	_assert(not bool(profile.get("texture_based_torch", true)), "lighting lab torch is effect-based, not texture-based")

	var torch_profiles: Array = profile.get("torch_profiles", [])
	_assert(torch_profiles.size() >= 3, "lighting lab exposes torch template profiles")
	for torch_profile in torch_profiles:
		_assert(bool(torch_profile.get("has_prop", false)), "%s has torch prop layers" % String(torch_profile.get("name", "")))
		_assert(bool(torch_profile.get("has_flame", false)), "%s has flame layers" % String(torch_profile.get("name", "")))
		_assert(bool(torch_profile.get("has_halo", false)), "%s has glow layers" % String(torch_profile.get("name", "")))
		_assert(not bool(torch_profile.get("texture_based", true)), "%s is not texture-based" % String(torch_profile.get("name", "")))

	var material_targets: Array = profile.get("material_targets", [])
	_assert(material_targets.size() >= 3, "lighting lab exposes wall and floor material targets")
	for target in material_targets:
		_assert(bool(target.get("shaded", false)), "%s is shaded" % String(target.get("name", "")))
		_assert(float(target.get("roughness", -1.0)) >= 0.8, "%s has matte HD-2D roughness" % String(target.get("name", "")))

	var light_profiles: Array = profile.get("light_profiles", [])
	for light_profile in light_profiles:
		_assert(float(light_profile.get("energy", 0.0)) > 0.25, "%s has visible light energy" % String(light_profile.get("name", "")))
		_assert(float(light_profile.get("range", 0.0)) >= 3.0, "%s reaches wall/floor targets" % String(light_profile.get("name", "")))
		_assert(bool(light_profile.get("shadow_enabled", false)), "%s has shadows enabled" % String(light_profile.get("name", "")))

	lab.call("set_dynamic_light_profile", 1)
	await process_frame
	var one_light_profile: Dictionary = lab.call("get_lighting_validation_profile")
	_assert(int(one_light_profile.get("torch_count", 0)) == 1, "lighting lab supports one-light minimum profile")
	_assert(int(one_light_profile.get("dynamic_light_count", 0)) == 1, "one-light minimum profile enables one dynamic light")
	_assert(String(one_light_profile.get("profile_role", "")) == "minimum", "one-light profile is marked as minimum")

	lab.call("set_dynamic_light_profile", 6)
	await process_frame
	var pressure_profile: Dictionary = lab.call("get_lighting_validation_profile")
	_assert(int(pressure_profile.get("torch_count", 0)) == 6, "lighting lab supports six-torch pressure profile")
	_assert(int(pressure_profile.get("dynamic_light_count", 0)) == 6, "six-light pressure profile enables six dynamic lights")
	_assert(bool(pressure_profile.get("pressure_profile", false)), "six-light profile is marked as pressure boundary")
	_assert(String(pressure_profile.get("profile_role", "")) == "pressure_boundary", "six-light profile is not treated as default")

	print("PASS test_hd2d_lighting_validation_lab")
	lab.queue_free()
	await process_frame
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
