# Phase 4 执行记录

阶段状态： [x] 已完成
本阶段目标：
- 为 `hd2d_effect_lab.tscn` 和 `run_hex_map_3d.tscn` 补齐最小 VFX 样本、轻量相机演出和压力测试记录。
- 在不破坏 P0 清晰度、遮挡和排序稳定性的前提下，验证粒子、局部雾、Glow、动态光和简单反馈特效。

输入资料：
- `tasks/hd2d-full-implementation-plan/phase-4-vfx-atmosphere-and-camera-performance.md`
- `scripts/map3d/hd2d_effect_lab.gd`
- `scripts/map3d/run_hex_map_3d.gd`
- `scripts/autotest/test_hd2d_phase4_vfx_samples.gd`
- `scripts/tools/profile_hd2d_phase4_pressure.gd`

本轮完成项：
- 在实验场和正式 Run 地图都建立了统一的 VFX 容器结构：
  - `VfxRoot/AmbientParticles`
  - `VfxRoot/GlowSources`
  - `VfxRoot/SkillSamples`
  - `VfxRoot/FogPlanes`
  - `VfxRoot/DynamicLights`
- `hd2d_effect_lab.gd` 中补齐最小 VFX 样本：
  - 低强度环境粒子
  - 局部雾 plane
  - Glow 样本
  - 点击/技能脉冲样本
  - 动态局部光样本
- `run_hex_map_3d.gd` 中补齐最小 VFX 样本和轻量相机演出：
  - fireflies 粒子
  - available 节点 glow source
  - 节点脉冲反馈
  - route fog
  - selection flash 动态光
  - 选中/进入节点时的轻推近与聚焦反馈
- 新增验证测试：
  - `scripts/autotest/test_hd2d_phase4_vfx_samples.gd`
- 生成 Phase 4 截图：
  - `output/phase4/hd2d-effect-lab-vfx-1280x720.png`
  - `output/phase4/run-hex-map-3d-vfx-1280x720.png`
- 生成压力测试报告：
  - `output/phase4/hd2d-phase4-pressure-report.json`

本轮未完成项：
- 当前压力 profile 的 `average_fps` 为 `20.98`，`minimum_fps` 为 `1.0`，说明默认上限不能直接放宽到压力场景规模。
- 若后续扩展真实战斗特效或更密集地图，需要继续按本阶段记录的降级顺序收紧预算。

验证命令：
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_hd2d_phase4_vfx_samples.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_camera.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_effect_lab.tscn --quit-after 60`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/run_hex_map_3d.tscn --quit-after 60`
- `D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/profile_hd2d_phase4_pressure.gd -- res://output/phase4/hd2d-phase4-pressure-report.json`

验证结果：
- `test_hd2d_phase4_vfx_samples.gd` 通过。
- `test_run_hex_map_3d_camera.gd` 通过。
- `hd2d_effect_lab.tscn` headless 加载成功，退出码 `0`。
- `run_hex_map_3d.tscn` headless 加载成功，退出码 `0`。
- `hd2d-phase4-pressure-report.json` 已生成，记录如下：
  - `average_fps = 20.9777777777778`
  - `minimum_fps = 1.0`
  - `character_count = 31`
  - `tile_count = 20`
  - `local_light_count = 8`
  - `particle_group_count = 3`
  - `transparent_layer_count = 5`
  - `glow_source_count = 3`
- 人工截图验收结论：
  - `hd2d-effect-lab-vfx-1280x720.png` 中角色主体仍清晰，雾层和透明特效没有完全洗掉角色轮廓。
  - `run-hex-map-3d-vfx-1280x720.png` 中 HUD 未被特效遮挡，节点 glow、粒子和局部雾都保持克制。
  - 相机轻推近和聚焦反馈不会把用户带离地图可读视角。

是否达到阶段完成标准：
是

下一阶段入口：
`tasks/hd2d-full-implementation-plan/phase-5-acceptance-rollout-and-maintenance.md`
