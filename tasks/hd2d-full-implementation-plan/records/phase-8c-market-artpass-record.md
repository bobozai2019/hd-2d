# Phase 8C 执行记录

阶段状态：[x] 已完成

本阶段目标：

- 在 8B 市集参考匹配实验链路上继续做 art pass。
- 补右侧二层体量、梯子/挂布、三组摊位视觉簇、墙面 detail、前景真实遮挡和后排灯光壳体。
- 给用户一个可直接打开并看到 8C 成果的非隐藏入口场景。

输入资料：

- `tasks/hd2d-full-implementation-plan/phase-8c-market-art-pass-and-scene-integration.md`
- `docs/hd2d/reference/light_sample.png`
- `output/market_reference_match/market-reference-match-v2-1280x720.png`
- `assets/source/map3d/blender/hd2d_market_reference_match.blend`

本轮完成项：

- 新增 8C 资产生成脚本：
  - `scripts/tools/generate_phase8c_market_artpass_assets.gd`
  - `scripts/tools/generate_phase8c_market_artpass_glb_assets.py`
- 新增 art pass Blender 源交接文件：
  - `assets/source/map3d/blender/hd2d_market_reference_match_artpass.blend`
- 更新源资产说明：
  - `assets/source/map3d/blender/hd2d_market_reference_match_source_note.md`
- 新增 art pass 运行时 GLB：
  - `assets/generated/map3d/models/hd2d_market_reference_match_artpass.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_wall_detail_set.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_stall_detail_set.glb`
  - `assets/generated/map3d/models/hd2d_market_prop_right_tower_set.glb`
- 新增 art pass 材质：
  - `assets/generated/map3d/materials/mat_hd2d_market_artpass_wall_trim.tres`
  - `assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_ceramic.tres`
  - `assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_fabric_red.tres`
  - `assets/generated/map3d/materials/mat_hd2d_market_artpass_prop_fabric_teal.tres`
  - `assets/generated/map3d/materials/mat_hd2d_market_artpass_shadow_wood.tres`
- 新增更自然的 light patch：
  - `assets/generated/hd2d/light_patches/alpha_market_artpass_center_pool.png`
  - `assets/generated/hd2d/light_patches/alpha_market_artpass_stall_bounce.png`
  - `assets/generated/hd2d/light_patches/alpha_market_artpass_back_lantern_haze.png`
  - `assets/generated/hd2d/light_patches/alpha_market_artpass_foreground_vignette.png`
- 新增 8C art pass lab：
  - `scenes/map3d/hd2d_market_reference_artpass_lab.tscn`
  - `scripts/map3d/hd2d_market_reference_artpass_lab.gd`
- 新增非隐藏用户入口候选场景：
  - `scenes/map3d/hd2d_market_artpass_candidate.tscn`
- 新增自动验证脚本：
  - `scripts/autotest/test_hd2d_market_reference_artpass_lab.gd`

8C 优先级和 8B 取舍：

| 项目 | 处理 |
|---|---|
| 右侧体量 | 8C 优先补强；新增 `RightTowerPlatform`、`RightTowerBalconyRail*`、`RightVisibleHighLadder*`、`RightHangingCloth*` |
| 摊位密度 | 8C 优先补强；新增 `StallClusterA/B/C` 三组视觉簇和盘罐货架 |
| 墙面层次 | 8C 补 `WallTrim`、`WindowFrame`、`DoorFrame`、后排檐口暗边 |
| 前景遮挡 | 保留 8B 前景关系，叠加真实 step / low wall / corner stone，减少纯黑遮罩感 |
| Patch 自然度 | 新增低强度噪声 patch；`no_patch` 下仍保留真实光照关系 |
| 主场景入口 | 不改正式 Run；新增非隐藏候选入口 `hd2d_market_artpass_candidate.tscn` |
| 8B 保留 | 保留 8B lab、截图和 GLB；8C lab 以 8B lab 为基线子场景叠加 art pass |
| 8B 重做 | 不覆盖 8B GLB；新增 8C art pass GLB 和 detail sets |

材质接线方式：

