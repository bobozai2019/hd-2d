# Phase 8C: 市集参考图美术精修和主场景迁移

阶段状态： `[x]` 已完成

## 目标

Phase 8B 已完成第二版实验链路：程序化 GLB、BlenderMCP 源交接文件、参考匹配实验场、截图矩阵和卡点记录都已经成立。但当前 final 仍然是“实验版低模复刻”，没有达到参考图里那种高密度市集、右侧高楼体量、街道纵深和柔和空气感。

Phase 8C 的目标是基于 8B 成果继续做一次真正面向画面的 art pass，并决定哪些成果迁移回玩家会看到的市场/主场景。

参考目标：

```text
C:\Users\18205\Desktop\test截图\light_sample.png
docs/hd2d/reference/light_sample.png
output/market_reference_match/market-reference-match-v2-1280x720.png
```

本阶段最终要回答：

1. 8B 的低模实验资产能否升级成更接近参考图的市集画面。
2. 当前主要差距是资产复杂度、构图机位、灯光层级、材质尺度、patch 形状，还是主场景接入方式。
3. 哪些资源和参数应迁移到 `hd2d_market_plaza_lighting_lab.tscn` 或正式 Run 地图，哪些只保留在实验场。

硬性边界：

- 只新增隐藏实验 lab，不算解决“用户打开场景看不到变化”。
- 8C 可以保留 `hd2d_market_reference_artpass_lab.tscn` 做调试，但阶段完成必须有一个明确的用户可打开入口。
- 若不迁移正式 Run 地图，必须写明本阶段只迁移到 market lighting lab，不要求 Run 流程回归。
- 若修改正式 Run 地图或主流程场景，必须追加节点点击、战斗返回、商店/休息/事件返回的最小回归记录。

## 做到什么程度

Phase 8C 不要求 1:1 复刻商业成品画面，但必须从“实验低模样张”推进到“可作为正式 HD-2D 场景方向样张”的程度。

| 项目 | 8B 当前状态 | 8C 目标程度 |
|---|---|---|
| 构图 | 左右框景成立，但空间像展示盒 | 前景、左右建筑、后排灯光形成参考图式街区包裹感 |
| 右侧建筑 | 梯子可读，但高楼体量弱 | 右侧二层平台、梯子、栏杆、挂布和立面凸出明显 |
| 市集密度 | 小物件数量达标但偏程序化 | 摊位、桶箱、盘罐、布料、货架至少形成 3 组视觉簇 |
| 地面 | 砖缝可读 | 中央暖光下仍有细碎石板节奏，前景暗部不过黑 |
| 墙面 | 明暗关系成立但平 | 门框、窗框、檐口、木梁、脏边让墙面不再是大色块 |
| 灯光 | 冷暗包暖光成立 | 中央光池、摊位灯、后排灯笼有层级，默认真实局部光仍 `<= 3` |
| Patch / Glow | 有空气感但形状偏实验 | patch 不显形，关闭 patch 后真实光关系仍成立 |
| 角色 | 比例通过 | 主角在 720p 下约 `10% ~ 13%`，清晰且不抢场景 |
| 主场景 | 主要在 8B lab 中 | 至少迁移一个可打开的主场景/候选场景，用户能直接看到变化 |

## 生成和修改什么资源

### Blender 源资产

基于 8B 的源交接文件继续细化，不再只依赖程序化方块生成：

```text
assets/source/map3d/blender/
  hd2d_market_reference_match.blend
  hd2d_market_reference_match_artpass.blend
  hd2d_market_reference_match_source_note.md
```

要求：

- 保留 `hd2d_market_reference_match.blend` 作为 8B 基线，不直接破坏。
- 新增或复制出 `hd2d_market_reference_match_artpass.blend`。
- 手工或 BlenderMCP 批量生成的对象必须有可读命名，例如 `RightTowerBalconyRailA`、`BackLanternShell03`。
- 不在源文件中保留会进入 Godot 默认启用的运行时灯光；预览灯必须命名 `PreviewOnly_*` 并隐藏 render。
- 导出前必须检查单位、轴向、原点和 transform；对象要应用 scale，法线方向正确。
- `PreviewOnly_*`、Blender 预览灯和临时 helper 不进入运行时 GLB；若导入 Godot，必须在场景脚本中禁用并记录。
- 对象命名必须保留到 GLB node name，供 Godot 脚本和测试做关键资产可见性检查。
- 8C art pass 开始后，`hd2d_market_reference_match_artpass.blend` 是 art pass 权威源；Python 生成器只能作为 fallback 或批量生成初稿，不能无说明地覆盖手工 `.blend` 改动。

