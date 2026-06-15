# 阶段 1：P0 遮挡、排序和比例验证

阶段状态： `[x]` 已完成

## 目标

把 `hd2d_effect_lab.tscn` 从静态展示升级为 P0 技术验证场。重点验证 HD-2D 最容易失败的部分：

- 角色移动时是否清晰、稳定、不抖。
- 角色和 3D 墙体、柱子、桥/台阶、前景物是否正确遮挡。
- 多个 `AnimatedSprite3D`、透明雾层、粒子/特效之间是否排序稳定。
- Perspective、Orthogonal、Billboard、固定朝向、Shaded、Unshaded 的取舍是否有截图依据。
- 角色世界尺寸和地图单位比例是否能作为后续模板。

## 范围

包含：

- 在实验场中增加可移动角色验证路径。
- 增加墙体、桥/台阶、前景遮挡、透明雾 Plane、简单透明特效样本。
- 增加第二个角色或角色分身，用于角色互相遮挡排序。
- 增加相机/渲染对照 profile。
- 增加固定截图矩阵和验收记录。

不包含：

- 不接入正式 Run 地图。
- 不制作完整战斗或完整地图。
- 不写复杂 Shader。
- 不引入体积雾作为必需项。

## [x] 任务 1.1：设计 P0 实验场布局

在 `hd2d_effect_lab.tscn` 的 `Stage` 下补齐一个小型移动路线：

```text
入口点
  -> 墙体前方
  -> 墙体后方
  -> 前景柱/树叶遮挡区
  -> 桥或台阶高度变化区
  -> 透明雾/特效区
  -> 发光物旁边
```

建议新增节点分组：

- `Stage/OcclusionSamples`
- `Stage/HeightSamples`
- `Stage/TransparentSamples`
- `CharacterRoot/ComparisonSprites`
- `Markers/CameraProfiles`

每个样本都应有明确用途，避免只为了好看堆节点。

## [x] 任务 1.2：增加角色移动验证

给实验场增加最小移动能力：

- WASD 控制角色在 XZ 平面移动。
- 角色脚点保持在地面高度或指定高度样本上。
- 假阴影跟随角色脚点。
- 相机仍可独立移动和旋转。

验证重点：

- 移动时角色边缘是否闪烁。
- 角色靠近镜头或远离镜头时大小是否可接受。
- 假阴影是否出现 z-fighting。
- 角色经过遮挡物边缘时是否穿帮。

## [x] 任务 1.3：建立遮挡组合测试

至少验证以下组合：

- 角色 vs 不透明墙体。
- 角色 vs 前景柱/树叶。
- 角色 vs 桥/台阶。
- 角色 vs 另一个 `AnimatedSprite3D`。
- 角色 vs 透明雾 Plane。
- 角色 vs Additive/Transparent 简单特效。

通过标准：

- 不透明物体能稳定遮住角色。
- 透明物体不会让角色忽隐忽现。
- 两个角色前后关系符合空间位置或明确的排序规则。
- 透明特效和前景雾不反向覆盖不该覆盖的对象。

## [x] 任务 1.4：建立对照截图矩阵

固定同一场景，分别截图：

```text
Perspective + Shaded
Perspective + Unshaded
Orthogonal + Shaded
Orthogonal + Unshaded
Perspective + Y-Billboard
Perspective + Fixed Facing
```

每张截图记录：

- 角色清晰度。
- 角色融入感。
- 舞台空间感。
- 遮挡可读性。
- 是否出现纸片感或漂浮感。

推荐默认选择规则：

- 如果 `Shaded` 让角色变脏或边缘不稳，角色主体默认 `Unshaded`，用 Rim/受击/特效做融合。
- 如果 Full Billboard 纸片感明显，优先测试 Y-Billboard 或固定朝向。
- 如果 Perspective 造成角色尺寸变化过大，降低 FOV 或为正式地图使用更轻透视。

## [x] 任务 1.5：锁定世界单位比例

记录并比较：

```text
角色有效像素高度
Sprite3D pixel_size
角色世界高度
地块直径/边长
墙体高度
门/桥/台阶高度
相机默认距离
```

通过标准：

- 普通角色高度与地块、墙体、道具比例协调。
- 角色在默认镜头下可读，不需要把相机拉得过近。
- 未来 48px、64px、96px、128px 角色可以按同一比例规则推导。

## [x] 任务 1.6：补 P0 自动验证

如果测试目录已存在，新增或扩展测试覆盖：

- 实验场加载。
- P0 样本节点存在。
- 主角色可移动控制节点存在。
- 相机 profile 方法存在。
- debug profile 返回角色数量、投影模式、关键视觉参数。

建议验证命令：

```bash
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_camera_controls.gd
godot --headless --quit
```

## 阶段完成标准

- 实验场可以手动移动角色验证遮挡。
- 六类 P0 遮挡/排序组合都有截图或人工记录。
- 角色默认 `Shaded/Unshaded`、Billboard、pixel_size 和镜头方案有明确推荐。
- 角色移动、假阴影、透明样本没有明显穿帮。
- 自动加载验证通过，或不存在的测试已记录为后续测试补齐项。
