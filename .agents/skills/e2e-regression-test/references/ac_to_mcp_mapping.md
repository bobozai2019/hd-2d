# 验收标准 → MCP 工具映射

将 PRD 中的验收标准（AC）转换为 GodotIQ MCP 测试步骤的模式库。

## 映射表

| AC 模式 | MCP 工具 | 断言类型 | 备注 |
|---------|----------|----------|------|
| "X 应显示/可见" | `godotiq_ui_map` + `_find_node_by_name` | `contains_search` | 递归搜索 UI 树 |
| "X 节点存在" | `godotiq_find_node` | `true` (found) | 比 ui_map 更快更可靠 |
| "状态值 Y = Z" | `godotiq_state_inspect` | `eq` | 支持嵌套属性和方法调用 |
| "点击 X 后发生 Y" | `godotiq_press_button` → `godotiq_state_inspect` | `true` + `eq` | 两步：操作 + 验证 |
| "无运行时错误" | `godotiq_read_debug_console` | `eq` (count, 0) | 每个测试用例结尾必加 |
| "场景切换到 X" | `godotiq_find_node` 或 `godotiq_game_scene_tree` | `true` (found) | 场景切换后用 find_node |
| "信号 X 被触发" | `godotiq_watch(start)` → 操作 → `godotiq_watch(read)` | `true` | 监控属性变化 |
| "动画播放" | `godotiq_verify_motion` | `true` (MOVING) | 两次快照比较 |
| "UI 文本 = X" | `godotiq_state_inspect` 查询 label.text | `eq` | 直接读属性比截图可靠 |
| "按钮可点击" | `godotiq_press_button` | `eq` (status, "pressed") | 直接 emit_signal |
| "元素不可见" | `godotiq_find_node` | `true` (not found) | 节点不存在 = 不可见 |
| "性能指标" | `godotiq_perf_snapshot` | 自定义 | FPS/内存/绘制调用 |

## AC 动词解析规则

### 验证类

- **"应显示" / "应可见" / "应存在"** → `godotiq_find_node(name=X)` + `assert found=true`
- **"应包含" / "应有"** → `godotiq_state_inspect` 或 `godotiq_game_scene_tree` + 断言
- **"应等于" / "应为"** → `godotiq_state_inspect` + `assert_eq`
- **"应不为" / "不应有"** → `godotiq_state_inspect` + 反向断言

### 交互类

- **"点击" / "按下" / "选择"** → `godotiq_press_button(name=X)` 或 `godotiq_input(tap=X)`
- **"拖拽"** → `godotiq_input(drag_at={...})`
- **"输入"** → `godotiq_input(key=X)` 或多次 key 调用
- **"等待"** → `godotiq_input(wait_ms=N)` 或 `wait_for="signal:..."`

### 导航类

- **"进入" / "打开" / "切换到"** → 交互触发 + `godotiq_find_node` 验证目标场景
- **"返回" / "退出"** → 按钮触发 + 验证原场景节点

## 步骤组合模式

### 模式 A: 状态验证（最简单）

AC: "AP 应为 3"

```
Step 1: godotiq_state_inspect(queries=[{node: "/root/...", properties: ["ap"]}])
  → assert eq actual_key="results.0.properties.ap" expected=3
```

### 模式 B: 交互 + 状态验证

AC: "点击结束回合后，回合数应增加"

```
Step 1: godotiq_press_button(name="EndTurnButton")
  → assert eq status="pressed"
Step 2: godotiq_state_inspect(queries=[{node: "/root/...", properties: ["turn_index"]}])
  → assert eq expected=2
```

### 模式 C: 场景导航验证

AC: "启动后应进入主场景"

```
Step 1: godotiq_press_button(name="StartButton")
  → assert eq status="pressed"
Step 2: godotiq_find_node(name="MainScreen")
  → assert true found=true
```

### 模式 D: UI 元素存在性验证

AC: "主界面应显示状态信息"

```
Step 1: godotiq_find_node(name="StatusLabel")
  → assert true found=true
Step 2: godotiq_state_inspect(queries=[{node: "/root/.../StatusLabel", properties: ["text"]}])
  → assert eq expected="Ready"
```

### 模式 E: 信号/属性变化验证

AC: "操作后状态应更新"

```
Step 1: godotiq_state_inspect(queries=[{autoload: "GameState", properties: ["score"]}])
  → 记录初始值
Step 2: godotiq_press_button(name="ActionButton")
  → assert eq status="pressed"
Step 3: godotiq_state_inspect(queries=[{autoload: "GameState", properties: ["score"]}])
  → assert eq expected=预期值
```

## 强制规则

1. **动态发现** — 永远不硬编码 UI 元素坐标，用 `godotiq_find_node` 或 `godotiq_ui_map` 运行时查找
2. **press_button > tap** — `godotiq_press_button` 直接 emit_signal，在 ScrollContainer 和 CanvasLayer 上更可靠
3. **game_scene_tree > ui_map** — 场景切换后用 `godotiq_game_scene_tree` 验证，`ui_map` 返回缓存数据
4. **每用例结尾检查错误** — 最后一步固定 `godotiq_read_debug_console` 确认无运行时错误
5. **重试机制** — 场景切换后的首次查询加 retry（首次加载可能超时）
