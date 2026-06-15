# 资产格式规范

版本：v0.1
日期：2026-06-15

## 目录职责

| 目录 | 用途 |
| --- | --- |
| `assets/generated/` | 当前可运行的生成图片资产 |
| `assets/generated/map3d/` | 3D 地图生成资产、模型导出和材质贴图 |
| `assets/generated/map3d/materials/` | 3D 地图运行时材质 |
| `assets/generated/characters/` | 角色帧动画和 SpriteFrames |
| `assets/ui/themes/` | Theme 资源 |
| `design_img/` | 设计参考图，不直接作为运行时资产 |
| `output/` | 验证输出，默认不进入生产资源 |

## 命名

通用规则：

- 文件名使用 `snake_case`。
- 同类资源保持统一前缀和后缀。
- 批次内保持统一比例和尺寸。

3D 地图资产：

```text
assets/generated/map3d/models/{asset_id}.glb
assets/generated/map3d/textures/{asset_id}_{channel}.png
assets/source/map3d/blender/{asset_id}.blend
```

第一阶段 3D 地图仍以 Godot 原语、`StandardMaterial3D` 和生成材质为主，不要求 Blender 源文件。进入正式 3D 地图后，允许引入 `.blend` 源文件和导出的 `.glb` 运行时模型，但运行时场景不得直接引用 `.blend`。精细地形、小地标或可复用模型制作时，把 Blender 源文件放入 `assets/source/map3d/blender/`，导出的运行时模型放入 `assets/generated/map3d/models/`，对应材质放入 `assets/generated/map3d/materials/`。

### HD2D 角色帧动画和效果实验场

- 透明序列帧源资源可以保留在 `assets/generated/<name>_transparent/`，不要为了重命名移动已导入资源。
- Godot 可播放资源放在 `assets/generated/characters/<character>/`，优先使用 `.spriteframes.tres`。
- 3D 场景角色使用 `AnimatedSprite3D`，角色场景放在 `scenes/map3d/characters/`。
- 第一版 HD2D 角色动画必须至少有一个循环 `stand` 动画。
- 效果实验场放在 `scenes/map3d/hd2d_effect_lab.tscn`，默认使用透视 `Camera3D` 做真实 3D 观察，只用于视觉稳定和调参，不作为正式入口。
- 相机、灯光、材质、mesh、环境和静态 transform 优先写在 `.tscn`；脚本只保留运行时状态、输入响应和必要的调试 API。
- 透明角色默认使用 billboard 面向相机，真实阴影不稳定时使用地面假阴影。
- Headless 截图测试在当前 dummy renderer 下会生成结构化验收图；真实 HD2D 观感仍以窗口运行截图和人工验收为准。

## 尺寸基准

推荐基准：

- 页面背景：1920x1080。
- UI 九宫格：单独存放到 `assets/generated/ui/9slice/`。

具体像素可按美术批次调整，但同一资源类型必须成组一致。

## source / sheet / alpha 文件

当前 `assets/generated/` 中可能存在：

- `*_source.png`
- `*_sheet_source.png`
- `*_sheet_alpha.png`
- `placeholder`

量产规则：

- 被 `.tres` 或 `.tscn` 直接引用的图片是运行时资产。
- `source/sheet/alpha` 是生成来源或切图中间产物，必须保留用途说明，否则迁移到归档目录。
- `placeholder` 只能用于早期阶段；进入量产内容后不能作为最终资源。

## `.import`

Godot 需要的 `.import` 可随运行时图片提交，但不要因为打开编辑器产生大量无关 `.import` 变动就混入业务提交。

规则：

- 新增运行时 PNG 时，允许提交对应 `.import`。
- 删除运行时 PNG 时，同批删除对应 `.import`。
- `output/`、`logs/`、临时截图对应 `.import` 不应进入长期版本管理。

## 资源引用

生产数据资源优先通过 `.tres` 字段保存路径。

脚本硬编码图片路径仅用于：

- 页面固定背景。
- 节点固定图标。
- 过渡期 UI。

硬编码路径新增后，必须在对应文档或资源规范中登记。
