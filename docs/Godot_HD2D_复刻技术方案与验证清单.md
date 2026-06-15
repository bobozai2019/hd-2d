# Godot 复刻 HD-2D 效果技术方案与验证清单

> 适用范围：Godot 桌面 / 本地版本优先。  
> 本文不绑定具体游戏类型，不讨论 Web 平台兼容。  
> 目标：把 HD-2D 的核心视觉结构、Godot 落地路线、提前验证的技术点和实施顺序整合成一份可执行技术文档。

---

# 1. 核心结论

HD-2D 不是“高清像素风”，也不是“普通 2D RPG 加滤镜”。

它的本质是：

```text
低分辨率像素角色
+
有真实空间层次的 3D 微缩舞台
+
现代光照
+
景深、雾、辉光、粒子、调色等后期
```

在 Godot 中，推荐的复刻路线是：

```text
Godot 3D 场景
+
Sprite3D / AnimatedSprite3D 像素角色
+
固定斜俯视 Camera3D
+
WorldEnvironment 后处理
+
局部灯光
+
假阴影
+
前景遮挡
+
粒子氛围
```

最重要的判断：

```text
HD-2D 首先是摄影、舞台和风格控制，不是单一 Shader 技术。
```

不要一开始追求复杂 Shader、体积雾、动态昼夜或大规模地图。  
第一阶段应该先证明：

```text
像素角色能清晰、稳定地放进 3D 场景里，并且画面有 HD-2D 的舞台感。
```

---

# 2. HD-2D 的视觉结构

## 2.1 2D 像素角色进入 3D 舞台

HD-2D 的关键不是把 2D 背景做高清，而是把像素角色放入一个有真实空间感的 3D 场景中。

它通常包含：

```text
真实高度差
真实遮挡关系
真实透视
局部灯光
前景 / 中景 / 远景层次
景深
雾气
辉光
粒子
整体调色
```

所以画面高级感来自：

```text
像素素材的复古感
+
3D 舞台的空间感
+
现代光照和后期的电影感
```

---

# 3. Godot 推荐基础架构

推荐使用 3D 场景作为主舞台。

```text
HD2D_Level.tscn
├── WorldEnvironment
├── CameraRig
│   └── Camera3D
├── Lighting
│   ├── DirectionalLight3D
│   ├── OmniLight3D
│   └── SpotLight3D
├── EnvironmentRoot
│   ├── Ground
│   ├── Walls
│   ├── Stairs
│   ├── Bridges
│   └── Buildings
├── Props
│   ├── Trees
│   ├── Lamps
│   ├── Barrels
│   └── Foliage
├── Characters
│   ├── Player Sprite3D / AnimatedSprite3D
│   ├── NPC Sprite3D / AnimatedSprite3D
│   └── Enemy Sprite3D / AnimatedSprite3D
├── Foreground
│   ├── ForegroundLeaves
│   ├── ForegroundWalls
│   └── FogPlanes
├── VFX
│   ├── GPUParticles3D
│   ├── GlowPlanes
│   └── Sprite3D Effects
└── Collision
    └── StaticBody3D / CharacterBody3D
```

---

# 4. 推荐渲染路线

## 4.1 推荐路线

```text
Renderer: Forward+
Scene: 3D
Characters: Sprite3D / AnimatedSprite3D
Environment: MeshInstance3D + 像素贴图 / 低模贴图
Lighting: DirectionalLight3D + Local Lights
Post Process: WorldEnvironment
```

## 4.2 不推荐一开始使用纯 2D

纯 2D 可以做像素 RPG，但难以自然获得：

```text
真实遮挡
高度差
前后景层次
局部光照
景深
空间雾
微缩模型感
```

如果目标是 HD-2D，3D 舞台是更合理的基础。

---

# 5. 实现优先级

正确顺序：

```text
镜头
>
角色比例
>
场景层次
>
遮挡排序
>
光照
>
像素清晰度
>
后处理
>
粒子
>
Shader
```

错误顺序：

```text
先写复杂 Shader
先做大地图
先堆体积雾
先做完整资源库
先做复杂动态光照
```

HD-2D 的前期成败主要看：

```text
角色是否清晰
场景是否有空间层次
光照是否有主次
镜头是否舒服
前中后景是否成立
后处理是否克制
```

---

# 6. 必须提前验证的技术点总表

