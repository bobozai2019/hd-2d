# 录制 JSON Schema

E2E 回归测试录制数据的正式格式定义。Claude 在 Phase 2 录制过程中严格按此 schema 生成 JSON。

## 顶层结构

```json
{
  "feature": "feature_name",
  "prd_path": "tasks/prd-feature.md",
  "recorded_at": "2026-05-30T10:00:00",
  "test_cases": [...],
  "environment": {
    "mcp_server": "python -m godotiq.server",
    "godot_version": "4.7",
    "scene": "main"
  }
}
```

| 字段 | 类型 | 必填 | 描述 |
|------|------|------|------|
| `feature` | string | 是 | 功能名称，kebab-case |
| `prd_path` | string | 是 | PRD 文件路径 |
| `recorded_at` | string | 是 | ISO 8601 时间戳 |
| `test_cases` | array | 是 | 测试用例列表 |
| `environment` | object | 是 | 测试环境信息 |

## 测试用例结构

```json
{
  "id": "TC-001",
  "source_ac": "US-001 AC-1",
  "description": "验证玩家选择弓箭手后进入地图",
  "status": "PASS",
  "steps": [...],
  "blocker": null
}
```

| 字段 | 类型 | 必填 | 描述 |
|------|------|------|------|
| `id` | string | 是 | 测试用例 ID，`TC-NNN` 格式 |
| `source_ac` | string | 是 | 来源验收标准，回溯到 PRD |
| `description` | string | 是 | 测试用例描述 |
| `status` | string | 是 | `PASS` / `FAIL` / `BLOCKED` / `SKIPPED` |
| `steps` | array | 是 | 测试步骤列表 |
| `blocker` | string/null | 否 | 阻塞原因（status=BLOCKED 时必填） |

## 步骤结构

```json
{
  "step": 1,
  "description": "启动游戏主场景",
  "tool": "godotiq_run",
  "params": {"action": "play", "scene": "main"},
  "result_summary": "游戏启动成功",
  "result_raw": {"success": true},
  "assertion": null
}
```

| 字段 | 类型 | 必填 | 描述 |
|------|------|------|------|
| `step` | int | 是 | 步骤序号（从 1 开始） |
| `description` | string | 是 | 步骤描述 |
| `tool` | string | 是 | MCP 工具名称 |
| `params` | object | 是 | 工具参数 |
| `result_summary` | string | 是 | 人类可读的结果摘要 |
| `result_raw` | any | 否 | MCP 返回的原始数据（可选，大结果可省略） |
| `assertion` | object/null | 否 | 断言定义（见下文） |

## 断言结构

### eq — 相等断言

```json
{
  "type": "eq",
  "actual_key": "results.0.properties.ap",
  "expected": 3,
  "message": "AP 应为 3"
}
```

从 MCP 返回结果中按 `actual_key`（点号分隔的嵌套路径）提取实际值，与 `expected` 比较。

### true — 真值断言

```json
{
  "type": "true",
  "actual_key": "found",
  "expected": true,
  "message": "节点应存在"
}
```

提取的值必须为 truthy。

### contains — 包含断言

```json
{
  "type": "contains",
  "actual_key": "names",
  "expected": "StartBattleButton",
  "message": "应包含 StartBattleButton"
}
```

提取的容器必须包含 `expected` 值。

### contains_search — UI 递归搜索断言

```json
{
  "type": "contains_search",
  "search_key": "name",
  "expected": "StartBattleButton",
  "message": "UI 树应包含 StartBattleButton 节点"
}
```

递归搜索 `godotiq_ui_map` 返回的 layout 数组，按 `search_key` 匹配。此断言类型需要在生成的 Python 脚本中使用 `_find_node_by_name` 辅助函数。

## 完整示例

```json
{
  "feature": "career-select-to-battle",
  "prd_path": "tasks/prd-career-system.md",
  "recorded_at": "2026-05-22T14:30:00",
  "test_cases": [
    {
      "id": "TC-001",
      "source_ac": "US-001 AC-1",
      "description": "从主菜单选择弓箭手进入地图",
      "status": "PASS",
      "steps": [
        {
          "step": 1,
          "description": "启动游戏主场景",
          "tool": "godotiq_run",
          "params": {"action": "play", "scene": "main"},
          "result_summary": "游戏启动成功",
          "assertion": null
        },
        {
          "step": 2,
          "description": "发现主菜单 StartBattleButton",
          "tool": "godotiq_ui_map",
          "params": {},
          "result_summary": "在 UI 树中找到 StartBattleButton",
          "assertion": {
            "type": "contains_search",
            "search_key": "name",
            "expected": "StartBattleButton",
            "message": "主菜单应包含 StartBattleButton"
          }
        },
        {
          "step": 3,
          "description": "点击 StartBattleButton",
          "tool": "godotiq_press_button",
          "params": {"name": "StartBattleButton"},
          "result_summary": "pressed 信号触发成功",
          "assertion": {
            "type": "eq",
            "actual_key": "status",
            "expected": "pressed",
            "message": "按钮应成功触发"
          }
        },
        {
          "step": 4,
          "description": "验证 CareerSelect 加载",
          "tool": "godotiq_find_node",
          "params": {"name": "CareerSelect"},
          "result_summary": "CareerSelect 节点存在",
          "assertion": {
            "type": "true",
            "actual_key": "found",
            "expected": true,
            "message": "CareerSelect 应已加载"
          }
        },
        {
          "step": 5,
          "description": "检查无运行时错误",
          "tool": "godotiq_read_debug_console",
          "params": {"limit": 10},
          "result_summary": "0 个运行时错误",
          "assertion": {
            "type": "eq",
            "actual_key": "runtime_errors_total",
            "expected": 0,
            "message": "不应有运行时错误"
          }
        }
      ],
      "blocker": null
    }
  ],
  "environment": {
    "mcp_server": "python -m godotiq.server",
    "godot_version": "4.7",
    "scene": "main"
  }
}
```