### GLB 运行时资产

新增 art pass 版本，避免覆盖 8B 实验基线：

```text
assets/generated/map3d/models/
  hd2d_market_reference_match_artpass.glb
  hd2d_market_prop_wall_detail_set.glb
  hd2d_market_prop_stall_detail_set.glb
  hd2d_market_prop_right_tower_set.glb
```

最低新增内容：

- 右侧二层平台：栏杆、梯子、挂布、阴影檐口、门窗框。
- 中央摊位细化：货架层板、盘罐堆、布料垂边、支撑木架。
- 后排灯光壳体：至少 6 个小高亮点，默认不增加真实动态光。
- 前景遮挡：真实台阶/低墙/边缘石块，不靠纯黑全屏遮罩。
- 左右建筑立面：窗框、门框、木梁、招牌、屋檐投影结构。

关键命名片段：

```text
RightTowerBalconyRail
RightTowerPlatform
RightVisibleHighLadder
RightHangingCloth
BackLanternShell
ForegroundStep
ForegroundLowWall
StallClusterA
StallClusterB
StallClusterC
WallTrim
WindowFrame
DoorFrame
```

自动测试和执行记录必须基于这些命名片段检查资产是否存在；视觉审核还要确认它们进入 final 机位，不能只证明文件存在。

组合 GLB 和 detail set 的使用规则：

- art pass 场景默认使用 `hd2d_market_reference_match_artpass.glb` 作为完整组合资产。
- detail set 主要用于迁移、替换或局部调试。
- 如果组合 GLB 和 detail set 同时实例化，必须记录哪些 detail set 是额外覆盖，避免右塔、摊位或墙面细节重复出现。

### 材质和贴图

8B 材质可复用，但 8C 要补一组更适合细节资产的材质：

```text
assets/generated/map3d/materials/
  mat_hd2d_market_artpass_wall_trim.tres
  mat_hd2d_market_artpass_prop_ceramic.tres
  mat_hd2d_market_artpass_prop_fabric_red.tres
  mat_hd2d_market_artpass_prop_fabric_teal.tres
  mat_hd2d_market_artpass_shadow_wood.tres
```

目标：

- 墙面和木梁不要整屏黄，基础色保持冷暗中性。
- 小物件高频细节靠形体和 AO，不靠过亮 albedo。
- 布料保留红/青对比，但夜景饱和度下降。
- 暗部前景不能纯黑死块，至少保留边缘轮廓。

材质接线规则：

- Blender 材质槽命名固定为 `wall_trim`、`ceramic`、`fabric_red`、`fabric_teal`、`shadow_wood`、`emission_lantern`、`emission_window`。
- Godot 导入后必须选择一种稳定接线方式：
  - 在导入设置中 remap 到对应 `.tres`；
  - 或在 art pass 场景中按 node/material slot 使用 `material_override` / surface material override。
- 执行记录要写明采用哪种方式，并用 `no_post` 截图证明材质不是只靠后处理变好。
- 如果仍使用嵌入 GLB 材质，必须说明哪些 `.tres` 没有用上，不能把未接入材质算作完成。

### Light Patch / VFX

新增更自然的 patch，不复用 8B 中形状感明显的实验贴图：

```text
assets/generated/hd2d/light_patches/
  alpha_market_artpass_center_pool.png
  alpha_market_artpass_stall_bounce.png
  alpha_market_artpass_back_lantern_haze.png
  alpha_market_artpass_foreground_vignette.png
```

要求：

- `no_patch` 下真实光照仍成立。
- patch 只补绘制感和空气感，不替代真实灯光。
- patch 边界不能在 720p final 截图中明显穿帮。

## 应用到场景

继续保留 8B 实验场，同时新增 8C art pass 场景：

```text
scenes/map3d/hd2d_market_reference_artpass_lab.tscn
scripts/map3d/hd2d_market_reference_artpass_lab.gd
```

并明确选择一个可见入口场景做迁移候选：

```text
scenes/map3d/hd2d_market_plaza_lighting_lab.tscn
```

迁移策略：

