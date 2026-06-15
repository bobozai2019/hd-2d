# HD-2D 视觉验收清单

适用版本：Godot 4.6 项目配置。

## 每次新增角色或地图时至少检查

- 主体角色是否清晰。
- 角色脚底是否贴地。
- 前中后景是否成立。
- 局部光源是否可见但不过曝。
- 雾 / DOF 是否服务层次而不是糊主体。
- 透明排序是否稳定。
- 正式截图和 headless 结构验证是否都通过。

## Phase 1 默认推荐

- 默认验证 profile：`Perspective + Unshaded + Y-Billboard`
- 对照镜头：`Orthogonal`
- 默认角色 `pixel_size = 0.0024`
- 默认角色阴影：假阴影，偏移 `(0, 0.018, 0.12)`

## 截图验收矩阵

固定同一场景，至少保留以下截图：

- `Perspective + Shaded`
- `Perspective + Unshaded`
- `Orthogonal + Shaded`
- `Orthogonal + Unshaded`
- `Perspective + Y-Billboard`
- `Perspective + Fixed Facing`

以及以下样本截图：

- `wall-front`
- `wall-back`
- `foreground-cover`
- `bridge-top`
- `transparent-zone`
- `glow-side`

## 当前验证命令

项目内 `docs/production/05-validation-matrix.md` 当前不存在，因此先在本清单记录 HD-2D 命令：

```bash
godot --headless --quit
godot --headless --path . --scene res://scenes/map3d/hd2d_effect_lab.tscn --quit-after 60
godot --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_hd2d_phase1_matrix.gd -- res://output/phase1 1280 720
```

如果未来补回 `scripts/autotest/`，将以下命令加入矩阵：

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
```
