# #8 GodotIQ 截图超时

## 问题描述

`godotiq_screenshot` 请求 30 秒超时，无法获取游戏截图。

## 问题场景

- 使用 png 格式、scale=0.4 以上时频繁超时
- webp 格式 scale=0.2 能成功但分辨率极低（230x129）
- 游戏运行正常，godotiq_state_inspect 能正常返回

## 可能原因

- SubViewport 渲染开销 + WebSocket 传输大图像数据的缓冲区限制（**确定**）
