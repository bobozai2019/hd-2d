# Phase 3 执行记录

阶段状态： [x] 已完成
本阶段目标：
- 把实验场验证过的 HD-2D 视觉公式迁移到正式 3D Run 地图骨架。
- 在当前仓库缺少正式 Run 数据流实现的前提下，先完成可加载、可截图、可验证的 scene/router/layout/HUD 基础层。

输入资料：
- `tasks/hd2d-full-implementation-plan/phase-3-run-map-hd2d-integration.md`
- `tasks/map3d-formal-run-integration/README.md`
- `tasks/map3d-formal-run-integration/phase-3-run-data-and-flow-integration.md`
- `tasks/map3d-formal-run-integration/phase-4-hud-polish-and-player-feedback.md`
- `tasks/map3d-formal-run-integration/phase-5-acceptance-and-rollout.md`

本轮完成项：
- 确认当前正式 Run 地图基线缺口：
  - 不存在 `scripts/systems/` 等 formal Run 数据流脚本
- 新建路由脚本：`scripts/run/run_map_scene_router.gd`
- 新建布局脚本：`scripts/map3d/run_hex_map_layout.gd`
- 新建 HUD 脚本和场景：
  - `scripts/map3d/run_hex_map_hud.gd`
  - `scenes/map3d/run_hex_map_hud.tscn`
- 新建正式 3D Run 地图骨架：
  - `scripts/map3d/run_hex_map_3d.gd`
  - `scenes/map3d/run_hex_map_3d.tscn`
- 正式 3D Run 地图骨架已包含：
  - `WorldEnvironment`
  - `CameraRig/Camera3D`
  - `Lighting`
  - `StageRoot/BackgroundLayer`
  - `StageRoot/TileRoot`
  - `StageRoot/ConnectionRoot`
  - `StageRoot/LandmarkRoot`
  - `StageRoot/ForegroundLayer`
  - `StageRoot/AtmosphereRoot`
  - `CharacterRoot`
  - `VfxRoot`
  - `HudLayer/RunHexMapHud`
  - `HudLayer/SubScreenHost`
- 在当前没有 `RunManager.current_ctx` / `MapSystem` / `MapDef` 的情况下，控制器先使用 preview fallback：
  - 生成 7 个 preview 节点
  - 生成连接线
  - 生成当前节点角色代表物
  - 用 HUD 显示 `No active run context - preview fallback active`
- 新建自动测试：
  - `scripts/autotest/test_run_map_scene_router.gd`
  - `scripts/autotest/test_run_hex_map_3d_layout.gd`
  - `scripts/autotest/test_run_hex_map_3d_scene.gd`
- 补充 preview 交互与 HUD 测试：
  - `scripts/autotest/test_run_hex_map_3d_hud.gd`
  - `scripts/autotest/test_run_hex_map_3d_preview_flow.gd`
- 扩展 preview fallback 体验：
  - HUD 空状态文案改为 `Hover: -` / `Selected: -`
  - available / locked 节点的 Enter 按钮启用状态可自动切换
  - 进入 available preview 节点会触发相机聚焦
  - 相机默认目标和聚焦目标会被 preview 地图 bounds clamp
  - scene controller 暴露 `debug_select_node()`、`debug_get_message()`、`debug_get_selected_state()`、`debug_is_enter_enabled()`、`debug_get_camera_target()` 供测试使用
- 继续强化 `任务 3.4` 的节点状态差异：
  - `available` 节点增加暖色发光环 accent
  - `completed` 节点增加历史标记柱体 accent
  - `locked` 节点增加暗色顶帽 accent
  - 更新后的 preview 截图仍保持地块厚度、连接线、landmark、角色代表物和状态差异同屏可读
- 补充正式 Run 预览验证测试：
  - `scripts/autotest/test_run_hex_map_3d_flow.gd`
  - `scripts/autotest/test_run_hex_map_3d_camera.gd`
- scene controller 继续暴露测试钩子：
  - `debug_get_camera_fov()`
  - `debug_focus_node()`
- 补建 legacy 2D 回退入口最小骨架：
  - `scenes/map/map_screen.tscn`
  - `scripts/ui/map_screen.gd`
  - `scripts/autotest/test_map_screen.gd`
- legacy 2D 回退入口当前可加载，并能显示 fallback 状态与 3D Run 路由目标
- 补建主菜单与 MVP 实验入口最小骨架：
  - `scenes/main/main.tscn`
  - `scripts/main/main.gd`
  - `scenes/map3d/hex_map_mvp.tscn`
  - `scripts/map3d/hex_map_mvp.gd`
  - `scripts/autotest/test_main_menu_hex_map_entry.gd`
