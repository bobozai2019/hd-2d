# #4 size_changed 信号连接到 SubViewport 自身

## 问题描述

脚本中 `_character_viewport.get_viewport().size_changed.connect(_sync_size)` 连接的是 SubViewport 自身的 size_changed 信号，而非主视口的。

## 问题场景

- 场景：`scenes/map3d/hd2d_market_plaza_lighting_lab2.tscn`
- 脚本：`scripts/map3d/hd2d_character_viewport_sync.gd`

```gdscript
if _character_viewport and _character_viewport.get_viewport():
    _character_viewport.get_viewport().size_changed.connect(_sync_size)
```

- `SubViewport.get_viewport()` 返回 SubViewport 自身（因为它本身就是 Viewport）
- 意图是监听主视口尺寸变化来同步 SubViewport 尺寸
- 实际连接到了 SubViewport 自己的信号

## 可能原因

- 对 `get_viewport()` 在 SubViewport 上的行为理解错误。Godot 中 `get_viewport()` 从自身开始向上找第一个 Viewport 祖先，SubViewport 自身就是 Viewport，所以返回自身。（**确定**）

## 修复方式

- 改为在 CharacterViewportSync 节点上调用：`get_viewport().size_changed.connect(_sync_size)`
- CharacterViewportSync 不是 Viewport，`get_viewport()` 会正确返回主视口

## 状态

已修复。改为 `get_tree().root.size_changed.connect(_sync_size)` 直接连接根视口。同时在 .tscn 中为 SubViewport 显式设置了 `own_world_3d = false`。