- GLB 中固定材质槽：`wall_trim`、`ceramic`、`fabric_red`、`fabric_teal`、`shadow_wood`、`emission_lantern`、`emission_window`。
- Godot 使用 `hd2d_market_reference_artpass_lab.gd` 在运行时遍历 art pass GLB 的 `MeshInstance3D`，按 surface material name 对前 5 个非发光槽执行 `set_surface_override_material()`。
- `emission_lantern` / `emission_window` 保留 GLB 嵌入发光材质，作为后排灯点壳体，不增加真实动态光。
- 自动测试验证 `material_override_count >= 12`；本轮没有把 `.tres` 只生成但不接入。

Profile 状态表：

| Profile | 真实局部光 | Artpass patch | Glow | Fog | DOF | 说明 |
|---|---:|---|---|---|---|---|
| `baseline_8b_final` | 3 | 否 | 是 | 是 | 是 | 8B `reference_match_v2` 基线，隐藏 8C overlay |
| `asset_artpass_only` | 3 | 否 | 否 | 否 | 否 | 8C GLB + 材质，不靠 patch/post |
| `artpass_reference_v1` | 3 | 是 | 是 | 是 | 是 | 8C 默认最终候选 |
| `no_local_light` | 0 | 是 | 是 | 是 | 是 | 真实局部光关闭，暖光 falloff 明显丢失 |
| `no_patch` | 3 | 否 | 是 | 是 | 是 | 真实光照仍成立，patch 不是唯一光源 |
| `no_post` | 3 | 是 | 否 | 否 | 否 | 资产、材质、真实光关系仍可读 |
| `character_scale_check` | 3 | 是 | 是 | 是 | 是 | 与 final 同机位，角色高度约 10%~13% |

最低资产入镜检查：

| 命名片段 | 结果 |
|---|---|
| `RightTowerBalconyRail` | 通过，右侧二层栏杆入镜 |
| `RightTowerPlatform` | 通过，右侧二层平台入镜 |
| `RightVisibleHighLadder` | 通过，右侧高梯成为视觉锚点 |
| `RightHangingCloth` | 通过，红/青挂布入镜 |
| `BackLanternShell` | 通过，后排 6 个以上小亮点入镜 |
| `ForegroundStep` / `ForegroundLowWall` | 通过，前景真实台阶/低墙入镜 |
| `StallClusterA/B/C` | 通过，三组摊位视觉簇入镜 |
| `WallTrim` / `WindowFrame` / `DoorFrame` | 通过，墙面不再只有大色块 |

参考图评分表：

| 项目 | 结论 | 原因 / 下一步 |
|---|---|---|
| 右侧建筑体量 | 通过 | 右侧高楼、二层平台、梯子、挂布在 final 和迁移入口中可读；仍可在 8D 继续手工细化立面厚度 |
| 市集密度 | 通过 | 三组摊位、货架、盘罐和布料形成视觉簇；物件仍偏低模 |
| 墙面层次 | 通过 | 后墙木梁、窗框、门框、檐口暗边增加层次 |
| 前景遮挡 | 通过 | 使用 step / low wall / corner stone 替代纯黑遮罩；前景暗部仍偏规整 |
| Patch 自然度 | 部分 | patch 已降强度且拆分；仍能看到实验性横向构图，不是参考图级空气透视 |
| 灯光层级 | 通过 | 中央暖光、摊位小灯、后排灯壳体层级成立；真实局部光保持 3 盏 |
| 主场景入口 | 通过 | 新增非隐藏入口 `scenes/map3d/hd2d_market_artpass_candidate.tscn`，用户打开即可看到 8C 成果 |

通过项数量：6 项通过，1 项部分。右侧建筑体量、市集密度、主场景入口均不失败。

主场景迁移记录：

- 本阶段没有修改正式 Run 地图，也没有替换 `hd2d_market_plaza_lighting_lab.tscn` 的既有内容。
- 原因：8C 仍保留实验 wrapper 和程序化批量 art pass，适合作为候选样张；直接塞回 market lighting lab 会把实验 overlay 和 8B 基线耦合进已有场景。
- 用户可打开路径：`res://scenes/map3d/hd2d_market_artpass_candidate.tscn`。
- `main_scene_migration` 截图使用该候选入口替代 `hd2d_market_plaza_lighting_lab.tscn`：
  - `output/market_reference_artpass/market-artpass-main-scene-migration-1280x720.png`
- 因未触碰正式 Run 地图，本阶段不要求节点点击、战斗返回、商店/休息/事件返回回归。

截图矩阵：

