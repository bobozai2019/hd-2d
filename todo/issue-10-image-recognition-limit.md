# #10 图像识别工具限制

## 问题描述

`mcp__image-recognition__image_recognize` 无法识别本地文件路径和 base64 data URL。

## 问题场景

- 传入本地路径 `d:\...\screenshot.webp` 返回"无法查看外部链接或图片内容"
- 传入 `data:image/webp;base64,...` 返回"图片不存在"
- 无法用于验证游戏截图

## 可能原因

- 工具限制，可能需要额外配置或使用其他图片分析方式。（**确定**）
