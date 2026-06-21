extends SceneTree

const TEXTURE_DIR := "res://assets/generated/map3d/textures"
const MATERIAL_DIR := "res://assets/generated/map3d/materials"
const PATCH_DIR := "res://assets/generated/hd2d/light_patches"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_make_dir(TEXTURE_DIR)
	_make_dir(MATERIAL_DIR)
	_make_dir(PATCH_DIR)

	_save_pattern("hd2d_market_ref_stone_floor", Color(0.50, 0.47, 0.37), Color(0.20, 0.19, 0.15), 12, 10, 0.042, 1, 0.54)
	_save_pattern("hd2d_market_ref_limestone_wall", Color(0.56, 0.50, 0.38), Color(0.25, 0.22, 0.17), 18, 12, 0.036, 1, 0.56)
	_save_pattern("hd2d_market_ref_aged_wood", Color(0.22, 0.16, 0.11), Color(0.09, 0.07, 0.05), 10, 18, 0.032, 1, 0.50)
	_save_pattern("hd2d_market_ref_fabric_canopy", Color(0.34, 0.08, 0.055), Color(0.055, 0.18, 0.18), 16, 16)
	_save_pattern("hd2d_market_ref_roof_tile", Color(0.20, 0.08, 0.055), Color(0.08, 0.052, 0.044), 14, 9, 0.028, 1, 0.48)

	_save_radial_patch("alpha_market_central_warm_pool", Color(1.0, 0.55, 0.18, 0.0), Color(1.0, 0.54, 0.17, 0.32), 1.0, 0.58)
	_save_radial_patch("alpha_market_wall_warm_falloff", Color(1.0, 0.43, 0.14, 0.0), Color(1.0, 0.46, 0.15, 0.24), 0.72, 0.42)
	_save_strip_patch("alpha_market_window_glow_strip", Color(1.0, 0.56, 0.2, 0.0), Color(1.0, 0.56, 0.19, 0.36))
	_save_edge_shadow_patch("alpha_market_edge_shadow_soft")

	_save_material("mat_hd2d_market_ref_stone_floor", "hd2d_market_ref_stone_floor", Color(0.78, 0.76, 0.66), 0.94, 0.07, 0.25, 0.14)
	_save_material("mat_hd2d_market_ref_limestone_wall", "hd2d_market_ref_limestone_wall", Color(0.85, 0.80, 0.68), 0.9, 0.08, 0.28, 0.16)
	_save_material("mat_hd2d_market_ref_aged_wood", "hd2d_market_ref_aged_wood", Color(0.62, 0.52, 0.42), 0.88, 0.07, 0.32, 0.18)
	_save_material("mat_hd2d_market_ref_fabric_canopy", "hd2d_market_ref_fabric_canopy", Color(0.28, 0.12, 0.10), 0.94, 0.05)
	_save_material("mat_hd2d_market_ref_roof_tile", "hd2d_market_ref_roof_tile", Color(0.58, 0.42, 0.34), 0.9, 0.07, 0.28, 0.16)
	_save_plain_material("mat_hd2d_market_ref_prop_dark", Color(0.055, 0.049, 0.045), 0.96, 0.04, false)
	_save_plain_material("mat_hd2d_market_ref_window_emission_warm", Color(0.8, 0.34, 0.11), 0.75, 0.03, true)
	_save_plain_material("mat_hd2d_market_ref_lantern_emission_warm", Color(1.0, 0.42, 0.12), 0.7, 0.03, true)

	quit(0)


