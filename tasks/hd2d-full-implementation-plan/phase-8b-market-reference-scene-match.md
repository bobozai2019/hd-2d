# Phase 8B: 市集参考图场景级表现复刻

阶段状态： `[x]` 已完成

## 目标

本阶段目标不是继续做单点受光实验，而是以参考图为目标，制作一张可对比的 HD-2D 市集场景截图。参考图路径：

```text
C:\Users\18205\Desktop\test截图\light_sample.png
docs/hd2d/reference/light_sample.png
```

Phase 8 已经证明“冷暗环境 + 暖色局部光 + 地面/墙体 falloff + hybrid 角色受光”在隔离样例中成立，但现有画面仍存在这些问题：

- `hd2d_reference_light_response_lab.tscn` 更像受光实验棚，不像城镇复刻。
- `hd2d_market_plaza_lighting_lab.tscn` 有城镇结构，但整体过亮、过黄，缺少冷暗边缘和中央局部暖光池。
- 资产密度不足，缺少参考图里的摊位、布棚、木架、桶箱、盘子、布料、招牌、梯子、二层平台和前景遮挡。
- 地砖尺度偏大，砖缝和石块边缘在暖光下不够可读。
- 角色比例偏展示用，未达到“角色小、场景包裹角色”的参考图读法。

本阶段最终要回答：

1. 使用 BlenderMCP 补资产和材质后，现有 Godot 渲染链路能否接近参考图的市集氛围。
2. 画面不足时，卡点到底是资产密度、地面材质、建筑材质、灯光分区、角色比例、镜头构图、后处理，还是 Godot 透明/导入限制。
3. 哪些参数和资产可以迁移回正式场景，哪些只能作为实验资源保留。

## 表现目标

参考图要转化为可验收的视觉目标：

| 画面项 | 参考图目标 | 第二版验收要求 |
|---|---|---|
| 构图 | 左右建筑和前景暗部框住中央街区 | 画面左右和前景有真实模型遮挡，不只靠全屏暗角 |
| 角色比例 | 角色小，场景是主角 | 主角高度约占 720p 画面高度的 `10% ~ 14%` |
| 中央暖光 | 中央街道有明显暖色光池 | 地面中央暖光明显，但砖缝仍可读 |
| 冷暗环境 | 边缘和远处偏冷偏暗 | Ambient 使用低能量冷色，不能整屏黄棕 |
| 建筑立面 | 受光面、背光面、屋檐阴影明确 | 墙面、屋檐、台阶至少有 3 层明暗关系 |
| 市集密度 | 摊位、货物、灯笼和二层结构丰富 | 新增小资产必须进入截图并提高画面复杂度 |
| 光源层级 | 多个灯笼/火光形成高亮点 | 默认真实动态局部光 `<= 3`，其余用 emission / patch |
| 角色融合 | 角色清晰且接住环境暖光 | 主体仍优先 unshaded，使用脚底/侧向暖色 hybrid 辅助 |
| 后处理 | Glow/雾服务空气感，不糊屏 | 关闭后处理时，资产和灯光关系仍成立 |

## 生成什么资源

本阶段允许使用 BlenderMCP 制作或修改 Blender 源资产。运行时仍不直接引用 `.blend`，只引用导出的 `.glb`、`.tres`、`.png`。

重要约束：

- Blender / GLB 中不保留运行时灯光。若源文件中为了预览放置了灯光，导出或 Godot 导入后必须删除、隐藏或禁用。
- 默认 profile 中，场景根节点和 GLB 实例子树内所有可见 `OmniLight3D` / `SpotLight3D` 合计必须 `<= 3`。
- 新增资产必须进入最终机位截图；只生成在 Blender 文件或 GLB 中但没有入镜，不算达成资产密度目标。

### Blender 源资产

优先复制现有市场源文件作为第二版实验源，避免破坏当前基线：

```text
assets/source/map3d/blender/
  hd2d_market_plaza.blend
  hd2d_market_reference_match.blend
```

`hd2d_market_reference_match.blend` 目标：

- 保留当前市场广场的基本建筑关系。
- 缩小角色视觉占比所需的街道纵深和前景空间。
- 增加真实模型遮挡，而不是只用黑色面片压暗边缘。
- 为新增小资产保留独立命名对象，方便 Godot 中定位和替换材质。

