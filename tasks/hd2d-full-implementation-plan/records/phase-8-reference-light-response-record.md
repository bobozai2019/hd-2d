# Phase 8 Reference Light Response Record

日期：2026-06-17

## 结论

- 是否新增资产：未新增正式美术资产。仅新增 Phase 8 隔离样例场景、脚本、自动测试、截图和本记录。
- 第一轮“不新增大资产”结论仍成立：地牢式“冷暗环境 + 暖火光池 + 明显 falloff”可以通过现有火把、现有 light patch、局部实验材质和环境参数达成最小验证效果。
- 城镇参考 `docs/hd2d/reference/light_sample.png` 只能部分接近。当前低模墙地样例能验证中央暖光、边缘压暗和石板受光，但缺少城镇参考里的建筑立面细节、台阶/屋檐遮挡和更丰富的地表纹理。
- 角色推荐方案：hybrid。主体保持 `shaded=false` 以保护像素轮廓，再用脚底/侧向暖色辅助层接入火光。纯 `shaded=true` 样例在强对比夜景下变脏、面部读性不足。
- 迁移决策：暂不直接改 `hd2d_effect_lab.tscn` 或 `run_hex_map_3d.tscn`。建议后续把 adjusted profile 的参数公式迁移为候选 profile，再针对正式地图单独截图验收。

## 新增与调整

新增：

- `scenes/map3d/hd2d_reference_light_response_lab.tscn`
- `scripts/map3d/hd2d_reference_light_response_lab.gd`
- `scripts/autotest/test_hd2d_reference_light_response_lab.gd`
- `output/reference_light_response/reference-baseline-1280x720.png`
- `output/reference_light_response/reference-adjusted-1280x720.png`
- `output/reference_light_response/reference-no-local-light-1280x720.png`
- `output/reference_light_response/reference-character-compare-1280x720.png`
- `output/reference_light_response/reference-town-sample-match-1280x720.png`

实验参数：

- 材质使用脚本内 local `StandardMaterial3D`，未回写正式 `.tres`。
- `adjusted` 降低冷色 ambient，弱化月光，提高 key torch 局部能量，开启地面/墙体 warm patch。
- `no_local_light` 关闭全部真实局部光，并隐藏样例 warm patch 与火把模板 wall patch，只保留火焰/halo emission。
- `town_sample_match` 提高基础环境、保留中央暖色空气感和边缘压暗，但没有假装已有资产能复现完整城镇建筑层次。

## 截图对比

| 对比项 | 参考图目标 | Baseline | Adjusted | 结论 |
|---|---|---|---|---|
| 地表受光 | 火把附近暖、远处冷暗 | 有火盆附近亮度，但 ambient 偏平，地面暖光池弱 | 地面中央暖光池明显，远处保持冷暗 | 通过最小验证 |
| 墙体 falloff | 中心亮、边缘渐暗 | 两侧火把墙面较亮，中墙层次不足 | 中央/两侧墙体有暖色衰减，暗部保留 | 通过最小验证，正式地图需更多墙体面片 |
| 角色读性 | 不被火光洗白，边缘清楚 | unshaded 清晰，shaded 偏暗 | hybrid 清晰且有暖色接地，shaded 仍偏脏 | 推荐 hybrid |
| 火把贡献 | 关灯后明显失去暖光 | 未验证关灯 | no-local-light 失去地面/墙体暖光，只剩火焰/halo | 通过 |
| 后处理 | glow 只服务高亮，不糊屏 | 火焰 glow 明显但不铺满画面 | adjusted glow 克制，墙地仍可读 | 通过 |
| 资产需求 | 尽量复用现有资产 | 复用现有火把、角色、light patch | 复用成立，无需第一轮新增大资产 | 不新增正式美术资产 |
| 城镇样例匹配 | 中央暖光、石板受光、建筑明暗面和边缘压暗 | 环境偏地牢，不匹配城镇亮度 | town_sample_match 有中央暖光和边缘压暗，但建筑/纹理信息不足 | 部分通过，城镇正式匹配需要墙地/建筑资产增强 |

## 资产审计

| 分类 | 路径 | 结果 | 后续条件 |
|---|---|---|---|
| 地面材质 | `assets/generated/map3d/materials/mat_hd2d_ground.tres` | 正式资源为 shaded，高 roughness；样例用 local 深色变体 | 若正式地图 falloff 不明显，再加地表纹理或低模边缘 |
| 墙体材质 | `assets/generated/map3d/materials/mat_hd2d_wall.tres` | 正式资源为 shaded，高 roughness；样例用 local 深色变体 | 城镇参考需要更多立面层次或建筑模块 |
| 前景材质 | `assets/generated/map3d/materials/mat_hd2d_foreground.tres` | 可作为暗部遮挡，未新增 | 若正式图黑块吞细节，再分层调亮 |
| 火把模板 | `scenes/map3d/vfx/hd2d_torch_effect.tscn` | 可复用，动态光和 glow 可按 profile 调整 | 火盆轮廓如需更强剪影再微调模板 |
| 光斑贴图 | `assets/generated/hd2d/fire/natural_torch/alpha_wall_light_patch_draft.png` | 可复用为地面/墙面 warm patch | 若正式地图出现贴图形状感，再重做 patch |
| 角色 | `scenes/map3d/characters/engineer_stand_animated_sprite_3d.tscn` | 三档对比完成；hybrid 最稳 | 不改原始帧，优先加场景辅助层 |

## 验证命令

```powershell
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_hd2d_reference_light_response_lab.gd
D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_reference_light_response_lab.tscn --quit-after 60
```

截图使用 `scripts/tools/capture_scene.gd` 分别传入：

```text
reference_profile=baseline
reference_profile=adjusted
reference_profile=no_local_light
reference_profile=character_compare
reference_profile=town_sample_match
```
