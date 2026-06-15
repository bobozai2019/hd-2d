# 第二阶段：HD2D 效果实验场和角色帧动画

> **给 agentic 工作者：** 按仓库 `AGENTS.md` 和本地技能触发规则执行；只有用户明确要求时才使用 superpowers 工作流。步骤使用复选框（`- [x]`）语法进行跟踪。

**目标：** 在不影响正式 Run 地图流程的前提下，把工程师透明序列帧转成 Godot 3D 场景可用的帧动画，并新增一个独立 HD2D 效果实验场，用于稳定观察景深、光照、着色、阴影和角色 billboard 效果。

**架构：** 角色动画资源独立放在 `assets/generated/characters/engineer/` 和 `scenes/map3d/characters/`，不直接写进 Run 地图控制器。HD2D 效果实验场使用独立 `Node3D` 场景，复用现有 map3d 视觉资产和相机思路，只承载效果预览、调参和自动化加载验证。后续确认效果稳定后，再由正式 Run 地图按资源路径实例化角色或效果节点。

**技术栈：** Godot 4.7 GDScript、`SpriteFrames`、`AnimatedSprite3D`、`WorldEnvironment`、`CameraAttributesPractical`、`DirectionalLight3D`、`OmniLight3D`、`StandardMaterial3D`、headless 场景测试。

---

## 范围

第二阶段只做“可看、可测、可复用”的 HD2D 效果样板，不改变 Run 地图规则和战斗规则。

包含：

- 工程师 stand 透明 PNG 序列帧转成 `SpriteFrames`。
- 工程师 `AnimatedSprite3D` 场景。
- 独立 HD2D 效果实验场。
- 默认透视 `Camera3D` profile，以及正交参考 profile。
- 前景、中景角色、背景六边格/landmark 三层样板，用于观察景深和雾。
- 景深、光照、环境色、雾、glow、地面材质、假阴影的第一版可调参数。
- 透明边缘对比样本：至少保留默认角色和一个近景边缘检查位。
- 截图验收：固定桌面比例截图，检查画面非空、角色可见、主体清晰、背景有层次。
- 主菜单实验入口，可快速打开效果实验场。
- 自动化测试覆盖资源、场景结构、关键效果参数和截图文件生成；HD2D 观感最终以截图和人工验收记录为准。

不包含：

- 不接入正式 Run 地图节点生成。
- 不制作 walk/attack 动画。
- 不重做战斗场景。
- 不要求 Blender 参与角色动画转换。
- 不删除或替换 `scenes/map3d/run_hex_map_3d.tscn`。

## HD2D 视觉基准

第二阶段不是只验证 Godot 节点能加载，而是判断这套方向能不能复刻 HD2D 观感。执行时按以下基准验收：

- 相机：正式判断以透视 `Camera3D` 为准；正交镜头只作为对照参考，不能作为默认 HD2D 实验镜头。
- 构图：必须同时看到前景遮挡物、中景角色、背景六边格/landmark，不能只让角色站在空平面上。
- 景深：主体角色清楚，背景地块/landmark 轻微柔化；前景遮挡不能糊住主体。
- 光照：暖主光、冷补光，角色有体积感但不过曝，地面不被洗平。
- 着色：低饱和暗背景、暖色高光、角色亮度高于地面但不脱离场景。
- 透明边缘：深色、浅色和发光背景下都不能有明显黑边、白边或锯齿断裂。
- 假阴影：阴影跟随脚点，提供落地感，不遮住角色透明边缘，不发生 z-fighting。
- glow/雾：必须有可控发光源和深度参照；开启参数但画面不可见不算通过。

## 输入资源

当前已存在资源：

```text
assets/generated/enginner/stand/frame_000001.png
assets/generated/enginner/stand/frame_000002.png
assets/generated/enginner/stand/frame_000003.png
assets/generated/enginner/stand/frame_000004.png
assets/generated/enginner/stand/frame_000005.png
assets/generated/enginner/stand/frame_000006.png
assets/generated/enginner/stand/frame_000007.png
assets/generated/enginner/stand/frame_000008.png
assets/generated/enginner/stand/frame_000009.png
```

说明：

- 目录名当前拼写为 `enginner/stand`，计划中保持现有路径，避免移动资源导致 `.import` 和已有引用失效。
- 每张图为 `960x960` 透明 PNG。
- 第一版只生成 `stand` 循环动画，建议播放速度 `8 fps`。

## 文件计划

创建：

