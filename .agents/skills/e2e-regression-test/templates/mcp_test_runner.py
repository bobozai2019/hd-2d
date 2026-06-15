#!/usr/bin/env python3
"""
MCP E2E 测试运行器
通过 MCP SDK 连接 GodotIQ 服务器，执行端到端回归测试。
零 exec 注入 — 所有操作严格通过 MCP 工具完成。
"""

import asyncio
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


@dataclass
class TestStep:
    """单个测试步骤"""
    index: int
    description: str
    tool: str
    params: dict[str, Any]
    assertion: dict[str, Any] | None = None
    result: Any = None
    passed: bool = True
    error: str | None = None


@dataclass
class TestResult:
    """测试结果"""
    name: str
    steps: list[TestStep] = field(default_factory=list)
    passed: bool = True
    error: str | None = None

    def add_step(self, step: TestStep):
        self.steps.append(step)
        if not step.passed:
            self.passed = False

    def summary(self) -> str:
        status = "PASS" if self.passed else "FAIL"
        lines = [f"{status}: {self.name}"]
        for s in self.steps:
            mark = "✓" if s.passed else "✗"
            lines.append(f"  {mark} Step {s.index}: {s.description}")
            if s.error:
                lines.append(f"    Error: {s.error}")
        return "\n".join(lines)


class MCPTestRunner:
    """
    MCP 测试运行器

    连接 GodotIQ MCP 服务器并执行测试步骤。
    所有游戏交互严格通过 MCP 工具完成。

    用法:
        runner = MCPTestRunner()
        await runner.connect()
        result = await runner.run_test("my_test", steps)
        await runner.disconnect()
    """

    def __init__(self, server_cmd: str = "python", server_args: list[str] | None = None, env: dict[str, str] | None = None):
        self._server_cmd = server_cmd
        self._server_args = server_args or ["-m", "godotiq.server"]
        self._env = env
        self._session: ClientSession | None = None
        self._read = None
        self._write = None
        self._context_manager = None

    async def connect(self) -> None:
        """连接 GodotIQ MCP 服务器"""
        params = StdioServerParameters(
            command=self._server_cmd,
            args=self._server_args,
            env=self._env,
        )
        self._context_manager = stdio_client(params)
        transport = await self._context_manager.__aenter__()
        self._read, self._write = transport
        self._session = ClientSession(self._read, self._write)
        await self._session.__aenter__()
        await self._session.initialize()

    async def disconnect(self) -> None:
        """断开 MCP 连接"""
        if self._session:
            await self._session.__aexit__(None, None, None)
            self._session = None
        if self._context_manager:
            await self._context_manager.__aexit__(None, None, None)
            self._context_manager = None

    async def call(self, tool: str, **kwargs) -> Any:
        """
        调用 MCP 工具

        Args:
            tool: MCP 工具名称 (如 "godotiq_run", "godotiq_input")
            **kwargs: 工具参数

        Returns:
            工具返回的结果
        """
        if not self._session:
            raise RuntimeError("未连接 MCP 服务器，请先调用 connect()")

        result = await self._session.call_tool(tool, kwargs)
        # MCP 返回 content 列表，提取文本内容
        if result.content:
            for item in result.content:
                if hasattr(item, "text"):
                    try:
                        return json.loads(item.text)
                    except (json.JSONDecodeError, TypeError):
                        return item.text
        return result

    def assert_eq(self, actual: Any, expected: Any, msg: str) -> tuple[bool, str]:
        """
        断言相等

        Returns:
            (passed, error_message)
        """
        if actual != expected:
            return False, f"{msg}: 期望 {expected}, 实际 {actual}"
        return True, ""

    def assert_true(self, condition: bool, msg: str) -> tuple[bool, str]:
        """
        断言为真

        Returns:
            (passed, error_message)
        """
        if not condition:
            return False, msg
        return True, ""

    def assert_contains(self, container: Any, item: Any, msg: str) -> tuple[bool, str]:
        """
        断言包含

        Returns:
            (passed, error_message)
        """
        if item not in container:
            return False, f"{msg}: {item} 不在 {container} 中"
        return True, ""

    async def run_test(self, name: str, steps: list[TestStep]) -> TestResult:
        """
        执行测试步骤序列

        Args:
            name: 测试名称
            steps: 测试步骤列表

        Returns:
            TestResult 包含每步结果和总结果
        """
        result = TestResult(name=name)

        for step in steps:
            try:
                # 执行 MCP 调用
                step.result = await self.call(step.tool, **step.params)

                # 执行断言（如果有）
                if step.assertion:
                    assertion_type = step.assertion.get("type", "eq")
                    actual_key = step.assertion.get("actual_key")
                    expected = step.assertion.get("expected")
                    message = step.assertion.get("message", step.description)

                    # 从结果中提取实际值
                    actual = step.result
                    if actual_key and isinstance(actual, dict):
                        # 支持嵌套 key 如 "state.ap"
                        for key in actual_key.split("."):
                            if isinstance(actual, dict):
                                actual = actual.get(key)
                            else:
                                break

                    if assertion_type == "eq":
                        step.passed, step.error = self.assert_eq(actual, expected, message)
                    elif assertion_type == "true":
                        step.passed, step.error = self.assert_true(actual, message)
                    elif assertion_type == "contains":
                        step.passed, step.error = self.assert_contains(actual, expected, message)

            except Exception as e:
                step.passed = False
                step.error = str(e)

            result.add_step(step)

        return result


