# HD-2D 完整实现计划总纲

> **给 agentic 工作者：** 本任务包是 HD-2D 方向的总计划。执行时按阶段文件推进，每个阶段完成后记录验证结果，再进入下一阶段。不要删除或覆盖既有 `tasks/map3d-hd2d-phase2/` 和 `tasks/map3d-formal-run-integration/`，它们是本计划的输入资料和历史基线。

## 制作目的

本项目目标是在 Godot 4.6 中形成一套可复用的 HD-2D 视觉公式：

```text
清晰的 2D 像素/序列帧角色
+
有真实空间厚度的 3D 微缩舞台
+
稳定的遮挡和透明排序
+
克制但有效的舞台光、雾、Glow、景深和粒子
+
可接入正式 Run 地图的资源与场景模板
```

最终不是只做一个漂亮截图，而是把实验场中验证过的视觉参数、角色规格、遮挡规则和验证流程沉淀为正式地图可用的制作规范。

## 要达成的效果

完成本计划后，项目应满足：

- `hd2d_effect_lab.tscn` 能作为稳定的 HD-2D 视觉实验场，验证角色清晰度、镜头、遮挡、排序、光照和后处理。
- 至少一个可移动 `AnimatedSprite3D` 角色能在墙体、前景、桥/台阶、雾层、发光物和透明特效之间移动，遮挡关系稳定。
- 角色 `pixel_size`、Billboard 模式、假阴影、导入规则和相机参数有明确默认值和对照记录。
- HD-2D 视觉模板能迁移到正式 3D Run 地图，而不是停留在独立实验场。
- 正式 Run 地图保持可玩流程：节点状态、战斗返回、商店/休息/事件返回不被视觉改造破坏。
- 资源、材质、后处理、截图验收和性能验收有文档化标准。

## 当前基线

已完成或已有可复用内容：

- `tasks/map3d-hd2d-phase2/` 已规划并记录 HD2D 效果实验场和工程师 `AnimatedSprite3D` 角色动画。
- `scenes/map3d/hd2d_effect_lab.tscn` 已包含 `WorldEnvironment`、透视相机、灯光、雾、Glow、DOF、前景物、背景地块、发光样本、假阴影和工程师角色。
- `scripts/map3d/hd2d_effect_lab.gd` 已提供实验场相机移动、旋转、缩放和调试 profile。
- `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn` 已提供第一版 `AnimatedSprite3D` 角色。
- `docs/Godot_HD2D_复刻技术方案与验证清单.md` 已给出 HD-2D 总体技术路线和优先级。

需要继续补齐的关键缺口：

- 当前实验场偏静态展示，缺少角色移动穿越遮挡物时的排序验证。
- 角色 `Shaded` 与 `Unshaded` 方案尚未用同屏或固定截图矩阵对比。
- 透视/正交镜头、Billboard 模式、角色比例和地图比例尚未固化成模板。
- Blender/GLB 地图素材、材质受光、阴影和发光材质还没有独立验证流程。
- 正式 Run 地图尚未继承实验场中的 HD-2D 视觉公式。
- 粒子、技能特效、局部雾层、动态光和性能压力尚未形成分级验收。

## 大流程

1. **锁定基线和目标图像**
   记录当前实验场、现有任务包、Godot 版本、验证命令和截图基线。

2. **补 P0 技术验证**
   在实验场中优先验证角色清晰度、移动遮挡、透明排序、Billboard、镜头和世界单位比例。

3. **沉淀视觉模板**
   把稳定的角色、灯光、相机、WorldEnvironment、假阴影和导入规则整理成可复用模板。

4. **制作可受光的地图素材**
   建立 Blender 源文件、GLB 运行时模型、StandardMaterial3D 材质和光影验证流程。

5. **迁移到正式 Run 地图**
   将 HD-2D 视觉公式接入正式 3D Run 地图，保持现有 Run 流程和回退入口。

