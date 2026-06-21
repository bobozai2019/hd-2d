# #7 World3D 为 null（已解决）

## 问题描述

CharacterViewport 的 `world_3d` 为 null，SubViewport 看不到任何 3D 对象。

## 问题场景

- 场景：`scenes/map3d/hd2d_market_plaza_lighting_lab2.tscn`
- SubViewport 默认不继承父视口的 World3D
- 运行时检查 `vp.world_3d` 为 null
- 主视口有 World3D（`Environment_market`）
- godotiq_exec 实测：`vp_world3d: "<Object#null>"`, `main_world3d: "<World3D#...>"`

## 可能原因

- SubViewport 不会自动继承父视口的 World3D，需要手动赋值。（**确定**）

## 修复方式

- 脚本中添加 `_character_viewport.world_3d = get_viewport().world_3d`
