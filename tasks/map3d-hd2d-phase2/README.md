# 3D 地图第二阶段：HD2D 效果和角色动画任务包

## 背景

第一阶段 3D 六边形地图和正式 Run 接入相关工作已经完成，本任务包不继续修改第一阶段计划。第二阶段先把 HD2D 视觉效果做稳：角色帧动画、景深、光照、着色、雾、glow、假阴影和独立效果实验场。

## 总目标

执行后，项目应满足：

- 工程师透明序列帧可以作为 Godot `SpriteFrames` 播放。
- 工程师角色可以作为 `AnimatedSprite3D` 放进 3D 场景。
- 独立 HD2D 效果实验场可以从主菜单进入。
- 实验场能在透视 `Camera3D` 下稳定观察景深、光照、环境、着色、雾、glow 和假阴影。
- 实验场包含前景、中景角色、背景六边格/landmark 和发光样本，用于判断 HD2D 层次是否成立。
- 正式 Run 地图、战斗、商店、休息、事件等第一阶段已完成流程不被改动。
- 新增自动化测试覆盖角色动画资源、实验场结构、关键视觉参数和截图生成；HD2D 观感以截图和人工验收记录确认。

## 执行文件

1. `phase-2-hd2d-effect-lab-and-character-animation.md`
   把工程师透明序列帧转成 Godot 帧动画，并新增独立 HD2D 效果实验场。

## 全局约束

- 不改第一阶段已完成的任务文件。
- 不把 HD2D 实验场直接接进 `run_hex_map_3d.gd`。
- 不改变正式 Run 地图规则、节点状态、战斗返回或商店/休息/事件流程。
- 不移动原始 `assets/generated/enginner_stand_transparent/` 目录。
- 不要求 Blender 参与角色帧动画转换。
- 不提交 `output/` 截图、临时日志、`.godot/` 缓存。

## 最小验证命令

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_camera_controls.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_capture.gd
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
godot --headless --quit
```

## 完成定义

全部完成时，执行者需要记录：

- 新增的角色动画资源和场景。
- 新增的 HD2D 效果实验场文件。
- 景深、光照、着色、雾、glow、假阴影是否已接入实验场。
- `output/hd2d-effect-lab-1280x720.png` 的人工验收结论。
- 执行过的验证命令和结果。
- 哪些效果还需要进入正式 Run 地图前继续调参。

## 执行记录

日期：2026-06-14

新增角色动画资源和场景：

- `assets/generated/characters/engineer/engineer_stand.spriteframes.tres`
- `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`

新增 HD2D 效果实验场：

- `scripts/map3d/hd2d_effect_lab.gd`
- `scenes/map3d/hd2d_effect_lab.tscn`

已接入实验场的效果：

- 默认透视 `Camera3D` profile：`projection = 0`，`fov = 34.0`。
- 工程师 `AnimatedSprite3D` billboard stand 循环动画。
- `WorldEnvironment` 环境色、雾、glow 和 `CameraAttributesPractical` 远景 DOF。
- 暖主光 `DirectionalLight3D`、冷补光 `OmniLight3D`。
- 前景遮挡物、中景角色、背景六边格、发光样本和脚底假阴影。

截图验收：

- Headless 自动测试生成 `output/hd2d-effect-lab-1280x720.png`。当前 Godot headless 使用 dummy renderer，测试会写出结构化验收图，证明自动流程、文件生成和基础对比度成立。
- 真实显示驱动捕获生成 `output/hd2d-effect-lab-rendered-1280x720.png`。人工检查结论：角色主体可见且比首版更清楚，脚底假阴影、前景柱、背景六边格和发光样本可见；雾和 DOF 已从过重调轻，能作为 HD2D 方向验证样板。

已执行验证：

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_capture.gd
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_camera.gd
godot --headless --quit
godot --headless --script scripts/autotest/validate_project_standards.gd
python .codex/skills/godot-headless/scripts/run_capture_scene.py --project-root . --scene res://scenes/map3d/hd2d_effect_lab.tscn --output res://output/hd2d-effect-lab-rendered-1280x720.png --width 1280 --height 720
```

结果：全部命令退出码为 `0`。`validate_project_standards.gd` 通过并报告既有 `logs/`、`output/` 警告；Run 地图相机测试结束时仍有 ObjectDB/resource cache 清理噪声，未阻断退出码。

进入正式 Run 地图前仍需调参：

- 角色在透视 3D 镜头下尺寸已经可读，后续可按正式地块尺度继续微调 `pixel_size`。
- DOF/雾当前用于样板验证，接入正式 Run 地图前需要结合实际地图纵深和背景资产重新定焦。
- glow 样本可见但表现偏基础，后续需要绑定到真实地标/事件资源上检查曝光。
