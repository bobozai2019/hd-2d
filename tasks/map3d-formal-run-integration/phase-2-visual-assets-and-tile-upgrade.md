# 阶段 2：视觉资产和六边格升级

## 目标

在不破坏第一阶段 MVP 的前提下，把 3D 地图资产从纯灰盒提升为可替换的生产候选：材质、tile 模型、节点图标、连接线和选中反馈都走清晰的资源路径。Blender 从本阶段开始参与，但运行时不能依赖 Blender。

## 文件计划

创建：

- `assets/generated/map3d/materials/mat_hex_plain.tres`
- `assets/generated/map3d/materials/mat_hex_available.tres`
- `assets/generated/map3d/materials/mat_hex_hover.tres`
- `assets/generated/map3d/materials/mat_hex_selected.tres`
- `assets/generated/map3d/materials/mat_hex_locked.tres`
- `assets/generated/map3d/materials/mat_hex_completed.tres`
- `assets/generated/map3d/materials/mat_connection_locked.tres`
- `assets/generated/map3d/materials/mat_connection_available.tres`
- `assets/generated/map3d/materials/mat_connection_completed.tres`
- `assets/generated/map3d/models/hex_tile_beveled.glb`
- `assets/generated/map3d/models/landmark_battle.glb`
- `assets/generated/map3d/models/landmark_shop.glb`
- `assets/generated/map3d/models/landmark_rest.glb`
- `assets/generated/map3d/models/landmark_event.glb`
- `assets/generated/map3d/models/landmark_boss.glb`
- `assets/source/map3d/blender/hex_tile_beveled.blend`
- `assets/source/map3d/blender/landmarks_basic.blend`
- `scenes/map3d/hex_connection_3d.tscn`
- `scripts/map3d/hex_connection_3d.gd`
- `scripts/autotest/test_hex_tile_3d_visual_assets.gd`

修改：

- `scenes/map3d/hex_tile_3d.tscn`
- `scripts/map3d/hex_tile_3d.gd`
- `scenes/map3d/hex_map_mvp.tscn`
- `scripts/map3d/hex_map_mvp.gd`

## 任务 2.1：生成材质资源

创建 6 个 tile 状态材质和 3 个连接线材质。建议颜色：

| 资源 | 用途 | 主色 |
| --- | --- | --- |
| `mat_hex_plain.tres` | 普通未激活格 | `Color(0.22, 0.27, 0.25, 1.0)` |
| `mat_hex_available.tres` | 可进入节点 | `Color(0.31, 0.43, 0.30, 1.0)` |
| `mat_hex_hover.tres` | hover | `Color(0.42, 0.50, 0.38, 1.0)` |
| `mat_hex_selected.tres` | selected | `Color(0.82, 0.62, 0.22, 1.0)` |
| `mat_hex_locked.tres` | locked | `Color(0.12, 0.12, 0.14, 1.0)` |
| `mat_hex_completed.tres` | completed | `Color(0.18, 0.32, 0.22, 1.0)` |
| `mat_connection_locked.tres` | 未解锁连接 | `Color(0.18, 0.15, 0.12, 1.0)` |
| `mat_connection_available.tres` | 可通行连接 | `Color(0.72, 0.56, 0.28, 1.0)` |
| `mat_connection_completed.tres` | 已走过连接 | `Color(0.35, 0.70, 0.42, 1.0)` |

每个材质使用 `StandardMaterial3D`：

- `roughness = 0.78`
- `metallic = 0.0`
- hover/selected/available 可以开启轻微 emission，`emission_energy_multiplier` 控制在 `0.15` 到 `0.35`。

## 任务 2.2：制作或导出基础模型

如果 Blender 可用：

- 在 `assets/source/map3d/blender/hex_tile_beveled.blend` 制作带厚度、轻微斜边、原点在底面中心的六边格。
- 在 `assets/source/map3d/blender/landmarks_basic.blend` 制作 5 个低模地标：battle、shop、rest、event、boss。
- 导出 `.glb` 到 `assets/generated/map3d/models/`。

导出规范：

- 单位比例与 Godot 一致，1 Blender unit 对应 1 Godot unit。
- 六边格半径接近 MVP `CylinderMesh.top_radius = 0.95`。
- 六边格高度接近 `0.12` 到 `0.22`。
- 所有模型原点在可摆放中心。
- 法线朝外，无负缩放。
- 运行时引用 `.glb`，不直接引用 `.blend`。

如果 Blender 不可用：

