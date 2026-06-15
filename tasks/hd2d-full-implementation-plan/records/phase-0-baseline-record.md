# Phase 0 执行记录

阶段状态： [x] 已完成
本阶段目标：
- 锁定当前 HD-2D 实验场、既有任务包、项目配置、截图基线和验证入口。
- 明确下一阶段优先处理的 P0 风险。

输入资料：
- `docs/Godot_HD2D_复刻技术方案与验证清单.md`
- `tasks/map3d-hd2d-phase2/README.md`
- `tasks/map3d-hd2d-phase2/phase-2-hd2d-effect-lab-and-character-animation.md`
- `tasks/map3d-formal-run-integration/README.md`
- `project.godot`
- `scenes/map3d/hd2d_effect_lab.tscn`
- `scripts/map3d/hd2d_effect_lab.gd`
- `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`

本轮完成项：
- 确认 `project.godot` 仍声明 `config/features=PackedStringArray("4.6", "Forward Plus")`，Windows 渲染 driver 为 `d3d12`，主场景 UID `uid://bihnyn1xo5cek` 对应 `res://scenes/map3d/hd2d_effect_lab.tscn`。
- 记录文档差异：`tasks/map3d-hd2d-phase2/phase-2-hd2d-effect-lab-and-character-animation.md` 仍写 Godot 4.7，但项目配置仍是 Godot 4.6，应按 4.6 继续执行并把 4.7 视为文档修正项。
- 记录运行环境差异：本机验证命令实际启动的是 `Godot Engine v4.7.beta.custom_build.dff2b9bb6 (2026-05-29)`，与项目配置版本不同，后续阶段需要继续关注兼容性。
- 记录当前实验场结构存在 `WorldEnvironment`、`Lighting/KeyLight`、`Lighting/FillLight`、`Stage/Ground`、`Stage/ForegroundProps`、`Stage/BackgroundTiles`、`Stage/GlowSample`、`Stage/FakeShadow`、`CharacterRoot/EngineerStandAnimatedSprite3D`、`CameraRig/Camera3D`。
- 记录关键参数：
  - Camera: `projection=Perspective`，`fov=34.0`，`size=12.0`，`far=80.0`，`CameraRig.position=(0, 5, 7.2)`。
  - CameraRig basis 对应俯角视角，控制脚本默认 `camera_move_speed=4.8`、`camera_rotate_sensitivity=0.006`、`camera_wheel_dolly_step=0.9`、`camera_min_pitch=-1.15`、`camera_max_pitch=-0.12`。
  - Environment: `ambient_light_source=Color`，`ambient_light_energy=0.72`，`tonemap_mode=ACES`，`tonemap_exposure=1.05`，`tonemap_white=1.4`，`glow_enabled=true`，`glow_intensity=0.18`，`glow_strength=0.42`，`fog_enabled=true`，`fog_density=0.006`。
  - CameraAttributesPractical: `dof_blur_far_enabled=true`，`dof_blur_far_distance=13.0`，`dof_blur_far_transition=2.8`，`dof_blur_amount=0.06`。
  - Engineer `AnimatedSprite3D`: `pixel_size=0.0024`，`billboard=1`，`texture_filter=1`，`shaded=true`，`alpha_cut=1`，`alpha_scissor_threshold=0.02`，`cast_shadow=0`。
- 使用 `C:\Python313\python.exe .codex/skills/godot-headless/scripts/sync_capture_scene.py --project-root . --force` 同步 `scripts/tools/capture_scene.gd`。
- 生成本地截图 `output/hd2d-baseline-1280x720.png`，人工检查结论：
  - 角色可见且清晰，像素边缘可读。
  - 前景柱体、角色、背景六边格存在层次，但层次对比仍偏轻，符合“实验场偏静态展示”的现状判断。
  - Glow 样本可见。
  - 雾和 DOF 当前较克制，没有明显把主体糊掉。
  - 假阴影可见且基本贴脚。
- 写下当前目标效果描述：
  - 角色是清晰的 2D 像素/序列帧纸片，但不漂浮。
  - 舞台是低饱和、有厚度、有前中后景的 3D 微缩空间。
  - 光照有冷暖主次，后处理服务层次，不牺牲主体清晰度。
  - 正式 Run 地图最终要继承这套视觉公式，而不是只保留在实验场。
- 确认下一阶段 P0 风险列表：遮挡、排序、清晰度、比例、Billboard、镜头。

本轮未完成项：
- `scripts/autotest/` 目录当前不存在，因此 Phase 0 提到的 `test_hd2d_character_animation_assets.gd`、`test_hd2d_effect_lab_scene.gd`、`test_hd2d_effect_lab_visual_profile.gd`、`test_hd2d_effect_lab_capture.gd` 在现工作区内缺失；按阶段要求记录为后续验证资产缺口，不在本阶段临时补建。

验证命令：
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --quit`
- `C:\Python313\python.exe .codex/skills/godot-headless/scripts/sync_capture_scene.py --project-root . --force`
- `C:\Python313\python.exe .codex/skills/godot-headless/scripts/run_capture_scene.py --project-root . --scene res://scenes/map3d/hd2d_effect_lab.tscn --output res://output/hd2d-baseline-1280x720.png --width 1280 --height 720`

验证结果：
- `godot --headless --quit` 退出码为 `0`。
- `sync_capture_scene.py` 执行成功，`scripts/tools/capture_scene.gd` 已同步。
- 基线截图已生成：`output/hd2d-baseline-1280x720.png`。
- 自动测试脚本未运行，原因是 `scripts/autotest/` 不存在。

是否达到阶段完成标准：
是

下一阶段入口：
`tasks/hd2d-full-implementation-plan/phase-1-p0-occlusion-sorting-and-scale.md`