| 优先级 | 技术点 | 需要验证的问题 | 为什么重要 | 建议验证方式 | 通过标准 |
|---|---|---|---|---|---|
| P0 | Sprite3D 排序 | 多个 Sprite3D、墙体、前景、特效是否排序稳定 | 2D 精灵放进 3D 后最容易出问题 | 放置多个角色、墙体、前景、透明特效 | 不闪烁、不乱盖、不穿帮 |
| P0 | 3D 遮挡 | 角色是否能被墙、树、桥、建筑正确遮挡 | 没有遮挡就没有空间感 | 让角色在遮挡物前后移动 | 遮挡关系自然稳定 |
| P0 | 像素清晰度 | 角色边缘是否被抗锯齿、后处理、缩放弄糊 | 像素角色一糊就失去 HD-2D 味道 | 测 Nearest、Mipmaps、AA、不同 Pixel Size | 清晰、不抖、不闪 |
| P0 | Billboard 模式 | Sprite3D 是否正确面向镜头，脚底是否贴地 | Billboard 设置错误会有纸片感、漂浮感 | 测 Full Billboard、Y-Billboard、固定朝向 | 角色立在场景里，不像贴屏幕 |
| P0 | 镜头角度 | Perspective / Orthogonal 哪个更适合目标画面 | 镜头决定空间感和读图舒适度 | 同场景做两种镜头对比 | 角色比例舒服，空间层次清楚 |
| P0 | 世界单位比例 | 像素尺寸如何换算到 3D 世界尺寸 | 比例不定会导致后续资源反复返工 | 测 48/64/96/128px 角色 | 角色、建筑、道具比例协调 |
| P1 | 角色受光 | 角色是否使用真实光照 | 影响融合感，也影响像素干净程度 | 测 Unshaded、Shaded、假 Rim Light | 角色清楚且不突兀 |
| P1 | 假阴影 | 角色脚底是否稳定贴地 | Sprite3D 容易漂浮 | 给角色加半透明圆形 ShadowPlane | 角色明显站在地面上 |
| P1 | 后处理强度 | Glow、DOF、Fog 是否过度 | 后处理过强会糊屏 | 测无/轻/中/强四档 | 有氛围但不损失清晰度 |
| P1 | 景深 | 前景和远景虚化是否自然 | 景深是微缩模型感的重要来源 | 测 Near Blur / Far Blur | 画面有层次但主体清晰 |
| P1 | Glow | 发光物是否过曝 | Glow 是 HD-2D 氛围来源，但容易廉价 | 测火把、窗户、魔法、特效 | 发光明显但不糊 |
| P1 | 雾 | 雾是否增强空气感 | 雾负责拉开层次 | 测全局雾、局部雾 Plane、粒子雾 | 有空气感，不遮挡主体 |
| P1 | 前景遮挡 | 前景树叶、墙体、雾是否服务画面 | 前景能增强深度，也可能干扰主体 | 放置前景叶片、墙角、雾层 | 有层次但不抢戏 |
| P1 | 材质风格 | 像素贴图和真实光照是否割裂 | 场景如果太现代会和角色不搭 | 测像素贴图、低模材质、轻 Normal | 风格统一 |
| P1 | 地面 Mipmap | 斜视地面是否闪烁 | 3D 斜视像素贴图容易摩尔纹 | 测 Mipmaps On / Off | 镜头移动时稳定 |
| P1 | 粒子融合 | 粒子是否增加氛围但不抢戏 | 粒子让场景活起来 | 测灰尘、火星、萤火虫、烟雾 | 有生命感但不混乱 |
| P1 | 特效融合 | 2D 像素特效和 3D 光照是否融合 | 技能、火焰、击中特效常混用 2D/3D | 测 Sprite3D 特效、发光材质、粒子 | 爽感强且排序稳定 |
| P1 | 性能压力 | 多角色、多灯光、多粒子是否稳定 | 后期场景复杂后会出现性能风险 | 30 个 Sprite3D、多个灯光和粒子 | 帧率稳定 |
| P2 | 分段光照 Shader | 是否需要像素化光照 | 后期增强角色像素感 | 做 4 档 / 6 档光照 Shader | 更融合且不脏 |
| P2 | LUT 调色 | 是否需要整体色彩统一 | HD-2D 很依赖整体调色 | 测白天、夜晚、洞穴、雪地 LUT | 场景情绪明确 |
| P2 | 体积雾 | 是否需要 Volumetric Fog | 氛围强但调试复杂 | 和普通 Fog / Fog Plane 对比 | 明显提升才保留 |
| P2 | 动态灯光 | 技能或事件时是否临时加光源 | 可增强戏剧性 | 测动态 OmniLight / SpotLight | 有冲击力但不过曝 |
| P2 | 摄像机演出 | 是否需要推近、震动、短暂压暗 | 可增强表现力 | 测普通攻击、技能、剧情镜头 | 有电影感但不混乱 |
| P2 | 自动导入流程 | 角色、特效、贴图是否能批量规范化 | 后期资源量大时必须标准化 | 制作导入规则和命名规范 | 能批量导入不返工 |

