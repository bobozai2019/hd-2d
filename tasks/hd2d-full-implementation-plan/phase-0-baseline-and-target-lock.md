# 阶段 0：基线和目标锁定

阶段状态： `[x]` 已完成

## 目标

确认当前 HD-2D 实验场、已有任务包和项目配置的真实状态，形成后续阶段的截图基线、验证入口和目标效果说明。

本阶段不追求新增效果，只做对齐和记录。完成后，执行者应清楚：

- 现在已经有什么。
- 哪些内容来自既有任务包。
- 下一阶段要优先补哪些 P0 风险。
- 用哪些命令证明当前项目可加载。

## 输入资料

先阅读：

- `docs/Godot_HD2D_复刻技术方案与验证清单.md`
- `tasks/map3d-hd2d-phase2/README.md`
- `tasks/map3d-hd2d-phase2/phase-2-hd2d-effect-lab-and-character-animation.md`
- `tasks/map3d-formal-run-integration/README.md`
- `project.godot`
- `scenes/map3d/hd2d_effect_lab.tscn`
- `scripts/map3d/hd2d_effect_lab.gd`
- `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`

## [x] 任务 0.1：确认 Godot 版本和项目设置

检查并记录：

- `project.godot` 的 `config/features` 是否仍为 Godot 4.6。
- 渲染器是否为 Forward Plus。
- Windows 渲染 driver 是否仍为 `d3d12`。
- 主场景是否指向当前项目入口。

若发现任务文档写 Godot 4.7，但项目仍是 4.6，记录为文档修正项。除非用户明确要求升级，否则后续计划按 Godot 4.6 执行。

## [x] 任务 0.2：记录当前 HD2D 实验场结构

检查 `scenes/map3d/hd2d_effect_lab.tscn` 是否包含：

- `WorldEnvironment`
- `Lighting/KeyLight`
- `Lighting/FillLight`
- `Stage/Ground`
- `Stage/ForegroundProps`
- `Stage/BackgroundTiles`
- `Stage/GlowSample`
- `Stage/FakeShadow`
- `CharacterRoot/EngineerStandAnimatedSprite3D`
- `CameraRig/Camera3D`

记录当前关键参数：

- Camera projection、FOV、size、位置和角度。
- `Environment` 中 Glow、Fog、Ambient、Tonemap 参数。
- `CameraAttributesPractical` 中 DOF 参数。
- 工程师角色 `pixel_size`、`billboard`、`texture_filter`、`shaded`、`alpha_cut`。

## [x] 任务 0.3：生成当前截图基线

使用现有截图流程生成实验场截图：

```bash
python .codex/skills/godot-headless/scripts/run_capture_scene.py --project-root . --scene res://scenes/map3d/hd2d_effect_lab.tscn --output res://output/hd2d-baseline-1280x720.png --width 1280 --height 720
```

人工检查并记录：

- 角色是否可见。
- 角色是否清晰。
- 前景、角色、背景是否有层次。
- Glow 样本是否可见。
- 雾和 DOF 是否过强。
- 假阴影是否贴脚。

截图文件只作本地验收，不提交 `output/`。

## [x] 任务 0.4：建立目标效果描述

在阶段执行记录中写下项目当前 HD-2D 目标图像：

```text
角色是清晰的 2D 像素/序列帧纸片，但不漂浮。
舞台是低饱和、有厚度、有前中后景的 3D 微缩空间。
光照有冷暖主次，后处理服务层次，不牺牲主体清晰度。
正式 Run 地图最终要继承这套视觉公式，而不是只保留在实验场。
```

## [x] 任务 0.5：运行基线验证

运行：

```bash
godot --headless --quit
```

如果已有 HD2D 自动测试存在，也运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_capture.gd
```

如果测试脚本不存在，记录为阶段 1 或阶段 2 需要补齐的验证资产，不在本阶段临时创建。

## 阶段完成标准

- 当前实验场结构和关键参数已记录。
- 当前截图基线已生成并人工检查。
- Godot 版本和文档版本差异已明确。
- `godot --headless --quit` 可运行，或失败原因已定位到环境/PATH/项目加载问题。
- 下一阶段 P0 风险列表已确认：遮挡、排序、清晰度、比例、Billboard、镜头。
