# #5 RemoteTransform3D 跨 SubViewport 无效（已解决）

## 问题描述

RemoteTransform3D 无法跨 SubViewport 边界设置子节点的 transform。

## 问题场景

- 场景：`scenes/map3d/hd2d_market_plaza_lighting_lab2.tscn`
- CharacterCameraSync（RemoteTransform3D）挂在 CameraRig/Camera3D 下
- `remote_path = NodePath("../../CharacterViewport/CharacterCamera")`
- 运行时 CharacterCamera 的 global_transform 为单位矩阵（O: 0,0,0），完全未同步
- 主相机 global_transform 为 O: (0.15, 9.6, 15.2)

## 可能原因

- RemoteTransform3D 内部使用 `get_node()` 解析 `remote_path`。虽然 SubViewport 的子节点在同一个 SceneTree 中，但 RemoteTransform3D 可能有特殊处理，不允许跨 Viewport 边界操作。（**确定**）

## 修复方式

- 改用脚本 `_process()` 中手动同步 `character_camera.global_transform = main_camera.global_transform`