def load_recording(recording_path: str) -> list[TestStep]:
    """
    从录制 JSON 文件加载测试步骤

    Args:
        recording_path: 录制 JSON 文件路径

    Returns:
        TestStep 列表
    """
    with open(recording_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    steps = []
    for item in data.get("steps", []):
        step = TestStep(
            index=item.get("step", 0),
            description=item.get("description", ""),
            tool=item.get("tool", ""),
            params=item.get("params", {}),
            assertion=item.get("assertion"),
        )
        steps.append(step)

    return steps


def generate_runner_code(steps: list[TestStep], test_name: str) -> str:
    """
    将 TestStep 列表转换为可执行的 Python 测试函数代码

    Args:
        steps: 测试步骤列表
        test_name: 测试函数名称

    Returns:
        Python 代码字符串
    """
    lines = [
        f"async def {test_name}():",
        f'    """E2E 回归测试: {test_name}"""',
        "    runner = MCPTestRunner()",
        "    await runner.connect()",
        "    result = TestResult(name='" + test_name + "')",
        "    try:",
    ]

    for step in steps:
        lines.append(f"        # Step {step.index}: {step.description}")
        params_str = ", ".join(f"{k}={repr(v)}" for k, v in step.params.items())
        lines.append(f"        step_{step.index}_result = await runner.call(\"{step.tool}\", {params_str})")

        if step.assertion:
            a = step.assertion
            a_type = a.get("type", "eq")
            expected = repr(a.get("expected"))
            actual_key = a.get("actual_key", "")
            message = repr(a.get("message", step.description))

            if a_type == "eq":
                if actual_key:
                    lines.append(f"        step_{step.index}_actual = step_{step.index}_result")
                    for key in actual_key.split("."):
                        lines.append(f"            .get(\"{key}\") if isinstance(step_{step.index}_result, dict) else step_{step.index}_result")
                    lines.append(f"        passed, err = runner.assert_eq(step_{step.index}_actual, {expected}, {message})")
                else:
                    lines.append(f"        passed, err = runner.assert_eq(step_{step.index}_result, {expected}, {message})")
            elif a_type == "true":
                lines.append(f"        passed, err = runner.assert_true(step_{step.index}_result, {message})")
            elif a_type == "contains":
                lines.append(f"        passed, err = runner.assert_contains(step_{step.index}_result, {expected}, {message})")

            lines.append(f"        result.add_step(TestStep(index={step.index}, description='{step.description}', tool='{step.tool}', params={repr(step.params)}, passed=passed, error=err))")
        else:
            lines.append(f"        result.add_step(TestStep(index={step.index}, description='{step.description}', tool='{step.tool}', params={repr(step.params)}, passed=True))")

        lines.append("")

    lines.extend([
        "    finally:",
        "        await runner.call('godotiq_run', action='stop')",
        "        await runner.disconnect()",
        "",
        "    print(result.summary())",
        "    return result.passed",
    ])

    return "\n".join(lines)