- `hd2d_market_reference_artpass_lab.tscn` 用于重度对比、profile 拆分和截图矩阵。
- `hd2d_market_plaza_lighting_lab.tscn` 只迁移成熟结果，不塞入所有实验 helper。
- 阶段完成时必须满足其一：
  - 成熟 art pass 参数/资产已经迁移到 `hd2d_market_plaza_lighting_lab.tscn`；
  - 或新增一个非隐藏、文档明确标注的用户可打开候选场景，并说明它为何暂不替换 `hd2d_market_plaza_lighting_lab.tscn`。
- 仅新增 `hd2d_market_reference_artpass_lab.tscn` 不单独计为主场景迁移完成。
- 如正式 Run 地图暂不迁移，必须写明原因和下一步入口，不能让用户“打开场景看不到变化”。

迁移灯光预算规则：

- 迁移到 `hd2d_market_plaza_lighting_lab.tscn` 时，必须审计现有 `OmniLight3D` / `SpotLight3D`。
- 禁用或隐藏导入 GLB 灯、torch 子树内置 `TorchLight` 和不参与最终默认 profile 的旧局部光。
- 默认只保留 `CenterWarmKey + LeftShopWarm + RightShopWarm` 或等价的 3 盏真实局部光。
- 若为了调试保留更多灯，必须在非默认 profile 中并写入记录，默认 profile 不允许超过 3 盏可见真实局部光。

## 场景调成什么效果

默认目标 profile：`artpass_reference_v1`

```text
Ambient:
  color = 冷蓝灰或冷绿灰
  energy = 0.06 ~ 0.14

Directional / moon:
  energy = 0.05 ~ 0.14
  color = 冷色
  只保留暗部方向，不抢中央暖光

CenterWarmKey:
  type = OmniLight3D
  energy = 1.6 ~ 2.6
  range = 5.2 ~ 7.2
  shadows = true

LeftShopWarm / RightShopWarm:
  type = OmniLight3D
  energy = 0.45 ~ 1.1
  range = 3.0 ~ 5.0
  至少一个启用 shadow

Emission:
  灯笼、窗光、摊位火光可多于 3 个
  但不增加真实动态光预算

Fog:
  中心暖雾轻微
  后排冷雾轻微
  角色脸和像素边缘不被糊掉

Glow:
  小面积 bloom，只服务灯笼/窗光/火光
  不让墙面和地面整体发光

DOF:
  远景轻微糊
  主角、中央摊位、地面光池清晰
```

镜头目标：

- 720p final 截图中主角高度约 `10% ~ 13%`。
- 画面必须包含前景台阶、左右建筑、右侧二层结构、中央摊位、后排灯笼。
- 参考图的右侧高楼/梯子/挂布必须成为一眼可见的视觉锚点。
- 允许比 8B 更接近参考图的横向构图，不强求沿用 8B 机位。

## Profile 和截图矩阵

8C 脚本应支持：

```text
reference_profile=baseline_8b_final
reference_profile=asset_artpass_only
reference_profile=artpass_reference_v1
reference_profile=no_local_light
reference_profile=no_patch
reference_profile=no_post
reference_profile=main_scene_migration
reference_profile=character_scale_check
```

Profile 语义：

| Profile | 语义 | 主要证明 |
|---|---|---|
| `baseline_8b_final` | 复现 8B `reference_match_v2` 或加载同等截图基线 | 证明 8C final 的提升对象明确 |
| `asset_artpass_only` | art pass GLB + 材质，关闭 patch/post，保留基础环境和必要真实光 | 证明资产和材质本身有贡献 |
| `artpass_reference_v1` | 8C 默认最终候选 | 对照参考图和 8B final |
| `no_local_light` | 关闭默认真实局部光 | 证明真实光照贡献 |
| `no_patch` | 保留真实光，关闭 patch | 证明 patch 不是唯一光源 |
| `no_post` | 关闭 Glow / Fog / DOF，不提高 exposure 补偿 | 证明资产、材质和光照关系成立 |
| `character_scale_check` | 与 final 同机位，输出角色比例检查状态 | 证明角色约 `10% ~ 13%` 且清晰 |

`main_scene_migration` 不作为 art pass lab 的普通 profile 处理。它是对迁移目标场景的单独截图和记录项：

```text
scene=res://scenes/map3d/hd2d_market_plaza_lighting_lab.tscn
output=output/market_reference_artpass/market-artpass-main-scene-migration-1280x720.png
```

如果最终采用新的非隐藏候选场景，必须在记录中把该场景路径替换到 `main_scene_migration` 项。

