# HD-2D 材质规则

适用版本：Godot 4.6 项目配置。

## 默认规则

- 普通场景材质优先使用 `StandardMaterial3D`。
- Roughness 默认偏高，起步值建议 `0.75 ~ 0.95`。
- Specular 控制在低到中等，不追求金属/塑料高亮。
- Emission 只给真实发光物、技能特效或引导性物件。
- 角色主体优先 `Alpha Cut`，复杂半透明只留给雾层、粒子和特效。
- 真实阴影优先给场景物件；Sprite3D/AnimatedSprite3D 角色默认仍使用假阴影。

## 角色相关

- 主体角色默认 `shaded = false`。
- 如果项目需要受光角色，先做对照 profile，再决定是否把个别角色切到 `shaded = true`。
- 不要用强 Emission 来弥补角色受光不足，这会让角色和场景脱节。

## 场景相关

- 地面、桥、墙、柱等基础物件先保证材质关系清楚，再加雾/Glow/局部光。
- 城墙、地板、台阶、柱子等可受光结构默认使用 shaded `StandardMaterial3D`，不要用 `SHADING_MODE_UNSHADED` 做正式光照验证。
- HD-2D 石墙和地板默认 `roughness` 控制在 `0.82 ~ 0.96`，`metallic_specular` 控制在 `0.05 ~ 0.18`，保证暖光渐变可读但不出现塑料高光。
- 半透明挡片要先验证排序是否稳定，再决定是否进入正式地图。
- 发光物和局部光源成对设计，避免“只亮不照”的廉价感。

## 火把和局部光

- P0 火把使用 Godot 原生节点组合：primitive 托架/火盆、additive mesh 火舌、additive glow volume、少量 `GPUParticles3D` 火星和暖色 `OmniLight3D`。
- Phase 7 起默认可复用模板为 `res://scenes/map3d/vfx/hd2d_torch_effect.tscn`，脚本为 `res://scripts/map3d/vfx/hd2d_torch_effect.gd`。
- 模板默认包含火盆/杯口/煤床拆层、三层 additive mesh 火舌、两层 glow volume、少量火星和可关闭的 `TorchLight`。
- 默认模板不使用贴图火焰、`Sprite3D` 火焰或程序 `ImageTexture` 火焰。
- 单屏默认动态局部光上限为 `3`。`6` 光源只保留为压力边界，不进入正式地图默认模板。
- 正式地图中可见火把数量可以多于真实动态光数量；非关键火把应关闭 `light_enabled`，只保留 emission/glow。