---

# 7. 角色实现方案

## 7.1 推荐节点结构

```text
Character.tscn
├── CharacterBody3D
│   ├── AnimatedSprite3D
│   ├── ShadowPlane
│   ├── CollisionShape3D
│   └── Marker3D / VFXSocket
```

## 7.2 AnimatedSprite3D 建议设置

```text
Texture Filter: Nearest
Alpha: Alpha Scissor / Alpha Cut
Billboard: 优先测试 Y-Billboard 和固定朝向
Pixel Size: 根据世界单位决定
Shaded: 第一阶段建议关闭
Cast Shadow: 谨慎开启，优先用假阴影
```

## 7.3 Billboard 选择

| 模式 | 特点 | 风险 | 建议 |
|---|---|---|---|
| Full Billboard | 永远面向摄像机 | 容易像贴在屏幕上 | 谨慎使用 |
| Y-Billboard | 只绕 Y 轴转向摄像机 | 更自然 | 推荐重点测试 |
| 固定朝向 | 不自动转向 | 需要手动管理方向 | 适合固定镜头或战斗场景 |

---

# 8. 角色受光策略

## 8.1 第一阶段推荐：不强受光

```text
角色主体：Unshaded
角色阴影：假阴影
受击表现：白闪 / 变色 / 边缘光
技能融合：发光特效 / 局部光源照亮场景
```

优点：

```text
像素最清晰
颜色最稳定
资源制作简单
不容易脏
批量角色更容易统一
```

缺点：

```text
角色和场景融合感略弱
真实光源不会直接照亮角色
```

## 8.2 第二阶段再测试受光角色

可以测试：

```text
Shaded Sprite3D
分段光照 Shader
Rim Light Shader
受击白闪 Shader
```

不要第一阶段就把角色受光做成复杂系统。

---

# 9. 假阴影方案

推荐给每个角色脚下加一个 ShadowPlane。

```text
ShadowPlane
├── MeshInstance3D
│   └── PlaneMesh
└── Material
    ├── 黑色半透明圆形贴图
    ├── Alpha Blend
    └── Billboard Off
```

跟随逻辑：

```gdscript
shadow.global_position = Vector3(
    character.global_position.x,
    ground_y + 0.01,
    character.global_position.z
)
```

优点：

```text
稳定
性能好
不会产生奇怪真实阴影
适合像素角色
可以强化角色贴地感
```

---

# 10. 像素清晰度控制

## 10.1 角色贴图导入

```text
Filter: Nearest
Mipmaps: Off
Compression: Lossless
```

## 10.2 场景贴图导入

场景贴图不应该完全一刀切。

建议分情况：

| 类型 | Filter | Mipmaps | 说明 |
|---|---|---|---|
| 角色 | Nearest | Off | 保持像素硬边 |
| UI | Nearest / 视风格 | Off | 保证清晰 |
| 近景像素特效 | Nearest | Off | 保持像素感 |
| 地面贴图 | Nearest | On / Off 都要测 | 斜视地面可能闪烁 |
| 远景贴图 | Nearest 或 Linear | On | 避免远处闪烁 |
| 粒子贴图 | Linear 通常更好 | On / Off 视效果 | 粒子不一定要硬边 |

## 10.3 抗锯齿

需要测试：

```text
No AA
FXAA
TAA
MSAA
```

注意：

```text
TAA 可能让像素角色变糊
FXAA 可能柔化边缘
MSAA 对透明 Sprite3D 帮助有限
```

建议第一阶段：

```text
角色优先保证清晰
场景边缘再考虑抗锯齿
```

---

# 11. 场景搭建方案

## 11.1 场景不是平面地图，而是微缩舞台

场景应该像一个手工搭出来的小剧场：

```text
地面有厚度
墙体有高度
建筑有真实体积
桥和台阶有高低差
前景有遮挡物
远景有轮廓
灯光有方向
```