6. **增强氛围和表现**
   增加粒子、局部雾、Glow 源、简单技能特效、动态光和相机演出，但只在 P0 稳定后进行。

7. **验收、性能和维护**
   建立截图矩阵、性能预算、验证矩阵、回滚说明和制作规范，确保后续资源能按同一公式扩展。

8. **继续验证关键光照效果**
   针对当前观感不足，单独验证火把纯特效、墙/地受光材质和多光源动态光照表现。

9. **制作可复用火把模板并做对比验收**
   基于参考图和 Phase 6 结论，建立独立火把模板，接入验证场和正式 Run 地图，最后输出 Phase 6 / Phase 7 / 参考图对比结论。

## Goal 驱动执行入口

本任务包支持两种执行方式：

### 方式 A：总 goal 模式

适用于一条长期目标持续推进 `phase 0 -> phase 5`。

推荐 goal 文本：

```text
按 tasks/hd2d-full-implementation-plan/README.md 顺序完成 HD-2D 完整实现计划。
从当前未完成的最早阶段开始，逐阶段完成实现、验证、记录和状态更新。
只有当前阶段达到完成标准后，才能进入下一阶段。
```

总 goal 模式规则：

- 每一轮先检查本 README 的阶段状态板，找到第一个 `[ ]` 阶段。
- 读取该阶段文档和上一阶段执行记录。
- 本轮结束前，必须更新：
  - README 中的阶段状态。
  - 当前阶段文档中的任务勾选状态。
  - `records/` 中对应阶段执行记录。
- 当前阶段未达到完成标准时，不进入下一阶段。
- 当前阶段达到完成标准时：
  - 把该阶段标记为 `[x]`。
  - 把下一阶段保持为 `[ ]`。
  - 在下一轮执行时自动切换焦点。

### 方式 B：单阶段 goal 模式

适用于一次只推进一个阶段。

推荐 goal 文本模板：

```text
完成 tasks/hd2d-full-implementation-plan/<phase-file>.md。
实现该阶段未完成任务，运行该阶段最小验证命令，更新任务勾选状态和执行记录。
如果未达到阶段完成标准，不要继续后续 phase。
```

单阶段 goal 模式规则：

- 只读取当前 phase 文档、README 状态板和上一阶段记录。
- 只修改当前阶段所需内容。
- 当前阶段完成后停止，不自动进入下一阶段。

## 状态标记规则

本任务包统一使用以下状态标记：

- `[ ]` 未完成
- `[x]` 已完成
- `[-]` 当前进行中

更新规则：

- README 中维护阶段级状态，只给每个 phase 一个主状态。
- 各 `phase-*.md` 中维护任务级状态，每个任务必须有一个状态标记。
- 开始执行某个任务时，将其改为 `## [-] 任务 x.x：...`。
- 任务完成并验证后，将其改为 `## [x] 任务 x.x：...`。
- 尚未开始的任务保持 `## [ ] 任务 x.x：...`。
- 一个阶段内同时最多只有一个任务使用 `[-]`。
- 如果阶段完成标准全部满足，将该阶段在 README 中标记为 `[x]`。
- 如果阶段仍有未完成任务或完成标准未满足，则该阶段在 README 中不得标记为 `[x]`。

## 阶段状态板

