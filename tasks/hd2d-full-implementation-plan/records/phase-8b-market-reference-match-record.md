# Phase 8B 执行记录

阶段状态：[x] 已完成

本阶段目标：

- 以 `docs/hd2d/reference/light_sample.png` / `C:\Users\18205\Desktop\test截图\light_sample.png` 为目标，制作市集场景级复刻截图。
- 拆分验证资产密度、材质尺度、真实局部光、light patch、Glow/Fog/DOF 和角色比例的贡献。

输入资料：

- `tasks/hd2d-full-implementation-plan/phase-8b-market-reference-scene-match.md`
- `output/market_plaza/hd2d_market_plaza_lighting_lab_1280x720.png`
- `docs/hd2d/reference/light_sample.png`
- `assets/generated/map3d/models/hd2d_market_plaza.glb`

本轮完成项：

- 新增 8B 专用资源生成脚本：`scripts/tools/generate_phase8b_market_assets.gd`。
- 生成第二版实验贴图、材质和 light patch：
  - `assets/generated/map3d/textures/hd2d_market_ref_*`
  - `assets/generated/map3d/materials/mat_hd2d_market_ref_*`
  - `assets/generated/hd2d/light_patches/alpha_market_*`
- 新增运行时 GLB 替代生成脚本：`scripts/tools/generate_phase8b_market_glb_assets.py`。
- 生成并导入 8B 运行时 GLB：
  - `assets/generated/map3d/models/hd2d_market_reference_match.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_crates.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_barrels.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_tableware.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_ladder.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_hanging_cloth.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_signboard.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_foreground_steps.glb`
- 使用 BlenderMCP 导入当前组合 GLB 并保存第二版源交接文件：
  - `assets/source/map3d/blender/hd2d_market_reference_match.blend`
  - `assets/source/map3d/blender/hd2d_market_reference_match_source_note.md`
- 新增市场参考匹配场景和 profile 控制脚本：
  - `scenes/map3d/hd2d_market_reference_match_lab.tscn`
  - `scripts/map3d/hd2d_market_reference_match_lab.gd`
- 新增 profile 验证脚本：`scripts/autotest/test_hd2d_market_reference_match_lab.gd`。
- 场景会在运行时禁用 `hd2d_market_plaza.glb` 子树中的导入灯光，默认最终 profile 只保留 3 盏真实局部光。
- `hd2d_market_reference_match_lab.tscn` 已接入 `hd2d_market_reference_match.glb`；上一轮 primitive 资产组保留为隐藏 fallback。
- 第二轮程序 GLB 细化：
  - 降低并前移前景低墙/台阶，减少 final 截图底部黑带压迫感。
  - 增加背墙木框、后排窗光、右侧外置梯子、二层布料、红/青布棚对比。
  - 增加 crate / barrel / jar / plate / cloth 等摊位小物件数量。
  - 调整 `reference_match_v2` 环境和真实暖光，让中央暖光池更可读，同时降低雾厚度。
- 第三轮高梯修正：
  - 把 `RightVisibleHighLadder*` 从右侧暗屋檐边缘移动到右摊位旁的受光墙面前方。
  - 增加 `ladder_highlight` 材质，提高高梯在 final / no_post 截图中的可读性。
  - 自动验收改为检查 `RightVisibleHighLadder` 和 `RightBalconyShelf`，避免“任意 Ladder 节点存在但截图不可读”。
- 生成截图矩阵：
  - `output/market_reference_match/market-baseline-1280x720.png`
  - `output/market_reference_match/market-asset-density-v2-1280x720.png`
  - `output/market_reference_match/market-reference-match-v2-1280x720.png`
  - `output/market_reference_match/market-no-local-light-1280x720.png`
  - `output/market_reference_match/market-no-patch-1280x720.png`
  - `output/market_reference_match/market-no-post-1280x720.png`
  - `output/market_reference_match/market-character-scale-check-1280x720.png`

本轮未完成项 / 后续增强项：

