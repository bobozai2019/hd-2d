# Phase 8: 材质受光与参考图氛围最小验证

阶段状态： `[x]` 已完成

## 目标

当前问题是人物和地表看起来没有明显受到光照影响，参考图目标是“冷暗环境 + 暖色火光池 + 地表/墙体明显 falloff + 角色仍清晰”。本阶段不先大范围改主场景，而是先判断是否真的需要新增资产或调整已有资产，再做一个最小测试样例，用固定截图和参考图进行对比。

最终回答两个问题：

1. 现有资源通过材质、灯光和后处理调参，能否达到接近参考图的效果。
2. 如果不能，缺口到底是材质参数、灯光比例、地面光斑辅助贴图、角色受光策略，还是需要新增模型/贴图资产。

## 输入资料

- 用户提供的参考截图。
- 城镇光照样例：`docs/hd2d/reference/light_sample.png`，来源为 `C:\Users\18205\Desktop\test截图\light_sample.png`。
- `docs/hd2d/material_rules.md`
- `docs/hd2d/lighting_validation_plan.md`
- `docs/hd2d/world_environment_profiles.md`
- `tasks/hd2d-full-implementation-plan/records/phase-7-torch-template-comparison-record.md`
- `scenes/map3d/hd2d_lighting_validation_lab.tscn`
- `scenes/map3d/vfx/hd2d_torch_effect.tscn`
- `assets/generated/map3d/materials/`
- `assets/generated/hd2d/fire/natural_torch/alpha_wall_light_patch_draft.png`
- `assets/generated/hd2d/fire/natural_torch/alpha_torch_glow_soft_draft.png`

## 参考样例拆解

本阶段同时参考两类图：

- 地牢火光参考：低环境光、火把为主光源、局部暖光池明显，远处保持冷暗。
- 城镇光照样例 `docs/hd2d/reference/light_sample.png`：环境更亮，但仍保留强烈的局部光照层次、暖色雾感和边缘压暗。

城镇样例中需要转化为验证项的重点：

- 石板地面不是均匀变亮，而是中央暖光区域明显，砖缝和石块边缘仍可读。
- 建筑立面有清楚的受光面和背光面，墙体不会因为 ambient 过高而变成平涂。
- 画面中央存在暖色空气感，远处灯笼和室内光形成小面积橙色高亮。
- 左右和前景边缘明显压暗，用暗部框住中央光区。
- 角色保持像素轮廓清晰，角色本体不应被 bloom 或强光洗掉。
- Glow/雾只服务光源和空气透视，不把整张画面糊成一层黄雾。

对当前项目的启发：

- 地表材质必须能接住暖光，但 roughness 仍要高，避免石板路变成湿亮塑料。
- 建筑、墙体、台阶、石块需要足够的高度和法线方向变化，否则只能看到亮度变化，看不到参考图里的面片层次。
- 允许在最小样例里加入 warm light patch 和轻雾来复现“绘制感”，但必须保留 `no_local_light` 截图证明真实灯光确实有贡献。

## 范围

包含：

- 审计现有地表、墙体、前景、角色和火把资产是否满足受光验证。
- 明确哪些资产只需要调参，哪些资产需要新增或重做。
- 建立一个最小受光样例场景，固定机位、固定灯光、固定截图尺寸。
- 输出 baseline / adjusted / no-local-light / character-profile 对比截图。
- 根据截图决定是否把参数迁移到 `hd2d_effect_lab.tscn` 或正式 Run 地图。

不包含：

- 不直接重做完整地图。
- 不直接覆盖主场景视觉参数作为最终效果。
- 不新增大规模贴图、完整 tile set 或 Blender 地图模块，除非最小样例证明现有资产无法达标。
- 不突破默认 `<= 3` 个动态局部光的预算。

## 资产判断结论先行

### 结论 A：第一轮不需要新增大资产

先复用现有资产做测试：

