# #2 角色双重绘制

## 问题描述

主相机和 CharacterCamera 都会渲染角色，导致角色被绘制两次（主视口一次 + CanvasLayer 叠加一次）。

## 问题场景

- 场景：`scenes/map3d/hd2d_market_plaza_lighting_lab2.tscn`
- 角色 `layers=2`（仅层 2）
- CharacterCamera `cull_mask=2`（仅层 2）— 正确
- 主 Camera3D **未设置 cull_mask**，默认值包含所有层（包括层 2）
- CanvasLayer 上的 CompositeRect 将 SubViewport 渲染结果叠加到主视口之上

## 可能原因

- 主相机的默认 cull_mask 包含层 2，所以主视口也会渲染角色。这是设计遗漏，不是 bug。（**确定**）

## 修复方式

- 主 Camera3D 设置 `cull_mask=1`（仅层 1），排除层 2

## 状态

已修复。在 .tscn 中为主 Camera3D 添加了 `cull_mask = 1`。
