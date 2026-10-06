---
name: e2e-regression-test
description: 在需要为游戏功能生成端到端回归测试、从需求推导测试流程、或录制 MCP 交互并生成可独立运行的 Python 测试脚本时使用。触发词：e2e test, regression test, 端对端测试, 回归测试, 录制测试
---

# E2E 回归测试

## 概述

从需求出发，通过 MCP 工具录制真实游戏交互，生成可独立运行的 Python 端到端回归测试脚本。四阶段流程：PRD → 测试用例规划 → MCP 录制 → Python 生成。零 exec 注入，所有操作严格通过 MCP。

## 何时使用

- 新功能需要端到端验收测试
- 用户描述测试场景（如"测试战斗流程"）
- 需要从 PRD 自动推导测试步骤
- 需要可独立运行的回归测试脚本

## 何时不使用

- 单元测试或集成测试 → 使用 `generate-test`
- 代码分析驱动的白盒测试 → 使用 `generate-test`
- 不需要独立脚本的手动验证 → 直接用 MCP 工具

## 命令格式

```bash
# 完整流程：需求 → PRD → 测试用例 → 录制 → 生成
/e2e-regression-test "玩家使用卡牌后 AP 减少，回合结束时敌人推进"

# 从设计文档生成
/e2e-regression-test --design docs/design/third/03-地图与Run流程设计.md

# 从已有 PRD 录制
/e2e-regression-test --prd tasks/prd-card-system.md

# 从录制数据生成脚本
/e2e-regression-test --from-recording .claude/e2e_recordings/card_test.json

# 指定场景
/e2e-regression-test "战斗遗物触发" --scene battle
```

## 四阶段流程

### Phase 0: PRD 生成

从设计文档或用户需求生成可测试的 PRD。

**输入来源（按优先级）：**
1. `--design` 指定的设计文档
2. `docs/design/` 下相关设计文档
3. 用户直接描述的需求

**流程：**
1. 读取设计文档，提取与目标功能相关的机制描述
2. 将游戏机制转换为可验证的验收标准（AC）
3. 调用 `prd` 技能生成结构化 PRD → `tasks/prd-{feature}.md`
4. 每个 AC 必须可验证（如"AP 减少 2"而非"正常工作"）

**AC 编写规则：**
- 使用具体数值而非模糊描述
- 每个 AC 对应一个可观察的状态变化
- 包含前置条件和预期结果
- 参考 `references/ac_to_mcp_mapping.md` 确保 AC 可通过 MCP 验证

**输出：** `tasks/prd-{feature}.md`

### Phase 1: 测试用例规划

将 PRD 的验收标准映射为结构化测试用例。

**流程：**
1. 解析 PRD 中所有用户故事和 AC
2. 按 `references/ac_to_mcp_mapping.md` 映射表，为每个 AC 选择 MCP 工具模式
3. 将相关 AC 组合为测试用例（TC），每个 TC 包含 1-N 个步骤
4. 标注每个 TC 的 `source_ac` 回溯到 PRD

**测试用例格式：**

```
TC-001: [描述]
  来源: US-001 AC-1, AC-2
  步骤:
    1. godotiq_run(play, scene=main) — 启动游戏
    2. godotiq_find_node(name=XXX) — 验证节点存在
    3. godotiq_press_button(name=YYY) — 触发交互
    4. godotiq_state_inspect(...) — 验证状态变化
    5. godotiq_read_debug_console(limit=10) — 无运行时错误
  预期: 全部通过
```

**输出：** 测试用例计划（文本），供用户审阅。

### Phase 1.5: 用户审阅检查点

**必须暂停，等待用户确认。**

输出格式：
```
📋 测试用例计划（共 N 个）

TC-001: [描述] ← US-001 AC-1
TC-002: [描述] ← US-002 AC-1, AC-2
...

请确认后开始录制（或调整测试用例）。
```

用户确认后才进入 Phase 2。

### Phase 2: MCP 交互录制