- 火把：复用 `res://scenes/map3d/vfx/hd2d_torch_effect.tscn`。
- 火焰 glow：复用 `assets/generated/hd2d/fire/natural_torch/alpha_torch_glow_soft_draft.png`。
- 墙地暖光辅助层：优先复用 `assets/generated/hd2d/fire/natural_torch/alpha_wall_light_patch_draft.png`。
- 地表/墙体材质：复用或局部复制 `assets/generated/map3d/materials/mat_hd2d_ground.tres`、`mat_hd2d_wall.tres`、`mat_hd2d_foreground.tres`。
- 角色：复用 `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn` 和 `assets/generated/characters/engineer/engineer_stand.spriteframes.tres`。

第一轮只允许新增“验证样例场景”和“可回滚的参数资源”，不要新增正式美术资产。

### 结论 B：允许调整的资产

这些可以在最小样例中调整，但通过验收前不回写正式默认值：

```text
resources/hd2d/
  hd2d_world_environment_night_warm_lights.tres
  hd2d_camera_attributes_night_warm_lights.tres

assets/generated/map3d/materials/
  mat_hd2d_ground.tres
  mat_hd2d_wall.tres
  mat_hd2d_foreground.tres
  mat_hd2d_background.tres
```

建议先在样例场景里使用 local subresource 或新增实验资源，命名带 `reference_match`：

```text
resources/hd2d/experiments/
  mat_reference_ground_wet_rough.tres
  mat_reference_wall_warm_response.tres
  env_reference_night_torch_contrast.tres
```

如果最终截图通过，再把参数整理回正式资源或文档，不直接把实验资源散落到正式场景里。

### 结论 C：新增资产的触发条件

只有满足下面任一条件，才新增或重做美术资产：

- 地面和墙体已经使用 shaded `StandardMaterial3D`，ambient 已降低，火把光已增强，但截图中仍然没有可读暖色 falloff。
- 现有地面太平，缺少能接住光的高度、边缘或纹理变化，导致受光只能变亮不能形成参考图那种岩石层次。
- 角色 `shaded=true` 后明显变脏或丢失像素轮廓，而 `shaded=false` 又完全脱离光照，需要额外角色光照辅助层。
- 现有 `alpha_wall_light_patch_draft.png` 无法形成自然墙地光斑，需要重新生成或手绘更合适的 light patch。

如果触发新增资产，按这个顺序处理：

1. **新增材质资源**：优先新增 `.tres`，不新增贴图。
2. **新增辅助 light patch**：放到 `assets/generated/hd2d/fire/natural_torch/`，保留 raw / alpha 命名，导入后用 nearest 或合适过滤规则。
3. **新增低模受光几何**：只在确实需要岩石边缘/台阶轮廓时新增 `.glb`，源文件放 `assets/source/map3d/blender/`，导出到 `assets/generated/map3d/models/`。
4. **新增角色受光辅助**：优先用场景内 `Sprite3D` rim / ground warm patch，不改角色原始帧。

## 推荐视觉公式

目标不是把整屏照亮，而是拉开局部对比：

- Ambient：低能量冷色，只保留暗部可读性。
- DirectionalLight：弱冷色月光，负责整体方向，不抢火把。
- Torch OmniLight：暖色主贡献，短 range，较高局部能量，轻微 flicker。
- Ground / Wall：shaded `StandardMaterial3D`，低到中等 albedo，高 roughness，低 specular。
- Light Patch：在火把周围加一层贴地/贴墙暖色 alpha 辅助，补足绘制感。
- Town Sample Variant：为 `light_sample.png` 增加一个更亮的城镇 profile，保留中央暖光、边缘压暗和建筑立面受光，不追求地牢式全局黑场。
- Character：做三档对比，不立即决定最终方案：
  - `shaded=false`：保持像素原画稳定。
  - `shaded=true`：真实吃光。
  - hybrid：主体 unshaded，加轻微暖色脚底/侧向辅助层。

## [x] 任务 8.1：资产审计和调参清单

目标：

- 读取当前地面、墙体、前景、角色、火把和环境资源。
- 确认是否存在 `shading_mode = unshaded`、过高 ambient、过高 albedo、过强 emission 或角色实例被显式设为 `shaded=false` 的情况。
- 输出“无需新增 / 需要调参 / 可能新增”的资产表。

