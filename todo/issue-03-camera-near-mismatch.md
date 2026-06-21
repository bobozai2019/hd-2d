# #3 CharacterCamera near 值与主相机不一致

## 问题描述

CharacterCamera 和主相机的投影矩阵 near 值不同，导致边缘像素可能有微小偏差。

## 问题场景

- 场景：`scenes/map3d/hd2d_market_plaza_lighting_lab2.tscn`
- 主 Camera3D `near=0.045`（在 .tscn 中显式设置）
- CharacterCamera 未设置 near，默认值 `0.05`

## 可能原因

- 遗漏了 CharacterCamera 的 near 设置。（**确定**）

## 修复方式

- CharacterCamera 设置 `near=0.045`

## 状态

已修复。在 .tscn 中为 CharacterCamera 添加了 `near = 0.045`。