Claude 逐个测试用例执行 MCP 调用，按 `references/recording_schema.md` schema 记录每步。

**录制协议（每个测试用例）：**

1. `godotiq_reload_addon()` — 热重载确保最新代码
2. `godotiq_run(action="play", scene=...)` — 启动游戏
3. 按测试用例步骤依次执行 MCP 调用
4. 每步记录：`tool`, `params`, `result_summary`, `assertion`
5. 执行断言并记录 PASS/FAIL
6. `godotiq_read_debug_console(limit=10)` — 检查无运行时错误
7. `godotiq_run(action="stop")` — 清理

**动态 UI 发现规则（强制）：**

- 不硬编码 UI 元素名称或坐标
- 每步先用 `godotiq_find_node` 或 `godotiq_game_scene_tree` 发现可用元素
- 场景切换后用 `godotiq_find_node`（不依赖 `ui_map` 缓存）
- 按钮触发优先用 `godotiq_press_button`（直接 emit_signal，ScrollContainer 内更可靠）

**失败处理协议：**

1. 步骤失败 → 重试一次（可能是时序问题）
2. 仍失败 → 记录为 BLOCKED，捕获错误信息
3. 继续下一个测试用例（除非是基础性阻塞如游戏无法启动）
4. 录制结束后输出阻塞报告

**中间保存：** 每完成一个测试用例，立即追加到 `.claude/e2e_recordings/{feature}_{date}.json`

### Phase 2.5: 录制结果审阅

**必须暂停，等待用户确认。**

输出格式：
```
📊 录制结果

✅ TC-001: PASS — [描述]
✅ TC-002: PASS — [描述]
❌ TC-003: BLOCKED — [描述]
   阻塞原因: [错误信息]
✅ TC-004: PASS — [描述]

通过: 3/4 | 阻塞: 1/4

请选择:
  a) 修复阻塞问题后重新录制 TC-003
  b) 跳过 TC-003，只生成通过的测试脚本
  c) 中止
```

### Phase 3: Python 脚本生成

将录制数据转换为可独立运行的 Python 测试脚本。

**脚本结构（基于 `templates/test_template.py`）：**

```python
#!/usr/bin/env python3
import asyncio, os, sys
from pathlib import Path

# 本地 godotiq 包路径
_local_pkg = str(Path(__file__).resolve().parents[2] / "addons" / "godotiq")
if _local_pkg not in sys.path:
    sys.path.insert(0, _local_pkg)
sys.path.insert(0, str(Path(__file__).parent))

from mcp_test_runner import MCPTestRunner, TestResult, TestStep
from helpers import ui_map_with_retry, verify_node_exists, ...

MCP_SERVER_CMD = "python"
MCP_SERVER_ARGS = ["-m", "godotiq.server"]

async def test_{feature}():
    _env = {**os.environ, "PYTHONPATH": _local_pkg}
    runner = MCPTestRunner(server_cmd=MCP_SERVER_CMD, server_args=MCP_SERVER_ARGS, env=_env)
    await runner.connect()
    result = TestResult(name="{feature}")
    try:
        # 热重载
        await runner.call("godotiq_reload_addon")
        await asyncio.sleep(1)

        # 录制的每步 MCP 调用 + 断言
        ...

        # 最终错误检查
        debug = await runner.call("godotiq_read_debug_console", limit=20)
        ...
    finally:
        await runner.call("godotiq_run", action="stop")
        await runner.disconnect()
    print(result.summary())
    return result.passed

if __name__ == "__main__":
    if sys.platform == "win32":
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    sys.exit(0 if asyncio.run(test_{feature}()) else 1)
```

**强制生成规则：**

