#!/usr/bin/env python3
"""
E2E 测试辅助函数
从 test_e2e_career_select_to_battle.py 提取的可复用工具函数。

用法:
    from helpers import ui_map_with_retry, verify_node_exists, ...
"""

import asyncio
from typing import Any


async def ui_map_with_retry(runner, max_retries: int = 3, delay: float = 3.0, **kwargs) -> Any:
    """
    godotiq_ui_map 带重试。
    游戏刚启动时首次调用可能超时，需要重试。
    """
    for i in range(max_retries):
        result = await runner.call("godotiq_ui_map", **kwargs)
        if isinstance(result, dict) and "error" not in result:
            return result
        if i < max_retries - 1:
            await asyncio.sleep(delay)
    return result


async def verify_node_exists(runner, node_name: str, max_retries: int = 5, delay: float = 2.0) -> bool:
    """
    通过 godotiq_find_node 按名称精确查找节点（带重试）。
    场景切换后节点可能需要时间加载。
    """
    for i in range(max_retries):
        try:
            result = await runner.call("godotiq_find_node", name=node_name)
        except Exception as e:
            print(f"  [DEBUG] verify_node_exists('{node_name}') exception: {e}")
            if i < max_retries - 1:
                await asyncio.sleep(delay)
            continue
        if isinstance(result, dict):
            if result.get("found"):
                return True
            if "error" in result:
                print(f"  [DEBUG] verify_node_exists('{node_name}') error: {result['error']}")
            elif i == max_retries - 1:
                print(f"  [DEBUG] verify_node_exists('{node_name}') not found")
        if i < max_retries - 1:
            await asyncio.sleep(delay)
    return False


def _find_node_by_name(ui_map_result: dict, name: str) -> dict | None:
    """递归搜索 ui_map layout 中匹配 name 的节点"""
    def _search(nodes):
        for node in nodes:
            if node.get("name") == name:
                return node
            found = _search(node.get("children", []))
            if found:
                return found
        return None
    return _search(ui_map_result.get("layout", []))


def _has_node_name(ui_map_result: dict, name: str) -> bool:
    """检查 ui_map 结果中是否包含指定名称的节点"""
    return _find_node_by_name(ui_map_result, name) is not None


async def find_map_available_buttons(runner) -> list[dict]:
    """
    通过 godotiq_game_scene_tree 查询地图中所有可用的节点按钮。
    只收集 MapScreen 下的未禁用按钮。
    """
    result = await runner.call("godotiq_game_scene_tree", depth=10, filter_type="Button", detail="full")
    buttons = []
    if isinstance(result, dict) and "nodes" in result:
        for node in result["nodes"]:
            path = node.get("path", "")
            if "MapScreen" in path and not node.get("disabled", False):
                pos = node.get("position", [0, 0])
                buttons.append({"name": node["name"], "y": pos[1] if len(pos) > 1 else 0})
    return buttons


async def press_map_button(runner, button_name: str) -> bool:
    """
    通过 godotiq_press_button 直接触发地图按钮的 pressed 信号。
    godotiq_input 的 tap 模拟鼠标点击在 ScrollContainer 内不可靠，
    godotiq_press_button 直接 emit_signal("pressed") 触发。
    """
    result = await runner.call("godotiq_press_button", name=button_name)
    if isinstance(result, dict):
        return result.get("status") == "pressed"
    return False
