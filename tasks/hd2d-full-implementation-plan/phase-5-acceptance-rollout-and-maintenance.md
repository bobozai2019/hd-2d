# 阶段 5：验收、发布和维护

阶段状态： `[x]` 已完成

## 目标

将 HD-2D 实验、模板、正式地图接入和表现增强整理为可长期维护的生产标准。完成后，后续新增角色、地图、节点资产和特效时，都能沿用同一套验证流程。

## 范围

包含：

- 最终截图验收。
- 自动验证命令整理。
- 性能预算整理。
- 回滚策略。
- 资源制作规范归档。
- 后续任务拆分建议。

不包含：

- 不继续新增视觉功能。
- 不在验收阶段临时大改视觉方向。
- 不删除历史任务包。

## [x] 任务 5.1：最终截图矩阵

固定生成并人工检查以下截图：

```text
hd2d_effect_lab_baseline_1280x720
hd2d_effect_lab_occlusion_1280x720
hd2d_effect_lab_vfx_1280x720
run_hex_map_3d_default_1280x720
run_hex_map_3d_node_selected_1280x720
run_hex_map_3d_return_from_battle_1280x720
```

每张截图记录：

- 角色清晰度。
- 地图可读性。
- 前中后景层次。
- 光照主次。
- 雾/DOF/Glow 是否过度。
- 是否存在明显排序问题。

截图文件保留在本地 `output/`，不提交。

## [x] 任务 5.2：整理最终验证命令

最终至少运行：

```bash
godot --headless --quit
godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd
godot --headless --script scripts/autotest/test_hd2d_effect_lab_capture.gd
godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd
godot --headless --script scripts/autotest/test_run_loop.gd
godot --headless --script scripts/autotest/test_map_system.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd
godot --headless --script scripts/autotest/test_run_hex_map_3d_camera.gd
```

不存在的测试应在验收记录中明确分类：

- 尚未需要，因为对应系统未实现。
- 应补齐，因为对应系统已实现但缺验证。
- 已由其他测试覆盖。

## [x] 任务 5.3：整理性能预算

记录默认上限：

- 默认相机 profile。
- 默认 Glow/Fog/DOF 强度。
- 每屏建议最大局部灯数量。
- 每屏建议最大粒子发射器数量。
- 每屏建议最大透明雾层数量。
- 每屏建议最大可见 Sprite3D/AnimatedSprite3D 数量。

若压力测试发现瓶颈，记录降级策略：

- 关闭或降低 DOF。
- 降低 Glow 强度。
- 合并或减少局部光。
- 减少透明雾和粒子。
- 远景资源使用更简单材质。

## [x] 任务 5.4：整理回滚策略

回滚策略必须保留：

- 2D Run 地图入口。
- 3D Run 地图功能入口。
- HD2D 实验场入口。

如果正式地图视觉改造出现阻断：

- 不删除 HD-2D 资源。
- 不还原无关系统。
- 优先通过地图路由或配置回退到稳定地图入口。
- 保留实验场继续调参。

## [x] 任务 5.5：归档制作规范

最终文档应至少包含：

- `docs/hd2d/character_template.md`
- `docs/hd2d/import_rules.md`
- `docs/hd2d/material_rules.md`
- `docs/hd2d/world_environment_profiles.md`
- `docs/hd2d/visual_acceptance_checklist.md`

如果项目已有生产文档目录，也可以同步更新：

- `docs/production/04-asset-pipeline.md`
- `docs/production/05-validation-matrix.md`

但不要只更新生产文档而缺少 HD-2D 专用说明。

## [x] 任务 5.6：拆分后续增强任务

验收后，把未进入默认模板的增强项拆成独立后续任务：

- 分段光照 Shader。
- Rim Light Shader。
- 受击白闪 Shader。
- 高级 LUT。
- 体积雾。
- 更复杂技能特效。
- 剧情镜头演出。
- 批量资源导入工具。

每个后续任务必须有明确触发条件：只有当基础视觉模板稳定、正式地图流程通过、性能预算允许时才进入。

## 阶段完成标准

- 最终截图矩阵已人工验收。
- 自动验证命令和结果已记录。
- 性能预算和降级策略已记录。
- 回滚策略明确可执行。
- HD-2D 制作规范已经归档。
- 后续增强任务已拆分，不混入当前基础实现收尾。