- `output/market_reference_artpass/market-8b-final-1280x720.png`
- `output/market_reference_artpass/market-artpass-asset-only-1280x720.png`
- `output/market_reference_artpass/market-artpass-reference-v1-1280x720.png`
- `output/market_reference_artpass/market-artpass-no-local-light-1280x720.png`
- `output/market_reference_artpass/market-artpass-no-patch-1280x720.png`
- `output/market_reference_artpass/market-artpass-no-post-1280x720.png`
- `output/market_reference_artpass/market-artpass-main-scene-migration-1280x720.png`
- `output/market_reference_artpass/market-artpass-character-scale-1280x720.png`
- 并排对比：`output/market_reference_artpass/market-artpass-side-by-side-comparison.png`

截图刷新时间：2026-06-21 22:47 ~ 22:48，本地时区 Asia/Shanghai。

截图命令：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn res://output/market_reference_artpass/market-8b-final-1280x720.png 1280 720 reference_profile=baseline_8b_final
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn res://output/market_reference_artpass/market-artpass-asset-only-1280x720.png 1280 720 reference_profile=asset_artpass_only
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn res://output/market_reference_artpass/market-artpass-reference-v1-1280x720.png 1280 720 reference_profile=artpass_reference_v1
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn res://output/market_reference_artpass/market-artpass-no-local-light-1280x720.png 1280 720 reference_profile=no_local_light
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn res://output/market_reference_artpass/market-artpass-no-patch-1280x720.png 1280 720 reference_profile=no_patch
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn res://output/market_reference_artpass/market-artpass-no-post-1280x720.png 1280 720 reference_profile=no_post
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn res://output/market_reference_artpass/market-artpass-character-scale-1280x720.png 1280 720 reference_profile=character_scale_check
D:\godot\Godot_v4.6.2\godot.exe --path . --quiet --no-header --single-window --windowed --position 32000,32000 --resolution 1280x720 -s res://scripts/tools/capture_scene.gd -- res://scenes/map3d/hd2d_market_artpass_candidate.tscn res://output/market_reference_artpass/market-artpass-main-scene-migration-1280x720.png 1280 720
```

验证命令：

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . -s res://scripts/tools/generate_phase8c_market_artpass_assets.gd
python scripts/tools/generate_phase8c_market_artpass_glb_assets.py
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --import
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn --quit-after 60
D:\godot\Godot_v4.6.2\godot.exe --headless --path . -s res://scripts/autotest/test_hd2d_market_reference_artpass_lab.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . -s res://scripts/autotest/test_hd2d_market_reference_match_lab.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_market_artpass_candidate.tscn --quit-after 60
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --quit
```

验证结果：

- 8C 材质 / patch 生成：通过。
- 8C GLB 生成：通过。
- Import：通过，退出码 0；GodotIQ 端口占用和 debugger attachment 仍是既有环境噪音。
- Art pass lab headless 加载：通过。
- Art pass 自动测试：通过，输出 `PASS: hd2d_market_reference_artpass_lab profiles validated`。
- 截图矩阵：通过，8 张 1280x720 PNG 已生成。
- 并排对比：通过，包含参考图、8B final、8C final、8C 用户入口。
- 使用命令路径：`D:\godot\Godot_v4.6.2\godot.exe`。
- 实际输出引擎版本：`Godot Engine v4.7.beta.custom_build.dff2b9bb6`。这不是 4.6.x，但本阶段使用的 Node3D、MeshInstance3D、StandardMaterial3D、GLB import、WorldEnvironment profile 和 screenshot capture 行为未触及已知 4.6/4.7 差异；结论可用于本阶段样张判断。

是否达到“可作为正式 HD-2D 市集方向样张”：是。

仍未攻克的差距：

- 建筑仍是程序化低模体块，不是手工雕刻的商业级建筑。
- 参考图的街道纵深、局部遮挡和空气透视还更丰富；8C 当前更像横向舞台式市集。
- 右侧高楼锚点已成立，但立面厚度、窗洞、屋檐和楼梯结构可以在 Phase 8D 手工 `.blend` pass 中继续提升。

下一步判断：

- 若目标是正式地图迁移，下一步应把 `hd2d_market_artpass_candidate.tscn` 的成熟子集迁移回 `hd2d_market_plaza_lighting_lab.tscn`，并清理 wrapper 依赖。
- 若目标是参考图级画面，建议进入 Phase 8D：在 `hd2d_market_reference_match_artpass.blend` 上做真正手工建模和机位重构。
