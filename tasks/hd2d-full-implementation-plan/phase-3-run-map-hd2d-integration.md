# 阶段 3：正式 Run 地图 HD-2D 接入

阶段状态： `[x]` 已完成

## 目标

将实验场验证过的 HD-2D 视觉公式迁移到正式 3D Run 地图，让正式地图具备微缩舞台感，同时保持 Run 流程、节点状态、战斗返回和回退入口稳定。

本阶段应和 `tasks/map3d-formal-run-integration/` 协同：如果正式 3D Run 地图尚未完成，先完成其基础接入；如果已完成，则只做 HD-2D 视觉升级。

## 范围

包含：

- 将 HD-2D 相机、灯光、环境、地块材质、前景/背景层次接入正式 3D Run 地图。
- 将角色或地图节点图标按 HD-2D 规则显示。
- 保留 2D 地图回退入口。
- 保持正式 Run 数据流不变。

不包含：

- 不重写 `MapSystem`。
- 不创建第二套 Run 状态。
- 不删除 2D 地图。
- 不把实验场直接当正式地图。

## [x] 任务 3.1：确认正式 Run 地图接入状态

检查：

- 是否存在 `scenes/map3d/run_hex_map_3d.tscn`。
- 是否存在 `scripts/map3d/run_hex_map_3d.gd`。
- 是否存在统一地图路由，如 `scripts/run/run_map_scene_router.gd`。
- 主菜单开始 Run、战斗胜利返回、商店/休息/事件返回是否使用同一个地图入口。

如果正式 3D Run 地图尚未完成，优先执行 `tasks/map3d-formal-run-integration/` 中的阶段 0、2、3、4、5。

## [x] 任务 3.2：建立 Run 地图 HD-2D 场景结构

正式 3D Run 地图建议结构：

```text
RunHexMap3D
├── WorldEnvironment
├── CameraRig
│   └── Camera3D
├── Lighting
├── StageRoot
│   ├── BackgroundLayer
│   ├── TileRoot
│   ├── ConnectionRoot
│   ├── LandmarkRoot
│   ├── ForegroundLayer
│   └── AtmosphereRoot
├── CharacterRoot
├── VfxRoot
└── HudLayer
```

其中：

- `TileRoot` 仍由正式地图数据生成。
- `BackgroundLayer` 和 `ForegroundLayer` 服务构图，不参与 Run 状态。
- `AtmosphereRoot` 放雾、粒子、远景层次。
- `CharacterRoot` 用于玩家纸片角色、NPC 或地图展示角色。

## [x] 任务 3.3：迁移相机和环境模板

从阶段 2 模板迁移：

- 默认透视相机参数。
- 轻雾和轻 DOF。
- 暖主光、冷补光。
- 可见但克制的 Glow。

正式 Run 地图应保留玩家可读性：

- 地图节点必须清楚。
- 可点击节点不能被前景或雾遮住。
- HUD 不受 3D 后处理影响。
- 镜头移动时地块和角色不明显闪烁。

## [x] 任务 3.4：升级地块和节点视觉

地块和节点应从“功能块”升级为“微缩舞台资产”：

- 地块有厚度和材质差异。
- 重要节点有 landmark 或发光提示。
- 路径连接线可读但不抢画面。
- locked、available、current、completed 状态在视觉上可区分。

状态建议：

- `locked`：低饱和、暗、不可点击反馈明确。
- `available`：轻微亮度或边缘提示。
- `current`：脚下/节点中心有聚焦效果。
- `completed`：降低强调但保留路径历史。

## [x] 任务 3.5：接入角色或地图代表物

如果正式 Run 地图需要玩家角色代表物：

- 使用阶段 2 的 HD-2D 角色模板。
- 角色只站在当前节点或路径位置，不影响地图状态。
- 假阴影随地块高度调整。
- 角色与 landmark、前景物保持稳定遮挡。

如果暂时不显示玩家角色：

- 至少使用 HD-2D 风格的节点图标、landmark 和局部光源验证视觉公式。

## [x] 任务 3.6：回归 Run 流程

运行现有或新增测试：

```bash
godot --headless --quit
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
godot --headless --script scripts/autotest/test_run_loop.gd
godot --headless --script scripts/autotest/test_map_system.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_camera.gd
```

不存在的测试不作为本阶段即时失败，但必须记录是否需要由正式 Run 地图任务包补齐。

## 阶段完成标准

- 正式 3D Run 地图拥有 HD-2D 基础舞台感。
- 正式 Run 流程不因视觉升级破坏。
- 2D 地图回退仍保留。
- 实验场参数和正式地图参数的差异有记录。
- 至少有一张正式 Run 地图截图用于人工验收。