- 主菜单骨架当前支持三条入口：
  - `Start Run` -> `RunMapSceneRouter.get_run_map_scene_path()`
  - `Hex Map MVP` -> `res://scenes/map3d/hex_map_mvp.tscn`
  - `HD2D Effect Lab` -> `res://scenes/map3d/hd2d_effect_lab.tscn`
- 补建战斗胜利返回最小骨架：
  - `scripts/battle/battle_controller.gd`
  - `scripts/autotest/test_battle_controller_map_return.gd`
- battle controller 当前已通过 router 返回正式 Run 地图路径
- 生成正式 3D Run 地图预览截图：
  - `output/phase3/run-hex-map-3d-preview-1280x720.png`

本轮未完成项：
- 当前 formal Run 数据链仍是当前工作树内的最小 stub baseline：
  - `scripts/run/run_manager.gd`
  - `scripts/systems/map_system.gd`
  - `scripts/battle/battle_launch_config.gd`
- shop/rest/event/battle/boss 的流程回写已能在当前 stub baseline 下通过 focused 测试，但后续若接入真实产品态数据模型，仍需继续对齐 upstream 行为。

验证命令：
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/run_hex_map_3d.tscn --quit-after 60`
- `C:\Python313\python.exe .codex/skills/godot-headless/scripts/run_capture_scene.py --project-root . --godot D:\godot\Godot_v4.6.2\godot.exe --scene res://scenes/map3d/run_hex_map_3d.tscn --output res://output/phase3/run-hex-map-3d-preview-1280x720.png --width 1280 --height 720`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_map_scene_router.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_layout.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_scene.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_hud.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_preview_flow.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_flow.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_camera.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_map_screen.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_main_menu_hex_map_entry.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_battle_controller_map_return.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_map_system.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_loop.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --script scripts/autotest/test_run_hex_map_3d_formal_ctx.gd`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --quit`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/main/main.tscn --quit-after 60`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hex_map_mvp.tscn --quit-after 60`

验证结果：
- `run_hex_map_3d.tscn` headless 加载成功，退出码 `0`。
- `test_run_map_scene_router.gd` 通过。
- `test_run_hex_map_3d_layout.gd` 通过。
- `test_run_hex_map_3d_scene.gd` 通过。
- `test_run_hex_map_3d_hud.gd` 通过。
- `test_run_hex_map_3d_preview_flow.gd` 通过。
- `test_run_hex_map_3d_flow.gd` 通过。
- `test_run_hex_map_3d_camera.gd` 通过。
- `test_map_screen.gd` 通过。
- `test_main_menu_hex_map_entry.gd` 通过。
- `test_battle_controller_map_return.gd` 通过。
- `test_map_system.gd` 通过。
- `test_run_loop.gd` 通过。
- `test_run_hex_map_3d_formal_ctx.gd` 通过。
- `godot --headless --quit` 通过，退出码 `0`。
- `main.tscn` headless 加载成功，退出码 `0`。
- `hex_map_mvp.tscn` headless 加载成功，退出码 `0`。
- `run-hex-map-3d-preview-1280x720.png` 已生成。
- 人工验收结论：
  - 正式 Run 地图骨架已经有基础舞台感。
  - 角色、前景、背景、连接线、节点 landmark、雾层和 HUD 已同屏成立。
  - preview 版 HUD 已能解释 hover / selected / reward / camera 状态，并能对 locked / available 节点给出不同反馈。
  - available / current / completed / locked 四种节点状态已可通过材质、accent 和聚焦提示区分。
  - `map_screen.tscn` 已能作为 legacy 2D fallback 入口存在于当前工作树，不再只是 router 中的路径占位。
  - `main.tscn` 和 `hex_map_mvp.tscn` 已在当前工作树中恢复为可加载入口，不再只是 formal task 文档中的缺失项。
  - `battle_controller.gd` 已能把战斗胜利返回路径统一收束到 `RunMapSceneRouter`，不再缺少这一层最小承接点。
  - `run_hex_map_3d.gd` 现已支持双模：无 ctx 时走 preview fallback，有 `RunManager.current_ctx` 时走最小 formal stub 数据链。
  - 当前 formal flow 仍是仓库内的最小 stub baseline，而不是外部 upstream 产品分支，但对本工作树来说已满足 Phase 3 的接入与回归要求。

是否达到阶段完成标准：
是

下一阶段入口：
`tasks/hd2d-full-implementation-plan/phase-4-vfx-atmosphere-and-camera-performance.md`