- `assets/generated/characters/engineer/engineer_stand.spriteframes.tres`
- `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`
- `scripts/map3d/hd2d_effect_lab.gd`
- `scenes/map3d/hd2d_effect_lab.tscn`
- `scripts/autotest/test_hd2d_character_animation_assets.gd`
- `scripts/autotest/test_hd2d_effect_lab_scene.gd`
- `scripts/autotest/test_hd2d_effect_lab_visual_profile.gd`
- `scripts/autotest/test_hd2d_effect_lab_capture.gd`

修改：

- `scenes/main/main.tscn`
- `scripts/main/main.gd`
- `scripts/autotest/test_main_menu_hex_map_entry.gd`
- `docs/production/04-asset-pipeline.md`
- `docs/production/05-validation-matrix.md`

检查：

- `assets/generated/enginner/stand/*.png`
- `assets/generated/enginner/stand/*.png.import`
- `scenes/map3d/run_hex_map_3d.tscn`
- `scripts/map3d/run_hex_map_3d.gd`

## 任务 2.1：建立工程师帧动画资源测试

**文件：**

- 创建：`scripts/autotest/test_hd2d_character_animation_assets.gd`
- 稍后创建：`assets/generated/characters/engineer/engineer_stand.spriteframes.tres`
- 稍后创建：`scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`

- [x] **步骤 1：写失败测试**

创建 `scripts/autotest/test_hd2d_character_animation_assets.gd`：

```gdscript
extends SceneTree

const SPRITE_FRAMES_PATH := "res://assets/generated/characters/engineer/engineer_stand.spriteframes.tres"
const ENGINEER_SCENE_PATH := "res://scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn"


func _init() -> void:
	var ok := true
	ok = _test_source_frames_exist() and ok
	ok = _test_sprite_frames_resource() and ok
	ok = _test_engineer_scene() and ok
	if ok:
		print("test_hd2d_character_animation_assets: PASS")
	quit(0 if ok else 1)


func _test_source_frames_exist() -> bool:
	for index in range(1, 10):
		var path := "res://assets/generated/enginner/stand/frame_%06d.png" % index
		if not ResourceLoader.exists(path):
			push_error("missing source frame: %s" % path)
			return false
	return true


func _test_sprite_frames_resource() -> bool:
	var frames := load(SPRITE_FRAMES_PATH) as SpriteFrames
	if frames == null:
		push_error("engineer SpriteFrames resource loads")
		return false
	if not frames.has_animation(&"stand"):
		push_error("engineer SpriteFrames has stand animation")
		return false
	if frames.get_frame_count(&"stand") != 9:
		push_error("stand animation has 9 frames")
		return false
	if not frames.get_animation_loop(&"stand"):
		push_error("stand animation loops")
		return false
	if absf(frames.get_animation_speed(&"stand") - 8.0) > 0.01:
		push_error("stand animation speed is 8 fps")
		return false
	return true


func _test_engineer_scene() -> bool:
	var packed := load(ENGINEER_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("engineer AnimatedSprite3D scene loads")
		return false
	var instance := packed.instantiate()
	var sprite := instance as AnimatedSprite3D
	var ok := true
	if sprite == null:
		push_error("engineer scene root is AnimatedSprite3D")
		ok = false
	elif sprite.sprite_frames == null:
		push_error("engineer scene has SpriteFrames")
		ok = false
	elif sprite.animation != &"stand":
		push_error("engineer scene defaults to stand")
		ok = false
	elif sprite.autoplay != "stand":
		push_error("engineer scene autoplays stand")
		ok = false
	elif sprite.pixel_size <= 0.0:
		push_error("engineer scene has positive pixel_size")
		ok = false
	instance.free()
	return ok
```

- [x] **步骤 2：运行测试验证失败**

运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
```

预期：

- 退出码为 `1`。
- 报错包含 `engineer SpriteFrames resource loads` 或 `engineer AnimatedSprite3D scene loads`。

## 任务 2.2：创建工程师 `SpriteFrames`

**文件：**

- 创建：`assets/generated/characters/engineer/engineer_stand.spriteframes.tres`
- 复用：`assets/generated/enginner/stand/frame_000001.png` 到 `frame_000009.png`

- [x] **步骤 1：创建目录**

运行：

```bash
New-Item -ItemType Directory -Force -Path 'assets/generated/characters/engineer'
```

预期：

- 目录存在。
- 不移动原始 PNG。

- [x] **步骤 2：写入 SpriteFrames 资源**

创建 `assets/generated/characters/engineer/engineer_stand.spriteframes.tres`：

```ini
[gd_resource type="SpriteFrames" load_steps=10 format=3]

