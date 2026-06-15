# 禁止直接读图 Hook

## 概述

拦截 Read 工具对图片文件的读取，强制使用 MCP image-recognition 服务。

## 限制

**此 Hook 无法拦截粘贴到输入框的图片。** 粘贴图片时，数据以 base64 内联方式直接嵌入消息，不经过任何工具。对于粘贴图片的场景，仅靠 CLAUDE.md 硬规则约束。

## Hook 类型

PreToolUse - 在 Read 工具调用前触发

## 触发条件

Read 工具的 file_path 参数匹配以下扩展名：
`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.bmp`, `.svg`, `.ico`, `.tga`

## 拦截行为

返回 `{"decision": "block"}` 并提示使用 MCP 工具：
```
mcp__image-recognition__image_recognize(image="<图片路径>", prompt="描述图片内容")
```

## 配置

在 `.claude/settings.json` 中：
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/block-image-read.sh"
          }
        ]
      }
    ]
  }
}
```
