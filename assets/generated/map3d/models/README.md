# HD-2D GLB 运行时模型目录

预期运行时模型名：

- `hd2d_hex_tile.glb`
- `hd2d_wall_low.glb`
- `hd2d_stairs_short.glb`
- `hd2d_bridge_short.glb`
- `hd2d_foreground_pillar.glb`
- `hd2d_background_silhouette.glb`
- `landmark_battle.glb`
- `landmark_shop.glb`
- `landmark_rest.glb`
- `landmark_event.glb`
- `landmark_boss.glb`

当前状态：

- GLB 资源尚未落地。
- `scenes/map3d/hd2d_map_asset_light_response_lab.tscn` 当前使用同名模块的 Godot 原语回退。
- 后续补 GLB 时，优先保持文件名不变，以便场景逐步替换。

新增运行时模型：

- `hd2d_market_plaza.glb` — 市集广场组合模块，使用 `assets/generated/map3d/textures/hd2d_market_plaza_*_{albedo,normal}.png` 贴图。
