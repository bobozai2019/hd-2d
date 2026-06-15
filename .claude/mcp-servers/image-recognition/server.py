#!/usr/bin/env python3
"""图片识别 MCP Server - 使用小米 MiMo 模型"""

import os
import sys
import json
import base64
import urllib.request
import urllib.error
from typing import Optional
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# 配置
MIMO_API_KEY = os.environ.get("MIMO_API_KEY", "")
MIMO_BASE_URL = os.environ.get("MIMO_BASE_URL", "https://token-plan-cn.xiaomimimo.com/v1")
MIMO_MODEL = os.environ.get("MIMO_MODEL", "mimo-v2.5")

app = Server("image-recognition")


@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="image_recognize",
            description="识别图片内容，返回详细描述。支持 URL 和本地文件路径。",
            inputSchema={
                "type": "object",
                "properties": {
                    "image": {
                        "type": "string",
                        "description": "图片 URL 或本地文件路径"
                    },
                    "prompt": {
                        "type": "string",
                        "description": "可选的提示词，指定要识别的内容",
                        "default": "请详细描述这张图片的内容"
                    }
                },
                "required": ["image"]
            }
        )
    ]


def load_image_as_base64(image_path: str) -> str:
    """将本地图片加载为 base64"""
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def get_image_url(image: str) -> str:
    """处理图片输入，返回可用的 URL 或 data URI"""
    if image.startswith(("http://", "https://")):
        return image
    # 本地文件转 base64
    if os.path.exists(image):
        b64 = load_image_as_base64(image)
        ext = os.path.splitext(image)[1].lower()
        mime = {
            ".png": "image/png",
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".gif": "image/gif",
            ".webp": "image/webp",
            ".bmp": "image/bmp"
        }.get(ext, "image/png")
        return f"data:{mime};base64,{b64}"
    raise FileNotFoundError(f"图片不存在: {image}")


def call_mimo_api(image_url: str, prompt: str) -> str:
    """调用 MiMo API 进行图片识别"""
    headers = {
        "Content-Type": "application/json",
        "api-key": MIMO_API_KEY
    }

    payload = {
        "model": MIMO_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": image_url}
                    },
                    {
                        "type": "text",
                        "text": prompt
                    }
                ]
            }
        ],
        "max_completion_tokens": 2048
    }

    req = urllib.request.Request(
        f"{MIMO_BASE_URL}/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            return result["choices"][0]["message"]["content"]
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        raise Exception(f"API 调用失败 ({e.code}): {error_body}")


@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name != "image_recognize":
        raise ValueError(f"未知工具: {name}")

    image = arguments["image"]
    prompt = arguments.get("prompt", "请详细描述这张图片的内容")

    try:
        image_url = get_image_as_url(image)
        result = call_mimo_api(image_url, prompt)
        return [TextContent(type="text", text=result)]
    except Exception as e:
        return [TextContent(type="text", text=f"错误: {str(e)}")]


def get_image_as_url(image: str) -> str:
    """获取图片 URL"""
    return get_image_url(image)


async def main():
    if not MIMO_API_KEY:
        print("错误: 请设置 MIMO_API_KEY 环境变量", file=sys.stderr)
        sys.exit(1)

    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
