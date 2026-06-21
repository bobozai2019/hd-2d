extends SceneTree

const TEXTURE_DIR := "res://assets/generated/map3d/textures"
const MODEL_TEXTURE_DIR := "res://assets/generated/map3d/models"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_make_dir(TEXTURE_DIR)
	_make_dir(MODEL_TEXTURE_DIR)

	_save_market_texture_set("hd2d_market_plaza_limestone_wall", "limestone_wall", Color(0.52, 0.50, 0.42), Color(0.36, 0.34, 0.28), 64, 42, 0.030, 0.020)
	_save_market_texture_set("hd2d_market_plaza_stone_floor", "stone_floor", Color(0.49, 0.47, 0.39), Color(0.25, 0.24, 0.20), 24, 18, 0.032, 0.014)
	_save_market_texture_set("hd2d_market_plaza_aged_wood", "aged_wood", Color(0.20, 0.16, 0.12), Color(0.09, 0.075, 0.06), 28, 256, 0.026, 0.012)
	_save_market_texture_set("hd2d_market_plaza_terracotta_roof", "terracotta_roof", Color(0.17, 0.095, 0.075), Color(0.075, 0.055, 0.048), 20, 16, 0.026, 0.012)
	_save_market_texture_set("hd2d_market_plaza_market_fabric", "market_fabric", Color(0.25, 0.075, 0.065), Color(0.045, 0.16, 0.16), 32, 256, 0.022, 0.010)

	quit(0)


func _make_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _save_market_texture_set(base_name: String, pattern: String, base: Color, line: Color, tile_w: int, tile_h: int, noise_strength: float, grain_strength: float) -> void:
	var albedo := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	var normal := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in range(512):
		for x in range(512):
			var color: Color = _pattern_color(pattern, x, y, base, line, tile_w, tile_h, noise_strength, grain_strength)
			albedo.set_pixel(x, y, Color(color.r, color.g, color.b, 1.0))
			normal.set_pixel(x, y, _pattern_normal(pattern, x, y, tile_w, tile_h))

	_save_png_pair(albedo, normal, base_name)


func _pattern_color(pattern: String, x: int, y: int, base: Color, line: Color, tile_w: int, tile_h: int, noise_strength: float, grain_strength: float) -> Color:
	var noise: float = (_hash01(x, y) - 0.5) * noise_strength
	var broad: float = sin(float(x) * 0.027) * grain_strength + sin(float(y) * 0.021) * grain_strength
	match pattern:
		"limestone_wall":
			var cell_x: int = int(floor(float(x) / float(tile_w)))
			var cell_y: int = int(floor(float(y) / float(tile_h)))
			var local_x: int = x % tile_w
			var local_y: int = y % tile_h
			var soft_joint: bool = local_x == 0 or local_y == 0
			var cell_tint: float = (_hash01(cell_x, cell_y) - 0.5) * 0.055
			var stain: float = (sin(float(x) * 0.009 + float(cell_y)) + sin(float(y) * 0.013 + float(cell_x))) * 0.018
			if soft_joint:
				return _shade_color(base.lerp(line, 0.28), noise + cell_tint - 0.025)
			return _shade_color(base, noise + broad + cell_tint + stain)
		"stone_floor":
			var floor_row: int = int(floor(float(y) / float(tile_h)))
			var floor_offset: int = (floor_row % 3) * int(tile_w / 3)
			var floor_x: int = (x + floor_offset) % tile_w
			var floor_y: int = y % tile_h
			var floor_seam: bool = floor_x <= 1 or floor_y <= 1
			var slab_tint: float = (_hash01(int((x + floor_offset) / tile_w), floor_row) - 0.5) * 0.075
			var crack: bool = _hash01(x / 3, y / 3) > 0.985 and (x + y) % 5 == 0
			return line.darkened(0.08) if crack else line if floor_seam else _shade_color(base, noise + broad + slab_tint)
		"aged_wood":
			var board_x: int = x % tile_w
			var board_seam: bool = board_x <= 1
			var board_index: int = int(floor(float(x) / float(tile_w)))
			var board_tint: float = (_hash01(board_index, 3) - 0.5) * 0.07
			var wood_grain: float = sin(float(y) * 0.055 + float(board_index) * 1.7) * 0.025 + sin(float(y) * 0.16 + float(x) * 0.015) * 0.012
			return line if board_seam else _shade_color(base, noise + board_tint + wood_grain)
		"terracotta_roof":
			var roof_row: int = int(floor(float(y) / float(tile_h)))
			var roof_offset: int = (roof_row % 2) * int(tile_w / 2)
			var roof_x: int = (x + roof_offset) % tile_w
			var roof_y: int = y % tile_h
			var roof_seam: bool = roof_x <= 1 or roof_y <= 1
			var tile_tint: float = (_hash01(int((x + roof_offset) / tile_w), roof_row) - 0.5) * 0.055
			return line if roof_seam else _shade_color(base, noise + broad + tile_tint)
		"market_fabric":
			var red_side: bool = x < 256
			var fabric_base: Color = base if red_side else line
			var stripe: float = abs(sin(float(x) * 0.055)) * 0.018 + sin(float(y) * 0.035) * 0.014
			return _shade_color(fabric_base, noise + stripe)
		_:
			return _shade_color(base, noise + broad)


func _pattern_normal(pattern: String, x: int, y: int, tile_w: int, tile_h: int) -> Color:
	match pattern:
		"limestone_wall", "terracotta_roof":
			if pattern == "limestone_wall":
				return Color(0.5, 0.5, 1.0, 1.0)
			var row: int = int(floor(float(y) / float(tile_h)))
			var offset: int = (row % 2) * int(tile_w / 2)
			var seam: bool = (x + offset) % tile_w == 0 or y % tile_h == 0
			return Color(0.485, 0.485, 0.94, 1.0) if seam else Color(0.5, 0.5, 1.0, 1.0)
		"stone_floor":
			var seam: bool = x % tile_w <= 1 or y % tile_h <= 1
			return Color(0.488, 0.488, 0.945, 1.0) if seam else Color(0.5, 0.5, 1.0, 1.0)
		"aged_wood":
			var seam: bool = x % tile_w <= 1
			return Color(0.49, 0.49, 0.95, 1.0) if seam else Color(0.5, 0.5, 1.0, 1.0)
		_:
			return Color(0.5, 0.5, 1.0, 1.0)


func _shade_color(color: Color, amount: float) -> Color:
	if amount >= 0.0:
		return color.lightened(clamp(amount, 0.0, 0.16))
	return color.darkened(clamp(abs(amount), 0.0, 0.14))


func _save_png_pair(albedo: Image, normal: Image, base_name: String) -> void:
	_save_png(albedo, "%s/%s_albedo.png" % [TEXTURE_DIR, base_name])
	_save_png(normal, "%s/%s_normal.png" % [TEXTURE_DIR, base_name])
	_save_png(albedo, "%s/hd2d_market_plaza_%s_albedo.png" % [MODEL_TEXTURE_DIR, base_name])
	_save_png(normal, "%s/hd2d_market_plaza_%s_normal.png" % [MODEL_TEXTURE_DIR, base_name])


func _save_png(image: Image, path: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Failed to save %s: %s" % [path, error_string(error)])


func _hash01(x: int, y: int) -> float:
	var value := int(x * 374761393 + y * 668265263)
	value = int((value ^ (value >> 13)) * 1274126177)
	return float(value & 65535) / 65535.0
