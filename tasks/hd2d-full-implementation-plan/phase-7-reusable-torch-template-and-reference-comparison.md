# 阶段 7：可复用火把模板和参考图对比验收

阶段状态： `[x]` 已完成

## 目标

Phase 6 已经证明 Godot 原生火把特效、受光材质和 `1 / 3 / 6` 动态光 profile 可以成立，但它仍停留在验证场：火把结构还不是独立模板，支架/火盆美术不够接近参考图，也没有把“参考图观感”和“项目内截图”做明确对比。

本阶段目标是把火把推进到可复用制作模板：

1. 基于参考图和 `docs/hd2d/fire/Godot 火把特效制作.docx`，明确火把视觉目标。
2. 建立独立 `Hd2dTorchEffect` 场景和脚本，供验证场与正式 Run 地图复用。
3. 保留 Phase 6 的 Godot 原生 3D 特效路线作为对照，同时允许 Phase 7 自然火把使用项目内生成的 sprite sheet 火焰来解决规整感。
4. 在独立验证场和正式地图中分别接入模板。
5. 最后生成对比截图和对比记录，判断新模板是否明显优于 Phase 6 P0 火把，并是否接近参考图的氛围。

## 输入资料

- `docs/hd2d/fire/ChatGPT Image 2026年6月15日 22_13_57.png`
- `docs/hd2d/fire/Godot 火把特效制作.docx`
- `tasks/hd2d-full-implementation-plan/phase-6-torch-material-and-dynamic-light-validation.md`
- `tasks/hd2d-full-implementation-plan/records/phase-6-lighting-validation-record.md`
- `docs/hd2d/lighting_validation_plan.md`
- `docs/hd2d/performance_budget.md`
- `docs/hd2d/material_rules.md`

## 范围

包含：

- 独立可复用火把场景。
- 火把支架、火盆、火舌、glow、火星和暖色动态光。
- 参数化 flicker、火焰缩放、glow 强度、火星数量、光源强度和光源范围。
- 验证场中的 Phase 6 火把替换或并排对照。
- 正式 Run 地图中的少量模板接入。
- 参考图、Phase 6 P0 和 Phase 7 模板的最终对比。

不包含：

- 不把 AI 参考图整张裁切进游戏使用。
- 不把 2D `Torch2D.tscn` 作为当前 HD-2D 3D 地图默认方案。
- 不制作完整城镇或完整地牢地图。
- 不引入体积雾、复杂噪声 Shader、动态昼夜系统。
- 不突破默认 `<= 3` 个动态局部光的预算。

## 方案总则

### 默认路线

本阶段继续使用 Godot 原生 3D 火把：

```text
Hd2dTorchEffect
├── TorchProp
│   ├── Stand
│   ├── Bracket
│   └── TorchCup
├── FlameEffect
│   ├── OuterFlame
│   ├── MiddleFlame
│   ├── CoreFlame
│   └── TopWisp
├── FlameHalo
│   ├── OuterGlowVolume
│   └── InnerGlowVolume
├── Sparks
└── TorchLight
```

推荐新增文件：

```text
scenes/map3d/vfx/hd2d_torch_effect.tscn
scripts/map3d/vfx/hd2d_torch_effect.gd
```

如果需要保存共享材质，可新增：

```text
resources/hd2d/vfx/
  mat_torch_metal.tres
  mat_torch_flame_outer.tres
  mat_torch_flame_middle.tres
  mat_torch_flame_inner.tres
  mat_torch_glow.tres
```

### 美术目标

参考图中的关键观感要拆成可验证项：

- 火盆和支架轮廓清楚，读起来是中世纪 / 日式 RPG 地牢道具。
- 火焰有白黄内核、黄橙中层、红橙外层。
- 火焰底部固定在火盆里，顶部轻微跳动和左右摇摆。
- 火星数量少，偶发上升。
- 暖色光照能在墙面和地面形成中心强、边缘弱的 falloff。
- 画面外围仍保留冷色暗部，不整屏过曝。

## [x] 任务 7.1：整理参考图目标和 Phase 6 差距

目标：

- 阅读参考图和 Word 文档，把可落地目标写成检查项。
- 对照 Phase 6 截图，列出当前 P0 火把还缺什么。
- 明确哪些来自参考图的效果进入本阶段，哪些只做后续美术增强。

需要说明清楚：

- 火盆美术是否需要从 primitive 进化到低模 `.glb`。
- 火焰形状是否需要更接近像素火舌。
- glow 是否需要更像参考图里的墙面暖光。
- 当前 Phase 6 是否存在火星过多、glow 抢主体、火把轮廓弱等问题。

验收：

- 在执行记录中留下“参考图目标 vs Phase 6 差距”列表。
- 不以主观一句“更好看”作为判断，必须拆成火盆、火焰、火星、光照、角色可读性、性能六类。

## [x] 任务 7.2：建立独立 `Hd2dTorchEffect` 模板

目标：

- 新增独立火把场景和脚本。
- 从 Phase 6 验证场中抽取可复用结构，而不是复制一堆散节点。
- 所有关键参数通过 `@export` 暴露，便于不同地图调参。

建议脚本参数：

```gdscript
@export var light_base_energy := 0.6
@export var light_flicker_strength := 0.16
@export var light_flicker_speed := 7.4
@export var light_range := 3.8
@export var glow_base_scale := 1.0
@export var glow_flicker_strength := 0.12
@export var flame_base_scale := 1.0
@export var sparks_enabled := true
@export var shadows_enabled := true
```