### GLB 运行时模型

导出组合场景和可复用模块两类资源：

```text
assets/generated/map3d/models/
  hd2d_market_reference_match.glb
  hd2d_market_prop_crates.glb
  hd2d_market_prop_barrels.glb
  hd2d_market_prop_tableware.glb
  hd2d_market_prop_ladder.glb
  hd2d_market_prop_hanging_cloth.glb
  hd2d_market_prop_signboard.glb
  hd2d_market_prop_foreground_steps.glb
```

最低资产清单：

| 资源 | 用途 | 必须解决的问题 |
|---|---|---|
| 前景台阶/低墙 | 画面底部压暗和层次 | 解决参考图前景暗框缺失 |
| 左右建筑屋檐 | 建筑投影和暗边 | 解决墙面平、无遮挡 |
| 布棚摊位 | 中央市集识别度 | 解决场景不像市集 |
| 桶箱货架 | 小物件密度 | 解决画面空和模型感太干净 |
| 餐盘/罐子/布料 | 高频细节 | 解决参考图杂物层次不足 |
| 梯子/二层平台 | 右侧纵向结构 | 解决参考图建筑高度变化不足 |
| 招牌/窗框/门框 | 立面读性 | 解决墙面大块色面 |
| 后排灯笼/窗光壳体 | 小高亮点 | 解决远景灯光层级不足 |

最终截图最低入镜要求：

- 前景台阶/低墙：至少 `1` 组可见。
- 左右建筑屋檐/立面凸出：左右至少各 `1` 处可见。
- 中央摊位/布棚：至少 `2` 组可见。
- 桶、箱、货架、罐、盘、布料等小物件：至少 `8` 个实例可见，并覆盖不少于 `3` 个类别。
- 梯子或二层平台：至少 `1` 处可见。
- 后排灯笼/窗光壳体：至少 `4` 个小高亮点可见，其中默认真实动态光不超过预算。

### 贴图资源

新增贴图以“低分辨率、可受光、不过度写实”为目标：

```text
assets/generated/map3d/textures/
  hd2d_market_ref_stone_floor_albedo.png
  hd2d_market_ref_stone_floor_normal.png
  hd2d_market_ref_stone_floor_occlusion.png
  hd2d_market_ref_limestone_wall_albedo.png
  hd2d_market_ref_limestone_wall_normal.png
  hd2d_market_ref_limestone_wall_occlusion.png
  hd2d_market_ref_aged_wood_albedo.png
  hd2d_market_ref_aged_wood_normal.png
  hd2d_market_ref_fabric_canopy_albedo.png
  hd2d_market_ref_fabric_canopy_normal.png
  hd2d_market_ref_roof_tile_albedo.png
  hd2d_market_ref_roof_tile_normal.png
```

贴图制作要求：

- 地面石板尺度比当前市场图更小，砖缝更暗。
- Albedo 不要自带过强暖黄，基础色应中性偏冷暗，让灯光负责变暖。
- Normal 只增强砖缝、木纹、屋瓦边缘，不做写实强凹凸。
- Occlusion 或暗线贴图用于保留砖缝和墙面脏边，避免暖光把细节洗平。
- 布棚允许红/青色对比，但饱和度要受夜景压低。

### Godot 材质资源

新增实验材质，不直接覆盖正式默认材质：

```text
assets/generated/map3d/materials/
  mat_hd2d_market_ref_stone_floor.tres
  mat_hd2d_market_ref_limestone_wall.tres
  mat_hd2d_market_ref_aged_wood.tres
  mat_hd2d_market_ref_fabric_canopy.tres
  mat_hd2d_market_ref_roof_tile.tres
  mat_hd2d_market_ref_prop_dark.tres
  mat_hd2d_market_ref_window_emission_warm.tres
  mat_hd2d_market_ref_lantern_emission_warm.tres
```

材质参数起点：

