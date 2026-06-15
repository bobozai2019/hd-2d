# Phase 6 执行记录

阶段状态： [x] 已完成

本阶段目标：
- 验证 P0 火把是否能用 Godot 原生特效成立，不使用贴图火焰。
- 验证墙体、地板和 wall block 是否能被真实灯光影响。
- 验证 `1 / 3 / 6` 动态局部光 profile，并明确默认上限和压力边界。

输入资料：
- `tasks/hd2d-full-implementation-plan/phase-6-torch-material-and-dynamic-light-validation.md`
- `docs/hd2d/lighting_validation_plan.md`
- `docs/hd2d/performance_budget.md`
- `docs/hd2d/material_rules.md`

本轮完成项：
- 修复并扩展 `res://scenes/map3d/hd2d_lighting_validation_lab.tscn` 的脚本化验证场。
- 实现 P0 纯特效火把结构：
  - primitive 托架/火盆。
  - additive mesh 火舌。
  - additive glow volume。
  - 少量 `GPUParticles3D` 火星。
  - 暖色 `OmniLight3D` 和轻微 flicker。
- 明确禁用贴图火焰、`Sprite3D` 火焰和程序 `ImageTexture` 火焰。
- 增加 `lighting_profile=1/3/6` profile 支持。
- 扩展 `scripts/tools/capture_scene.gd`，支持把额外截图参数传给目标场景。
- 扩展 `scripts/autotest/test_hd2d_lighting_validation_lab.gd`，覆盖默认 3 光源、1 光源最小 profile 和 6 光源压力 profile。
- 更新制作规范：
  - `docs/hd2d/lighting_validation_plan.md`
  - `docs/hd2d/performance_budget.md`
  - `docs/hd2d/material_rules.md`
- 生成截图矩阵到 `output/lighting_validation/`。

截图矩阵和人工结论：
- `torch-effect-p0-1280x720.png`：通过。火焰由 mesh、glow volume 和 sparks 组成，没有方形贴片感，可作为 P0 火把模板继续调参。
- `material-light-response-1280x720.png`：通过。墙体、地板和 wall block 使用 shaded `StandardMaterial3D`，火把附近有暖色 falloff，暗部保持冷色层次。
- `dynamic-lights-1-1280x720.png`：通过。单火把能证明最小照明效果成立，但氛围偏弱，只适合最小场景或远景道具。
- `dynamic-lights-3-1280x720.png`：通过。角色轮廓清楚，墙地受光方向可读，推荐作为默认动态局部光上限。
- `dynamic-lights-6-pressure-1280x720.png`：需要调参，不作为默认方案。氛围增强明显，但前景火把和 glow 开始抢角色主体，保留为压力边界。

制作结论：
- 火把方案：采用 Godot 原生特效节点组合，不使用贴图火焰。
- 材质方案：墙、地、柱、block 默认使用 shaded `StandardMaterial3D`，高 roughness、低 specular。
- 多光源上限：默认 `3` 个动态局部光，`6` 只作为压力边界。
- 可进入正式 Run 地图：三光源 profile、P0 原生火把结构、shaded 墙地材质规则。
- 仅保留验证场：6 光源压力 profile、额外压力火把、过密 glow/particles 组合。

验证命令：
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_hd2d_lighting_validation_lab.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_lighting_validation_lab.tscn --quit-after 3`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --quit`
- `D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/torch-effect-p0-1280x720.png 1280 720 lighting_profile=3`
- `D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/material-light-response-1280x720.png 1280 720 lighting_profile=3`
- `D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/dynamic-lights-1-1280x720.png 1280 720 lighting_profile=1`
- `D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/dynamic-lights-3-1280x720.png 1280 720 lighting_profile=3`
- `D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_lighting_validation_lab.tscn res://output/lighting_validation/dynamic-lights-6-pressure-1280x720.png 1280 720 lighting_profile=6`

验证结果：
- 自动测试通过，输出 `PASS test_hd2d_lighting_validation_lab`。
- `hd2d_lighting_validation_lab.tscn` headless 加载成功，退出码 `0`。
- 项目 headless 加载成功，退出码 `0`。
- 5 张阶段截图均已生成，分辨率为 `1280x720`。
- 本地 Godot 可执行文件路径为 `D:\godot\Godot_v4.6.2\godot.exe`，实际输出版本为 `Godot Engine v4.7.beta.custom_build.dff2b9bb6`。

是否达到阶段完成标准：
是

下一阶段入口：
- 把三光源 P0 火把模板接入正式 Run 地图前，先基于具体地图布局重新摆放火把，避免 foreground glow 压住角色主体。