| 规则 | 说明 |
|------|------|
| 使用 helpers.py | `ui_map_with_retry`, `verify_node_exists` 等辅助函数必须从 helpers 导入 |
| press_button > tap | 按钮触发一律用 `godotiq_press_button`，不用 `godotiq_input(tap=)` |
| game_scene_tree > ui_map | 场景切换后验证用 `godotiq_find_node` 或 `godotiq_game_scene_tree` |
| 本地 godotiq 包 | `sys.path.insert` 指向 `addons/godotiq`，`PYTHONPATH` 环境变量 |
| Windows 编码 | 入口处 `sys.stdout.reconfigure(encoding="utf-8")` |
| 最终错误检查 | 每个测试结尾 `godotiq_read_debug_console` 确认零运行时错误 |
| cleanup in finally | `godotiq_run(action="stop")` + `disconnect()` 必须在 finally 中 |

**输出位置：**
- 脚本：`scripts/tools/test_e2e_{feature}.py`
- 录制数据：`.claude/e2e_recordings/{feature}_{date}.json`

## 前置条件

- Python 3.10+ 已安装
- `mcp` Python 包已安装 (`pip install mcp`)
- GodotIQ MCP 服务器可用（Godot 编辑器已打开 + GodotIQ 插件已启用）

## 辅助函数参考

`templates/helpers.py` 提供以下可复用函数：

| 函数 | 用途 |
|------|------|
| `ui_map_with_retry(runner, ...)` | `godotiq_ui_map` 带重试（首次加载可能超时） |
| `verify_node_exists(runner, name, ...)` | `godotiq_find_node` 带重试（场景切换后需要等待） |
| `_find_node_by_name(ui_map, name)` | 递归搜索 `ui_map` layout 树 |
| `_has_node_name(ui_map, name)` | 布尔包装 |
| `find_map_available_buttons(runner)` | 动态发现地图中可用按钮 |
| `press_map_button(runner, name)` | `godotiq_press_button` 封装 |

## 快速参考

| 命令 | 描述 |
|------|------|
| `/e2e-regression-test "需求描述"` | 完整流程 |
| `/e2e-regression-test --design docs/design/xxx.md` | 从设计文档生成 |
| `/e2e-regression-test --prd tasks/prd-xxx.md` | 从已有 PRD 录制 |
| `/e2e-regression-test --from-recording file.json` | 从录制数据生成脚本 |
| `/e2e-regression-test "需求" --scene battle` | 指定场景 |

## 常见错误

1. **MCP 服务器未启动** — 确保 Godot 编辑器已打开且 GodotIQ 插件已启用
2. **Python mcp 包未安装** — 运行 `pip install mcp`
3. **元素名硬编码** — 录制时必须使用 `godotiq_find_node` 动态发现
4. **断言过于宽泛** — AC 必须具体可验证，如 `ap == 3` 而非 `ap 减少`
5. **忘记清理** — 每个测试必须在 `finally` 中停止游戏
6. **用 ui_map 验证场景切换** — 场景切换后 `ui_map` 返回缓存数据，应用 `godotiq_find_node`
7. **用 tap 触发按钮** — ScrollContainer 内 tap 不可靠，应用 `godotiq_press_button`

## 故障排除

### MCP 连接失败

**症状：** Python 脚本无法连接 GodotIQ

**解决方案：**
1. 确认 Godot 编辑器已打开
2. 确认 GodotIQ 插件已启用
3. 检查 `addons/godotiq` 目录在 PYTHONPATH 中
4. 手动测试：`python -m godotiq.server` 看是否有输出

### 录制中断

**症状：** 录制过程中遇到 MCP 不支持的操作

**解决方案：**
1. 查看中断报告中的缺失能力
2. 选择：a) 实现 MCP 能力  b) 跳过  c) 中止
3. 参考 `references/mcp_capability_matrix.md` 确认能力覆盖

### 生成的脚本运行失败

**症状：** `python test_e2e_xxx.py` 报错

**解决方案：**
1. 检查 MCP 服务器是否正在运行
2. 检查游戏场景路径是否正确
3. 检查 UI 元素名是否在运行时可用（动态发现）
4. 查看 `result.summary()` 输出定位失败步骤
5. 可能需要重新录制（UI 变更导致节点名变化）