| 材质 | Albedo 目标 | Roughness | Specular | 其他 |
|---|---|---|---|---|
| 石板地面 | 中性冷灰棕，低饱和 | `0.9 ~ 0.96` | `0.05 ~ 0.1` | 可用 normal / occlusion |
| 石灰墙 | 暗米灰，受光后偏暖 | `0.86 ~ 0.94` | `0.06 ~ 0.12` | 加脏边和砖缝 |
| 老木头 | 深棕但不橙 | `0.82 ~ 0.92` | `0.06 ~ 0.12` | 木纹只服务边缘 |
| 布棚 | 红/青低饱和 | `0.88 ~ 0.96` | `0.04 ~ 0.08` | 不开 emission |
| 屋瓦 | 暗赤褐 | `0.86 ~ 0.94` | `0.05 ~ 0.1` | 避免整片亮橙 |
| 暗部道具 | 深冷棕/冷黑 | `0.9 ~ 0.98` | `0.03 ~ 0.08` | 前景压暗但保轮廓 |
| 灯笼/窗光 | 暖橙 emission | 不关键 | 不关键 | emission 强度先低后调 |

### 光斑和空气感贴图

允许新增第二版 light patch，避免复用火把墙光 patch 时形状太明显：

```text
assets/generated/hd2d/light_patches/
  alpha_market_central_warm_pool.png
  alpha_market_wall_warm_falloff.png
  alpha_market_window_glow_strip.png
  alpha_market_edge_shadow_soft.png
```

要求：

- Light patch 必须有 `no_patch` 截图对照。
- Patch 只补绘制感，不允许取代真实灯光贡献。
- 边缘压暗优先来自模型遮挡；`alpha_market_edge_shadow_soft.png` 只作为最后微调。

## 应用到场景

新增或复制一个场景作为第二版实验场：

```text
scenes/map3d/hd2d_market_reference_match_lab.tscn
scripts/map3d/hd2d_market_reference_match_lab.gd
```

推荐结构：

```text
Hd2dMarketReferenceMatchLab
├── WorldEnvironment
├── Lighting
│   ├── CoolAmbientMoon
│   ├── CenterWarmKey
│   ├── LeftShopWarm
│   └── RightShopWarm
├── Stage
│   ├── MarketReferenceMatch
│   ├── ForegroundOccluders
│   ├── LightPatches
│   └── EdgeShadowHelpers
├── VfxRoot
│   ├── TorchAndLanternSprites
│   ├── WarmDustMotes
│   └── DistantGlowCards
├── Characters
│   ├── PlayerCharacter
│   ├── LeftNpc
│   └── RightNpc
└── CameraRig
    └── Camera3D
```

### 场景调成什么效果

默认目标 profile：`reference_match_v2`

```text
Ambient:
  color = 冷蓝灰或冷绿灰
  energy = 0.08 ~ 0.18

Directional / moon:
  energy = 0.08 ~ 0.18
  color = 冷色
  只保留暗部方向，不抢暖光

CenterWarmKey:
  type = OmniLight3D
  color = warm orange
  energy = 1.4 ~ 2.4
  range = 5.5 ~ 7.5
  shadows = true

LeftShopWarm / RightShopWarm:
  type = OmniLight3D
  energy = 0.45 ~ 1.1
  range = 3.2 ~ 5.0
  至少一个启用 shadow

Emission lights:
  后排灯笼、窗光、摊位火光可多于 3 个
  但默认不增加真实动态光

Fog:
  暖色中心雾很轻
  冷色远景雾很轻
  不遮角色脸和像素边缘

Glow:
  intensity/strength 克制
  只让灯笼、火焰、窗光有小面积 bloom

DOF:
  远景轻微糊
  角色和中央摊位必须清晰
```

角色策略：

- 主体继续 `shaded=false`。
- 加脚底暖色 patch 或侧向小光感 helper，复用 Phase 8 的 hybrid 结论。
- 角色高度控制在画面高度 `10% ~ 14%`。
- 不用强 emission 补角色亮度。

镜头策略：

- 透视相机优先，保持 HD-2D 舞台纵深。
- 镜头俯角约 `-50° ~ -58°`。
- FOV 从 `34 ~ 40` 对照，优先选择能接近参考图压缩感的值。
- 画面必须露出前景暗台阶、中央街道、左右建筑和后排灯光。

## Profile 和截图矩阵

脚本应支持固定 profile，方便拆贡献：

```text
reference_profile=baseline_market
reference_profile=asset_density_v2
reference_profile=reference_match_v2
reference_profile=no_local_light
reference_profile=no_patch
reference_profile=no_post
reference_profile=character_scale_check
```

Profile 行为：