## 11.2 推荐制作方式

```text
Blender 制作模块化场景
或 Godot 内 MeshInstance3D / GridMap 快速搭建
或 CSG 快速白盒后转 Mesh
```

## 11.3 场景层次

至少应该有：

```text
远景背景层
中远景建筑层
可行走地面层
角色互动层
前景遮挡层
空气层 / 雾层 / 粒子层
```

在 Godot 中对应：

```text
Background Meshes
Midground Meshes
Walkable Meshes
Characters
Foreground Props
Fog / Particles
```

如果场景只有：

```text
地面 + 角色
```

就很难有 HD-2D 感。

---

# 12. 镜头方案

## 12.1 透视镜头

```text
Projection: Perspective
FOV: 35 ~ 45
Rotation X: -45° ~ -60°
```

优点：

```text
空间感强
更有微缩舞台感
前中后景层次明显
```

缺点：

```text
远处物体会变小
角色尺寸会随距离变化
需要控制构图
```

## 12.2 正交镜头

```text
Projection: Orthogonal
Size: 8 ~ 14
Rotation X: -45° ~ -60°
```

优点：

```text
角色大小稳定
画面更可控
更容易控制构图
```

缺点：

```text
透视空间感略弱
电影感稍弱
```

## 12.3 推荐策略

第一阶段建议两种都测。

```text
如果目标偏电影感：优先 Perspective
如果目标偏稳定展示：优先 Orthogonal
如果要兼顾：使用轻透视 Perspective，降低 FOV 变化
```

---

# 13. 光照方案

## 13.1 HD-2D 的光是舞台光，不是写实光

目标不是物理真实，而是：

```text
主体清楚
层次明确
情绪明确
冷暖对比
局部强调
```

## 13.2 基础灯光结构

```text
主光：DirectionalLight3D
环境光：WorldEnvironment Ambient
局部光：OmniLight3D / SpotLight3D
轮廓光：侧后方补光
发光物：Emission 材质 + Glow
```

## 13.3 示例：白天场景

```text
DirectionalLight3D:
  Color: 暖白
  Energy: 1.0 ~ 2.0
  Shadow: On

WorldEnvironment:
  Ambient Color: 淡蓝灰
  Ambient Energy: 0.3 ~ 0.6
  Glow: 轻微
  Fog: 轻微
```

## 13.4 示例：夜晚场景

```text
DirectionalLight3D:
  Color: 深蓝
  Energy: 0.2 ~ 0.5

OmniLight3D:
  Color: 暖橙
  Energy: 1.5 ~ 4.0
  Range: 小范围

WorldEnvironment:
  Ambient: 深蓝
  Glow: 中等
  Fog: 中等
```

## 13.5 示例：洞穴场景

```text
Ambient: 很低
主光：局部火把 / 水晶 / 魔法光
Fog: 中等
Glow: 中等
对比度：偏高
```

---

# 14. 后处理方案

HD-2D 很依赖后处理，但后处理必须克制。

Godot 中主要使用：

```text
WorldEnvironment
├── Glow
├── Fog
├── Volumetric Fog
├── Depth of Field
├── Tonemap
├── Adjustment
└── Color Correction / LUT
```

## 14.1 Glow

适合发光的对象：

```text
火把
灯笼
窗户
水晶
魔法阵
技能特效
阳光边缘
```

不适合：

```text
所有角色边缘
所有白色物体
整个 UI
全屏高亮
```

建议起点：

```text
Glow Enabled: On
Intensity: 0.2 ~ 0.6
Strength: 0.6 ~ 1.2
HDR Threshold: 根据场景调整
```

## 14.2 Fog

雾负责：

```text
拉开层次
隐藏远景细节
制造空气感
让光线更有体积感
```

低成本方案：

```text
半透明雾 Plane
GPUParticles3D 雾粒子
远景 Fog
局部烟雾 Sprite3D
```

不建议一开始重度依赖体积雾。

## 14.3 Depth of Field

景深负责微缩模型感。

建议原则：

```text
主体附近清晰
前景轻微虚化
远景轻微虚化
不要全屏糊
```

起点：

```text
Near Blur Amount: 0.05 ~ 0.15
Far Blur Amount: 0.08 ~ 0.25
Transition: 稍微拉长
```

## 14.4 调色

每类场景建议独立 WorldEnvironment 或 LUT。