截图输出：

```text
output/market_reference_artpass/
  market-8b-final-1280x720.png
  market-artpass-asset-only-1280x720.png
  market-artpass-reference-v1-1280x720.png
  market-artpass-no-local-light-1280x720.png
  market-artpass-no-patch-1280x720.png
  market-artpass-no-post-1280x720.png
  market-artpass-main-scene-migration-1280x720.png
  market-artpass-character-scale-1280x720.png
```

并排对比必须包含：

```text
C:\Users\18205\Desktop\test截图\light_sample.png
output/market_reference_match/market-reference-match-v2-1280x720.png
output/market_reference_artpass/market-artpass-reference-v1-1280x720.png
output/market_reference_artpass/market-artpass-main-scene-migration-1280x720.png
```

## 卡点处理

本阶段卡点不能跳过，必须判断能不能攻克：

| 卡点 | 可能表现 | 攻克方式 | 不通过判定 |
|---|---|---|---|
| BlenderMCP 只能导入不能稳定手工生成 | 资产仍像程序方块 | 分批生成右塔、摊位、墙面 detail set，再导出验证 | art pass GLB 和 8B final 几乎无差别 |
| 右侧建筑仍不成立 | 没有参考图右侧高楼/梯子锚点 | 加高楼体量、二层平台、栏杆、挂布、外置梯 | final 中右侧仍只是平墙 |
| 市集仍空 | 桶箱盘罐像散落 props | 做 3 组视觉簇，明确摊位货架层次 | 小物件数量达标但截图仍空 |
| 前景过黑 | 底部黑带压迫 | 用真实台阶/低墙层次替代黑色遮罩 | 前景没有石块边缘，只是黑带 |
| Patch 穿帮 | 透明面边界可见 | 重做 alpha、调位置、拆多张低强度 patch | `no_patch` 与 final 差距过大且 final 能看出贴片形状 |
| 主场景看不到变化 | 用户打开常用场景仍是旧效果 | 迁移一份成熟候选到 `hd2d_market_plaza_lighting_lab.tscn` 或新入口 | 只有 lab 截图变好，常用场景无可见入口 |
| 动态光超预算 | 为每个灯笼加真实光 | 3 盏真实光，其余 emission/patch | 默认 profile 可见真实局部光 `> 3` |
| 材质未接入 | `.tres` 存在但 GLB 仍用嵌入材质 | 固定材质槽命名并 remap / override | `no_post` 下看不出 art pass 材质差异，记录也说不清材质接线 |

## [x] 任务 8C.1：锁定 8B 差距和 8C 目标画面

目标：

- 并排查看参考图、8B final、8B no_post、8B no_patch。
- 明确 8C 必须优先攻克的画面问题。

验收：

- 写出 8C 优先级：右侧体量、摊位密度、墙面层次、前景遮挡、patch 自然度、主场景入口。
- 明确哪些 8B 内容保留，哪些要重做。

## [x] 任务 8C.2：制作 art pass Blender 源资产

目标：

- 基于 `hd2d_market_reference_match.blend` 新增 `hd2d_market_reference_match_artpass.blend`。
- 补右侧二层、高楼体量、摊位细节、墙面 detail、前景遮挡和后排灯光壳体。

验收：

- `.blend` 存在并可打开。
- 对象命名可读，材质槽可定位。
- 无默认启用的运行时灯光。
- 单位、轴向、原点、transform、法线和对象命名保留策略已记录。
- 源资产说明更新，写明哪些是手工/BlenderMCP 生成，哪些仍是程序化基线。

## [x] 任务 8C.3：导出 art pass GLB 并接入 Godot

目标：

- 导出 art pass 组合 GLB 和 detail set。
- 新增 art pass 场景并接入模型、材质和 patch。

验收：

- GLB import 成功。
- 场景 headless 可加载。
- 默认 profile 可见真实局部光 `<= 3`。
- 材质 remap / override 路径已落地，且执行记录写明接线方式。
- 最低新增资产全部在 final 机位入镜。

## [x] 任务 8C.4：重调灯光、patch、fog、glow 和镜头

目标：

- 从 8B 的“实验盒子感”推进到参考图的“市集街区感”。
- 保持冷暗边缘 + 中央暖光池，避免整屏黄。

验收：

- `artpass_reference_v1` 明显优于 8B final。
- `no_local_light` 明显失去暖光 falloff。
- `no_patch` 仍有真实光照关系。
- `no_post` 仍有资产/材质/光照层次。
- 角色高度约 `10% ~ 13%`，不超过 `15%`。

