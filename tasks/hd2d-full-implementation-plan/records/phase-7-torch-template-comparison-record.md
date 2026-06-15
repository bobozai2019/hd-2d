# Phase 7 执行记录

阶段状态： [x] 已完成

本阶段目标：

- 把 Phase 6 验证场中的 Godot 原生火把整理为可复用 `Hd2dTorchEffect` 模板。
- 在光照验证场和正式 Run 地图中接入该模板。
- 用同机位截图对比参考图目标、Phase 6 P0 和 Phase 7 模板，判断是否可进入默认制作模板。

输入资料：

- `docs/hd2d/fire/ChatGPT Image 2026年6月15日 22_13_57.png`
- `docs/hd2d/fire/Godot 火把特效制作.docx`
- `tasks/hd2d-full-implementation-plan/phase-6-torch-material-and-dynamic-light-validation.md`
- `tasks/hd2d-full-implementation-plan/records/phase-6-lighting-validation-record.md`
- `docs/hd2d/lighting_validation_plan.md`
- `docs/hd2d/performance_budget.md`
- `docs/hd2d/material_rules.md`

本轮完成项：

- 新增可复用模板：
  - `scenes/map3d/vfx/hd2d_torch_effect.tscn`
  - `scripts/map3d/vfx/hd2d_torch_effect.gd`
- 模板结构包含：
  - `TorchProp/Stand`
  - `TorchProp/Bracket`
  - `TorchProp/TorchCup`
  - `TorchProp/CupRim`
  - `TorchProp/CoalBed`
  - `FlameEffect/OuterTongue`
  - `FlameEffect/MiddleTongue`
  - `FlameEffect/InnerTongue`
  - `FlameHalo/OuterGlowVolume`
  - `FlameHalo/InnerGlowVolume`
  - `Sparks`
  - `TorchLight`
- 默认参数：
  - `light_base_energy = 0.6`
  - `light_flicker_strength = 0.16`
  - `light_flicker_speed = 7.4`
  - `light_range = 3.8`
  - `glow_base_scale = 1.0`
  - `glow_flicker_strength = 0.12`
  - `flame_base_scale = 1.0`
  - `sparks_enabled = true`
  - `shadows_enabled = true`
  - `light_enabled = true`
- 光照验证场接入：
  - `scripts/map3d/hd2d_lighting_validation_lab.gd` 在运行时把旧火把保留为 `Phase6Reference_*`。
  - 默认使用 Phase 7 模板实例。
  - 新增 `torch_variant=phase6|phase7` 捕获参数，用于同场景同机位切换对照。
  - `lighting_profile=1/3/6` 继续可用，默认仍为 `3` 动态光。
- 正式 Run 地图接入：
  - `scripts/map3d/run_hex_map_3d.gd` 新增 `VfxRoot/TorchSamples` 运行时样本根节点。
  - `RunTorch_Key` 启用真实 `TorchLight`。
  - `RunTorch_Atmosphere` 只保留发光、glow 和火焰，不启用真实动态光。
- 规范更新：
  - `docs/hd2d/lighting_validation_plan.md`
  - `docs/hd2d/performance_budget.md`
  - `docs/hd2d/material_rules.md`

本轮未完成项：

- 无。后续可做美术增强，但不阻塞 Phase 7：
  - 用 Blender 制作低模 `.glb` 火盆和支架。
  - 为远景火焰做更强的像素化轮廓控制。
  - 为正式地图做按屏幕预算自动降级的多火把布局规则。

截图文件：

- `output/lighting_validation/torch-phase6-p0-reference-1280x720.png`
- `output/lighting_validation/torch-phase7-template-1280x720.png`
- `output/lighting_validation/torch-phase7-material-response-1280x720.png`
- `output/lighting_validation/torch-phase7-dynamic-lights-3-1280x720.png`
- `output/lighting_validation/torch-phase7-run-map-sample-1280x720.png`

参考图目标 vs Phase 6 差距：