| 场景 | 主色 | 辅色 | 情绪 |
|---|---|---|---|
| 白天村庄 | 暖黄 | 草绿 | 安全 |
| 夜晚城镇 | 深蓝 | 暖橙 | 神秘 |
| 雪地 | 蓝白 | 冷紫 | 空旷 |
| 沙漠 | 金黄 | 红棕 | 炎热 |
| 洞穴 | 暗紫 | 火橙 | 危险 |
| Boss 场景 | 黑红 | 金色 | 压迫 |

---

# 15. 材质方案

## 15.1 场景材质

建议使用：

```text
StandardMaterial3D
Albedo: 像素贴图 / 低分辨率贴图
Normal: 轻微
Roughness: 0.6 ~ 1.0
Specular: 0.1 ~ 0.3
Emission: 只给发光物使用
```

不要让材质太塑料。  
不要让所有东西都反光。  
不要让场景比角色更抢戏。

## 15.2 像素贴图 + 真实光照的矛盾

常见问题：

```text
贴图是块状像素
光照是连续渐变
两者可能割裂
```

可选处理：

### 方案 A：接受混合感

最简单，也最接近 HD-2D 的现代感。

### 方案 B：场景光照轻微分段

让光照不要过于丝滑，但会损失高清感。

### 方案 C：只对角色做分段光照

场景保持现代光，角色保持像素感。  
这是比较实用的后期方案。

---

# 16. 透明和排序规则

## 16.1 角色主体优先使用硬边透明

角色贴图建议：

```text
Alpha Scissor / Alpha Cut
避免复杂半透明边缘
避免角色主体使用大面积透明混合
```

优点：

```text
深度排序更稳定
遮挡更自然
更符合像素风硬边
```

## 16.2 特效单独处理

角色主体和特效不要混用同一套透明逻辑。

建议：

```text
角色：Alpha Cut / Depth 稳定
技能特效：Additive / Transparent / 独立排序
粒子：独立材质和渲染优先级
前景雾：单独层级控制
```

## 16.3 必测排序组合

```text
角色 vs 墙体
角色 vs 角色
角色 vs 前景树叶
角色 vs 雾 Plane
角色 vs 粒子
角色 vs 技能特效
透明特效 vs 透明前景
```

---

# 17. 资源规格建议

## 17.1 角色尺寸

推荐起点：

```text
小型角色：48×48
普通角色：64×64
主要角色：96×96
大型敌人：128×128
Boss：192×192+
```

## 17.2 动画帧数

| 动作 | 帧数建议 |
|---|---|
| Idle | 6 ~ 8 |
| Walk | 6 ~ 8 |
| Run | 8 |
| Attack | 6 ~ 10 |
| Hit | 3 ~ 5 |
| Death | 8 ~ 12 |
| Cast | 8 ~ 12 |
| Skill | 12 ~ 24 |

## 17.3 精灵图规格

建议使用严格网格，不依赖不规则间隔。

例如：

```text
单帧内容：64×64
格子尺寸：72×72
安全边距：每边 4px
排列方式：一行动画或规则网格
背景：透明
```

这样 Godot 切图更稳定。

## 17.4 世界单位换算

必须提前定比例。

公式：

```text
角色世界高度 = 角色有效像素高度 × Sprite3D Pixel Size
```

示例：

```text
64px × 0.02 = 1.28 world units
96px × 0.015 = 1.44 world units
```

然后再决定：

```text
角色高度
门的高度
墙的高度
台阶高度
道具尺寸
场景比例
```

---

# 18. 推荐最小验证 Demo

第一阶段不要做完整地图。  
做一个小型 HD-2D 技术场景即可。

## 18.1 Demo 内容

```text
1 个小型 3D 场景
1 块地面
1 面墙
1 个台阶或桥
1 个前景遮挡物
1 个远景背景
2 ~ 3 个 Sprite3D 角色
1 个火把或灯笼
1 个简单技能特效
1 组粒子
1 个固定斜俯视相机
1 套 WorldEnvironment
```

## 18.2 必须测试

```text
角色站立是否清晰
角色移动是否抖动
角色被墙遮挡是否正确
前景遮挡是否自然
火光 Glow 是否好看
景深是否糊主体
雾是否增强层次
粒子是否抢戏
技能特效是否排序稳定
不同镜头角度是否舒服
```

## 18.3 验收标准