## [x] 任务 8C.5：迁移一个可见入口场景

目标：

- 让用户打开常用市场场景时能看到 8C 成果，而不是只在隐藏 lab 中存在。

验收：

- 必须完成其一：
  - 将成熟 art pass 参数/资产迁移到 `hd2d_market_plaza_lighting_lab.tscn`；
  - 或新增非隐藏候选场景并在 README/记录中写明用户打开路径和暂不替换 market lighting lab 的原因。
- 仅新增 `hd2d_market_reference_artpass_lab.tscn` 不算通过。
- 默认迁移入口真实局部光 `<= 3`；如目标场景原本有更多灯，必须禁用或转入非默认 profile。
- 截图包含 `main_scene_migration` 对照。
- 不破坏原 8B lab 回归。

## [x] 任务 8C.6：截图对比、评分和下一步判断

目标：

- 生成完整 8C 截图矩阵。
- 和参考图、8B final、主场景迁移图并排对比。

推荐记录：

```text
tasks/hd2d-full-implementation-plan/records/phase-8c-market-artpass-record.md
```

记录内容：

- 新增/修改资产清单。
- BlenderMCP / 手工资产卡点。
- profile 状态表：真实局部光数量、patch、Glow、Fog、DOF。
- 最低资产入镜检查。
- 参考图评分表，至少包含：右侧建筑体量、市集密度、墙面层次、前景遮挡、patch 自然度、灯光层级、主场景入口。
- 每个评分项记录 `通过 / 部分 / 失败`、原因、下一步。
- 阶段完成要求至少 5 项通过，且右侧建筑体量、市集密度、主场景入口不得失败。
- 主场景迁移记录：迁移目标场景路径、用户打开路径、迁移内容清单、未迁移内容清单、未迁移原因、下一步入口。
- Godot 验证记录：`godot.exe` 路径、实际输出 Godot 版本；若不是 4.6.x，必须说明是否影响本阶段结论。
- 是否达到“可作为正式 HD-2D 市集方向样张”。

## 最小验证命令

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --import
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn --quit-after 60
D:\godot\Godot_v4.6.2\godot.exe --headless --path . -s res://scripts/autotest/test_hd2d_market_reference_artpass_lab.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --quit
```

自动测试脚本至少检查：

- art pass GLB 和必要 detail set 资源存在。
- art pass lab、8B lab、迁移入口场景都能加载。
- 7 个 art pass lab profile 可切换。
- 默认 profile 可见真实局部光 `<= 3`。
- `no_local_light` 可见真实局部光为 `0`。
- `no_patch` 隐藏所有 art pass patch。
- `no_post` 同时关闭 Glow / Fog / DOF。
- 关键命名片段存在并达到最低计数：`RightTowerBalconyRail`、`RightVisibleHighLadder`、`BackLanternShell`、`ForegroundStep`、`StallClusterA/B/C`。

截图命令必须在阶段完成前写入执行记录，格式沿用 `scripts/tools/capture_scene.gd`，且必须使用 windowed / offscreen 窗口方式；headless 只用于加载和自动测试，不作为截图导出方式。

记录中必须保存：

- 8 张截图矩阵的完整命令。
- `main_scene_migration` 单独场景截图命令。
- 输出路径和截图刷新时间。

## 阶段完成标准

- 已建立 `hd2d_market_reference_match_artpass.blend` 或等价可解释源资产。
- 已导出 art pass GLB，并接入 Godot art pass 场景。
- 已补右侧二层/高楼体量、摊位细节、墙面 detail、前景遮挡和后排灯光壳体。
- 默认 profile 可见真实局部光 `<= 3`。
- 已生成 8C 截图矩阵。
- 已证明真实光、patch、后处理贡献。
- `artpass_reference_v1` 明显优于 8B final，且评分表至少 5 项通过。
- 右侧建筑体量、市集密度、主场景入口不得失败。
- 至少一个用户可打开的市场场景能看到 8C 成果；仅隐藏 lab 不算完成。
- 若未触碰正式 Run 地图，已记录本阶段不要求 Run 流程回归；若触碰正式 Run 地图，已追加节点点击、战斗返回、商店/休息/事件返回回归记录。
- 已记录仍未攻克的参考图差距，并判断是否继续 Phase 8D 或进入正式地图迁移。