- [x] Phase 0: [phase-0-baseline-and-target-lock.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-0-baseline-and-target-lock.md)
- [x] Phase 1: [phase-1-p0-occlusion-sorting-and-scale.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-1-p0-occlusion-sorting-and-scale.md)
- [x] Phase 2: [phase-2-visual-template-and-resource-rules.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-2-visual-template-and-resource-rules.md)
- [x] Phase 2A: [phase-2a-blender-map-assets-and-lighting-materials.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-2a-blender-map-assets-and-lighting-materials.md)
- [x] Phase 3: [phase-3-run-map-hd2d-integration.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-3-run-map-hd2d-integration.md)
- [x] Phase 4: [phase-4-vfx-atmosphere-and-camera-performance.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-4-vfx-atmosphere-and-camera-performance.md)
- [x] Phase 5: [phase-5-acceptance-rollout-and-maintenance.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-5-acceptance-rollout-and-maintenance.md)
- [x] Phase 6: [phase-6-torch-material-and-dynamic-light-validation.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-6-torch-material-and-dynamic-light-validation.md)
- [x] Phase 7: [phase-7-reusable-torch-template-and-reference-comparison.md](D:/godot/project/hd-2d/tasks/hd2d-full-implementation-plan/phase-7-reusable-torch-template-and-reference-comparison.md)

使用方式：

- 总 goal 模式下，从上到下找到第一个 `[ ]` 阶段并执行。
- 单阶段 goal 模式下，只更新当前目标阶段的状态。
- 如果某阶段正在进行，可临时改为 `[-]`，本轮结束前再收敛为 `[ ]` 或 `[x]`。

## 阶段文件

按顺序执行：

1. `phase-0-baseline-and-target-lock.md`
   锁定当前完成度、目标效果、截图基线和验证入口。

2. `phase-1-p0-occlusion-sorting-and-scale.md`
   补齐 HD-2D 最容易翻车的 P0 验证：遮挡、透明排序、清晰度、比例、Billboard 和镜头。

3. `phase-2-visual-template-and-resource-rules.md`
   将实验场中稳定的视觉配置沉淀为角色模板、环境模板、导入规则和视觉规范。

4. `phase-2a-blender-map-assets-and-lighting-materials.md`
   建立 Blender 地图素材、GLB 导出、材质受光、阴影和发光材质验证流程。

5. `phase-3-run-map-hd2d-integration.md`
   将 HD-2D 视觉公式接入正式 3D Run 地图，并保持地图流程测试通过。

6. `phase-4-vfx-atmosphere-and-camera-performance.md`
   增强氛围、特效、动态光、相机演出和性能压力验证。

7. `phase-5-acceptance-rollout-and-maintenance.md`
   做最终验收、文档归档、回滚策略和后续制作维护规则。

8. `phase-6-torch-material-and-dynamic-light-validation.md`
   继续验证火把纯特效、墙/地受光材质和多光源动态光照，形成可进入正式地图的下一轮制作方案。

9. `phase-7-reusable-torch-template-and-reference-comparison.md`
   基于参考图制作可复用火把模板，接入验证场和正式 Run 地图，并用同机位截图完成 Phase 6 / Phase 7 / 参考图对比。

## 阶段交付物索引

每个阶段结束时，都要留下可被下一阶段直接使用的交付物：

| 阶段 | 主要交付物 | 进入下一阶段的门槛 |
|---|---|---|
| 阶段 0 | 当前实验场结构记录、截图基线、Godot 版本记录、P0 风险清单 | `godot --headless --quit` 可运行，或失败原因已明确 |
| 阶段 1 | 可移动角色验证路线、遮挡/排序样本、截图矩阵、比例推荐值 | 角色移动、遮挡、透明排序和镜头方案有明确推荐 |
| 阶段 2 | 角色模板、环境模板、导入规则、材质规则、视觉验收清单 | 默认参数已写入模板，不再靠口头记忆调参 |
| 阶段 2A | Blender 源资产规范、GLB 路径规范、地图材质规则、受光验证场 | 地图素材可被 Godot 灯光、阴影、Glow 和后处理正确影响 |
| 阶段 3 | 正式 Run 地图 HD-2D 场景结构、地图视觉升级、Run 流程回归记录 | 正式 Run 流程不破坏，2D 回退仍保留 |
| 阶段 4 | 最小 VFX 样本、动态光样本、相机演出规则、性能压力记录 | 增强效果不破坏 P0 清晰度、遮挡和排序 |
| 阶段 5 | 最终截图矩阵、验证命令清单、性能预算、回滚策略、制作规范归档 | 后续角色、地图、特效能按同一规范扩展 |
| 阶段 6 | 火把纯特效验证场、墙/地受光材质截图、多光源对照、下一轮光照制作规范 | 3 光源默认方案有截图证据，火把不用贴图且墙/地能受光 |
| 阶段 7 | 可复用火把模板、验证场接入、正式 Run 地图样本、Phase 6 / Phase 7 / 参考图对比表 | 新模板优于 Phase 6 P0，默认不超过 3 动态光，正式地图流程不破坏 |

