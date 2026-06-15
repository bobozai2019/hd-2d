# HD-2D 地图资产流程

适用版本：Godot 4.6 项目配置。

## 目录规范

```text
assets/source/map3d/blender/
  hd2d_map_modules.blend
  hd2d_landmarks_basic.blend

assets/generated/map3d/models/
  hd2d_hex_tile.glb
  hd2d_wall_low.glb
  hd2d_stairs_short.glb
  hd2d_bridge_short.glb
  hd2d_foreground_pillar.glb
  hd2d_background_silhouette.glb
  landmark_battle.glb
  landmark_shop.glb
  landmark_rest.glb
  landmark_event.glb
  landmark_boss.glb

assets/generated/map3d/materials/
  mat_hd2d_ground.tres
  mat_hd2d_wall.tres
  mat_hd2d_foreground.tres
  mat_hd2d_background.tres
  mat_hd2d_emission_warm.tres
  mat_hd2d_emission_cool.tres
```

运行时场景只引用 `.glb`、`.tres`、`.png` 等 Godot 可加载资产，不直接引用 `.blend`。

## Blender 模块要求

- 1 Blender unit = 1 Godot unit。
- 原点放在底面中心。
- 地块、墙、桥、台阶必须有真实厚度。
- 墙体高度要能稳定遮住 Sprite3D 角色身体的一部分。
- 前景挡片要形成层次，但不能吃掉主要交互区域。
- 远景轮廓只服务构图，不参与碰撞。
- 法线方向正确，避免导入后受光翻面。
- 模块尺寸要能拼接，不留明显缝。

最小模块集合：

- 厚六边格地块
- 低墙
- 短台阶
- 短桥
- 前景柱/树干/墙角
- 远景轮廓块
- `battle` / `shop` / `rest` / `event` / `boss` 五类 landmark

## Blender 导出规则

- Apply Transform。
- Apply Scale。
- 保留 UV。
- 保留材质槽名称。
- 运行时优先在 Godot 中挂 `.tres` 材质。
- 不导出 Blender 灯光和相机作为运行时依赖。
- 不导出无关动画。
- 碰撞体优先在 Godot 中创建简单版本。

命名统一使用 `snake_case`。

## 当前回退策略

- 由于当前工作区还没有 `.glb`，`scenes/map3d/hd2d_map_asset_light_response_lab.tscn` 先使用 Godot 原语回退。
- 回退节点命名和 GLB 模块语义一致，后续替换时优先保持模块名不变。
- 回退只是为了保证材质、受光、阴影、雾、Glow 和角色同屏验证不中断，不代表最终美术完成度。
