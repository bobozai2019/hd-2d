# 阶段 5：验收、文档和发布切换

## 目标

完成最终回归、文档同步、验证矩阵更新和可回滚发布说明，让 3D Run 地图可以作为正式地图入口交付。

## 文件计划

修改：

- `docs/current/implemented-features.md`
- `docs/current/code-reference-audit.md`
- `docs/production/04-asset-pipeline.md`
- `docs/production/05-validation-matrix.md`
- `docs/PRD/prd-run-map-system.md`

检查：

- `tasks/map3d-formal-run-integration/README.md`
- `tasks/map3d-formal-run-integration/phase-*.md`

## 任务 5.1：更新当前实现文档

修改 `docs/current/implemented-features.md`：

- 把“独立 3D 六边形地图 MVP 灰盒入口”更新为“独立 MVP 入口保留，正式 Run 地图可通过 3D Run Map 入口承接”。
- 在 Run、地图和战斗外节点段落中补充 3D Run 地图的代码入口：
  - `scenes/map3d/run_hex_map_3d.tscn`
  - `scripts/map3d/run_hex_map_3d.gd`
  - `scripts/map3d/run_hex_map_layout.gd`
  - `scripts/run/run_map_scene_router.gd`

修改 `docs/current/code-reference-audit.md`：

- 记录正式 Run 地图入口由 `RunMapSceneRouter.get_run_map_scene_path()` 决定。
- 记录 legacy 2D 地图仍存在且可回退。
- 记录 `hex_map_mvp.tscn` 是实验入口，不是正式 Run 地图入口。

## 任务 5.2：更新资产规范

修改 `docs/production/04-asset-pipeline.md`：

- 保留第一阶段 Godot 原语说明。
- 新增第二阶段资产说明：
  - `.blend` 源文件放 `assets/source/map3d/blender/`。
  - `.glb` 运行时模型放 `assets/generated/map3d/models/`。
  - `StandardMaterial3D` 材质放 `assets/generated/map3d/materials/`。
  - 运行时场景不得直接引用 `.blend`。
  - 模型缺失时允许 Godot 原语回退，但正式验收记录必须说明资产状态。

## 任务 5.3：更新验证矩阵

修改 `docs/production/05-validation-matrix.md`：

在“修改范围与验证”中保留 MVP 行，并新增正式 3D Run 地图行：

```text
3D Run 地图正式接入 | test_run_map_scene_router.gd、test_run_hex_map_3d_layout.gd、test_run_hex_map_3d_scene.gd、test_run_hex_map_3d_flow.gd、test_run_hex_map_3d_hud.gd、test_run_hex_map_3d_camera.gd、test_run_loop.gd、test_map_system.gd
```

在推荐批量验证中新增：

```bash
godot --headless --script scripts/autotest/test_run_map_scene_router.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_layout.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_hud.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_camera.gd
```

## 任务 5.4：更新 Run 地图 PRD

修改 `docs/PRD/prd-run-map-system.md`：

- 增加“3D 地图表现层”章节。
- 明确产品行为仍以 `MapSystem`、`MapDef`、`MapNodeDef` 为准。
- 明确 3D 地图是表现层替换，不改变节点解锁、节点进入、奖励、战斗启动规则。
- 新增验收标准：
  - 3D 地图节点状态与 2D 地图一致。
  - 战斗胜利返回 3D 地图后，当前节点 completed，后继 available。
  - 回退到 2D 地图后，同一个 RunState 能继续显示正确状态。

## 任务 5.5：最终自动化验证

运行完整命令：

```bash
godot --headless --quit
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
godot --headless --script scripts/autotest/test_hex_grid_math.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_scene.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_input.gd
godot --headless --script scripts/autotest/test_hex_map_hud.gd
godot --headless --script scripts/autotest/test_run_map_scene_router.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_layout.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_hud.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_camera.gd
godot --headless --script scripts/autotest/test_run_loop.gd
godot --headless --script scripts/autotest/test_map_system.gd
godot --headless --script scripts/autotest/test_map_screen.gd
godot --headless --script scripts/autotest/test_act_transitions.gd
godot --headless --script scripts/autotest/validate_project_standards.gd
```

通过标准：

- 所有命令退出码为 0。
- 测试脚本打印 `PASS` 或现有通过格式。
- `validate_project_standards.gd` 不出现新增 `ERROR`。

## 任务 5.6：手动验收流程

在 Godot 编辑器或正常运行窗口中验收：

1. 进入主菜单。
2. 点击第一阶段 3D MVP 入口，确认仍进入 `3D Hex Map MVP`，可返回主菜单。
3. 开始正式 Run，确认进入 `3D Run Map`。
4. hover 一个 available 节点，HUD 显示 hover 信息。
5. 点击 locked 节点，HUD 显示不可进入原因，Run 状态不变。
6. 点击 available battle 节点，确认 selected 状态明显。
7. 点击 Enter，进入战斗。
8. 赢得战斗或使用测试路径触发胜利，确认返回 3D Run 地图。
9. 返回后确认刚完成节点为 completed，后继节点 available。
10. 进入 shop/rest/event 节点，完成后确认回到 3D Run 地图并刷新状态。
11. 把 `RunMapSceneRouter.USE_3D_RUN_MAP` 改为 `false` 做一次本地回退检查，确认正式 Run 可进入 2D 地图。
12. 回退检查后把 `USE_3D_RUN_MAP` 恢复为 `true`。

## 任务 5.7：发布切换和回滚说明

最终记录中必须写清：

- 默认：`RunMapSceneRouter.USE_3D_RUN_MAP = true`。
- 回滚：把 `USE_3D_RUN_MAP` 改为 `false`，正式 Run 会回到 `res://scenes/map/map_screen.tscn`。
- MVP 实验入口不受影响。
- 回滚不需要删除任何 3D 场景、脚本或资产。

## 阶段完成标准

- 当前实现、资产规范、验证矩阵、Run 地图 PRD 已同步。
- 自动化验证全部通过。
- 手动验收流程完成并记录。
- 3D 地图默认承接正式 Run，2D 地图可一行配置回退。