推荐阶段执行记录路径：

```text
tasks/hd2d-full-implementation-plan/records/
  phase-0-baseline-record.md
  phase-1-p0-validation-record.md
  phase-2-template-record.md
  phase-2a-blender-asset-record.md
  phase-3-run-map-integration-record.md
  phase-4-vfx-performance-record.md
  phase-5-final-acceptance-record.md
  phase-6-lighting-validation-record.md
  phase-7-torch-template-comparison-record.md
```

执行记录只保存结论、命令结果、截图文件名和关键参数，不提交 `output/` 截图文件。

## 执行记录模板

每个 `records/phase-*.md` 至少包含以下字段：

```text
# Phase X 执行记录

阶段状态： [ ] 未完成 / [-] 进行中 / [x] 已完成
本阶段目标：
输入资料：
本轮完成项：
本轮未完成项：
验证命令：
验证结果：
是否达到阶段完成标准：
下一阶段入口：
```

写入要求：

- `本轮完成项` 只记录已经落地并验证的内容。
- `本轮未完成项` 要和当前 phase 文档中的 `[ ]` 任务保持一致。
- `是否达到阶段完成标准` 只能写 `是` 或 `否`。
- 如果写 `否`，`下一阶段入口` 必须仍指向当前 phase。
- 如果写 `是`，`下一阶段入口` 指向下一个 phase；phase 5 完成时写 `总 goal 完成`。

## 全局约束

- 优先保持 Godot 4.6 兼容；文档中出现 Godot 4.7 时，执行前应改回 4.6 或明确升级决策。
- 不把复杂 Shader、体积雾、动态昼夜、大规模地图放在 P0 阶段。
- Blender 只作为源资产制作工具，不作为运行时依赖；运行时引用 `.glb`、`.tres`、`.png` 或 Godot 原语回退。
- 不删除现有 2D 地图、3D MVP 地图或 HD2D 实验场。
- 不移动 `assets/generated/enginner/` 现有资源路径，避免破坏 `.import` 和已有引用。
- 不提交 `.godot/`、`logs/`、`output/` 截图和临时缓存。
- 每个阶段宣称完成前至少运行该阶段列出的最小验证命令。

## 总体验收标准

- 固定截图能看出前景、中景角色、背景层次和局部光源。
- 角色像素边缘清晰，不被 TAA、DOF、雾或缩放明显糊掉。
- 角色在墙体、柱子、前景、桥/台阶和透明特效之间移动时，遮挡关系不闪烁、不反盖、不穿帮。
- 假阴影让角色稳定贴地，没有 z-fighting。
- 正式 Run 地图视觉升级后，节点点击、战斗返回、商店/休息/事件返回仍按原流程工作。
- 性能压力测试下帧率稳定，后处理、灯光、粒子数量有可维护上限。

## 总 goal 完成判据

只有同时满足以下条件，整个 README 对应的总 goal 才算完成：

- README 阶段状态板中的 `Phase 0` 到当前最后阶段全部为 `[x]`。
- 每个 phase 文档中的任务项全部为 `[x]`。
- 每个 phase 的执行记录已经写入 `records/`。
- 每个 phase 文档要求的最小验证命令已经运行，或已在执行记录中明确阻断原因。
- `phase 5` 的最终截图矩阵、验证矩阵、性能预算和回滚策略都已归档。