- 当前 `.blend` 是 BlenderMCP 导入程序化低模 GLB 后保存的源交接文件，不是最终手工美术精修版。
- 最终截图已经有冷暗边缘、中央暖光池、更多摊位小物件和背墙层次，但距离参考图的建筑复杂度、街道纵深、二层结构和真实市集质感仍是“部分通过”。
- 后续若继续追求参考图级复刻，应在 `hd2d_market_reference_match.blend` 上做手工美术细化，再导出替换当前程序化 GLB。

BlenderMCP / 资产链路卡点：

| 项目 | 结果 | 说明 | 下一步 |
|---|---|---|---|
| BlenderMCP 源文件生成 | 通过 | 已用 `execute_blender_code` 导入 `hd2d_market_reference_match.glb` 并保存 `hd2d_market_reference_match.blend`，对象数 59 | 后续在该 `.blend` 上做手工结构和小物件细化 |
| BlenderMCP 手工建模复杂度 | 部分 | 本轮主要证明源资产链路和运行时表现，未做高复杂度手工模型 | 下一轮补右侧建筑体量、二层平台、檐口、门窗和摊位杂物 |
| 本机 Blender CLI | 失败 | 未在 PATH 和常见安装目录发现 `blender.exe` | 安装或提供 Blender 路径 |
| 程序化 GLB 生成方案 | 通过 | 使用 `generate_phase8b_market_glb_assets.py` 生成无运行时灯光的 `.glb` 组合场景和 prop 模块，并接入 lab | 可作为后续 Blender 源细化前的稳定基线 |

Profile 状态表：

| Profile | 可见真实局部光数量 | LightPatches 可见 | Glow | Fog | DOF | 备注 |
|---|---:|---|---|---|---|---|
| `baseline_market` | 3 | 否 | 是 | 是 | 是 | 隐藏新增资产，保留偏暖基线 |
| `asset_density_v2` | 3 | 否 | 是 | 是 | 是 | 显示新增 GLB 资产，不靠 patch |
| `reference_match_v2` | 3 | 是 | 是 | 是 | 是 | 当前最终候选；已降低前景黑带、增强中心暖光并让右侧高梯可读 |
| `no_local_light` | 0 | 否 | 是 | 是 | 是 | 冷暗环境保留，中央真实暖光消失 |
| `no_patch` | 3 | 否 | 是 | 是 | 是 | 真实暖光池和墙地 falloff 仍可读 |
| `no_post` | 3 | 是 | 否 | 否 | 否 | 未提高 exposure / ambient 作补偿 |
| `character_scale_check` | 3 | 是 | 是 | 是 | 是 | 与 final 相同，用于角色比例检查 |

最低资产入镜检查：

| 要求 | 当前结果 | 结论 |
|---|---|---|
| 前景台阶/低墙至少 1 组 | `ForegroundLowWall` / 左右 step 入镜 | 通过 |
| 左右屋檐/立面凸出左右各 1 处 | `LeftFacade` / `RightFacade` 入镜 | 通过 |
| 中央摊位/布棚至少 2 组 | 左右布棚摊位入镜 | 通过 |
| 小物件至少 8 个实例，至少 3 类 | GLB 中箱、桶、罐、盘、布、货架超过 10 个实例 | 通过 |
| 梯子或二层平台至少 1 处 | GLB 中 `RightVisibleHighLadder*` 和 `RightBalconyShelf` 已入镜，final / no_post 下轮廓可读 | 通过 |
| 后排灯笼/窗光壳体至少 4 个 | 6 个以上 glow shell / window glow 入镜 | 通过 |

参考图对比评分表：