- 保留 Godot `CylinderMesh(radial_segments = 6)` 作为运行时模型。
- 仍创建 `assets/generated/map3d/materials/` 材质资源。
- 在执行记录中写明模型资产暂由 Godot 原语替代，代码和测试仍必须通过。

## 任务 2.3：升级 `HexTile3D` 节点结构

修改 `scenes/map3d/hex_tile_3d.tscn`，推荐结构：

```text
HexTile3D Area3D
├─ Body MeshInstance3D
├─ LandmarkRoot Node3D
│  └─ Landmark MeshInstance3D 或 imported scene instance
├─ IconRoot Node3D
│  └─ Sprite3D
├─ SelectionRing MeshInstance3D
└─ CollisionShape3D
```

要求：

- `Body` 继续作为主地块 mesh。
- `CollisionShape3D` 保持 `CylinderShape3D`，保证 MVP 点击稳定。
- `SelectionRing` 默认隐藏，selected 或 current 状态显示。
- `IconRoot` 可先复用 `assets/generated/map/node_*.png` 作为 `Sprite3D.texture`。
- `LandmarkRoot` 在模型资产存在时启用，缺失时隐藏，不阻断场景加载。

## 任务 2.4：扩展 `hex_tile_3d.gd` 状态

保留第一阶段方法：

- `setup(new_tile_id, new_axial, new_tile_type)`
- `set_neighbors(new_neighbors)`
- `set_hovered(active)`
- `set_selected(active)`
- `set_locked(active)`
- `get_state_label()`

新增正式 Run 可用方法：

```gdscript
func setup_run_node(node_id: StringName, node_type: StringName, axial_coord: Vector2i, state_name: StringName, node_ref: Variant) -> void
func set_node_state(state_name: StringName) -> void
func set_available(active: bool) -> void
func set_completed(active: bool) -> void
func get_node_id() -> StringName
func get_node_type() -> StringName
func get_node_ref() -> Variant
```

状态优先级：

1. selected
2. hover
3. current
4. available
5. completed
6. locked
7. plain

元数据必须包含：

- `tile_id`
- `node_id`
- `axial`
- `tile_type`
- `node_type`
- `state`
- `neighbors`

第一阶段 MVP 调用 `setup()` 后仍应显示 plain/start/edge/event，不要求传 `node_ref`。

## 任务 2.5：新增连接线组件

创建 `scripts/map3d/hex_connection_3d.gd`：

职责：

- 接收 `from_world: Vector3`、`to_world: Vector3`、`state_name: StringName`。
- 生成细长 `BoxMesh` 或 `CylinderMesh` 连接两个 tile。
- 根据 state 使用 locked/available/completed 材质。
- 不参与点击，不创建碰撞。

推荐接口：

```gdscript
extends Node3D

@onready var _body: MeshInstance3D = $Body

func setup(from_world: Vector3, to_world: Vector3, state_name: StringName) -> void:
	# 计算中点、长度和朝向，更新 _body.mesh 与 transform。
	pass

func set_state(state_name: StringName) -> void:
	# 更新 material_override。
	pass
```

连接线 y 值建议固定在 `0.045`，避免与地面 z-fighting，同时低于 tile 顶面选中效果。

## 任务 2.6：补视觉资产测试

创建 `scripts/autotest/test_hex_tile_3d_visual_assets.gd`。

覆盖：

- `scenes/map3d/hex_tile_3d.tscn` 可加载。
- 实例化后存在 `Body`、`CollisionShape3D`、`SelectionRing`。
- 调用 `setup()`、`set_hovered(true)`、`set_selected(true)` 不报错。
- 调用 `setup_run_node()` 后，`get_node_id()`、`get_node_type()`、metadata 正确。
- `scenes/map3d/hex_connection_3d.tscn` 可加载，`setup(Vector3.ZERO, Vector3(2,0,0), &"available")` 不报错。

运行：

```bash
godot --headless --script scripts/autotest/test_hex_tile_3d_visual_assets.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_scene.gd
godot --headless --script scripts/autotest/test_hex_map_mvp_input.gd
```

预期：

- 新测试通过。
- MVP 场景测试仍通过。

## 阶段完成标准

- 材质资源路径固定并被 tile/connection 引用。
- Blender/GLB 资产存在，或 Godot 原语回退明确可运行。
- `hex_tile_3d.gd` 同时兼容 MVP 和正式 Run 节点数据。
- 连接线组件可独立实例化。
- 第一阶段 MVP 测试未回退。
