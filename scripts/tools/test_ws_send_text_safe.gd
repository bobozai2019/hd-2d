extends SceneTree
# 测试 _send_text_safe 消息大小守卫（Fix B）
# 运行: godot -s scripts/tools/test_ws_send_text_safe.gd
#
# 注意: 无法在 headless 中直接测试 WebSocket 发送行为。
# 本测试验证大小计算逻辑和边界条件。
# 完整集成测试需通过 godotiq_run + godotiq_input 在运行时验证。

const WS_MAX_MESSAGE_BYTES: int = 65536


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- Test 1: 空字符串大小为 0 ---
	print("[Test 1] 空字符串 UTF-8 大小应为 0")
	var empty := ""
	var size := empty.to_utf8_buffer().size()
	if size == 0:
		print("  PASS: size = %d" % size)
		passed += 1
	else:
		print("  FAIL: size = %d, expected 0" % size)
		failed += 1

	# --- Test 2: ASCII 字符串大小 = 字符数 ---
	print("[Test 2] ASCII 字符串 UTF-8 大小应等于字符数")
	var ascii_msg := "hello world"
	var ascii_size := ascii_msg.to_utf8_buffer().size()
	if ascii_size == 11:
		print("  PASS: size = %d" % ascii_size)
		passed += 1
	else:
		print("  FAIL: size = %d, expected 11" % ascii_size)
		failed += 1

	# --- Test 3: 中文字符 UTF-8 = 3 字节/字 ---
	print("[Test 3] 中文字符 UTF-8 应为 3 字节/字")
	var cn_msg := "你好"  # 2 个中文字符
	var cn_size := cn_msg.to_utf8_buffer().size()
	if cn_size == 6:
		print("  PASS: size = %d (2 chars * 3 bytes)" % cn_size)
		passed += 1
	else:
		print("  FAIL: size = %d, expected 6" % cn_size)
		failed += 1

	# --- Test 4: 超大 base64 payload 应超过阈值 ---
	print("[Test 4] 超大 base64 payload 应被识别为过大")
	# 模拟截图响应: 70KB base64 + JSON 封装 → 必然超 65536
	var fake_b64 := ""
	for i in range(70000):
		fake_b64 += "A"
	var fake_json := '{"image":"%s","format":"webp","width":960,"height":540}' % fake_b64
	var json_size := fake_json.to_utf8_buffer().size()
	if json_size > WS_MAX_MESSAGE_BYTES:
		print("  PASS: %d bytes > %d (会触发丢弃)" % [json_size, WS_MAX_MESSAGE_BYTES])
		passed += 1
	else:
		print("  FAIL: %d bytes <= %d (测试数据有误)" % [json_size, WS_MAX_MESSAGE_BYTES])
		failed += 1

	# --- Test 5: 刚好在阈值内的消息 ---
	print("[Test 5] 刚好 <= 65536 字节的消息应被允许")
	var ok_msg := ""
	for i in range(65536):
		ok_msg += "x"
	var ok_size := ok_msg.to_utf8_buffer().size()
	if ok_size <= WS_MAX_MESSAGE_BYTES:
		print("  PASS: %d bytes <= %d" % [ok_size, WS_MAX_MESSAGE_BYTES])
		passed += 1
	else:
		print("  FAIL: %d bytes > %d" % [ok_size, WS_MAX_MESSAGE_BYTES])
		failed += 1

	# --- Test 6: 超过阈值 1 字节的消息 ---
	print("[Test 6] 超过 65536 字节的消息应被识别为过大")
	var over_msg := ""
	for i in range(65537):
		over_msg += "x"
	var over_size := over_msg.to_utf8_buffer().size()
	if over_size > WS_MAX_MESSAGE_BYTES:
		print("  PASS: %d bytes > %d (会触发丢弃)" % [over_size, WS_MAX_MESSAGE_BYTES])
		passed += 1
	else:
		print("  FAIL: %d bytes <= %d" % [over_size, WS_MAX_MESSAGE_BYTES])
		failed += 1

	# --- Test 7: 典型截图 payload 应超过阈值 ---
	print("[Test 7] 典型截图 payload (1920x1080) 应超过阈值")
	# 1920x1080 填充密集噪声 → webp 不可压缩 → base64 后必然超 65536
	var img := Image.create(1920, 1080, false, Image.FORMAT_RGBA8)
	for y in range(0, 1080, 2):
		for x in range(0, 1920, 2):
			img.set_pixel(x, y, Color(randf(), randf(), randf()))
	var raw := img.save_webp_to_buffer(true, 0.5)
	var b64 := Marshalls.raw_to_base64(raw)
	var payload := JSON.stringify({"image": b64, "format": "webp", "width": 1920, "height": 1080})
	var payload_size := payload.to_utf8_buffer().size()
	print("  INFO: raw=%d, b64=%d, payload=%d bytes" % [raw.size(), b64.length(), payload_size])
	if payload_size > WS_MAX_MESSAGE_BYTES:
		print("  PASS: payload %d > %d (截图会触发体积保护)" % [payload_size, WS_MAX_MESSAGE_BYTES])
		passed += 1
	else:
		print("  FAIL: payload %d <= %d (预期应超限)" % [payload_size, WS_MAX_MESSAGE_BYTES])
		failed += 1

	# --- 汇总 ---
	print("\n=== 结果: %d passed, %d failed ===" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
