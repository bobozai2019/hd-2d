# 3D 六边形地图正式 Run 接入任务包

## 背景

第一阶段 Godot-only 灰盒 MVP 已经完成：`scenes/map3d/hex_map_mvp.tscn`、`scripts/map3d/` 和 `scripts/autotest/test_hex_map_*` 已经提供独立 3D 六边形地图入口、点击、hover、相机移动、HUD 和 headless 验证。

本任务包从第一阶段之后开始，目标是把 3D 六边形地图从“独立实验场景”推进到“可正式承接 Run 地图流程”的生产候选，同时保留当前 2D Run 地图作为回退入口。

## 总目标

一次性执行后，项目应满足：

- 3D Run 地图可以读取当前 `RunManager.current_ctx` 和 `MapSystem` 的正式地图数据。
- 主流程开始 Run、战斗胜利返回、商店/休息/事件完成返回，都能回到同一个地图入口。
- 3D 地图有可替换的 Blender/GLB 资产管线，但在资产缺失时仍能用 Godot 原语运行。
- 2D `scenes/map/map_screen.tscn` 不被删除，作为兼容回退和对照测试保留。
- 新增自动化测试覆盖 3D Run 地图布局、场景加载、节点点击流转、战斗返回路由和 HUD 状态。
- `godot --headless --quit` 与相关地图/Run/3D 地图测试通过。

## 执行文件

按顺序执行以下文件。每个阶段都可以单独验收，但计划设计为一个连续批次：

1. `phase-0-baseline-and-guardrails.md`
   锁定第一阶段现状、确认测试基线、建立回退策略。
2. `phase-2-visual-assets-and-tile-upgrade.md`
   引入可替换的 3D 地图资产结构，升级 tile、连接线、图标和材质。
3. `phase-3-run-data-and-flow-integration.md`
   新建正式 3D Run 地图场景，接入 `MapDef`、`MapSystem`、节点进入与战斗返回。
4. `phase-4-hud-polish-and-player-feedback.md`
   做 Run 级 HUD、节点信息、不可点击反馈、相机/选中体验和视觉一致性。
5. `phase-5-acceptance-and-rollout.md`
   补齐验收、文档、验证矩阵和回滚说明。
## 全局约束

- 不删除或重写第一阶段 MVP 场景；`hex_map_mvp.tscn` 继续作为实验入口。
- 不删除当前 2D 地图；正式接入期间必须保留 `scenes/map/map_screen.tscn` 和其现有测试。
- 不改已有核心逻辑和场景。
- 不把 Blender 作为运行时依赖。`.blend` 只做源文件，运行时只引用 `.glb`、`.tres`、`.png` 或 Godot 原语。
- 不提交 `output/` 截图、临时日志、`.godot/` 缓存。
- 如果工作树已有用户改动，执行者只处理本任务相关文件，不还原无关改动。

## 推荐架构

新增正式 3D 地图，而不是把 MVP 场景直接改成生产入口：

```text
scenes/map3d/hex_map_mvp.tscn          # 第一阶段灰盒，保留
scenes/map3d/run_hex_map_3d.tscn       # 新正式 Run 入口
scenes/map3d/run_hex_map_hud.tscn      # 新 Run HUD

scripts/map3d/hex_tile_3d.gd           # 可复用 tile，增加正式节点数据和状态
scripts/map3d/hex_connection_3d.gd     # 连接线显示
scripts/map3d/run_hex_map_layout.gd    # MapDef -> 3D 位置的纯逻辑
scripts/map3d/run_hex_map_3d.gd        # 正式 3D Run 地图控制器
scripts/map3d/run_hex_map_hud.gd       # Run HUD 控制器
scripts/run/run_map_scene_router.gd    # 统一返回 2D/3D 地图场景路径
```

正式 3D 地图只消费现有 `MapDef`、`MapNodeDef`、`MapState` 和 `MapSystem`，不创建第二套 Run 状态。

## 场景路由策略

新增 `scripts/run/run_map_scene_router.gd` 统一返回地图场景：

- 默认正式入口：`res://scenes/map3d/run_hex_map_3d.tscn`
- 回退入口：`res://scenes/map/map_screen.tscn`
- MVP 实验入口：`res://scenes/map3d/hex_map_mvp.tscn` 只保留在主菜单的实验按钮，不参与 Run 返回。

需要改的硬编码跳转：

- `scripts/main/main.gd`：开始正式 Run 后使用 router 返回的地图场景。
- `scripts/battle/battle_controller.gd`：战斗胜利完成节点后使用 router 返回的地图场景。
- 后续任何新增 Run 返回点都必须使用 router。

## 全局验收标准

- 从主菜单开始正式 Run 后进入 3D Run 地图，而不是 MVP 场景。
- 3D Run 地图节点数量等于当前 act 的 `map_def.nodes.size()`。
- 节点状态与 `MapSystem.get_node_state(node_id)` 一致：locked、available、current、completed。
- 只有 available 节点可进入；locked/completed/current 点击不破坏状态。
- battle/boss 节点能启动战斗，战斗胜利后完成节点并回到 3D Run 地图。
- shop/rest/event 节点能打开对应界面，完成后写回状态并刷新 3D 地图。
- 2D 地图测试仍通过，证明回退入口未被破坏。
- 第一阶段 MVP 测试仍通过，证明实验场景未被正式接入改坏。

## 最小验证命令

每个阶段至少运行该阶段文件中列出的命令。最终必须运行：

```bash
godot --headless --quit
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
godot --headless --script scripts/autotest/test_hex_grid_math.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_scene.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_input.gd
godot --headless --script scripts/autotest/test_hex_map_hud.gd
godot --headless --script scripts/autotest/test_run_loop.gd
godot --headless --script scripts/autotest/test_map_system.gd
godot --headless --script scripts/autotest/test_map_screen.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_layout.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd
godot --headless --script scripts/autotest/validate_project_standards.gd
```

## 完成定义

全部阶段完成时，执行者需要在最终记录中列出：

- 新增/修改的生产文件。
- 新增/修改的测试文件。
- 是否有 Blender 源文件和 `.glb` 运行时模型。
- 默认地图入口是 3D 还是 2D 回退。
- 执行过的验证命令和结果。
- 未解决但不阻断的风险。