验收：

- 模板能单独实例化。
- 多个实例有不同 flicker phase，不会同步闪烁。
- `TorchLight` 可按参数开启 / 关闭阴影。
- 不使用整张 AI 参考图裁切进游戏；自然火焰必须拆为项目内生成的外焰、中焰、内核和顶部细火舌 sprite sheet。

## [x] 任务 7.3：强化火盆和火焰层次

目标：

- 让火把本体比 Phase 6 primitive 更接近参考图。
- 火盆、支架、金属边缘和底座要在 HD-2D 镜头下读得清。
- 火焰层次要比 Phase 6 更明确。

可选实现路径：

- P0+：继续使用 Godot primitive，但优化比例、颜色、材质和分层。
- P1：使用 Blender 制作低模火盆 / 支架 `.glb`，导入到 `assets/generated/map3d/models/`。

验收：

- 远景 1280x720 截图中能读出火盆口、支架和火焰位置。
- 火焰内中外三层颜色可区分。
- 火焰不会像一团圆形 glow，也不会像扁平贴片。

## [x] 任务 7.4：接入光照验证场并保留对照

目标：

- 在 `hd2d_lighting_validation_lab.tscn` 中接入新的 `Hd2dTorchEffect`。
- 保留 Phase 6 P0 对照，或生成同机位 Phase 6 / Phase 7 截图。
- 继续支持 `lighting_profile=1/3/6`，其中 3 光源仍是默认推荐上限。

验收：

- `lighting_profile=1`：单火把成立。
- `lighting_profile=3`：默认模板成立，角色清楚，墙地受光方向可读。
- `lighting_profile=6`：只作为压力边界，记录是否过曝或抢主体。
- 自动测试能确认默认 profile 中动态光数量仍可控。

## [x] 任务 7.5：接入正式 Run 地图的小范围样本

目标：

- 在 `run_hex_map_3d.tscn` 或对应脚本中放入少量火把模板实例。
- 不破坏节点点击、战斗返回和地图流程。
- 只在关键位置启用真实 `OmniLight3D`，远景火把可只保留 emission / glow。

验收：

- 正式 Run 地图能加载。
- 现有 Run 地图自动测试通过。
- 角色和地图节点仍是主体，火把只增强氛围。
- 单屏动态局部光保持 `<= 3`。

## [x] 任务 7.6：最终截图对比和人工结论

目标：

生成固定对比截图，并写明结论。

推荐截图：

```text
output/lighting_validation/
  torch-phase6-p0-reference-1280x720.png
  torch-phase7-template-1280x720.png
  torch-phase7-material-response-1280x720.png
  torch-phase7-dynamic-lights-3-1280x720.png
  torch-phase7-run-map-sample-1280x720.png
```

最终必须有一张对比表：

| 对比项 | 参考图目标 | Phase 6 P0 | Phase 7 结果 | 结论 |
|---|---|---|---|---|
| 火盆轮廓 | 金属火盆和支架清楚 | 待记录 | 待记录 | 通过 / 需调参 |
| 火焰层次 | 白黄内核、橙色中层、红橙外焰 | 待记录 | 待记录 | 通过 / 需调参 |
| 火星 | 少量、偶发、上升 | 待记录 | 待记录 | 通过 / 需调参 |
| 墙地暖光 | 中心暖、边缘暗、falloff 清楚 | 待记录 | 待记录 | 通过 / 需调参 |
| 角色可读性 | 火光不抢主体 | 待记录 | 待记录 | 通过 / 需调参 |
| 性能预算 | 默认不超过 3 动态光 | 待记录 | 待记录 | 通过 / 需调参 |

验收：

- 至少生成 Phase 6 和 Phase 7 同场景同机位对比截图。
- 至少生成一张正式 Run 地图样本截图。
- 对比结论必须明确写出：Phase 7 是否比 Phase 6 更接近参考图；是否可以进入正式地图默认模板；还需要哪些后续美术增强。

## [x] 任务 7.7：记录结论并更新规范

目标：

- 新增执行记录：`records/phase-7-torch-template-comparison-record.md`。
- 更新 `docs/hd2d/lighting_validation_plan.md`，写入 Phase 7 模板结论。
- 必要时更新 `docs/hd2d/performance_budget.md` 和 `docs/hd2d/material_rules.md`。

验收：

- 记录新模板文件路径。
- 记录默认参数。
- 记录正式地图接入位置。
- 记录 Phase 6 / Phase 7 / 参考图对比结论。
- 明确哪些内容进入默认模板，哪些保留为后续增强。

## 最小验证命令

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_hd2d_lighting_validation_lab.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_scene.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_lighting_validation_lab.tscn --quit-after 60
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/run_hex_map_3d.tscn --quit-after 60
```

截图命令可沿用当前 `scripts/tools/capture_scene.gd` 或 `.codex/skills/godot-headless/scripts/run_capture_scene.py`，但必须固定 `1280x720`，并保证 Phase 6 / Phase 7 对比使用同一机位。

## 阶段完成标准

- 独立 `Hd2dTorchEffect` 模板已建立并可复用。
- 光照验证场已接入模板，并能做 Phase 6 / Phase 7 同机位对比。
- 正式 Run 地图已有小范围样本接入，且流程测试不破坏。
- 默认动态局部光仍保持 `<= 3`。
- 最终截图矩阵生成并记录人工结论。
- 对比表明确说明 Phase 7 是否优于 Phase 6、是否接近参考图、是否可进入默认模板。
- 执行记录和相关制作规范已更新。
