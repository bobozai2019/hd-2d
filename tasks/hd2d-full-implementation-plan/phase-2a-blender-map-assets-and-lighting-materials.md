# 阶段 2A：Blender 地图素材、材质和受光验证

阶段状态： `[x]` 已完成

## 目标

建立 HD-2D 地图素材的 Blender 到 Godot 运行时资产流程。重点不是做大量精美模型，而是先做一套能被 Godot 光照、阴影、雾、Glow 和后处理正确影响的模块化地图素材。

完成后，项目应具备：

- Blender 源文件路径规范。
- `.glb` 运行时模型路径规范。
- 地图模块资产的最小集合。
- 场景材质受光规则。
- 光照/阴影/材质截图验收标准。
- Blender 不可用时的 Godot 原语回退策略。

## 范围

包含：

- 六边格/地块模型。
- 墙体、台阶、桥、前景遮挡物、远景轮廓和基础 landmark。
- 低模/像素贴图混合材质。
- StandardMaterial3D 受光、阴影、Emission 和轻 Normal 验证。
- Godot 中的 GLB 导入、实例化和回退。

不包含：

- 不制作完整大地图。
- 不制作大量场景主题。
- 不把 `.blend` 作为运行时依赖。
- 不在本阶段制作复杂 Shader。
- 不强制 Blender 必须在 CI 或 headless 环境中可用。

## [x] 任务 2A.1：建立资产目录规范

使用以下路径：

```text
assets/source/map3d/blender/
  hd2d_map_modules.blend
  hd2d_landmarks_basic.blend

assets/generated/map3d/models/
  hd2d_hex_tile.glb
  hd2d_wall_low.glb
  hd2d_stairs_short.glb
  hd2d_bridge_short.glb
  hd2d_foreground_pillar.glb
  hd2d_background_silhouette.glb
  landmark_battle.glb
  landmark_shop.glb
  landmark_rest.glb
  landmark_event.glb
  landmark_boss.glb

assets/generated/map3d/materials/
  mat_hd2d_ground.tres
  mat_hd2d_wall.tres
  mat_hd2d_foreground.tres
  mat_hd2d_background.tres
  mat_hd2d_emission_warm.tres
  mat_hd2d_emission_cool.tres
```

运行时场景只引用 `.glb`、`.tres`、`.png` 等 Godot 可加载资产，不直接引用 `.blend`。

## [x] 任务 2A.2：制作最小 Blender 模块集

在 Blender 中制作模块时遵守：

- 1 Blender unit 对应 1 Godot unit。
- 模型原点放在底面中心，方便贴地和按地图坐标摆放。
- 地块、墙、桥、台阶要有真实厚度，不能只是平面。
- 墙体高度能稳定遮挡 Sprite3D 角色身体的一部分。
- 前景遮挡物要足够靠近相机时形成层次，但不能遮住主要交互区域。
- 远景轮廓只服务构图，不参与碰撞和交互。
- 法线方向正确，导入 Godot 后受光不反。
- 模块尺寸要能拼接，不出现明显缝隙。

最小模型集合：

```text
1 个厚六边格地块
1 个低墙
1 个短台阶
1 个短桥
1 个前景柱/树干/墙角
1 个远景轮廓块
5 个节点 landmark：battle、shop、rest、event、boss
```

## [x] 任务 2A.3：制定 Blender 导出规则

导出 `.glb` 时：

- Apply Transform。
- 应用 scale，避免 Godot 中缩放异常。
- 保留 UV。
- 保留材质槽名称，但运行时优先在 Godot 中指定 `.tres` 材质。
- 不导出 Blender 灯光和相机作为运行时依赖。
- 不导出不需要的动画。
- 碰撞体不强制从 Blender 导出；优先在 Godot 中按模块需求创建简单碰撞。

文件命名使用 snake_case，例如：

```text
hd2d_hex_tile.glb
hd2d_wall_low.glb
landmark_battle.glb
```

## [x] 任务 2A.4：建立地图材质受光规则

地图素材默认使用 `StandardMaterial3D`，并接受 Godot 真实光照。

建议起点：

```text
Albedo: 低饱和像素贴图或低分辨率色块贴图
Roughness: 0.75 ~ 1.0
Specular: 0.05 ~ 0.25
Metallic: 0.0
Normal: 轻微使用，只增强体积，不做写实细节
Emission: 只给火把、窗户、水晶、魔法阵等真实发光物
```

受光原则：

- 地图和建筑应接受主光、补光和阴影，承担 3D 舞台感。
- 地面和墙体不能太光滑，避免塑料感。
- 像素贴图与连续光照割裂时，优先降低材质对比和 Normal 强度，而不是立刻写复杂 shader。
- 发光材质必须和 `WorldEnvironment` 的 Glow 一起截图验证，避免过曝。
- 前景物可以更暗，但不能完全黑成一团。

角色与地图区别：

- 地图素材默认 `Shaded`，接受真实光照。
- 角色主体可以继续保留 `Shaded` / `Unshaded` 对照，最终以清晰度和融合感决定。
- 角色真实阴影不作为默认方案，继续优先用假阴影。

## [x] 任务 2A.5：建立受光和阴影验证场景

在实验场或新建资产验证场中摆放：

```text
一个厚地块
一面墙
一个台阶或桥
一个前景遮挡物
一个远景轮廓
一个发光 landmark
一个 Sprite3D 角色
一个主光
一个补光
一个低强度环境光
```

验证角度：

- 主光是否能让地块和墙体出现体积关系。
- 墙体是否能投射或接受阴影。
- 角色经过墙体前后时遮挡是否成立。
- Emission 是否触发 Glow 但不过曝。
- Normal 是否增强材质体积而不显得写实油腻。
- 雾和 DOF 是否仍然不糊主体。

## [x] 任务 2A.6：Godot 原语回退策略

如果 Blender 不可用或 GLB 未完成：

- 使用 `MeshInstance3D` + `BoxMesh`、`CylinderMesh`、`PlaneMesh` 搭建同名回退节点。
- 材质 `.tres` 仍按正式路径创建和引用。
- 测试应允许模型缺失时加载回退原语。
- 执行记录必须写明哪些 GLB 缺失，哪些由 Godot 原语代替。

回退不是最终画面，只用于保证脚本、流程和验证不中断。

## [x] 任务 2A.7：自动验证建议

新增或扩展测试：

- `scripts/autotest/test_hd2d_map_asset_paths.gd`
- `scripts/autotest/test_hd2d_material_resources.gd`
- `scripts/autotest/test_hd2d_asset_light_response_scene.gd`

验证内容：

- `.tres` 材质资源能加载。
- 运行时场景不直接引用 `.blend`。
- GLB 存在时能加载，缺失时有 Godot 原语回退。
- 受光验证场景包含主光、补光、WorldEnvironment、发光材质和遮挡样本。

建议命令：

```bash
godot --headless --script scripts/autotest/test_hd2d_map_asset_paths.gd
godot --headless --script scripts/autotest/test_hd2d_material_resources.gd
godot --headless --script scripts/autotest/test_hd2d_asset_light_response_scene.gd
godot --headless --quit
```

## 阶段完成标准

- Blender 源文件和 GLB 运行时路径规范已明确。
- 最小地图模块清单已完成，或回退原语已明确记录。
- 地图材质能接受 Godot 光照和阴影。
- 发光材质和 Glow 的关系经过截图验收。
- 地图素材与 Sprite3D 角色同屏时不割裂、不糊、不严重穿帮。
- 正式 Run 地图接入前，已有一套可复用的 HD-2D 地图素材基础。
