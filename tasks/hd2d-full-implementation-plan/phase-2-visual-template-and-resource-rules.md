# 阶段 2：视觉模板和资源规则

阶段状态： `[x]` 已完成

## 目标

把阶段 1 验证稳定的视觉配置沉淀为可复用模板，让后续角色、地图、灯光、后处理和特效可以按同一套规则制作。

本阶段的核心产物不是更复杂的画面，而是可复制的制作标准。

## 范围

包含：

- HD-2D 角色模板。
- 假阴影模板。
- WorldEnvironment 默认模板。
- 相机 profile 模板。
- 导入规则和命名规则。
- 截图验收规范。

不包含：

- 不制作大量角色动画。
- 不批量重做地图资源。
- 不接入正式 Run 地图。
- 不引入复杂 shader 系统。

## [x] 任务 2.1：整理角色模板

基于 `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn` 提炼模板规则。

模板应明确：

- 根节点是否直接使用 `AnimatedSprite3D`，或是否升级为 `CharacterBody3D + AnimatedSprite3D + ShadowPlane`。
- 默认 `pixel_size`。
- 默认 `billboard`。
- 默认 `texture_filter`。
- 默认 `alpha_cut` 和阈值。
- 默认是否 `shaded`。
- 假阴影相对脚点的位置和比例。
- 动画命名：`stand`、`walk`、`run`、`attack`、`hit`、`death`。

推荐输出：

- `scenes/map3d/characters/hd2d_character_template.tscn`
- `docs/hd2d/character_template.md`

## [x] 任务 2.2：整理环境和后处理模板

将实验场中稳定的环境参数保存为可复用资源。

推荐输出：

- `resources/hd2d/hd2d_world_environment_default.tres`
- `resources/hd2d/hd2d_camera_attributes_default.tres`
- `docs/hd2d/world_environment_profiles.md`

至少定义三类 profile：

- `day_soft`：白天村庄/野外，轻雾、轻 Glow、低对比。
- `night_warm_lights`：夜晚城镇，深蓝环境光、暖色局部光、中等 Glow。
- `cave_high_contrast`：洞穴/地下，低环境光、局部光源、较强对比。

每个 profile 都要记录：

- Ambient 色和能量。
- Glow 强度和阈值。
- Fog 密度和颜色。
- DOF 距离、过渡和强度。
- Tonemap 设置。

## [x] 任务 2.3：制定贴图导入规则

新增或更新文档：

- `docs/hd2d/import_rules.md`

明确以下资源类型：

| 类型 | Filter | Mipmaps | Compression | 说明 |
|---|---|---|---|---|
| 角色序列帧 | Nearest | Off | Lossless | 保持硬边和透明稳定 |
| 近景像素特效 | Nearest | Off | Lossless | 保持像素感 |
| 地面像素贴图 | Nearest 或 Linear 对照 | On/Off 都测 | Lossless/VRAM | 斜视地面优先稳定 |
| 远景贴图 | Linear 或 Nearest | On | VRAM | 减少远处闪烁 |
| 粒子贴图 | Linear 通常优先 | On/Off 视效果 | VRAM | 粒子不必强制硬边 |
| UI | 按 UI 风格 | Off | Lossless | 不混入 3D 后处理判断 |

## [x] 任务 2.4：制定材质规则

新增或更新：

- `docs/hd2d/material_rules.md`

规定：

- 普通场景材质优先 `StandardMaterial3D`。
- Roughness 默认偏高，避免塑料感。
- Specular 控制在低到中等。
- Emission 只给真实发光物或特效，不给所有高亮边缘。
- 透明角色主体优先 Alpha Cut，复杂半透明只给特效/雾层。
- 真实阴影先用于场景，不作为 Sprite3D 角色默认阴影方案。

## [x] 任务 2.5：制定视觉验收模板

新增或更新：

- `docs/hd2d/visual_acceptance_checklist.md`

每次新增地图或角色时，至少检查：

- 主体角色是否清晰。
- 角色脚底是否贴地。
- 前中后景是否成立。
- 局部光源是否可见但不过曝。
- 雾/DOF 是否服务层次而不是糊主体。
- 透明排序是否稳定。
- 正式截图和 headless 结构测试是否都通过。

## [x] 任务 2.6：更新验证矩阵

如果项目已有 `docs/production/05-validation-matrix.md`，将 HD-2D 相关命令加入矩阵。若该文档不存在，先在 `docs/hd2d/visual_acceptance_checklist.md` 中记录验证命令。

最小命令：

```bash
godot --headless --quit
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
```

## 阶段完成标准

- 角色模板、环境模板、导入规则、材质规则和验收清单已成文。
- 新角色和新地图可以按模板配置，不需要重新猜参数。
- P0 阶段确认的默认值已经写入模板。
- 文档没有与 Godot 4.6 项目配置冲突的版本描述。
