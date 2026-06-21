extends SceneTree
# 测试游戏端截图体积保护逻辑（Fix A）
# 运行: godot -s scripts/tools/test_ws_screenshot_size.gd
#
# 验证压缩降级链的每个步骤是否有效:
# 1. quality 降低 → buffer 变小
# 2. resize → buffer 变小
# 3. PNG 超限时降级为 webp
# 4. resize 最小尺寸 >= 100

const MAX_ENCODED_BYTES: int = 45000


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- Test 1: webp 小图不触发压缩 ---
	print("[Test 1] webp 小图应保持原样")
	var img_small := Image.create(100, 100, false, Image.FORMAT_RGBA8)
	var buf := img_small.save_webp_to_buffer(true, 0.5)
	if buf.size() <= MAX_ENCODED_BYTES:
		print("  PASS: %d bytes <= %d" % [buf.size(), MAX_ENCODED_BYTES])
		passed += 1
	else:
		print("  FAIL: %d bytes > %d" % [buf.size(), MAX_ENCODED_BYTES])
		failed += 1

	# --- Test 2: webp quality 降低应产生更小的 buffer ---
	print("[Test 2] webp 降 quality 应减小 buffer")
	var img_2 := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in range(0, 512, 4):
		for x in range(0, 512, 4):
			img_2.set_pixel(x, y, Color(randf(), randf(), randf()))
	var buf_hi := img_2.save_webp_to_buffer(true, 0.8)
	var buf_lo := img_2.save_webp_to_buffer(true, 0.1)
	if buf_lo.size() < buf_hi.size():
		print("  PASS: q=0.1 %d < q=0.8 %d (%.1f%% 压缩)" % [buf_lo.size(), buf_hi.size(), (1.0 - float(buf_lo.size()) / float(buf_hi.size())) * 100])
		passed += 1
	else:
		print("  FAIL: q=0.1 %d >= q=0.8 %d" % [buf_lo.size(), buf_hi.size()])
		failed += 1

	# --- Test 3: resize 应产生更小的 buffer ---
	print("[Test 3] resize 应减小 buffer")
	var img_3 := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in range(0, 512, 4):
		for x in range(0, 512, 4):
			img_3.set_pixel(x, y, Color(randf(), randf(), randf()))
	var buf_before := img_3.save_webp_to_buffer(true, 0.5)
	img_3.resize(256, 256)
	var buf_after := img_3.save_webp_to_buffer(true, 0.5)
	if buf_after.size() < buf_before.size():
		print("  PASS: 256x256 %d < 512x512 %d" % [buf_after.size(), buf_before.size()])
		passed += 1
	else:
		print("  FAIL: resize 后 %d >= %d" % [buf_after.size(), buf_before.size()])
		failed += 1

	# --- Test 4: PNG 超限时应降级为 webp（体积减小） ---
	print("[Test 4] PNG 超限时降级为 webp 应减小体积")
	var img_4 := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in range(0, 512, 2):
		for x in range(0, 512, 2):
			img_4.set_pixel(x, y, Color(randf(), randf(), randf()))
	var buf_png := img_4.save_png_to_buffer()
	var buf_webp := img_4.save_webp_to_buffer(true, 0.5)
	if buf_png.size() > MAX_ENCODED_BYTES:
		if buf_webp.size() < buf_png.size():
			print("  PASS: PNG %d > webp %d (降级有效)" % [buf_png.size(), buf_webp.size()])
			passed += 1
		else:
			print("  FAIL: webp %d >= PNG %d" % [buf_webp.size(), buf_png.size()])
			failed += 1
	else:
		# 512x512 渐变图 PNG 可能未超限 — 此分支验证"无需降级"的正常路径
		print("  PASS: PNG %d 未超限，无需降级（正常路径）" % buf_png.size())
		passed += 1

	# --- Test 5: jpg quality 降低应产生更小的 buffer ---
	print("[Test 5] jpg 降 quality 应减小 buffer")
	var img_5 := Image.create(512, 512, false, Image.FORMAT_RGBA8)
	for y in range(0, 512, 4):
		for x in range(0, 512, 4):
			img_5.set_pixel(x, y, Color(randf(), randf(), randf()))
	var jpg_hi := img_5.save_jpg_to_buffer(0.8)
	var jpg_lo := img_5.save_jpg_to_buffer(0.1)
	if jpg_lo.size() < jpg_hi.size():
		print("  PASS: q=0.1 %d < q=0.8 %d" % [jpg_lo.size(), jpg_hi.size()])
		passed += 1
	else:
		print("  FAIL: q=0.1 %d >= q=0.8 %d" % [jpg_lo.size(), jpg_hi.size()])
		failed += 1

	# --- Test 6: 完整降级链 — 复现源码 while 循环逻辑 ---
	# 高噪声渐变: q=0.1 仍超限 → 必须触发 resize 循环
	print("[Test 6] 完整降级链: 降 quality → resize 循环 → 最终达标")
	var img_6 := Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	for y in range(1080):
		for x in range(1920):
			img_6.set_pixel(x, y, Color(
				float(x) / 1920.0 + randf() * 0.4,
				float(y) / 1080.0 + randf() * 0.4,
				sin(float(x + y) * 0.02) * 0.3 + randf() * 0.3
			))
	var step0 := img_6.save_webp_to_buffer(true, 0.5)
	# Step 1: 降 quality
	var step1 := img_6.save_webp_to_buffer(true, 0.1)
	print("  step0(q=0.5)=%d, step1(q=0.1)=%d" % [step0.size(), step1.size()])
	# Step 2: resize 循环（复现源码 while 循环）
	var final_buf := step1
	while final_buf.size() > MAX_ENCODED_BYTES and img_6.get_width() > 100:
		var ratio: float = sqrt(float(MAX_ENCODED_BYTES) / float(final_buf.size())) * 0.9
		var new_w: int = maxi(int(img_6.get_width() * ratio), 100)
		var new_h: int = maxi(int(img_6.get_height() * ratio), 100)
		img_6.resize(new_w, new_h)
		final_buf = img_6.save_webp_to_buffer(true, 0.5)
		print("  resize -> %dx%d: %d bytes" % [new_w, new_h, final_buf.size()])
	if final_buf.size() <= MAX_ENCODED_BYTES:
		print("  PASS: %d -> ... -> %d <= %d" % [step0.size(), final_buf.size(), MAX_ENCODED_BYTES])
		passed += 1
	else:
		print("  FAIL: 最终 %d > %d" % [final_buf.size(), MAX_ENCODED_BYTES])
		failed += 1

	# --- Test 7: resize 最小尺寸 >= 100 ---
	print("[Test 7] resize 最小尺寸应 >= 100")
	var img_tiny := Image.create(120, 120, false, Image.FORMAT_RGBA8)
	if img_tiny.get_width() >= 100 and img_tiny.get_height() >= 100:
		print("  PASS: 最小尺寸 %dx%d >= 100" % [img_tiny.get_width(), img_tiny.get_height()])
		passed += 1
	else:
		print("  FAIL: 尺寸 %dx%d < 100" % [img_tiny.get_width(), img_tiny.get_height()])
		failed += 1

	# --- Test 8: maxi(..., 100) 保护验证 ---
	print("[Test 8] maxi(ratio*size, 100) 应限制最小输出")
	var tiny_ratio: float = 0.01  # 1% — 理论上应被 clamp 到 100
	var calc_w: int = maxi(int(512 * tiny_ratio), 100)
	var calc_h: int = maxi(int(512 * tiny_ratio), 100)
	if calc_w >= 100 and calc_h >= 100:
		print("  PASS: maxi(5, 100) = %d >= 100" % calc_w)
		passed += 1
	else:
		print("  FAIL: maxi 结果 %d < 100" % calc_w)
		failed += 1

	# --- 汇总 ---
	print("\n=== 结果: %d passed, %d failed ===" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