| Profile | 用途 | 验收重点 |
|---|---|---|
| `baseline_market` | 当前市场场景基线 | 证明第二版前的差距 |
| `asset_density_v2` | 只换资产/材质，尽量少改灯光 | 证明资产密度和材质尺度的贡献 |
| `reference_match_v2` | 第二版最终候选 | 对照参考图整体观感 |
| `no_local_light` | 关闭真实 OmniLight | 证明真实灯光贡献 |
| `no_patch` | 保留真实光，关闭光斑贴图 | 证明 patch 不是唯一光源 |
| `no_post` | 关闭 glow / fog / DOF | 证明资产和灯光关系本身成立 |
| `character_scale_check` | 检查角色比例和清晰度 | 证明角色小比例仍可读 |

Profile 状态必须可记录。脚本或执行记录至少输出：

| Profile | 可见真实局部光数量 | LightPatches 可见 | Glow | Fog | DOF | 备注 |
|---|---:|---|---|---|---|---|
| `baseline_market` | 待记录 | 待记录 | 待记录 | 待记录 | 待记录 | 当前市场基线 |
| `asset_density_v2` | 待记录 | 待记录 | 待记录 | 待记录 | 待记录 | 资产/材质贡献 |
| `reference_match_v2` | `<= 3` | 是 | 是 | 是 | 是 | 最终候选 |
| `no_local_light` | `0` | 可按测试目标关闭或保留并注明 | 是 | 是 | 是 | 验证真实光贡献 |
| `no_patch` | `<= 3` | 否 | 是 | 是 | 是 | 验证 patch 贡献 |
| `no_post` | `<= 3` | 是 | 否 | 否 | 否 | 同时关闭 Glow、Fog、DOF，不用提高 exposure 补偿 |
| `character_scale_check` | `<= 3` | 是 | 是 | 是 | 是 | 验证角色高度和清晰度 |

截图输出：

```text
output/market_reference_match/
  market-baseline-1280x720.png
  market-asset-density-v2-1280x720.png
  market-reference-match-v2-1280x720.png
  market-no-local-light-1280x720.png
  market-no-patch-1280x720.png
  market-no-post-1280x720.png
  market-character-scale-check-1280x720.png
```

截图必须和参考图并排对比：

```text
C:\Users\18205\Desktop\test截图\light_sample.png
docs/hd2d/reference/light_sample.png
output/market_reference_match/market-reference-match-v2-1280x720.png
```

## 卡点处理

本阶段遇到卡点不能跳过，必须记录并判断是否能攻克：

| 卡点 | 可能表现 | 攻克方式 | 不通过判定 |
|---|---|---|---|
| BlenderMCP 资产生成不稳定 | 物件比例、原点、法线或材质槽混乱 | 先生成少量模块，逐个导出验证 | GLB 导入后面片错乱或无法稳定复用 |
| 地面仍像大色块 | 暖光下砖缝消失 | 缩小石板尺度，增强暗缝和 AO | `no_post` 下地面仍无细节 |
| 墙面仍平 | 建筑立面没有受光/背光层次 | 增加屋檐、窗框、门框、凹凸边 | 只能靠全屏调色区分明暗 |
| 画面仍太黄 | 冷暗边缘消失 | 降低暖 ambient，改用局部暖光 | 关闭局部光后画面仍整屏暖黄 |
| 动态光超预算 | 多灯笼都想照亮场景 | 3 个真实光，其余 emission/patch | 默认 profile 超过 3 个动态局部光 |
| 角色太大或太抢 | 不像参考图微缩舞台 | 调相机、角色 scale、站位 | 主角高度超过画面 16% |
| 角色太糊 | DOF/雾/bloom 吃掉像素边 | 降低 DOF/雾，角色区避开 bloom | 720p 下脸部和轮廓不可读 |
| Patch 穿帮 | 透明面排序或形状感明显 | 调层级、位置、alpha，必要时重做贴图 | `no_patch` 与最终图差距过大且 patch 形状明显 |

参考图对比评分表必须写入执行记录：