审计清单：

| 分类 | 路径 | 第一轮动作 | 新增资产条件 |
|---|---|---|---|
| 地面材质 | `assets/generated/map3d/materials/mat_hd2d_ground.tres` | 实验中调低 albedo，保持 high roughness | 光照仍无 falloff 或地面太平 |
| 墙体材质 | `assets/generated/map3d/materials/mat_hd2d_wall.tres` | 实验中调低 albedo，低 specular | 墙面无法表现暖光边缘 |
| 前景材质 | `assets/generated/map3d/materials/mat_hd2d_foreground.tres` | 确认暗部遮挡读得出 | 前景完全糊成黑块 |
| 火把模板 | `scenes/map3d/vfx/hd2d_torch_effect.tscn` | 调 light energy/range/glow | 火盆轮廓仍不清或光照不稳定 |
| 光斑贴图 | `alpha_wall_light_patch_draft.png` | 优先复用 | 贴图形状明显不自然 |
| 角色 | `engineer_stand_animated_sprite_3d.tscn` | 对比 shaded/unshaded/hybrid | 两种模式都不达标 |

验收：

- 本任务结束时，记录“第一轮不新增大资产”是否仍成立。
- 如果需要新增资产，必须写明新增路径、用途、回滚方式和验证截图。

## [x] 任务 8.2：建立最小测试样例

目标：

新增一个隔离场景，用最少节点测试参考图公式。

推荐新增：

```text
scenes/map3d/hd2d_reference_light_response_lab.tscn
scripts/map3d/hd2d_reference_light_response_lab.gd
```

场景结构：

```text
Hd2dReferenceLightResponseLab
├── WorldEnvironment
├── Lighting
│   ├── MoonKey
│   └── DebugAmbientProbe
├── Stage
│   ├── GroundPlate
│   ├── RaisedRockLeft
│   ├── RaisedRockRight
│   ├── BackWall
│   ├── WarmLightPatchGround
│   └── WarmLightPatchWall
├── CharacterSamples
│   ├── CharacterUnshaded
│   ├── CharacterShaded
│   └── CharacterHybrid
├── VfxRoot
│   ├── TorchKey
│   ├── TorchSecondary
│   └── TorchFarAtmosphere
└── CameraRig
    └── Camera3D
```

最小要求：

- 只放 1 个关键动态火把光，最多 2 个辅助真实光；第三个远景火把默认只保留 emission/glow。
- 地面、墙体、石块必须使用 shaded `StandardMaterial3D`。
- 场景内放三种角色受光方案，固定在同一光照范围内，截图一次就能比较。
- 所有实验材质先作为 scene subresource 或 `resources/hd2d/experiments/` 资源，避免污染正式资源。

验收：

- 场景可 headless 加载。
- 截图中能同时看到火把、地面、墙体、角色三种 profile。
- 动态局部光数量默认不超过 3。

## [x] 任务 8.3：实现可切换 profile

目标：

脚本提供固定 profile，方便截图对比。

建议参数：

```text
reference_profile=baseline
reference_profile=adjusted
reference_profile=no_local_light
reference_profile=character_compare
reference_profile=town_sample_match
```

profile 行为：

- `baseline`：当前接近 Phase 7 默认参数，不加额外地面光斑。
- `adjusted`：低 ambient、弱冷月光、增强火把局部光、开启地面/墙面 warm patch。
- `no_local_light`：关闭火把真实光，只保留 emission/glow，用于证明材质是否真的受动态光影响。
- `character_compare`：保持 adjusted 光照，同时突出三种角色受光方案。
- `town_sample_match`：以 `docs/hd2d/reference/light_sample.png` 为目标，使用更亮的基础环境、中央暖光、建筑/墙体受光分区、边缘压暗和克制 glow。

验收：

- 同一场景、同一机位、不同 profile 可稳定捕获。
- `no_local_light` 和 `adjusted` 的地面/墙体亮度与色温差异明显。
- `character_compare` 能判断角色最终走 shaded、unshaded 还是 hybrid。

## [x] 任务 8.4：生成对比截图

目标：

生成固定尺寸截图，用肉眼对比参考图效果。

