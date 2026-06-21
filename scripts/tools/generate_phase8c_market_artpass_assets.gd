extends SceneTree

const MATERIAL_DIR := "res://assets/generated/map3d/materials"
const PATCH_DIR := "res://assets/generated/hd2d/light_patches"
const TEXTURE_DIR := "res://assets/generated/map3d/textures"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_make_dir(MATERIAL_DIR)
	_make_dir(PATCH_DIR)

	_save_textured_material("mat_hd2d_market_artpass_wall_trim", "hd2d_market_ref_limestone_wall", Color(0.44, 0.40, 0.31), 0.92, 0.035, 0.24, 0.14)
	_save_plain_material("mat_hd2d_market_artpass_prop_ceramic", Color(0.32, 0.30, 0.26), 0.88, 0.045, false)
	_save_plain_material("mat_hd2d_market_artpass_prop_fabric_red", Color(0.24, 0.065, 0.055), 0.96, 0.025, false)
	_save_plain_material("mat_hd2d_market_artpass_prop_fabric_teal", Color(0.045, 0.13, 0.14), 0.96, 0.025, false)
	_save_textured_material("mat_hd2d_market_artpass_shadow_wood", "hd2d_market_ref_aged_wood", Color(0.42, 0.34, 0.27), 0.94, 0.025, 0.28, 0.16)

	_save_radial_patch("alpha_market_artpass_center_pool", Color(1.0, 0.54, 0.18, 0.0), Color(1.0, 0.52, 0.16, 0.24), 1.05, 0.52, 0.12)
	_save_radial_patch("alpha_market_artpass_stall_bounce", Color(1.0, 0.42, 0.12, 0.0), Color(1.0, 0.43, 0.15, 0.16), 0.68, 0.46, 0.18)
	_save_radial_patch("alpha_market_artpass_back_lantern_haze", Color(1.0, 0.55, 0.22, 0.0), Color(1.0, 0.54, 0.20, 0.13), 1.2, 0.36, 0.2)
	_save_foreground_vignette("alpha_market_artpass_foreground_vignette")

	quit(0)


func _make_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _save_radial_patch(base_name: String, edge: Color, center: Color, sx: float, sy: float, noise_strength: float) -> void:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in range(256):
		for x in range(256):
			var uv := Vector2((float(x) + 0.5) / 256.0 * 2.0 - 1.0, (float(y) + 0.5) / 256.0 * 2.0 - 1.0)
			var d := sqrt(pow((uv.x + sin(uv.y * 4.7) * 0.035) / sx, 2.0) + pow((uv.y + sin(uv.x * 5.3) * 0.025) / sy, 2.0))
			var t: float = clamp(1.0 - d, 0.0, 1.0)
			t = t * t * (3.0 - 2.0 * t)
			var noise := (_hash01(x, y) - 0.5) * noise_strength
			var color := edge.lerp(center, clamp(t + noise, 0.0, 1.0))
			image.set_pixel(x, y, color)
	_save_png(image, "%s/%s.png" % [PATCH_DIR, base_name])


func _save_foreground_vignette(base_name: String) -> void:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in range(256):
		for x in range(256):
			var u: float = abs((float(x) + 0.5) / 256.0 * 2.0 - 1.0)
			var v: float = (float(y) + 0.5) / 256.0
			var side_alpha := pow(clamp(u, 0.0, 1.0), 2.1) * 0.22
			var bottom_alpha := pow(clamp(v, 0.0, 1.0), 2.7) * 0.18
			image.set_pixel(x, y, Color(0.0, 0.0, 0.0, clamp(side_alpha + bottom_alpha, 0.0, 0.34)))
	_save_png(image, "%s/%s.png" % [PATCH_DIR, base_name])


func _save_png(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error_string(error)])


func _save_plain_material(name: String, albedo: Color, roughness: float, specular: float, emission: bool) -> void:
	var emission_text := ""
	if emission:
		emission_text = "\nemission_enabled = true\nemission = %s\nemission_energy_multiplier = 1.0\n" % _color_text(albedo)
	var body := """[gd_resource type="StandardMaterial3D" format=3]

[resource]
albedo_color = %s
metallic_specular = %.4f
roughness = %.4f%s
""" % [_color_text(albedo), specular, roughness, emission_text]
	_save_text("%s/%s.tres" % [MATERIAL_DIR, name], body)


func _save_textured_material(
	name: String,
	texture_base: String,
	albedo: Color,
	roughness: float,
	specular: float,
	normal_scale: float,
	ao_light_affect: float
) -> void:
	var body := """[gd_resource type="StandardMaterial3D" load_steps=4 format=3]

[ext_resource type="Texture2D" path="%s/%s_albedo.png" id="1_albedo"]
[ext_resource type="Texture2D" path="%s/%s_normal.png" id="2_normal"]
[ext_resource type="Texture2D" path="%s/%s_occlusion.png" id="3_occlusion"]

[resource]
albedo_color = %s
albedo_texture = ExtResource("1_albedo")
metallic_specular = %.4f
roughness = %.4f
normal_enabled = true
normal_scale = %.4f
normal_texture = ExtResource("2_normal")
ao_enabled = true
ao_light_affect = %.4f
ao_texture = ExtResource("3_occlusion")
""" % [TEXTURE_DIR, texture_base, TEXTURE_DIR, texture_base, TEXTURE_DIR, texture_base, _color_text(albedo), specular, roughness, normal_scale, ao_light_affect]
	_save_text("%s/%s.tres" % [MATERIAL_DIR, name], body)


func _save_text(path: String, text: String) -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	if file == null:
		push_error("Failed to open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(text)


func _color_text(color: Color) -> String:
	return "Color(%.4f, %.4f, %.4f, %.4f)" % [color.r, color.g, color.b, color.a]


func _hash01(x: int, y: int) -> float:
	var value := int(x * 374761393 + y * 668265263)
	value = int((value ^ (value >> 13)) * 1274126177)
	return float(value & 65535) / 65535.0
