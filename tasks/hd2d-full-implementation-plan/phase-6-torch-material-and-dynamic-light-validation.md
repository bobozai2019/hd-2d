# 阶段 6：火把特效、受光材质和多光源动态光验证

阶段状态： `[x]` 已完成

## 目标

当前 HD-2D 基线已经能加载、截图和跑通最小 VFX，但画面效果仍不够成立。本阶段只验证三个会直接决定最终观感的问题：

1. 火把效果怎么做、用什么工具、做到什么程度。
2. 城墙或地板材质是否能被真实灯光影响。
3. 多光源动态光照是否能增强氛围，而不是洗掉角色和地图层次。

本阶段结论要能直接指导正式地图制作：哪些效果进入默认模板，哪些只作为压力或后续美术增强。

## 范围

包含：

- 独立光照验证场景。
- 火把纯特效方案，不使用贴图火焰。
- 墙体、地板、柱子等 `StandardMaterial3D` 受光验证。
- `1 / 3 / 6` 局部光源对照。
- 夜晚环境 profile、Glow、阴影和角色可读性截图。
- 自动测试、截图矩阵和执行记录。

不包含：

- 不做最终火把美术资产库。
- 不做完整城镇地图。
- 不引入体积雾、复杂 Shader 或动态昼夜系统。
- 不用贴图火焰、Sprite3D 火焰或程序 `ImageTexture` 火焰来替代特效。
- 不把 6 个以上动态光源作为默认模板。

## 方案总则

### 火把效果

默认方案：Godot 原生特效节点组合。

```text
Hd2dTorchEffect
├── TorchProp               # 低模托架/火盆，可先用 Godot primitive
├── FlameEffect             # 纯 mesh/粒子火焰，不使用贴图
│   ├── OuterTongue         # additive 发光火舌 mesh
│   ├── MiddleTongue        # additive 发光火舌 mesh
│   └── InnerTongue         # 高亮内焰 mesh
├── SparkParticles          # 少量 GPUParticles3D 火星
├── HeatGlowVolume          # 半透明 additive glow 体，不使用贴图
└── TorchLight              # 暖色 OmniLight3D
```

工具选择：

- P0 使用 Godot 4.6 内置节点：`MeshInstance3D`、`CylinderMesh`、`SphereMesh`、`StandardMaterial3D`、`GPUParticles3D`、`ParticleProcessMaterial`、`OmniLight3D`、`Tween` 或 `_process`。
- Blender 只用于 P1 之后替换托架/火盆模型，不参与运行时特效逻辑。
- Aseprite/Krita/Photoshop 暂不用于火焰本体；后续可用于墙地 albedo 贴图，但不能替代本阶段火把特效验证。

做到什么程度：

- P0：远近景能看出是火把；火舌会轻微跳动；有少量火星；点光源能照亮墙和地；不出现方形贴片感。
- P1：托架换成低模 `.glb`；火焰参数可配置；可在多个地图位置复用。
- P2：根据正式美术风格再补更精细的 shader、噪声或美术资产。

### 墙体和地板受光材质

默认方案：`StandardMaterial3D` 受光材质。

- 墙体、地板、台阶、柱子必须使用 shaded 材质。
- `roughness` 默认 `0.82 ~ 0.96`。
- `metallic_specular` 默认 `0.05 ~ 0.18`。
- 不使用 `SHADING_MODE_UNSHADED` 验证受光。
- 允许使用简单 albedo 色块或未来的像素风贴图，但材质必须能被 `OmniLight3D` 和 `DirectionalLight3D` 影响。

验收重点：

- 火把附近能看到暖色 falloff。
- 远离火把处仍保留冷色暗部。
- 地板不能变成塑料高光。
- 墙面 block/缝隙要能帮助读出光照方向。

### 多光源动态光

默认方案：3 个动态局部光源作为可用上限。

验证矩阵：

```text
1 light  = 最小可用火把效果
3 lights = 推荐默认上限
6 lights = 压力边界，不默认启用
```

默认参数：

- 火把 `OmniLight3D.light_energy`: `0.45 ~ 0.75`
- 火把 `OmniLight3D.omni_range`: `3.2 ~ 4.2`
- 单屏默认动态局部光：`<= 3`
- 粒子组：`<= 3`
- 透明/发光体：保持少量，不遮挡角色

如果画面过曝或性能不稳，降级顺序：

1. 降低 `light_energy`。
2. 降低 Glow 强度。
3. 关闭小火把阴影，只保留关键火把阴影。
4. 合并或减少动态光源。
5. 减少火星粒子和透明 glow 体。