推荐输出：

```text
output/reference_light_response/
  reference-baseline-1280x720.png
  reference-adjusted-1280x720.png
  reference-no-local-light-1280x720.png
  reference-character-compare-1280x720.png
  reference-town-sample-match-1280x720.png
```

推荐命令：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_reference_light_response_lab.tscn --quit-after 60

D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_reference_light_response_lab.tscn res://output/reference_light_response/reference-baseline-1280x720.png 1280 720 reference_profile=baseline

D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_reference_light_response_lab.tscn res://output/reference_light_response/reference-adjusted-1280x720.png 1280 720 reference_profile=adjusted

D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_reference_light_response_lab.tscn res://output/reference_light_response/reference-no-local-light-1280x720.png 1280 720 reference_profile=no_local_light

D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_reference_light_response_lab.tscn res://output/reference_light_response/reference-character-compare-1280x720.png 1280 720 reference_profile=character_compare

D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_reference_light_response_lab.tscn res://output/reference_light_response/reference-town-sample-match-1280x720.png 1280 720 reference_profile=town_sample_match
```

验收：

- `adjusted` 必须比 `baseline` 更接近参考图的局部暖光和冷暗环境。
- `no_local_light` 必须明显失去地面/墙体暖色受光，否则说明真实灯光贡献不足或被环境光托平。
- `character_compare` 必须给出明确推荐角色方案。
- `town_sample_match` 必须体现 `light_sample.png` 的中央暖光、石板地面受光、建筑立面分区和边缘压暗；如果只能靠全屏曝光变亮，判定不通过。

## [x] 任务 8.5：截图结论和迁移决策

目标：

新增执行记录：

```text
tasks/hd2d-full-implementation-plan/records/phase-8-reference-light-response-record.md
```

记录内容：

- 是否新增资产。
- 调整了哪些实验材质和环境参数。
- 截图文件名。
- 参考图目标 vs baseline vs adjusted 对比表。
- 角色受光推荐方案。
- 是否把参数迁移到 `hd2d_effect_lab.tscn`。
- 是否把参数迁移到 `run_hex_map_3d.tscn`。

对比表模板：

| 对比项 | 参考图目标 | Baseline | Adjusted | 结论 |
|---|---|---|---|---|
| 地表受光 | 火把附近暖、远处冷暗 | 待记录 | 待记录 | 通过 / 需新增资产 |
| 墙体 falloff | 中心亮、边缘渐暗 | 待记录 | 待记录 | 通过 / 需调参 |
| 角色读性 | 不被火光洗白，边缘清楚 | 待记录 | 待记录 | shaded / unshaded / hybrid |
| 火把贡献 | 关灯后明显失去暖光 | 待记录 | 待记录 | 通过 / 灯光贡献不足 |
| 后处理 | glow 只服务高亮，不糊屏 | 待记录 | 待记录 | 通过 / 需调低 |
| 资产需求 | 尽量复用现有资产 | 待记录 | 待记录 | 不新增 / 新增 light patch / 新增模型 |
| 城镇样例匹配 | 中央暖光、石板受光、建筑明暗面和边缘压暗 | 待记录 | 待记录 | 通过 / 需要墙体或地面资产增强 |

验收：

- 只有当截图证明 adjusted 方案成立，才把参数迁移到正式场景。
- 如果 adjusted 仍不接近参考图，必须先写清楚资产缺口，再新增对应资产。

## 最小验证命令

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_reference_light_response_lab.tscn --quit-after 60
```

如果新增脚本测试，再补：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_hd2d_reference_light_response_lab.gd
```

## 阶段完成标准

- 已明确是否需要新增资产，且每个新增资产都有路径、用途和触发原因。
- 已建立最小受光样例场景。
- 已生成 baseline / adjusted / no-local-light / character-compare / town-sample-match 五张截图。
- 已记录 adjusted 是否接近参考图。
- 已记录 `town_sample_match` 是否接近 `docs/hd2d/reference/light_sample.png`。
- 已给出角色受光推荐方案。
- 已决定是否迁移到主实验场和正式 Run 地图。
