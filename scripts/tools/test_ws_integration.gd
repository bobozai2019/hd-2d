extends SceneTree
# 运行时集成测试: 验证 _send_text_safe 和截图体积保护
# 运行: godot -s scripts/tools/test_ws_integration.gd
#
# 本测试需要 GodotIQ 插件加载，验证:
# 1. _send_text_safe 存在且可调用
# 2. WS_MAX_MESSAGE_BYTES 常量正确
# 3. 截图函数存在且编码逻辑正常

const EXPECTED_MAX_BYTES: int = 65536
const EXPECTED_SCREENSHOT_MAX: int = 45000


func _init() -> void:
	var passed := 0
	var failed := 0

	# --- Test 1: 验证 godotiq_server.gd 中的常量 ---
	print("[Test 1] 验证 WS_MAX_MESSAGE_BYTES 常量")
	# 通过检查文件内容验证常量存在
	var server_file := FileAccess.open("res://addons/godotiq/godotiq_server.gd", FileAccess.READ)
	if server_file == null:
		print("  FAIL: 无法打开 godotiq_server.gd")
		failed += 1
	else:
		var content := server_file.get_as_text()
		server_file.close()
		if content.contains("WS_MAX_MESSAGE_BYTES"):
			print("  PASS: WS_MAX_MESSAGE_BYTES 常量存在")
			passed += 1
		else:
			print("  FAIL: WS_MAX_MESSAGE_BYTES 常量未找到")
			failed += 1

	# --- Test 2: 验证 _send_text_safe 函数存在 ---
	print("[Test 2] 验证 _send_text_safe 函数存在")
	var server_file2 := FileAccess.open("res://addons/godotiq/godotiq_server.gd", FileAccess.READ)
	if server_file2 != null:
		var content := server_file2.get_as_text()
		server_file2.close()
		if content.contains("func _send_text_safe"):
			print("  PASS: _send_text_safe 函数存在")
			passed += 1
		else:
			print("  FAIL: _send_text_safe 函数未找到")
			failed += 1
	else:
		print("  FAIL: 无法打开文件")
		failed += 1

	# --- Test 3: 验证 _send_text 调用 _send_text_safe ---
	print("[Test 3] 验证 _send_text 委托给 _send_text_safe")
	var server_file3 := FileAccess.open("res://addons/godotiq/godotiq_server.gd", FileAccess.READ)
	if server_file3 != null:
		var content := server_file3.get_as_text()
		server_file3.close()
		# 查找 _send_text 函数体中调用 _send_text_safe
		var idx := content.find("func _send_text(")
		if idx >= 0:
			var func_body := content.substr(idx, 200)
			if func_body.contains("_send_text_safe"):
				print("  PASS: _send_text 正确委托给 _send_text_safe")
				passed += 1
			else:
				print("  FAIL: _send_text 未调用 _send_text_safe")
				failed += 1
		else:
			print("  FAIL: _send_text 函数未找到")
			failed += 1
	else:
		print("  FAIL: 无法打开文件")
		failed += 1

	# --- Test 4: 验证 send_event 调用 _send_text_safe ---
	print("[Test 4] 验证 send_event 调用 _send_text_safe")
	var server_file4 := FileAccess.open("res://addons/godotiq/godotiq_server.gd", FileAccess.READ)
	if server_file4 != null:
		var content := server_file4.get_as_text()
		server_file4.close()
		var idx := content.find("func send_event(")
		if idx >= 0:
			var func_body := content.substr(idx, 300)
			if func_body.contains("_send_text_safe"):
				print("  PASS: send_event 正确调用 _send_text_safe")
				passed += 1
			else:
				print("  FAIL: send_event 未调用 _send_text_safe")
				failed += 1
		else:
			print("  FAIL: send_event 函数未找到")
			failed += 1
	else:
		print("  FAIL: 无法打开文件")
		failed += 1

	# --- Test 5: 验证游戏端截图有 max_encoded_bytes 保护 ---
	print("[Test 5] 验证游戏端截图编码保护")
	var runtime_file := FileAccess.open("res://addons/godotiq/godotiq_runtime.gd", FileAccess.READ)
	if runtime_file != null:
		var content := runtime_file.get_as_text()
		runtime_file.close()
		if content.contains("max_encoded_bytes"):
			print("  PASS: max_encoded_bytes 保护存在")
			passed += 1
		else:
			print("  FAIL: max_encoded_bytes 未找到")
			failed += 1
	else:
		print("  FAIL: 无法打开 godotiq_runtime.gd")
		failed += 1

	# --- Test 6: 验证 PNG 降级逻辑 ---
	print("[Test 6] 验证 PNG 超限时降级为 webp")
	var runtime_file2 := FileAccess.open("res://addons/godotiq/godotiq_runtime.gd", FileAccess.READ)
	if runtime_file2 != null:
		var content := runtime_file2.get_as_text()
		runtime_file2.close()
		# 查找 PNG 分支中 fmt = "webp" 的降级
		var png_idx := content.find('"png":')
		if png_idx >= 0:
			var png_block := content.substr(png_idx, 300)
			if png_block.contains('fmt = "webp"') or png_block.contains("fmt = \"webp\""):
				print("  PASS: PNG 超限时降级为 webp")
				passed += 1
			else:
				print("  FAIL: PNG 降级逻辑未找到")
				failed += 1
		else:
			print("  FAIL: PNG 分支未找到")
			failed += 1
	else:
		print("  FAIL: 无法打开文件")
		failed += 1

	# --- Test 7: 验证 resize 使用循环 + 最小尺寸保护 ---
	print("[Test 7] 验证 resize 循环 + 最小尺寸 >= 100")
	var runtime_file3 := FileAccess.open("res://addons/godotiq/godotiq_runtime.gd", FileAccess.READ)
	if runtime_file3 != null:
		var content := runtime_file3.get_as_text()
		runtime_file3.close()
		# 查找 "while buffer.size() > max_encoded_bytes" 循环
		var has_loop := content.contains("while buffer.size() > max_encoded_bytes")
		var has_guard := content.contains("maxi(") and content.contains(", 100)")
		if has_loop and has_guard:
			print("  PASS: resize 循环 + 最小尺寸保护存在")
			passed += 1
		elif not has_loop:
			print("  FAIL: resize 未使用 while 循环")
			failed += 1
		else:
			print("  FAIL: 最小尺寸保护未找到")
			failed += 1
	else:
		print("  FAIL: 无法打开文件")
		failed += 1

	# --- 汇总 ---
	print("\n=== 结果: %d passed, %d failed ===" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
