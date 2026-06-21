# #9 WebSocket 缓冲区溢出

## 问题描述

控制台大量报错：`wsl_peer.cpp:790 outbound_buffer_size > 0 ... ERR_OUT_OF_MEMORY`

## 问题场景

- GodotIQ WebSocket 通信时，截图数据超过缓冲区限制
- 不影响游戏运行，仅影响 GodotIQ 工具通信
- 用户在命令台看到一堆报错

## 可能原因

- GodotIQ 已知限制，WebSocket 缓冲区大小不足。（**确定**）
