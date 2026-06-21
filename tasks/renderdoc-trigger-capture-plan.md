# RenderDoc 主动触发截帧方案（修订版）

> 创建时间：2026-06-22
> 状态：待实施

## Context

RenderDoc 截帧插件当前只能通过编辑器 UI 按钮（"Editor RDC" / "Game RDC"）触发。用户希望从 Claude Code 主动触发 Editor RDC 和 Game RDC 截帧。

三轮审核确认的核心约束：
1. `godotiq_exec` 不支持 `await`，无法在同步 `func run()` 中等待帧渲染
2. `godotiq_exec` 屏蔽 `FileAccess.open`，无法直接创建触发文件
3. `godotiq_exec` 无法访问 EditorPlugin 实例（不在场景树中）
4. `capture_frame()` C++ 同步实现缺少帧间等待，捕获数据可能无效
5. `godotiq_file_ops` 仅支持 `res://` 路径（不支持 `user://`）

## 方案：文件触发 + 插件 timer async 处理

通过 `godotiq_file_ops` 写入 `res://` 触发文件，插件 timer 检测后用 async 流程处理。

```
Claude Code:
  godotiq_file_ops(write, res://.renderdoc_trigger.json, {"mode":"editor"})
  └→ GodotIQ Python MCP → res:// 文件写入 ✓

Plugin (timer 0.5s):
  检测 res://.renderdoc_trigger.json
  → Editor: await _capture_editor_frame() → 写 res://.renderdoc_result.json
  → Game:  _request_game_capture() → 回调写 res://.renderdoc_result.json

Claude Code:
  godotiq_file_ops(read, res://.renderdoc_result.json)  (轮询)
  godotiq_exec → DirAccess.remove_absolute(清理)
```

## 触发/结果协议

### 触发文件 `res://.renderdoc_trigger.json`
```json
{"mode": "editor", "request_id": "optional-id"}
```
- `mode`：`"editor"` 或 `"game"`，默认 `"game"`
- `request_id`：可选，透传到结果

### 结果文件 `res://.renderdoc_result.json`
```json
{"ok": true, "path": "D:/.../editor_xxx.rdc", "request_id": "optional-id"}
```

### 原子写入
写入方先写 `.renderdoc_trigger.json.tmp`，完成后 rename 为 `.renderdoc_trigger.json`。插件只检测最终文件名。

## 修改文件

### 1. `addons/renderdoc_bridge/plugin.gd`（修改）

**新增常量**：
```gdscript
const TRIGGER_PATH := "res://.renderdoc_trigger.json"
const RESULT_PATH := "res://.renderdoc_result.json"
```

**新增变量**：
```gdscript
var _trigger_request_id: String = ""
var _trigger_mode: String = ""
```

**修改 `_on_timer_timeout()`**：末尾增加 `_check_trigger_file()` 调用

**新增 `_check_trigger_file()`**：
- 检查忙碌状态（`_editor_capture_in_progress` / `_game_capture_in_progress`），忙碌则跳过（下个周期重试）
- 读取并解析触发文件，删除触发文件
- 根据 mode 分发到 `_run_trigger_editor_capture()` 或 `_run_trigger_game_capture()`
- JSON null 防护：`JSON.parse_string()` 返回 null 时写回错误

**新增 `_run_trigger_editor_capture()`**：
- 调用 `await _capture_editor_frame()`（复用已验证的 async 流程，含帧间等待）
- 写回结果到 `RESULT_PATH`

**新增 `_run_trigger_game_capture()`**：
- 调用 `_request_game_capture()`，失败时立即写回错误
- 成功时等待 `_on_game_capture_result()` 回调

**修改 `_on_game_capture_result()`**：末尾增加 `_trigger_request_id` 非空时写回结果

**修改 `_on_game_capture_timeout()`**：末尾增加 `_trigger_request_id` 非空时写回超时错误

**新增 `_write_trigger_result(result)`**：写入 `RESULT_PATH`

### 2. `.claude/knowledge/renderdoc.md`（新建）

记录使用方法和先验知识。

### 3. `.gitignore`（修改）

增加：
```
.renderdoc_trigger.json
.renderdoc_trigger.json.tmp
.renderdoc_result.json
```

## 使用方式（Claude Code 端）

### Editor RDC 完整调用链

```
Step 1: godotiq_file_ops(op="write",
          path="res://.renderdoc_trigger.json",
          content='{"mode":"editor","request_id":"ed-001"}')

Step 2: godotiq_file_ops(op="read", path="res://.renderdoc_result.json")
        (轮询，间隔 1-2 秒，最多 30 秒)

Step 3: godotiq_exec(code='func run():
            DirAccess.remove_absolute("res://.renderdoc_result.json")
            return "ok"', context="editor")
```

### Game RDC 完整调用链

```
Step 0: godotiq_run(action="play")  (确保游戏在运行)

Step 1: godotiq_file_ops(op="write",
          path="res://.renderdoc_trigger.json",
          content='{"mode":"game","request_id":"gm-001"}')

Step 2: godotiq_file_ops(op="read", path="res://.renderdoc_result.json")
        (轮询，间隔 2 秒，最多 30 秒)

Step 3: 清理同上
```

## 验证

1. 确认 Godot 通过 `Start Godot RenderDoc.cmd` 启动
2. **Editor RDC**：执行上述 Step 1-3，检查 result 中 `ok: true` 且 `.rdc` 文件存在
3. **Game RDC**：先 Play 场景，执行 Step 1-3
4. **错误场景**：普通 Godot 启动下触发，确认收到 `"Not launched by bridge"` 错误
5. **并发**：UI 按钮截帧进行中时写入触发文件，确认收到 `"busy"` 延迟处理

## 已知限制

- **必须通过 RenderDoc 入口启动**：普通 Godot 启动会收到明确错误
- **0.5 秒延迟**：timer 轮询间隔导致触发到执行的最大延迟
- **Game RDC 异步**：需要游戏运行 + runtime 就绪 + debugger 通信
- **Windows only**：GDExtension 仅编译了 Windows 版本
- **结果文件残留**：调用者必须在读取后清理，否则下次可能读到旧数据
