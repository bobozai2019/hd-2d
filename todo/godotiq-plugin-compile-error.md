# GodotIQ 插件编译失败，check_errors 等工具不可用

**发现时间**：2026-06-17

## 现象

- `godotiq_ping` 正常返回（走 MCP 代理层，不经过 Godot 编辑器）
- `godotiq_check_errors` 等需要连编辑器内服务的工具全部报错：`Failed to connect to 127.0.0.1:6007: [WinError 1225] 远程计算机拒绝网络连接`
- Godot 编辑器启动时 editor.log 有以下报错：

```
Parse Error: Static function "set_run_instances_config()" not found in base "GDScriptNativeClass".
Parse Error: Cannot infer the type of "single_err" variable because the value doesn't have a set type.
Compile Error: Failed to compile depended scripts.
Failed to load script "res://addons/godotiq/godotiq_plugin.gd" with error "Compilation failed".
```

## 原因

GodotIQ 0.5.4 与 Godot 4.7.beta (dff2b9bb6) 不兼容。插件调用了 `set_run_instances_config()` 静态方法，该 API 在当前 Godot 版本中不存在或签名变更。

## 当前尝试

- `godot --headless --quit` 验证场景加载 — 通过，无报错
- `godotiq_ping` — 正常，版本 0.5.4
- `godotiq_check_errors` — 连接失败

## 待办

- 升级 GodotIQ 插件到 0.5.13（当前最新），验证兼容性
