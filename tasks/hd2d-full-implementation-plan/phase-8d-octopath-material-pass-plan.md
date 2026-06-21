# Phase 8D: 八方风格建筑材质调整计划

阶段状态：`[x]` 已完成

## Summary

先做一轮“材质 + 贴图”调整，不重做模型结构，不等 RenderDoc。目标是把当前黑红橙、塑料感、低模线条感，改成更接近八方的低饱和灰黄石墙、灰暖石板、暗褐木梁、局部暖光染色的读法。成果优先体现在 `hd2d_market_artpass_candidate.tscn` 和 8C 截图矩阵里。

## Key Changes

- 重调生成贴图色阶：墙面、地面、屋顶、木材从“深色底 + 高对比线”改成“较亮低饱和底色 + 细暗缝 + AO 柔化”。
- 重调材质倍率：避免 `albedo_texture * albedo_color` 双重压暗；墙/地材质 `albedo_color` 提亮到接近白灰暖色，木材保持暗但降低红橙饱和。
- 8C artpass 纯色材质补纹理化：`wall_trim`、`shadow_wood` 不再是纯色条，改为复用或生成对应 trim/wood 贴图材质，避免新增细节像黑色塑料。
- 场景光照小调：降低整体暖红污染，保留中心暖光池；ambient 稍偏冷灰绿，墙面本色靠材质可读，暖色主要由灯光/patch 提供。
- 保留角色受光和脚底阴影改动，不回退到完全 unshaded。

## Implementation Details

- 修改 `scripts/tools/generate_phase8b_market_assets.gd` 的贴图生成参数：
  - 石墙：底色改为灰黄石 `Color(0.56, 0.50, 0.38)`，缝线 `Color(0.25, 0.22, 0.17)`，降低随机亮度范围，砖缝更细。
  - 石地：底色改为 `Color(0.50, 0.47, 0.37)`，缝线 `Color(0.20, 0.19, 0.15)`，减少纯黑缝。
  - 木材：底色改为冷暗褐 `Color(0.22, 0.16, 0.11)`，线色 `Color(0.09, 0.07, 0.05)`，降低红色倾向。
  - 屋顶：底色改为暗赤褐 `Color(0.20, 0.08, 0.055)`，减少亮红面。
- 修改生成材质参数：
  - 墙/地 `albedo_color` 提升到 `Color(0.85, 0.80, 0.68)` / `Color(0.78, 0.76, 0.66)`。
  - 木/屋顶 `albedo_color` 控制在 `Color(0.62, 0.52, 0.42)` / `Color(0.58, 0.42, 0.34)`。
  - `normal_scale` 从 `0.45` 降到 `0.25 ~ 0.32`，避免像硬边塑料。
  - `ao_light_affect` 从 `0.28` 降到 `0.14 ~ 0.18`，让阴影缝保留但不脏黑。
- 修改 8C artpass 材质生成：
  - `mat_hd2d_market_artpass_wall_trim` 改为带墙面/木纹贴图的材质，颜色接近深灰黄而不是纯黑褐。
  - `mat_hd2d_market_artpass_shadow_wood` 改为带木纹贴图材质，保持暗部但保留纹理反光层次。
  - `ceramic` 降低亮度和饱和，避免小物件像干净圆柱。
- 微调 `scripts/map3d/hd2d_market_reference_match_lab.gd` 默认 final profile：
  - ambient 保持冷灰，但略提高可读性。
  - 中央暖光不再把墙面整体染成橙色。
  - patch alpha 降一点，让材质本体变化在 `no_post` / `no_patch` 下也可见。

## Test Plan

- 重新生成材质/贴图和截图矩阵。
- 必跑：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . -s res://scripts/tools/generate_phase8b_market_assets.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_market_artpass_candidate.tscn --quit-after 60
D:\godot\Godot_v4.6.2\godot.exe --headless --path . -s res://scripts/autotest/test_hd2d_market_reference_artpass_lab.gd
```

- 刷新截图：
  - `output/market_reference_artpass/market-artpass-reference-v1-1280x720.png`
  - `output/market_reference_artpass/market-artpass-no-post-1280x720.png`
  - `output/market_reference_artpass/market-artpass-no-patch-1280x720.png`
  - `output/market_reference_artpass/market-artpass-main-scene-migration-1280x720.png`
  - `output/market_reference_artpass/market-artpass-side-by-side-comparison.png`
- 验收标准：
  - `no_post` 下建筑不再大面积黑红，墙/地/木各自材质能分辨。
  - final 下暖色主要来自灯光区域，不是整栋建筑底色发橙。
  - 右侧高楼和后墙细节仍可读，但不再像黑色描边塑料条。
  - 角色仍受光、仍有脚底阴影，且不被材质调整淹没。

## Assumptions

- 本轮只调整 8C 候选场景链路，不迁移正式 Run 地图。
- 不重建 GLB 几何，只调整贴图、材质、profile 参数。
- RenderDoc 后续仍可用于更深一轮还原；本轮先用截图参考和当前 no_post/no_patch 结果做材质方向修正。
