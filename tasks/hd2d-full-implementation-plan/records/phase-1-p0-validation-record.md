# Phase 1 执行记录

阶段状态： [x] 已完成
本阶段目标：
- 把 `hd2d_effect_lab.tscn` 从静态展示升级为可验证遮挡、排序、比例和镜头取舍的 P0 技术验证场。
- 用固定截图矩阵和人工结论锁定当前阶段推荐方案。

输入资料：
- `tasks/hd2d-full-implementation-plan/phase-1-p0-occlusion-sorting-and-scale.md`
- `docs/Godot_HD2D_复刻技术方案与验证清单.md`
- `scenes/map3d/hd2d_effect_lab.tscn`
- `scripts/map3d/hd2d_effect_lab.gd`
- `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`
- `assets/generated/characters/engineer/engineer_stand.spriteframes.tres`

本轮完成项：
- 扩展 `scenes/map3d/hd2d_effect_lab.tscn`，新增：
  - `Stage/OcclusionSamples`
  - `Stage/HeightSamples`
  - `Stage/TransparentSamples`
  - `CharacterRoot/ComparisonSprites`
  - `Markers/MovementRoute`
  - `Markers/CameraProfiles`
- 让实验场具备最小可控移动：
  - `WASD` 控制主角色在 XZ 平面移动。
  - 方向键控制相机平移，鼠标右键/中键拖拽继续控制相机旋转，滚轮继续 dolly。
  - 主角色经过桥台区域时自动切换高度；脚底假阴影会跟随角色并同步高度。
- 补齐 P0 遮挡/排序样本：
  - 不透明墙体：`wall-front`、`wall-back`
  - 前景遮挡：`foreground-cover`
  - 桥/台阶高度变化：`bridge-top`
  - 角色 vs 角色：`sprite_sorting` 对照截图中包含两个比较角色
  - 透明雾 Plane：`transparent-zone`
  - 简单透明/发光特效：`transparent-zone` 与 `glow-side`
- 在 `scripts/map3d/hd2d_effect_lab.gd` 中加入：
  - `apply_validation_profile()`
  - `move_player_to_route_marker()`
  - `get_profile_capture_specs()`
  - `get_occlusion_capture_specs()`
  - 扩展版 `get_debug_profile()`
- 新增 `scripts/tools/capture_hd2d_phase1_matrix.gd`，用于批量导出 Phase 1 对照截图和样本截图。
- 导出 12 张 Phase 1 截图：
  - 对照矩阵：
    - `output/phase1/hd2d-phase1-perspective-shaded-1280x720.png`
    - `output/phase1/hd2d-phase1-perspective-unshaded-1280x720.png`
    - `output/phase1/hd2d-phase1-orthogonal-shaded-1280x720.png`
    - `output/phase1/hd2d-phase1-orthogonal-unshaded-1280x720.png`
    - `output/phase1/hd2d-phase1-perspective-y-billboard-1280x720.png`
    - `output/phase1/hd2d-phase1-perspective-fixed-facing-1280x720.png`
  - 遮挡/排序样本：
    - `output/phase1/hd2d-phase1-wall-front-1280x720.png`
    - `output/phase1/hd2d-phase1-wall-back-1280x720.png`
    - `output/phase1/hd2d-phase1-foreground-cover-1280x720.png`
    - `output/phase1/hd2d-phase1-bridge-top-1280x720.png`
    - `output/phase1/hd2d-phase1-transparent-zone-1280x720.png`
    - `output/phase1/hd2d-phase1-glow-side-1280x720.png`
- 锁定当前阶段推荐方案：
  - 默认手动验证 profile：`Perspective + Unshaded + Y-Billboard`
  - 默认镜头：`fov = 34.0`
  - 对照正交镜头：`size = 7.0`
  - 默认角色 `pixel_size = 0.0024`
- 锁定当前世界单位比例：
  - 角色源帧大小：`960 x 960`
  - 主角色 `pixel_size = 0.0024`，理论显示高度约 `2.304` world units
  - 比较角色 `pixel_size = 0.0022`，理论显示高度约 `2.112` world units
  - 前景柱体宽度：`0.35`
  - 桥顶平台宽度：`1.85`
  - 桥顶高度：`0.72`
  - 相机默认验证距离（PerspectiveCapture marker z）：`7.82`

本轮未完成项：
- `scripts/autotest/` 目录仍不存在，因此 Phase 1 文档建议的 `test_hd2d_effect_lab_scene.gd`、`test_hd2d_effect_lab_visual_profile.gd`、`test_hd2d_effect_lab_camera_controls.gd` 没有在本阶段补建；记录为 Phase 2 继续补齐的验证资产缺口。

验证命令：
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_effect_lab.tscn --quit-after 60`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --quit`
- `D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_hd2d_phase1_matrix.gd -- res://output/phase1 1280 720`

验证结果：
- `hd2d_effect_lab.tscn` headless 加载成功，退出码 `0`。
- 项目整体 `godot --headless --quit` 成功，退出码 `0`。
- Phase 1 批量截图脚本成功，输出 12 张 PNG。
- 人工验收结论：
  - `wall-front` / `wall-back`：主角色在墙体前后切换时遮挡关系稳定，没有反盖。
  - `foreground-cover`：前景柱体和 canopy 能稳定压住角色上半身，适合做树叶/近景挡片样本。
  - `bridge-top`：角色抬升到桥面后，假阴影和角色一起抬高，没有明显 z-fighting。
  - `transparent-zone`：角色在雾层和透明特效后仍可读，没有忽隐忽现。
  - `sprite_sorting` 对照矩阵：多角色前后关系在当前固定镜头下稳定，透明雾和平面特效不会把全部角色错误反盖。
  - `Perspective + Unshaded` 比 `Perspective + Shaded` 边缘更干净，主体更稳定。
  - `Perspective + Y-Billboard` 与 Full Billboard 清晰度接近，但更符合后续移动镜头下的自然朝向预期。
  - `Orthogonal` 比例更稳定，但舞台空间感明显变弱，因此保留为对照镜头而不是默认镜头。
  - `Perspective + Fixed Facing` 在当前角度下纸片感更明显，不作为默认方案。

是否达到阶段完成标准：
是

下一阶段入口：
`tasks/hd2d-full-implementation-plan/phase-2-visual-template-and-resource-rules.md`
