# lab2 双视口方案问题清单

> 场景：`scenes/map3d/hd2d_market_plaza_lighting_lab2.tscn`
> 目标：NPC 排除景深效果（双视口 + CanvasLayer 合成）
> 记录时间：2026-06-21

---

## #1 SubViewport ViewportTexture 全透明（已解决）

### 问题描述

CharacterViewport 的 ViewportTexture 采样 5 个点全部 alpha=0，SubViewport 没有渲染出任何内容。

### 根因

共享 World3D 不能让 SubViewport 看到主场景树中的节点。每个 Viewport 有独立的场景树，World3D 只共享环境/光照/物理世界，不共享渲染的节点图。

### 修复方式

将角色节点移到 CharacterViewport/ 下作为子节点。Shadow mesh 保留在主场景 Characters/ 下。

---

## #2 角色双重绘制（已修复）

### 问题描述

主相机和 CharacterCamera 都会渲染角色，导致角色被绘制两次。

### 修复方式

主 Camera3D 设置 `cull_mask=1`（仅层 1），排除层 2。

---

## #3 CharacterCamera near 值与主相机不一致（已修复）

### 问题描述

CharacterCamera near=0.05 与主相机 near=0.045 不一致。

### 修复方式

CharacterCamera 设置 `near=0.045`。

---

## #4 size_changed 信号连接到 SubViewport 自身

### 问题描述

脚本中 `_character_viewport.get_viewport().size_changed.connect(_sync_size)` 连接的是 SubViewport 自身的 size_changed 信号，而非主视口的。

### 问题场景

```gdscript
if _character_viewport and _character_viewport.get_viewport():
    _character_viewport.get_viewport().size_changed.connect(_sync_size)
```

- `SubViewport.get_viewport()` 返回 SubViewport 自身（因为它本身就是 Viewport）
- 意图是监听主视口尺寸变化来同步 SubViewport 尺寸
- 实际连接到了 SubViewport 自己的信号，`_sync_size()` 设置 size 可能再次触发 size_changed（虽然值不变时 Godot 通常不会重发，但逻辑不正确）

### 可能原因

- 对 `get_viewport()` 在 SubViewport 上的行为理解错误。（**确定**）

### 修复方式

- 改为在 CharacterViewportSync 节点上调用：`get_viewport().size_changed.connect(_sync_size)`
- CharacterViewportSync 不是 Viewport，`get_viewport()` 会正确返回主视口

---

## #5 RemoteTransform3D 跨 SubViewport 无效（已解决）

### 问题描述

RemoteTransform3D 无法跨 SubViewport 边界设置子节点的 transform。

### 问题场景

- CharacterCameraSync（RemoteTransform3D）挂在 CameraRig/Camera3D 下
- `remote_path = NodePath("../../CharacterViewport/CharacterCamera")`
- 运行时 CharacterCamera 的 global_transform 为单位矩阵（O: 0,0,0），完全未同步

### 可能原因

- RemoteTransform3D 内部使用 `get_node()` 解析 `remote_path`。虽然 SubViewport 的子节点在同一个 SceneTree 中，但 RemoteTransform3D 可能有特殊处理，不允许跨 Viewport 边界操作。（**确定**）

### 修复方式

- 改用脚本 `_process()` 中手动同步 `character_camera.global_transform = main_camera.global_transform`

---

## #6 get_node 路径解析错误（已解决）

### 问题描述

脚本中 `get_node(^"CharacterViewport")` 从根子节点调用时找不到节点，返回 null。

### 问题场景

- CharacterViewportSync 是场景根的直接子节点（parent="."）
- 脚本中使用 `get_node_or_null(^"CharacterViewport")` 查找兄弟节点
- 运行时三个引用变量全部为 null
- 验证：`get_node_or_null(^"../CharacterViewport")` 能正确找到

### 可能原因

- Godot 中 `get_node(^"X")` 从当前节点开始查找**子节点** X，不是兄弟节点。要访问兄弟节点需要 `get_node(^"../X")`。（**确定**）

### 修复方式

- 改为 `get_node_or_null(^"../CharacterViewport")` 等带 `../` 的路径

---

## #7 World3D 为 null（已解决）

### 问题描述

CharacterViewport 的 `world_3d` 为 null，SubViewport 看不到任何 3D 对象。

### 问题场景

- SubViewport 默认不继承父视口的 World3D
- 运行时检查 `vp.world_3d` 为 null
- 主视口有 World3D（`Environment_market`）

### 可能原因

- SubViewport 不会自动继承父视口的 World3D，需要手动赋值。（**确定**）

### 修复方式

- 脚本中添加 `_character_viewport.world_3d = get_viewport().world_3d`

---

## #8 GodotIQ 截图超时

### 问题描述

`godotiq_screenshot` 请求 30 秒超时，无法获取游戏截图。

### 问题场景

- 使用 png 格式、scale=0.4 以上时频繁超时
- webp 格式 scale=0.2 能成功但分辨率极低（230x129）

### 可能原因

- SubViewport 渲染开销 + WebSocket 传输大图像数据的缓冲区限制（**确定**）

---

## #9 WebSocket 缓冲区溢出

### 问题描述

控制台大量报错：`wsl_peer.cpp:790 outbound_buffer_size > 0 ... ERR_OUT_OF_MEMORY`

### 问题场景

- GodotIQ WebSocket 通信时，截图数据超过缓冲区限制
- 不影响游戏运行，仅影响 GodotIQ 工具通信

### 可能原因

- GodotIQ 已知限制，WebSocket 缓冲区大小不足。（**确定**）

---

## #10 图像识别工具限制

### 问题描述

`mcp__image-recognition__image_recognize` 无法识别本地文件路径和 base64 data URL。

### 问题场景

- 传入本地路径 `d:\...\screenshot.webp` 返回"无法查看外部链接"
- 传入 `data:image/webp;base64,...` 返回"图片不存在"

### 可能原因

- 工具限制，可能需要额外配置或使用其他图片分析方式。（**确定**）