```text
静态截图有 HD-2D 舞台感
角色像素边缘清晰
角色和场景比例协调
前中后景层次明显
光照有主次和情绪
后处理不糊屏
透明排序没有明显问题
```

---

# 19. 推荐开发阶段

## 阶段 1：技术 Spike

目标：证明技术路线成立。

内容：

```text
Sprite3D 角色
3D 小场景
固定镜头
基础光照
假阴影
前景遮挡
轻雾
轻 Glow
轻景深
简单粒子
透明排序测试
```

不做：

```text
复杂 Shader
完整关卡
大量角色
复杂战斗
动态昼夜
体积雾
高级 LUT
```

---

## 阶段 2：视觉原型

目标：形成稳定的 HD-2D 视觉模板。

内容：

```text
确定镜头参数
确定角色 Pixel Size
确定导入规则
确定假阴影规格
确定光照模板
确定后处理模板
确定场景材质风格
确定角色和特效排序规则
```

输出：

```text
HD2D_Level_Template.tscn
HD2D_Character_Template.tscn
HD2D_WorldEnvironment_Default.tres
HD2D_Import_Rules.md
HD2D_Visual_Guideline.md
```

---

## 阶段 3：资源规范化

目标：让角色、场景、特效可以批量生产。

内容：

```text
角色尺寸规范
动画帧数规范
Sprite Sheet 规格
特效规格
命名规则
导入规则
材质规则
场景模块尺寸
```

---

## 阶段 4：表现增强

目标：在基础稳定后增强画面表现。

内容：

```text
分段光照 Shader
Rim Light Shader
受击白闪 Shader
技能动态光
高级 LUT
体积雾
镜头演出
更复杂粒子
```

---

# 20. 常见失败原因

## 20.1 只有像素角色，没有 3D 舞台

结果会像普通 2D RPG，而不是 HD-2D。

## 20.2 场景太平

没有高度差、前景、远景、遮挡和局部光，就没有空间感。

## 20.3 后处理太重

Glow、景深、雾全部开太强，会变成糊屏。

## 20.4 角色太高清

角色边缘太平滑、细节太现代，会失去像素风味。

## 20.5 角色太糊

抗锯齿、TAA、后处理、缩放如果控制不好，会让像素角色失去清晰度。

## 20.6 光照没有主次

所有地方都亮，就没有舞台感。  
HD-2D 需要局部强调和明暗关系。

## 20.7 透明排序没有提前验证

Sprite3D、粒子、前景、特效混在一起后，排序问题会集中爆发。

## 20.8 一开始就做复杂系统

没有先做小型技术验证，就直接做完整场景和资源，很容易返工。

---

# 21. 推荐参数起点

## 21.1 Camera3D

### Perspective 起点

```text
Projection: Perspective
FOV: 40
Rotation X: -50°
Position: 根据场景尺寸调整
```

### Orthogonal 起点

```text
Projection: Orthogonal
Size: 8 ~ 14
Rotation X: -50° ~ -60°
```

## 21.2 DirectionalLight3D

```text
Energy: 1.0 ~ 2.0
Color: 暖白 / 冷白
Shadow: On
```

## 21.3 WorldEnvironment

```text
Ambient Energy: 0.3 ~ 0.6
Glow: On
Fog: Light
DOF: Light
Tonemap: 根据场景调整
```

## 21.4 Sprite3D / AnimatedSprite3D

```text
Texture Filter: Nearest
Pixel Size: 0.015 ~ 0.03 起步测试
Alpha Cut: On
Billboard: Y-Billboard / 固定朝向优先测试
Shaded: 第一阶段 Off
```

---

# 22. 最终实施建议

第一阶段只做一件事：

```text
做一个小型 3D 微缩场景，把 2 ~ 3 个像素角色稳定地放进去。
```

它必须同时验证：

```text
Sprite3D 清晰度
Sprite3D 排序
3D 遮挡
角色比例
假阴影
镜头角度
局部光照
轻雾
轻景深
轻 Glow
粒子氛围
前景遮挡
简单技能特效
```

只要这个 Demo 成功，说明 Godot 复刻 HD-2D 的核心路线成立。  
之后再扩展资源、场景、演出和 Shader。

最终目标不是堆技术，而是形成稳定的视觉公式：

```text
清晰像素角色
+
有空间厚度的 3D 舞台
+
克制但有效的光照
+
轻量景深、雾、辉光和粒子
+
统一调色
=
Godot 中可落地的 HD-2D 效果
```