| 分类 | 参考图目标 | Phase 6 P0 差距 | Phase 7 处理 |
|---|---|---|---|
| 火盆 | 金属火盆和支架轮廓清楚 | primitive 火盆偏简单，缺少杯口层次 | 增加 `CupRim` 和 `CoalBed`，支架、火盆、杯口拆层 |
| 火焰 | 白黄内核、橙色中层、红橙外焰 | 三层成立，但模板不可复用 | 独立模板内置三层 mesh 火舌和不同 flicker phase |
| 火星 | 少量、偶发、上升 | 可用，但跟随散节点重复 | 模板内置 `Sparks`，默认更克制 |
| 光照 | 墙地暖光中心强、边缘弱 | 只在验证场成立 | 验证场和 Run 地图复用同一模板；默认 3 光源 |
| 角色可读性 | 火光不抢角色主体 | 3 光源可读，6 光源为压力边界 | Phase 7 默认保持 3 光源，Run 地图只启用 1 个真实样本光 |
| 性能 | 默认不超过 3 动态光 | 已证明 3 光源上限 | 模板继续遵守 `<= 3`，远景火把可关闭真实光 |

最终对比：

| 对比项 | 参考图目标 | Phase 6 P0 | Phase 7 结果 | 结论 |
|---|---|---|---|---|
| 火盆轮廓 | 金属火盆和支架清楚 | 能读出火盆，但杯口和支架层次偏少 | 杯口、煤床、支架拆层后更清楚 | 通过 |
| 火焰层次 | 白黄内核、橙色中层、红橙外焰 | 已有三层火焰 | 模板化三层火舌，独立 flicker | 通过 |
| 火星 | 少量、偶发、上升 | 可用 | 模板内置，数量保持克制 | 通过 |
| 墙地暖光 | 中心暖、边缘暗、falloff 清楚 | 可见暖色 falloff | 继续可见，默认 3 光源 | 通过 |
| 角色可读性 | 火光不抢主体 | 角色仍可读 | 角色仍为主体，中心火把略抢眼但可调 | 通过，后续可降 glow |
| 性能预算 | 默认不超过 3 动态光 | 默认 3，压力 6 | 验证场默认 3；Run 地图样本只启用 1 个真实火把光 | 通过 |

人工结论：

- Phase 7 比 Phase 6 更接近参考图，主要提升在“火盆/杯口轮廓”和“可复用模板化”。
- Phase 7 可以进入正式地图默认模板，但正式地图默认应只给关键火把启用真实 `TorchLight`。
- 仍建议后续美术增强：低模 `.glb` 火盆、像素火舌轮廓、远景火把 LOD/降级规则。

验证命令：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_hd2d_lighting_validation_lab.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_scene.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_lighting_validation_lab.tscn --quit-after 60
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/run_hex_map_3d.tscn --quit-after 60
```

截图命令：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/torch-phase6-p0-reference-1280x720.png 1280 720 lighting_profile=3 torch_variant=phase6
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/torch-phase7-template-1280x720.png 1280 720 lighting_profile=3 torch_variant=phase7
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/torch-phase7-material-response-1280x720.png 1280 720 lighting_profile=3 torch_variant=phase7
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/torch-phase7-dynamic-lights-3-1280x720.png 1280 720 lighting_profile=3 torch_variant=phase7
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/run_hex_map_3d.tscn res://output/lighting_validation/torch-phase7-run-map-sample-1280x720.png 1280 720
```

验证结果：

- `test_hd2d_lighting_validation_lab.gd`：通过。
- `test_run_hex_map_3d_scene.gd`：通过。
- `hd2d_lighting_validation_lab.tscn` headless 加载：通过。
- `run_hex_map_3d.tscn` headless 加载：通过。
- 截图矩阵：已生成。
- 注意：本机 `D:\godot\Godot_v4.6.2\godot.exe` 实际输出版本为 `Godot Engine v4.7.beta.custom_build.dff2b9bb6`，路径名与引擎报告版本不一致。

是否达到阶段完成标准：

是

下一阶段入口：

当前任务包最后阶段已完成；后续若继续扩展，应从新的 Phase 8 或独立美术增强任务开始。
