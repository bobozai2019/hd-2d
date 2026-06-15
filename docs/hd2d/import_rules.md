# HD-2D 贴图导入规则

适用版本：Godot 4.6 项目配置。

## 规则表

| 类型 | Filter | Mipmaps | Compression | 说明 |
|---|---|---|---|---|
| 角色序列帧 | `Nearest` | `Off` | `Lossless` | 保持硬边和透明稳定 |
| 近景像素特效 | `Nearest` | `Off` | `Lossless` | 保持像素感，避免发光边缘发糊 |
| 地面像素贴图 | `Nearest` 为默认，必要时和 `Linear` 对照 | `On/Off` 都测 | `Lossless` 或 `VRAM` | 斜视地面优先看远处是否闪烁 |
| 远景贴图 | `Linear` 或 `Nearest` 对照 | `On` | `VRAM` | 优先减少远处闪烁 |
| 粒子贴图 | `Linear` 通常优先 | `On/Off` 视效果 | `VRAM` | 粒子不强制保留硬边 |
| UI | 按 UI 需求 | `Off` | `Lossless` | 不混入 3D 后处理判断 |

## 操作原则

- 新资源导入后先按上表设置，不要每次从默认 import 配置开始。
- 角色、近景特效、UI 三类资源默认不参加 mipmaps。
- 远景和粒子类资源优先观察远处闪烁，再决定是否允许 `Linear`。
- Phase 1 已确认角色主体默认更适合 `Unshaded + Y-Billboard`，因此角色贴图导入规则首先服务“清晰”和“稳定”，不是服务写实受光。

## 验收方法

- 在 `hd2d_effect_lab.tscn` 中做 A/B 对照。
- 检查静止和移动两种情况。
- 只要出现边缘抖动、透明噪点或远处闪烁，就把当前导入设置记录为不通过。
