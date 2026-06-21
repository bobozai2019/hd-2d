# #1 SubViewport ViewportTexture 全透明（已解决）

## 问题描述

CharacterViewport 的 ViewportTexture 采样 5 个点全部 alpha=0，SubViewport 没有渲染出任何内容。CanvasLayer 上的 CompositeRect 显示全透明。

## 问题场景

- 场景：`scenes/map3d/hd2d_market_plaza_lighting_lab2.tscn`
- SubViewport（CharacterViewport）设置 `transparent_bg=true`、`render_target_update_mode=3`、`size=1920x1080`
- 脚本在 `_ready()` 中设置 `_character_viewport.world_3d = get_viewport().world_3d`，运行时确认 `same_world=true`
- 角色节点（AnimatedSprite3D）在主视口的 Characters/ 下，`layers=2`、`visible=true`、`visible_in_tree=true`
- CharacterCamera 在 SubViewport 下，`cull_mask=2`、`current=true`、`fov=38`
- CharacterCamera 的 global_transform 与主相机完全一致（脚本同步正常）
- ViewportTexture 的 `viewport_path = NodePath("CharacterViewport")` 路径正确

## 根因

**共享 World3D 不能让 SubViewport 看到主场景树中的节点。** 每个 Viewport 有独立的场景树，World3D 只共享环境/光照/物理世界，不共享渲染的节点图。角色节点必须是 SubViewport 的子节点才能被其渲染。

## 修复方式

- 将角色节点（PlayerCharacter、LeftNpc、RightNpc）从 `Characters/` 移到 `CharacterViewport/` 下作为子节点
- Shadow mesh 保留在主场景树 `Characters/` 下（layers=1，主相机 cull_mask=1 可见）
- SubViewport camera cull_mask=2 渲染角色层，主相机 cull_mask=1 排除角色层
- 显式设置 SubViewport `own_world_3d = false`

## 状态

已修复。场景结构变更为：
```
CharacterViewport (SubViewport)
├── CharacterCamera (cull_mask=2)
├── PlayerCharacter (layers=2)
├── LeftNpc (layers=2)
└── RightNpc (layers=2)
Characters/ (主场景树)
├── PlayerShadow (layers=1)
├── LeftNpcShadow (layers=1)
└── RightNpcShadow (layers=1)
```
