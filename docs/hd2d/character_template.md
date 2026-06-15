# HD-2D 角色模板

适用版本：Godot 4.6 项目配置。

## 推荐模板

- 模板场景：`res://scenes/map3d/characters/hd2d_character_template.tscn`
- 根节点：`CharacterBody3D`
- 子节点：
  - `FootPoint`
  - `Visual` (`AnimatedSprite3D`)
  - `ShadowPlane` (`MeshInstance3D`)

选择 `CharacterBody3D + AnimatedSprite3D + ShadowPlane` 的原因：

- Phase 1 已经证明角色移动、桥台抬升和假阴影跟随是 P0 必需项。
- 直接用 `AnimatedSprite3D` 做实验场静态展示可以，但作为后续地图/NPC/玩家模板时，`CharacterBody3D` 更适合承载移动、碰撞和脚点对齐。
- 角色脚点和假阴影需要稳定绑定，不再依赖单独场景里手动摆放。

## 默认参数

`Visual` 默认值：

| 项目 | 默认值 | 说明 |
|---|---|---|
| `pixel_size` | `0.0024` | Phase 1 推荐值，960px 角色约为 `2.304` world units 高 |
| `billboard` | `Y-Billboard` (`2`) | 比 Full Billboard 更自然，适合作为默认方案 |
| `texture_filter` | `Nearest` (`1`) | 保持像素边缘 |
| `alpha_cut` | `Alpha Cut` (`1`) | 角色主体优先使用硬边透明 |
| `alpha_scissor_threshold` | `0.02` | 当前工程师角色已验证稳定 |
| `shaded` | `false` | Phase 1 推荐默认关闭，保持主体清晰 |
| `cast_shadow` | `0` | 角色默认不用真实透明阴影 |

`ShadowPlane` 默认值：

| 项目 | 默认值 |
|---|---|
| 相对脚点偏移 | `(0, 0.018, 0.12)` |
| 半径 | `0.62` |
| 深度厚度 | `0.01` |
| 透明度 | `0.32` |

## 比例规则

世界高度计算公式：

```text
世界高度 = 角色像素高度 * pixel_size
```

当前推荐起点：

| 角色尺寸 | 推荐 `pixel_size` | 理论世界高度 |
|---|---|---|
| 48px | `0.0200` | `0.96` |
| 64px | `0.0156` | `0.9984` |
| 96px | `0.0104` | `0.9984` |
| 128px | `0.0078` | `0.9984` |
| 960px 源插画角色 | `0.0024` | `2.304` |

说明：

- 48/64/96/128px 是后续真正像素角色的推导起点。
- 工程师资源当前是高分辨率插画序列帧，仍可沿用同一公式。
- 新角色先按公式摆到目标世界高度，再微调 `pixel_size`，不要先靠相机补救。

## 动画命名

统一使用以下动画名：

- `stand`
- `walk`
- `run`
- `attack`
- `hit`
- `death`

资源缺失时可以只做 `stand`，但命名空间不要改。

## 使用建议

- 玩家、可移动 NPC、正式地图中的交互角色：优先用模板场景。
- 单纯远景点缀或静态立牌：可以直接用 `AnimatedSprite3D`，但要沿用本文默认参数。
- 如果角色必须强受光，先建立单独对照 profile，不要直接覆盖模板默认值。