[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000001.png" id="1"]
[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000002.png" id="2"]
[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000003.png" id="3"]
[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000004.png" id="4"]
[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000005.png" id="5"]
[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000006.png" id="6"]
[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000007.png" id="7"]
[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000008.png" id="8"]
[ext_resource type="Texture2D" path="res://assets/generated/enginner/stand/frame_000009.png" id="9"]

[resource]
animations = [{
"frames": [{
"duration": 1.0,
"texture": ExtResource("1")
}, {
"duration": 1.0,
"texture": ExtResource("2")
}, {
"duration": 1.0,
"texture": ExtResource("3")
}, {
"duration": 1.0,
"texture": ExtResource("4")
}, {
"duration": 1.0,
"texture": ExtResource("5")
}, {
"duration": 1.0,
"texture": ExtResource("6")
}, {
"duration": 1.0,
"texture": ExtResource("7")
}, {
"duration": 1.0,
"texture": ExtResource("8")
}, {
"duration": 1.0,
"texture": ExtResource("9")
}],
"loop": true,
"name": &"stand",
"speed": 8.0
}]
```

- [x] **步骤 3：运行资源测试验证仍失败在场景缺失**

运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
```

预期：

- `SpriteFrames` 相关断言通过。
- 测试仍失败，失败点为 `engineer AnimatedSprite3D scene loads`。

## 任务 2.3：创建工程师 `AnimatedSprite3D` 场景

**文件：**

- 创建：`scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`
- 使用：`assets/generated/characters/engineer/engineer_stand.spriteframes.tres`

- [x] **步骤 1：创建目录**

运行：

```bash
New-Item -ItemType Directory -Force -Path 'scenes/map3d/characters'
```

预期：

- 目录存在。

- [x] **步骤 2：创建角色场景**

创建 `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`：

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="SpriteFrames" path="res://assets/generated/characters/engineer/engineer_stand.spriteframes.tres" id="1"]

[node name="EngineerStandAnimatedSprite3D" type="AnimatedSprite3D"]
sprite_frames = ExtResource("1")
animation = &"stand"
autoplay = "stand"
centered = true
pixel_size = 0.00155
billboard = 1
texture_filter = 1
shaded = true
alpha_cut = 1
alpha_scissor_threshold = 0.02
cast_shadow = 0
```

参数说明：

- `pixel_size = 0.00155`：960px 角色约显示为 1.49 Godot unit 高，适合站在六边格地块上预览。
- `billboard = 1`：角色始终面向相机，符合 HD2D 纸片角色需求。
- `texture_filter = 1`：关闭过度模糊，保留插画/像素边缘。
- `shaded = true`：允许角色吃到 3D 光照，便于测试光照融合。
- `cast_shadow = 0`：第一版不用真实透明阴影，后续用假阴影稳定表现。

- [x] **步骤 3：运行角色资源测试**

运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
```

预期：

- 输出 `test_hd2d_character_animation_assets: PASS`。

## 任务 2.4：建立 HD2D 效果实验场场景测试

**文件：**

- 创建：`scripts/autotest/test_hd2d_effect_lab_scene.gd`
- 稍后创建：`scripts/map3d/hd2d_effect_lab.gd`
- 稍后创建：`scenes/map3d/hd2d_effect_lab.tscn`

- [x] **步骤 1：写失败测试**

创建 `scripts/autotest/test_hd2d_effect_lab_scene.gd`：

```gdscript
extends SceneTree

const LAB_SCENE_PATH := "res://scenes/map3d/hd2d_effect_lab.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_lab_scene_structure()
	if _failures.is_empty():
		print("test_hd2d_effect_lab_scene: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_lab_scene_structure() -> void:
	var packed := load(LAB_SCENE_PATH) as PackedScene
	if packed == null:
		_failures.append("HD2D effect lab scene loads")
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	current_scene = instance
	await process_frame
	await process_frame

	if not (instance is Node3D):
		_failures.append("HD2D effect lab root is Node3D")
	if instance.get_node_or_null("WorldEnvironment") == null:
		_failures.append("HD2D effect lab has WorldEnvironment")
	if instance.get_node_or_null("CameraRig/Camera3D") == null:
		_failures.append("HD2D effect lab has Camera3D")
	if instance.get_node_or_null("Lighting/KeyLight") == null:
		_failures.append("HD2D effect lab has KeyLight")
	if instance.get_node_or_null("Lighting/FillLight") == null:
		_failures.append("HD2D effect lab has FillLight")
	if instance.get_node_or_null("Stage/Ground") == null:
		_failures.append("HD2D effect lab has Ground")
	if instance.get_node_or_null("Stage/ForegroundProps") == null:
		_failures.append("HD2D effect lab has foreground props")
	if instance.get_node_or_null("Stage/BackgroundTiles") == null:
		_failures.append("HD2D effect lab has background depth samples")
	if instance.get_node_or_null("Stage/GlowSample") == null:
		_failures.append("HD2D effect lab has visible glow sample")
	if instance.get_node_or_null("CharacterRoot/EngineerStandAnimatedSprite3D") == null:
		_failures.append("HD2D effect lab has engineer character")

	var engineer := instance.get_node_or_null("CharacterRoot/EngineerStandAnimatedSprite3D") as AnimatedSprite3D
	if engineer == null or not engineer.is_playing():
		_failures.append("engineer stand animation plays after entering tree")

	var profile := {}
	if instance.has_method("get_debug_profile"):
		profile = instance.call("get_debug_profile")
	if profile.get("camera_projection", -1) != Camera3D.PROJECTION_PERSPECTIVE:
		_failures.append("default lab profile uses perspective Camera3D")
	if profile.get("character_count", 0) < 1:
		_failures.append("debug profile reports visible character")

	instance.queue_free()
	await process_frame
```

- [x] **步骤 2：运行测试验证失败**

运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
```

预期：

- 退出码为 `1`。
- 报错包含 `HD2D effect lab scene loads`。

## 任务 2.5：创建 HD2D 效果实验场脚本和场景

**文件：**

- 创建：`scripts/map3d/hd2d_effect_lab.gd`
- 创建：`scenes/map3d/hd2d_effect_lab.tscn`
- 复用：`scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn`

- [x] **步骤 1：创建实验场脚本**

创建 `scripts/map3d/hd2d_effect_lab.gd`：

```gdscript
extends Node3D

const RUN_MAP_CAMERA_POSITION := Vector3(0.0, 8.0, 9.0)
const RUN_MAP_CAMERA_LOOK_AT := Vector3(0.0, 0.0, 0.0)
const CLOSE_CAMERA_POSITION := Vector3(0.0, 3.4, 5.2)
const CLOSE_CAMERA_LOOK_AT := Vector3(0.0, 0.8, 0.0)

@onready var _camera_rig: Node3D = $CameraRig
@onready var _camera: Camera3D = $CameraRig/Camera3D
@onready var _character_root: Node3D = $CharacterRoot


func _ready() -> void:
	apply_perspective_3d_profile()
	_play_character_stand()


func reset_view() -> void:
	apply_perspective_3d_profile()


func apply_perspective_3d_profile() -> void:
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 34.0
	_camera_rig.position = PERSPECTIVE_CAMERA_POSITION
	_camera_rig.look_at(PERSPECTIVE_CAMERA_LOOK_AT, Vector3.UP)


func apply_close_preview_profile() -> void:
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 34.0
	_camera_rig.position = CLOSE_CAMERA_POSITION
	_camera_rig.look_at(CLOSE_CAMERA_LOOK_AT, Vector3.UP)


func get_debug_profile() -> Dictionary:
	return {
		"camera_position": _camera_rig.position,
		"camera_projection": _camera.projection,
		"camera_size": _camera.size,
		"camera_fov": _camera.fov,
		"character_count": _character_root.get_child_count(),
	}


func _play_character_stand() -> void:
	for child in _character_root.get_children():
		if child is AnimatedSprite3D:
			var sprite := child as AnimatedSprite3D
			sprite.play(&"stand")
```

- [x] **步骤 2：创建实验场场景**

创建 `scenes/map3d/hd2d_effect_lab.tscn`：

```ini
[gd_scene load_steps=1 format=3]

[ext_resource type="Script" path="res://scripts/map3d/hd2d_effect_lab.gd" id="1"]
[ext_resource type="PackedScene" path="res://scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn" id="2"]

[sub_resource type="Environment" id="Environment_hd2d"]
background_mode = 1
background_color = Color(0.035, 0.039, 0.045, 1)
ambient_light_source = 2
ambient_light_color = Color(0.62, 0.58, 0.52, 1)
ambient_light_energy = 0.72
tonemap_mode = 2
tonemap_exposure = 1.05
tonemap_white = 1.4
glow_enabled = true
glow_intensity = 0.18
glow_strength = 0.42
fog_enabled = true
fog_light_color = Color(0.48, 0.52, 0.58, 1)
fog_density = 0.018

[sub_resource type="CameraAttributesPractical" id="CameraAttributes_hd2d"]
dof_blur_far_enabled = true
dof_blur_far_distance = 7.0
dof_blur_far_transition = 2.4
dof_blur_amount = 0.18

[sub_resource type="StandardMaterial3D" id="Material_ground"]
albedo_color = Color(0.19, 0.22, 0.19, 1)
roughness = 0.86

[sub_resource type="StandardMaterial3D" id="Material_background_tile"]
albedo_color = Color(0.16, 0.20, 0.18, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="Material_foreground"]
albedo_color = Color(0.09, 0.11, 0.10, 1)
roughness = 0.86

[sub_resource type="StandardMaterial3D" id="Material_glow"]
albedo_color = Color(0.80, 0.56, 0.24, 1)
emission_enabled = true
emission = Color(0.95, 0.62, 0.24, 1)
emission_energy_multiplier = 1.2
roughness = 0.55

[sub_resource type="PlaneMesh" id="PlaneMesh_ground"]
size = Vector2(10, 10)

[sub_resource type="CylinderMesh" id="CylinderMesh_hex_sample"]
top_radius = 0.95
bottom_radius = 0.95
height = 0.12
radial_segments = 6
rings = 1

[sub_resource type="BoxMesh" id="BoxMesh_foreground"]
size = Vector3(0.35, 0.9, 0.35)

[sub_resource type="StandardMaterial3D" id="Material_shadow"]
albedo_color = Color(0, 0, 0, 0.32)
transparency = 1
roughness = 1.0

[sub_resource type="CylinderMesh" id="CylinderMesh_shadow"]
top_radius = 0.62
bottom_radius = 0.62
height = 0.01
radial_segments = 32
rings = 1

[node name="Hd2dEffectLab" type="Node3D"]
script = ExtResource("1")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_hd2d")
camera_attributes = SubResource("CameraAttributes_hd2d")

[node name="Lighting" type="Node3D" parent="."]

[node name="KeyLight" type="DirectionalLight3D" parent="Lighting"]
transform = Transform3D(0.573576, -0.579228, 0.579228, 0, 0.707107, 0.707107, -0.819152, -0.40558, 0.40558, 0, 5, 0)
light_energy = 2.15
shadow_enabled = true

[node name="FillLight" type="OmniLight3D" parent="Lighting"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2.2, 2.1, 2.8)
light_color = Color(0.52, 0.64, 0.85, 1)
light_energy = 0.42
omni_range = 6.0

[node name="Stage" type="Node3D" parent="."]

[node name="Ground" type="MeshInstance3D" parent="Stage"]
material_override = SubResource("Material_ground")
mesh = SubResource("PlaneMesh_ground")

[node name="ForegroundProps" type="Node3D" parent="Stage"]

[node name="ForegroundPillarLeft" type="MeshInstance3D" parent="Stage/ForegroundProps"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.6, 0.45, 1.2)
material_override = SubResource("Material_foreground")
mesh = SubResource("BoxMesh_foreground")

[node name="BackgroundTiles" type="Node3D" parent="Stage"]

[node name="BackgroundTileNear" type="MeshInstance3D" parent="Stage/BackgroundTiles"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.15, 0.06, -1.25)
material_override = SubResource("Material_background_tile")
mesh = SubResource("CylinderMesh_hex_sample")

[node name="BackgroundTileFar" type="MeshInstance3D" parent="Stage/BackgroundTiles"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.15, 0.06, -3.2)
material_override = SubResource("Material_background_tile")
mesh = SubResource("CylinderMesh_hex_sample")

[node name="GlowSample" type="MeshInstance3D" parent="Stage"]
transform = Transform3D(0.42, 0, 0, 0, 0.03, 0, 0, 0, 0.42, 0, 0.03, -1.7)
material_override = SubResource("Material_glow")
mesh = SubResource("CylinderMesh_hex_sample")

[node name="FakeShadow" type="MeshInstance3D" parent="Stage"]
transform = Transform3D(1.0, 0, 0, 0, 0.02, 0, 0, 0, 0.58, 0, 0.018, 0.12)
material_override = SubResource("Material_shadow")
mesh = SubResource("CylinderMesh_shadow")
cast_shadow = 0

[node name="CharacterRoot" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0)

[node name="EngineerStandAnimatedSprite3D" parent="CharacterRoot" instance=ExtResource("2")]

[node name="CameraRig" type="Node3D" parent="."]

[node name="Camera3D" type="Camera3D" parent="CameraRig"]
current = true
projection = 1
size = 12.0
fov = 34.0
near = 0.05
far = 80.0
```

说明：

- `load_steps` 不需要手算，执行者创建后以 Godot 保存后的实际值为准。
- 默认 `Camera3D` 必须使用 `projection = 1` 和 `size = 12.0`，复刻正式 Run 地图相机；`apply_close_preview_profile()` 只作为近景调参辅助。
- `ForegroundProps`、`CharacterRoot`、`BackgroundTiles` 和 `GlowSample` 都是验收对象，不能因为“先简单”删掉。

- [x] **步骤 3：运行场景结构测试**

运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
```

预期：

- 输出 `test_hd2d_effect_lab_scene: PASS`。

## 任务 2.6：锁定 HD2D 结构和参数测试

**文件：**

- 创建：`scripts/autotest/test_hd2d_effect_lab_visual_profile.gd`
- 检查：`scenes/map3d/hd2d_effect_lab.tscn`

- [x] **步骤 1：写结构和参数测试**

创建 `scripts/autotest/test_hd2d_effect_lab_visual_profile.gd`：

```gdscript
extends SceneTree

const LAB_SCENE_PATH := "res://scenes/map3d/hd2d_effect_lab.tscn"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_visual_profile()
	if _failures.is_empty():
		print("test_hd2d_effect_lab_visual_profile: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _test_visual_profile() -> void:
	var packed := load(LAB_SCENE_PATH) as PackedScene
	if packed == null:
		_failures.append("HD2D effect lab scene loads")
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	current_scene = instance
	await process_frame
	await process_frame

	var world_environment := instance.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var camera := instance.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var key_light := instance.get_node_or_null("Lighting/KeyLight") as DirectionalLight3D
	var fill_light := instance.get_node_or_null("Lighting/FillLight") as OmniLight3D
	var engineer := instance.get_node_or_null("CharacterRoot/EngineerStandAnimatedSprite3D") as AnimatedSprite3D

	if world_environment == null or world_environment.environment == null:
		_failures.append("WorldEnvironment has environment")
	else:
		var env := world_environment.environment
		if not env.glow_enabled:
			_failures.append("HD2D profile enables glow")
		if not env.fog_enabled:
			_failures.append("HD2D profile enables fog")
		if env.ambient_light_energy < 0.45:
			_failures.append("HD2D profile has enough ambient light for sprites")

	if world_environment == null or world_environment.camera_attributes == null:
		_failures.append("WorldEnvironment has camera attributes")
	elif not world_environment.camera_attributes.dof_blur_far_enabled:
		_failures.append("HD2D profile enables far DOF")

	if camera == null or not camera.current:
		_failures.append("lab camera is current")
	elif camera.projection != Camera3D.PROJECTION_PERSPECTIVE:
		_failures.append("default lab camera uses perspective Camera3D")
	elif absf(camera.size - 12.0) > 0.01:
		_failures.append("default lab camera size matches Run map")
	if key_light == null or not key_light.shadow_enabled:
		_failures.append("key light casts shadows")
	if fill_light == null or fill_light.light_energy <= 0.0:
		_failures.append("fill light exists and has energy")
	if engineer == null:
		_failures.append("engineer sprite exists")
	elif engineer.sprite_frames == null or engineer.sprite_frames.get_frame_count(&"stand") != 9:
		_failures.append("engineer stand animation remains wired")
	elif not engineer.is_playing():
		_failures.append("engineer stand animation is playing")

	if instance.get_node_or_null("Stage/ForegroundProps") == null:
		_failures.append("foreground props exist for DOF/depth checks")
	if instance.get_node_or_null("Stage/BackgroundTiles/BackgroundTileFar") == null:
		_failures.append("far background tile exists for DOF/fog checks")
	if instance.get_node_or_null("Stage/GlowSample") == null:
		_failures.append("glow sample exists")
	if instance.get_node_or_null("Stage/FakeShadow") == null:
		_failures.append("fake shadow exists")

	instance.queue_free()
	await process_frame
```

- [x] **步骤 2：运行结构和参数测试**

运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
```

预期：

- 输出 `test_hd2d_effect_lab_visual_profile: PASS`。

说明：

- 该测试只证明实验场结构、关键参数和运行时 `_ready()` 能正常执行。
- 它不证明最终 HD2D 观感成立；观感必须通过任务 2.7 的截图验收和手动记录判断。

## 任务 2.7：增加 HD2D 截图验收

**文件：**

- 创建：`scripts/autotest/test_hd2d_effect_lab_capture.gd`
- 可生成但不提交：`output/hd2d-effect-lab-1280x720.png`
- 检查：`scenes/map3d/hd2d_effect_lab.tscn`

- [x] **步骤 1：写截图生成测试**

创建 `scripts/autotest/test_hd2d_effect_lab_capture.gd`：

```gdscript
extends SceneTree

const LAB_SCENE_PATH := "res://scenes/map3d/hd2d_effect_lab.tscn"
const OUTPUT_PATH := "res://output/hd2d-effect-lab-1280x720.png"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _capture_lab()
	if _failures.is_empty():
		print("test_hd2d_effect_lab_capture: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _capture_lab() -> void:
	var packed := load(LAB_SCENE_PATH) as PackedScene
	if packed == null:
		_failures.append("HD2D effect lab scene loads")
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	current_scene = instance
	root.get_viewport().size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	await process_frame

	var image := root.get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_failures.append("captured image is non-empty")
	else:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output"))
		var error := image.save_png(OUTPUT_PATH)
		if error != OK:
			_failures.append("saves HD2D effect lab screenshot")
		_assert_image_has_visible_content(image)

	instance.queue_free()
	await process_frame


func _assert_image_has_visible_content(image: Image) -> void:
	var sample_points := [
		Vector2i(320, 360),
		Vector2i(640, 360),
		Vector2i(960, 360),
		Vector2i(640, 520),
	]
	var min_luma := 10.0
	var max_luma := 0.0
	for point in sample_points:
		var color := image.get_pixelv(point)
		var luma := (color.r + color.g + color.b) / 3.0
		min_luma = minf(min_luma, luma)
		max_luma = maxf(max_luma, luma)
	if max_luma - min_luma < 0.04:
		_failures.append("screenshot has visible contrast")
```

- [x] **步骤 2：运行截图测试**

运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_effect_lab_capture.gd
```

预期：

- 输出 `test_hd2d_effect_lab_capture: PASS`。
- 本地生成 `output/hd2d-effect-lab-1280x720.png`。
- `output/` 文件不提交，只作为阶段验收记录。

- [x] **步骤 3：人工检查截图**

人工检查 `output/hd2d-effect-lab-1280x720.png`：

- 角色主体可见，站在地面上，脚底阴影位置合理。
- 前景、中景角色、背景地块/landmark 有明确层次。
- 透视 3D 摄像机下主体仍清楚。
- 远处背景有雾/景深感，但没有把主体洗灰。
- glow 样本在画面中可见。
- 深色背景附近角色透明边缘没有明显黑边。

## 任务 2.8：给主菜单增加 HD2D 实验场入口

**文件：**

- 修改：`scenes/main/main.tscn`
- 修改：`scripts/main/main.gd`
- 修改：`scripts/autotest/test_main_menu_hex_map_entry.gd`

- [x] **步骤 1：扩展主菜单测试**

在 `scripts/autotest/test_main_menu_hex_map_entry.gd` 中增加对新按钮的断言。测试应检查：

```gdscript
func _run() -> void:
	await _test_hex_map_entry_button_changes_scene()
	await _test_hd2d_effect_lab_button_changes_scene()
	_finish()


func _test_hd2d_effect_lab_button_changes_scene() -> void:
	var instance := await _spawn_main_scene()
	if instance == null:
		return

	var button := instance.get_node_or_null("UiLayer/MenuRoot/ButtonColumn/Hd2dEffectLabButton") as Button
	_assert(button != null, "Hd2dEffectLabButton exists")
	if button == null:
		await _cleanup_current_scene()
		return

	_assert(not button.disabled, "Hd2dEffectLabButton is clickable")
	button.pressed.emit()
	await process_frame
	await process_frame

	_assert(current_scene != null, "HD2D effect lab scene change keeps a current scene")
	_assert(current_scene != null and current_scene.scene_file_path == "res://scenes/map3d/hd2d_effect_lab.tscn", "Hd2dEffectLabButton opens HD2D effect lab scene")
	await _cleanup_current_scene()


func _spawn_main_scene() -> Node:
	var packed: PackedScene = load("res://scenes/main/main.tscn")
	_assert(packed != null, "main scene loads")
	if packed == null:
		return null
	var instance := packed.instantiate()
	_assert(instance != null, "main scene instantiates")
	if instance == null:
		return null
	root.add_child(instance)
	current_scene = instance
	await process_frame
	return instance


func _cleanup_current_scene() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
```

同时把现有 `_test_hex_map_entry_button_changes_scene()` 改为复用 `_spawn_main_scene()` 和 `_cleanup_current_scene()`，保证两个入口测试互相独立。

- [x] **步骤 2：运行测试验证失败**

运行：

```bash
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
```

预期：

- 失败点为 `Hd2dEffectLabButton exists`。

- [x] **步骤 3：修改主菜单场景**

在 `scenes/main/main.tscn` 的 `ButtonColumn` 下新增按钮：

```ini
[node name="Hd2dEffectLabButton" type="Button" parent="UiLayer/MenuRoot/ButtonColumn"]
custom_minimum_size = Vector2(180, 44)
layout_mode = 2
text = "HD2D Effect Lab"
```

位置建议放在 `HexMapMvpButton` 后面，明确它是 3D/HD2D 实验入口。`ButtonColumn` 当前按三个按钮高度设置，新增按钮后同步扩大 `offset_top/offset_bottom`，避免按钮溢出。

- [x] **步骤 4：修改主菜单脚本**

在 `scripts/main/main.gd` 中增加节点引用和信号：

```gdscript
@onready var _hd2d_effect_lab_button: Button = $UiLayer/MenuRoot/ButtonColumn/Hd2dEffectLabButton


# 在现有 _ready() 中追加这一行，不替换已有 settings layer 初始化和按钮连接。
_hd2d_effect_lab_button.pressed.connect(_open_hd2d_effect_lab)


func _open_hd2d_effect_lab() -> void:
	get_tree().change_scene_to_file("res://scenes/map3d/hd2d_effect_lab.tscn")
```

不得重写现有 `_ready()`。保留 `_settings_layer` 初始化、`StartBattleButton`、`HexMapMvpButton` 和 `SettingsButton` 的现有连接，只追加 HD2D 按钮连接。

- [x] **步骤 5：运行主菜单入口测试**

运行：

```bash
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
```

预期：

- 输出 `test_main_menu_hex_map_entry: PASS`。

## 任务 2.9：补资产和验证文档

**文件：**

- 修改：`docs/production/04-asset-pipeline.md`
- 修改：`docs/production/05-validation-matrix.md`

- [x] **步骤 1：更新资产规范**

在 `docs/production/04-asset-pipeline.md` 增加一节：

```markdown
### HD2D 角色帧动画和效果实验场

- 透明序列帧源资源可以保留在 `assets/generated/<name>_transparent/`，不要为了重命名移动已导入资源。
- Godot 可播放资源放在 `assets/generated/characters/<character>/`，优先使用 `.spriteframes.tres`。
- 3D 场景角色使用 `AnimatedSprite3D`，角色场景放在 `scenes/map3d/characters/`。
- 第一版 HD2D 角色动画必须至少有一个循环 `stand` 动画。
- 效果实验场放在 `scenes/map3d/hd2d_effect_lab.tscn`，只用于视觉稳定和调参，不作为正式 Run 地图入口。
- 透明角色默认使用 billboard 面向相机，真实阴影不稳定时使用地面假阴影。
```

- [x] **步骤 2：更新验证矩阵**

在 `docs/production/05-validation-matrix.md` 的相关验证命令中新增：

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_capture.gd
```

在“修改范围与验证”中新增一行：

```text
HD2D 效果实验场/角色帧动画 | test_hd2d_character_animation_assets.gd、test_hd2d_effect_lab_scene.gd、test_hd2d_effect_lab_visual_profile.gd、test_hd2d_effect_lab_capture.gd、test_main_menu_hex_map_entry.gd
```

## 任务 2.10：最终验证

**文件：**

- 检查第二阶段所有新增/修改文件。

- [x] **步骤 1：运行第二阶段最小验证**

运行：

```bash
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_capture.gd
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
```

预期：

- 五个脚本全部退出码为 `0`。
- 每个脚本输出 `PASS`。

- [x] **步骤 2：运行地图回归验证**

运行：

```bash
godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_camera.gd
godot --headless --quit
```

预期：

- 3D Run 地图测试仍通过。
- 项目 headless 加载退出码为 `0`。

- [x] **步骤 3：运行规范校验**

运行：

```bash
godot --headless --script scripts/autotest/validate_project_standards.gd
```

预期：

- 不出现新增 `ERROR`。
- 如果仍有既有 `logs/`、`output/` 警告，在执行记录中标注为既有工作区状态。

## 手动验收流程

1. 正常启动项目。
2. 从主菜单点击 `HD2D Effect Lab`。
3. 确认工程师角色自动播放 stand 动画，没有明显透明黑边。
4. 移动观察窗口或调整场景视角时，角色始终面向相机。
5. 确认远景有轻微景深和雾，但角色主体保持清楚。
6. 确认主光方向让角色和地面有体积感，补光不把画面洗平。
7. 确认假阴影在角色脚下，透明度不抢眼。
8. 返回主菜单或重启项目后，正式 Run 地图入口仍进入 `run_hex_map_3d.tscn`。

## 阶段完成标准

- 工程师 `stand` 透明序列帧已转为 Godot `SpriteFrames`。
- 工程师 `AnimatedSprite3D` 场景可独立实例化并自动播放。
- `hd2d_effect_lab.tscn` 能展示角色、地面、景深、环境、光照和假阴影。
- 主菜单可进入 HD2D 效果实验场。
- 第二阶段新增测试和既有 3D Run 地图核心测试通过。
- 资产规范和验证矩阵记录了第二阶段资源路径和验证命令。
