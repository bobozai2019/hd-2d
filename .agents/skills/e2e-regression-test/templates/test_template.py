#!/usr/bin/env python3
"""
E2E 回归测试模板
由 e2e-regression-test 技能自动生成。

运行方式:
    pip install mcp
    python scripts/autotest/test_e2e_{feature_name}.py

MCP 服务器配置:
    使用本地 godotiq 包（addons/godotiq），通过 python -m godotiq.server 启动。
    需要 Godot 编辑器已打开且 GodotIQ 插件已启用。
"""

import asyncio
import os
import sys
from pathlib import Path

# 使用本地 godotiq 包（优先于全局安装）
_local_pkg = str(Path(__file__).resolve().parents[2] / "addons" / "godotiq")
if _local_pkg not in sys.path:
    sys.path.insert(0, _local_pkg)

sys.path.insert(0, str(Path(__file__).parent))
from mcp_test_runner import (
    MCPTestRunner,
    TestResult,
    TestStep,
)
from helpers import (
    ui_map_with_retry,
    verify_node_exists,
    _find_node_by_name,
    _has_node_name,
    find_map_available_buttons,
    press_map_button,
)


# ============================================================
# MCP 服务器配置
# ============================================================
MCP_SERVER_CMD = "python"
MCP_SERVER_ARGS = ["-m", "godotiq.server"]


# ============================================================
# 测试用例
# ============================================================

async def test_{FEATURE_NAME}():
    """
    E2E 回归测试: {TEST_DESCRIPTION}

    PRD 参考: {PRD_PATH}
    验收标准: {ACCEPTANCE_CRITERIA}
    """
    _env = {**os.environ, "PYTHONPATH": _local_pkg}
    runner = MCPTestRunner(server_cmd=MCP_SERVER_CMD, server_args=MCP_SERVER_ARGS, env=_env)
    await runner.connect()
    result = TestResult(name="{FEATURE_NAME}")

    try:
        # --- Step 0: 热重载 addon 确保新 MCP 工具可用 ---
        await runner.call("godotiq_reload_addon")
        await asyncio.sleep(1)

        # --- 自动生成的测试步骤 ---

        # Step 1: {STEP_1_DESCRIPTION}
        step_1 = await runner.call("{STEP_1_TOOL}", **{STEP_1_PARAMS})
        {STEP_1_ASSERTION}

        # Step 2: {STEP_2_DESCRIPTION}
        step_2 = await runner.call("{STEP_2_TOOL}", **{STEP_2_PARAMS})
        {STEP_2_ASSERTION}

        # ... 更多步骤由录制过程自动生成 ...

        # --- 最终检查: 无运行时错误 ---
        debug = await runner.call("godotiq_read_debug_console", limit=20)
        error_count = debug.get("runtime_errors_total", 0) if isinstance(debug, dict) else 0
        passed, err = runner.assert_eq(error_count, 0, "不应有运行时错误")
        result.add_step(TestStep(
            index=99, description="检查无运行时错误",
            tool="godotiq_read_debug_console", params={"limit": 20},
            passed=passed, error=err,
        ))

    finally:
        # 清理: 停止游戏
        await runner.call("godotiq_run", action="stop")
        await runner.disconnect()

    # 输出结果
    print(result.summary())
    return result.passed


# ============================================================
# 入口
# ============================================================

if __name__ == "__main__":
    # Windows 编码修复
    if sys.platform == "win32":
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    passed = asyncio.run(test_{FEATURE_NAME}())
    sys.exit(0 if passed else 1)