func _make_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _save_pattern(base_name: String, base: Color, line: Color, tile_w: int, tile_h: int, jitter_strength: float = 0.07, seam_width: int = 1, seam_ao: float = 0.42) -> void:
	var albedo := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var normal := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var occlusion := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in range(256):
		for x in range(256):
			var jitter := _hash01(x, y) * jitter_strength - jitter_strength * 0.5
			var brick_offset := int(floor(float(y) / float(tile_h))) % 2 * int(tile_w / 2)
			var seam_x := (x + brick_offset) % tile_w <= seam_width
			var seam_y := y % tile_h <= seam_width
			var seam := seam_x or seam_y
			var shade := sin(float(x) * 0.11) * 0.02 + sin(float(y) * 0.07) * 0.025 + jitter
			var color := line if seam else base.lightened(clamp(shade, 0.0, 0.12))
			if shade < 0.0:
				color = color.darkened(abs(shade))
			albedo.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0))
			var normal_color := Color(0.5, 0.5, 1.0, 1.0)
			if seam:
				normal_color = Color(0.47, 0.47, 0.88, 1.0)
			normal.set_pixel(x, y, normal_color)
			var ao_value: float = seam_ao if seam else clamp(0.82 + jitter, 0.68, 0.92)
			occlusion.set_pixel(x, y, Color(ao_value, ao_value, ao_value, 1.0))
	_save_png(albedo, "%s/%s_albedo.png" % [TEXTURE_DIR, base_name])
	_save_png(normal, "%s/%s_normal.png" % [TEXTURE_DIR, base_name])
	_save_png(occlusion, "%s/%s_occlusion.png" % [TEXTURE_DIR, base_name])


func _save_radial_patch(base_name: String, edge: Color, center: Color, sx: float, sy: float) -> void:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in range(256):
		for x in range(256):
			var uv := Vector2((float(x) + 0.5) / 256.0 * 2.0 - 1.0, (float(y) + 0.5) / 256.0 * 2.0 - 1.0)
			var d := sqrt(pow(uv.x / sx, 2.0) + pow(uv.y / sy, 2.0))
			var t: float = clamp(1.0 - d, 0.0, 1.0)
			t = t * t * (3.0 - 2.0 * t)
			image.set_pixel(x, y, edge.lerp(center, t))
	_save_png(image, "%s/%s.png" % [PATCH_DIR, base_name])


func _save_strip_patch(base_name: String, edge: Color, center: Color) -> void:
	var image := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	for y in range(128):
		for x in range(256):
			var u: float = abs((float(x) + 0.5) / 256.0 * 2.0 - 1.0)
			var v: float = abs((float(y) + 0.5) / 128.0 * 2.0 - 1.0)
			var t: float = clamp(1.0 - max(u * 0.72, v * 1.8), 0.0, 1.0)
			image.set_pixel(x, y, edge.lerp(center, t * t))
	_save_png(image, "%s/%s.png" % [PATCH_DIR, base_name])


func _save_edge_shadow_patch(base_name: String) -> void:
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	for y in range(256):
		for x in range(256):
			var u: float = abs((float(x) + 0.5) / 256.0 * 2.0 - 1.0)
			var alpha: float = pow(clamp(u, 0.0, 1.0), 2.2) * 0.46
			image.set_pixel(x, y, Color(0.0, 0.0, 0.0, alpha))
	_save_png(image, "%s/%s.png" % [PATCH_DIR, base_name])


func _save_png(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error_string(error)])


func _save_material(
	name: String,
	texture_base: String,
	albedo: Color,
	roughness: float,
	specular: float,
	normal_scale: float = 0.32,
	ao_light_affect: float = 0.18
) -> void:
	var body := """[gd_resource type="StandardMaterial3D" load_steps=4 format=3]

[ext_resource type="Texture2D" path="res://assets/generated/map3d/textures/%s_albedo.png" id="1_albedo"]
[ext_resource type="Texture2D" path="res://assets/generated/map3d/textures/%s_normal.png" id="2_normal"]
[ext_resource type="Texture2D" path="res://assets/generated/map3d/textures/%s_occlusion.png" id="3_occlusion"]

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
""" % [texture_base, texture_base, texture_base, _color_text(albedo), specular, roughness, normal_scale, ao_light_affect]
	_save_text("%s/%s.tres" % [MATERIAL_DIR, name], body)


func _save_plain_material(name: String, albedo: Color, roughness: float, specular: float, emission: bool) -> void:
	var emission_text := ""
	if emission:
		emission_text = "\nemission_enabled = true\nemission = %s\nemission_energy_multiplier = 1.35\n" % _color_text(albedo)
	var body := """[gd_resource type="StandardMaterial3D" format=3]

[resource]
albedo_color = %s
metallic_specular = %.4f
roughness = %.4f%s
""" % [_color_text(albedo), specular, roughness, emission_text]
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