| 对比项 | 通过标准 | Baseline | Final | 结论 | 原因 / 下一步 |
|---|---|---|---|---|---|
| 构图框景 | 左右建筑和前景暗部都入镜，中央街区被框住 | 部分 | 部分 | 部分 | 前景黑带已减轻，左右框景成立；右侧高梯已可读，但右侧高楼体量仍不如参考图 |
| 资产密度 | 最低入镜资产数量和类别达标 | 失败 | 部分 | 部分 | 数量达标，且已改为运行时 GLB；第二轮增加了背墙框架和摊位小物件，但仍缺少手工市集细节 |
| 地面尺度 | 中央暖光下砖缝仍可读，不是大色块 | 部分 | 通过 | 通过 | 第二版石板贴图和 `no_post` 下砖缝可读 |
| 墙面层次 | 墙面、屋檐、台阶至少有 3 层明暗关系 | 部分 | 部分 | 部分 | 明暗关系成立，建筑立面仍偏平，需要 BlenderMCP 细化窗框/门框/檐口 |
| 灯光分区 | 冷暗边缘 + 中央暖光池成立，非整屏黄 | 失败 | 通过 | 通过 | final 明显从整屏暖黄改为冷暗包暖光；第二轮中心暖光更可读 |
| 真实光贡献 | `no_local_light` 明显失去墙地暖光 | 未记录 | 通过 | 通过 | `no_local_light` 下中央暖光和墙地 falloff 明显消失 |
| Patch 控制 | `no_patch` 仍保留真实 falloff，final 只增强绘制感 | 未记录 | 部分 | 部分 | `no_patch` 可读，但 final 的空气感仍依赖 patch/DOF，需要更自然的 patch 形状 |
| 后处理控制 | `no_post` 下资产和光照关系仍成立 | 未记录 | 通过 | 通过 | 关闭 Glow/Fog/DOF 后仍能看出光照和材质关系 |
| 角色比例 | 主角高度约占 720p 画面 `10% ~ 14%`，超过 `16%` 失败 | 部分 | 通过 | 通过 | 角色已缩小并保持 unshaded 可读 |

验证命令：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . -s res://scripts/tools/generate_phase8b_market_assets.gd
python scripts/tools/generate_phase8b_market_glb_assets.py
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --import
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_market_reference_match_lab.tscn --quit-after 60
D:\godot\Godot_v4.6.2\godot.exe --headless --path . -s res://scripts/autotest/test_hd2d_market_reference_match_lab.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --quit
```

截图命令：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_match_lab.tscn res://output/market_reference_match/market-reference-match-v2-1280x720.png 1280 720 reference_profile=reference_match_v2
```

验证结果：

- 贴图/材质/patch 生成：通过。
- 程序化 GLB 生成：通过。
- BlenderMCP 源交接 `.blend` 生成：通过，导入当前组合 GLB 后保存 `hd2d_market_reference_match.blend`，对象数 59。
- PNG / GLB / `.blend` import：通过。
- 场景 headless 加载：通过。
- profile / GLB 存在性自动验证：通过，输出 `PASS: hd2d_market_reference_match_lab profiles validated`。
- 项目 headless 加载：通过。
- 截图矩阵：通过，7 张 1280x720 png 已生成并刷新。
- 已知非 8B 噪音：`--import` 期间出现 GodotIQ 端口占用提示和 `Plugin is not attached to debugger`，命令退出码为 0；与本阶段场景无关，未作为 8B 验收失败处理。
- 本轮命令路径为 `D:\godot\Godot_v4.6.2\godot.exe`，实际输出引擎版本为 `Godot Engine v4.7.beta.custom_build.dff2b9bb6`。

是否达到阶段完成标准：是

原因：

- 已明确参考图目标，并生成 baseline / asset density / final / no light / no patch / no post / character scale 截图矩阵。
- 已生成第二版材质、贴图、light patch、运行时 GLB 和 BlenderMCP 源交接 `.blend`。
- 默认 profile 真实局部光为 3 盏，`no_local_light` / `no_patch` / `no_post` 已证明真实光、patch、后处理各自贡献。
- 最终图比当前市场基线更接近参考图的冷暗边缘、中央暖光池、资产密度和右侧高梯轮廓。
- 阶段完成不等于参考图级最终美术完成；建筑/摊位/杂物仍是程序化低模，已作为后续手工美术卡点记录。

下一阶段入口：

- Phase 8B 可收口。
- 若继续提升复刻度，建议另开 Phase 8C / art pass：在 `hd2d_market_reference_match.blend` 上做手工结构细化，重点补右侧高楼体量、前景真实遮挡、摊位杂物密度、墙面檐口层次和更自然的 patch / 远景 glow。