| 对比项 | 通过标准 | Baseline | Final | 结论 | 原因 / 下一步 |
|---|---|---|---|---|---|
| 构图框景 | 左右建筑和前景暗部都入镜，中央街区被框住 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |
| 资产密度 | 最低入镜资产数量和类别达标 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |
| 地面尺度 | 中央暖光下砖缝仍可读，不是大色块 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |
| 墙面层次 | 墙面、屋檐、台阶至少有 3 层明暗关系 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |
| 灯光分区 | 冷暗边缘 + 中央暖光池成立，非整屏黄 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |
| 真实光贡献 | `no_local_light` 明显失去墙地暖光 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |
| Patch 控制 | `no_patch` 仍保留真实 falloff，final 只增强绘制感 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |
| 后处理控制 | `no_post` 下资产和光照关系仍成立 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |
| 角色比例 | 主角高度约占 720p 画面 `10% ~ 14%`，超过 `16%` 失败 | 待记录 | 待记录 | 通过 / 部分 / 失败 | 待记录 |

## [x] 任务 8B.1：锁定参考图目标和当前差距

目标：

- 读取 `C:\Users\18205\Desktop\test截图\light_sample.png` 和 `docs/hd2d/reference/light_sample.png`。
- 对比当前 `output/market_plaza/hd2d_market_plaza_lighting_lab_1280x720.png`。
- 记录当前差距：构图、角色比例、资产密度、地面尺度、墙面层次、灯光分区、后处理。

验收：

- 输出参考图拆解表。
- 明确第二版不是继续调 `hd2d_reference_light_response_lab.tscn`，而是制作场景级复刻样例。

## [x] 任务 8B.2：使用 BlenderMCP 生成第二版市集资产

目标：

- 基于 `hd2d_market_plaza.blend` 复制或生成 `hd2d_market_reference_match.blend`。
- 补齐市集小资产和真实遮挡结构。
- 保持所有对象命名可读、原点合理、法线正确、scale 已应用。

最低生成内容：

- 前景台阶/低墙。
- 左右建筑屋檐和墙面凸出层。
- 中央摊位、布棚、桌架。
- 桶、箱、罐、盘、布料、货架。
- 梯子或二层平台。
- 门框、窗框、招牌。
- 后排灯笼/窗光壳体。

验收：

- Blender 文件存在。
- GLB 导出成功。
- Godot 导入后模型方向、比例和材质槽可用。
- GLB 导入后不包含默认启用的运行时真实灯光；如包含，必须在场景中禁用并记录。
- 最低资产清单中的关键模块必须进入最终机位截图。
- 若 BlenderMCP 无法生成某类资产，必须记录失败原因和替代方案。

当前进展：

- 已用 `scripts/tools/generate_phase8b_market_glb_assets.py` 生成程序化运行时 GLB 资产，并导入 Godot：
  - `assets/generated/map3d/models/hd2d_market_reference_match.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_crates.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_barrels.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_tableware.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_ladder.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_hanging_cloth.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_signboard.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_foreground_steps.glb`
- 已通过 BlenderMCP 将组合 GLB 导入 Blender，并保存可追溯源文件：
  - `assets/source/map3d/blender/hd2d_market_reference_match.blend`
  - `assets/source/map3d/blender/hd2d_market_reference_match_source_note.md`
- `scenes/map3d/hd2d_market_reference_match_lab.tscn` 已接入组合 GLB；原 Godot primitive 组保留为隐藏 fallback。
- 本阶段已满足“BlenderMCP 或可解释替代流程生成第二版市集资产”的验收；但当前 `.blend` 是 BlenderMCP 导入程序化低模 GLB 后保存的源交接文件，不是最终手工美术精修版。
- 手工复杂度仍作为后续卡点记录：右侧建筑体量、二层平台、摊位杂物、门窗檐口和远景空气感还需要继续美术细化。

## [x] 任务 8B.3：制作第二版材质和贴图

目标：

- 新增参考匹配用材质和贴图。
- 地面、墙面、木头、布棚、屋瓦都能接收真实光照。
- 基础 albedo 避免过暖，保留冷暗环境空间。

验收：

- 新增 `.tres` 材质不覆盖当前正式材质。
- 地面石板在暖光下仍有砖缝。
- 墙体有脏边、窗框、屋檐阴影和受光面差异。
- `no_post` 截图下材质层次仍成立。

## [x] 任务 8B.4：建立市场参考匹配场景

目标：

- 新增 `hd2d_market_reference_match_lab.tscn`。
- 接入第二版 GLB、材质、light patch、角色和火把/灯笼。
- 实现 profile 切换脚本。

验收：