## [x] 任务 6.1：清理并锁定验证场基线

目标：

- 建立或修复 `res://scenes/map3d/hd2d_lighting_validation_lab.tscn`。
- 修复 `res://scripts/map3d/hd2d_lighting_validation_lab.gd` 当前可能存在的 GDScript 类型错误。
- 移除火把中的贴图火焰、`Sprite3D` 火焰和程序 `ImageTexture` 火焰。
- 保留独立验证场，不污染 `hd2d_effect_lab.tscn` 的主基线。

验收：

- 场景 headless 可加载。
- 自动测试能实例化场景。
- `get_lighting_validation_profile()` 返回 `texture_based_torch = false`。

## [x] 任务 6.2：实现 P0 纯特效火把

目标：

- 用 Godot 原生节点实现 `Hd2dTorchEffect` 或等价结构。
- 火焰由 additive mesh、glow volume 和 `GPUParticles3D` 组成。
- 火把包含可调 `OmniLight3D`，并支持轻微 flicker。

验收：

- 画面中至少 3 个火把可见。
- 火焰不是贴图，不出现方形 halo。
- 火星数量克制，不遮挡角色。
- 火把光源能照到附近墙/地。

## [x] 任务 6.3：验证墙体和地板受光材质

目标：

- 构建背墙、侧墙、石地板和少量 wall block/groove。
- 使用 shaded `StandardMaterial3D`，验证暖光/冷光/暗部关系。
- 对比墙体和地板在火把附近与远离火把处的视觉差异。

验收：

- 墙和地板材质都不是 unshaded。
- 火把附近能看到暖色渐变。
- 暗部仍有冷色层次。
- 地板粗糙、低高光，不像塑料。

## [x] 任务 6.4：验证 1/3/6 多光源动态表现

目标：

- 在同一验证场支持 1、3、6 光源 profile。
- 3 光源作为推荐默认上限。
- 6 光源作为压力边界，只用于决定降级策略。

验收：

- 1 光源：能证明单火把的最小效果成立。
- 3 光源：角色轮廓仍清楚，墙/地受光方向可读。
- 6 光源：记录是否过曝、性能是否明显下降、是否需要禁用阴影或减少光源。

## [x] 任务 6.5：截图矩阵和人工视觉判断

目标：

生成固定 1280x720 截图：

```text
output/lighting_validation/
  torch-effect-p0-1280x720.png
  material-light-response-1280x720.png
  dynamic-lights-1-1280x720.png
  dynamic-lights-3-1280x720.png
  dynamic-lights-6-pressure-1280x720.png
```

人工检查项：

- 火把是否像特效，而不是贴图或静态道具。
- 墙/地是否能被光照影响。
- 多光源是否提升氛围。
- 角色是否仍是画面主体。
- Glow、阴影、火星是否过量。

验收：

- 至少 5 张截图都生成。
- 每张截图有一句结论：通过、需要调参、不可作为默认方案。
- 3 光源截图必须达到可继续制作标准，否则不得进入正式地图模板。

## [x] 任务 6.6：记录结论并更新制作规范

目标：

- 新增执行记录：`records/phase-6-lighting-validation-record.md`。
- 更新或补充 `docs/hd2d/lighting_validation_plan.md`。
- 必要时更新 `docs/hd2d/performance_budget.md` 和 `docs/hd2d/material_rules.md`。

验收：

- 明确写出火把方案：Godot 原生特效，不使用贴图火焰。
- 明确写出材质方案：墙/地 shaded `StandardMaterial3D`。
- 明确写出多光源上限：默认 3，6 只做压力边界。
- 写出哪些内容可进入正式 Run 地图，哪些仅保留在验证场。

## 最小验证命令

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_hd2d_lighting_validation_lab.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_lighting_validation_lab.tscn --quit-after 60
python .codex/skills/godot-headless/scripts/run_capture_scene.py --project-root . --godot D:\godot\Godot_v4.6.2\godot.exe --scene res://scenes/map3d/hd2d_lighting_validation_lab.tscn --output res://output/lighting_validation/torch-effect-p0-1280x720.png --width 1280 --height 720
```

## 阶段完成标准

- 火把 P0 特效方案成立，并明确不用贴图火焰。
- 墙体和地板材质能被动态光照影响。
- 1/3/6 光源对照完成，3 光源推荐上限有截图证据。
- 自动测试、headless 加载和截图流程通过。
- 执行记录和制作规范更新完成。
- 如果视觉效果仍不满意，记录具体失败原因和下一轮调参方向，不把阶段标为完成。
