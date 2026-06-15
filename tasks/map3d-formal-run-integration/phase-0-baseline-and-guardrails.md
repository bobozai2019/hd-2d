# 阶段 0：基线和护栏

## 目标

确认第一阶段 3D 地图 MVP、当前 2D Run 地图和战斗返回流程的实际状态，为后续一次性接入建立测试基线和回退路径。

## 输入文件

需要先阅读：

- `docs/README.md`
- `docs/current/implemented-features.md`
- `docs/production/04-asset-pipeline.md`
- `docs/production/05-validation-matrix.md`
- `scripts/map3d/hex_map_mvp.gd`
- `scripts/map3d/hex_tile_3d.gd`
- `scripts/map3d/hex_map_camera.gd`
- `scripts/map3d/hex_map_hud.gd`
- `scripts/ui/map_screen.gd`
- `scripts/systems/map_system.gd`
- `scripts/battle/battle_controller.gd`
- `scripts/main/main.gd`

## 任务 0.1：记录当前路由硬编码

检查并记录以下路径：

- 主菜单实验入口：`scripts/main/main.gd` 中 `_open_hex_map_mvp()` 应指向 `res://scenes/map3d/hex_map_mvp.tscn`。
- 正式 Run 地图入口：`scripts/main/main.gd` 中当前正式 Run 应指向 `res://scenes/map/map_screen.tscn`。
- 战斗胜利返回：`scripts/battle/battle_controller.gd` 中当前应硬编码返回 `res://scenes/map/map_screen.tscn`。

本阶段不修改这些代码，只把它们作为 Phase 3 的替换点。

## 任务 0.2：运行第一阶段 3D MVP 基线测试

运行：

```bash
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
godot --headless --script scripts/autotest/test_hex_grid_math.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_scene.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_input.gd
godot --headless --script scripts/autotest/test_hex_map_hud.gd
```

预期：

- 每个命令退出码为 0。
- 测试脚本打印 `PASS` 或项目现有通过格式。
- 若有失败，先修复第一阶段回归，再进入 Phase 2。

## 任务 0.3：运行当前 Run/地图基线测试

运行：

```bash
godot --headless --script scripts/autotest/test_run_loop.gd
godot --headless --script scripts/autotest/test_map_system.gd
godot --headless --script scripts/autotest/test_map_screen.gd
godot --headless --script scripts/autotest/test_act_transitions.gd
```

预期：

- 2D 地图现有测试通过。
- `MapSystem` 节点状态流转保持：entry available、enter 后 current、complete 后 completed 并解锁后继。

## 任务 0.4：新增地图场景路由测试先行

在 Phase 3 实现前，先新增失败测试：

- 创建：`scripts/autotest/test_run_map_scene_router.gd`

测试内容：

```gdscript
extends SceneTree

const RouterScript := preload("res://scripts/run/run_map_scene_router.gd")

func _init() -> void:
	var router = RouterScript
	_assert(router.get_run_map_scene_path() == "res://scenes/map3d/run_hex_map_3d.tscn", "default run map scene is 3D")
	_assert(router.get_legacy_map_scene_path() == "res://scenes/map/map_screen.tscn", "legacy map scene path is preserved")
	_assert(router.get_mvp_map_scene_path() == "res://scenes/map3d/hex_map_mvp.tscn", "mvp scene path is preserved")
	print("PASS test_run_map_scene_router")
	quit(0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
```

运行：

```bash
godot --headless --script scripts/autotest/test_run_map_scene_router.gd
```

预期：

- 当前应失败，原因是 `scripts/run/run_map_scene_router.gd` 不存在。
- 该失败是 Phase 3 的第一个实现目标。

## 任务 0.5：建立回退说明

在执行记录中写明：

- 默认目标是 3D Run 地图。
- 若 Phase 3/4 出现阻断，允许把 `RunMapSceneRouter.USE_3D_RUN_MAP` 临时设为 `false` 以回退到 2D 地图。
- 回退不能删除 3D 文件；只切换 router 返回路径。

## 阶段完成标准

- 第一阶段 MVP 测试已通过，或失败项已经被记录并修复。
- 当前 2D Run/地图测试已通过，或失败项已经被记录并修复。
- `test_run_map_scene_router.gd` 已新增并确认在 router 实现前失败。
- 执行者清楚后续要替换的硬编码地图路径位置。
