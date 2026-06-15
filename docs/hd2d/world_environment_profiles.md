# HD-2D 环境与后处理 Profile

适用版本：Godot 4.6 项目配置。

## 资源文件

- 默认白天：`res://resources/hd2d/hd2d_world_environment_default.tres`
- 默认 DOF：`res://resources/hd2d/hd2d_camera_attributes_default.tres`
- 夜晚暖灯：`res://resources/hd2d/hd2d_world_environment_night_warm_lights.tres`
- 夜晚 DOF：`res://resources/hd2d/hd2d_camera_attributes_night_warm_lights.tres`
- 洞穴高反差：`res://resources/hd2d/hd2d_world_environment_cave_high_contrast.tres`
- 洞穴 DOF：`res://resources/hd2d/hd2d_camera_attributes_cave_high_contrast.tres`

## Profile 表

| Profile | Ambient 色 / 能量 | Glow | Fog | DOF | Tonemap | 适用场景 |
|---|---|---|---|---|---|---|
| `day_soft` | `Color(0.62, 0.58, 0.52)` / `0.72` | `intensity=0.18`, `strength=0.42` | `Color(0.48, 0.52, 0.58)`, `density=0.006` | `distance=13.0`, `transition=2.8`, `amount=0.06` | `ACES`, `exposure=1.05`, `white=1.4` | 白天村庄、野外、默认实验场 |
| `night_warm_lights` | `Color(0.18, 0.23, 0.34)` / `0.28` | `intensity=0.24`, `strength=0.56` | `Color(0.18, 0.24, 0.33)`, `density=0.01` | `distance=11.0`, `transition=2.4`, `amount=0.08` | `ACES`, `exposure=0.95`, `white=1.35` | 夜晚城镇、灯笼街道 |
| `cave_high_contrast` | `Color(0.08, 0.11, 0.12)` / `0.12` | `intensity=0.20`, `strength=0.62` | `Color(0.11, 0.14, 0.16)`, `density=0.014` | `distance=9.5`, `transition=2.0`, `amount=0.11` | `ACES`, `exposure=0.9`, `white=1.2` | 洞穴、地下、强局部光环境 |

## 使用规则

- `day_soft` 作为默认 profile。
- 正式地图接入前，先复制最接近的 profile，再按地图资源调小范围参数，不要从空白环境开始猜。
- Glow 只服务真实发光源，不用于“补救画面不够亮”。
- Fog 和 DOF 的目标是拉出层次，不是盖掉角色像素边缘。

## 相机建议

- 默认透视：`Perspective`, `fov = 34.0`
- 对照正交：`Orthogonal`, `size = 7.0`
- 相机俯角保持约 `-50°` 到 `-58°`

当前 Phase 1 推荐：

```text
默认验证：Perspective + Unshaded + Y-Billboard
对照镜头：Orthogonal
```