- 场景可 headless 加载。
- 默认 profile 中，场景根节点和 GLB 子树内所有可见 `OmniLight3D` / `SpotLight3D` 合计 `<= 3`。
- 记录每个 profile 的真实局部光数量、patch 可见性、Glow、Fog、DOF 状态。
- 同一机位能输出 baseline / asset_density / final / no_local_light / no_patch / no_post / character_scale 截图。

## [x] 任务 8B.5：调光照和后处理到参考图方向

目标：

- 从“整屏暖黄”调整为“冷暗包暖光”。
- 中央暖光池明确，左右和前景有暗部框景。
- Glow、Fog、DOF 不糊角色。

验收：

- `reference_match_v2` 比 `baseline_market` 更接近参考图。
- `no_local_light` 明显失去地面/墙体暖光。
- `no_local_light` 下画面不能仍然整体暖黄，冷暗环境必须成立。
- `no_patch` 仍保留真实灯光贡献。
- `no_patch` 与 final 相比可以少空气感，但中央真实暖光池和墙地 falloff 仍应可读。
- `no_post` 仍能读出资产和光照关系。
- `no_post` 必须同时关闭 Glow、Fog、DOF，不允许通过提高 exposure 或 ambient 补偿亮度。

当前进展：

- 已降低程序 GLB 前景低墙高度和暗度，减少最终截图底部黑带压迫感。
- 已增加背墙木框、后排窗光、红/青布棚对比和摊位小物件密度。
- 已略提高 `reference_match_v2` 中心暖光和 ambient 可读性，同时保持 `no_local_light` 下冷暗环境成立。
- `no_post` 下仍能读出砖缝、中央暖光和墙面受光关系。
- 已把右侧高梯移到受光墙面前方，并使用 `RightVisibleHighLadder*` 节点作为更严格的可见性验收对象。
- 当前右侧高梯 / 二层平台已经能读出轮廓；若要接近参考图的手工复杂度，下一步仍需要在已生成的 Blender 源文件上做手工 GLB 细化。

## [x] 任务 8B.6：截图对比和卡点记录

目标：

- 生成固定截图矩阵。
- 和 `light_sample.png` 并排对比。
- 记录哪些问题已经攻克，哪些仍是卡点。

推荐记录：

```text
tasks/hd2d-full-implementation-plan/records/phase-8b-market-reference-match-record.md
```

记录内容：

- 新增资产和材质清单。
- BlenderMCP 是否顺利，失败项是什么。
- 截图文件名。
- Profile 状态表：真实局部光数量、patch 可见性、Glow、Fog、DOF。
- 最低资产入镜检查表。
- 参考图目标 vs baseline_market vs reference_match_v2 对比表。
- 参考图对比评分表，每项记录 `通过 / 部分 / 失败 / 原因 / 下一步`。
- 是否达到“场景级表现复刻”。
- 是否迁移资源或参数到 `hd2d_market_plaza_lighting_lab.tscn`、`hd2d_effect_lab.tscn` 或正式 Run 地图。

## 最小验证命令

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_market_reference_match_lab.tscn --quit-after 60
```

截图命令按实际场景落地后补齐，格式沿用：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_match_lab.tscn res://output/market_reference_match/market-reference-match-v2-1280x720.png 1280 720 reference_profile=reference_match_v2
```

## 阶段完成标准

- 已明确参考图目标，并记录当前市场基线差距。
- 已使用 BlenderMCP 或可解释的替代流程生成第二版市集资产。
- 已新增或调整材质和贴图，且没有覆盖正式默认材质。
- 已建立市场参考匹配场景并支持 profile 切换。
- 默认 profile 中所有可见真实局部光合计 `<= 3`，并已确认 GLB 子树没有额外启用灯光。
- 最低资产入镜要求达标。
- 已生成对比截图矩阵。
- 已证明真实光、patch、后处理各自贡献。
- 已写入参考图对比评分表，且构图、资产密度、地面尺度、墙面层次、灯光分区、角色比例至少达到“通过”或明确记录“部分通过”的卡点和下一步。
- 已记录所有卡点，不能攻克的项目必须说明原因和下一步方案。
- 最终截图比当前 `hd2d_market_plaza_lighting_lab` 更接近 `light_sample.png` 的构图、资产密度、冷暗边缘和中央暖光池。
