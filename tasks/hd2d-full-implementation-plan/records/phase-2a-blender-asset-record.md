# Phase 2A 执行记录

阶段状态： [x] 已完成
本阶段目标：
- 建立 HD-2D 地图模块的 Blender/GLB 路径规范、材质规则和受光验证流程。
- 在 GLB 尚未落地时，用 Godot 原语回退保证流程和截图验收不中断。

输入资料：
- `tasks/hd2d-full-implementation-plan/phase-2a-blender-map-assets-and-lighting-materials.md`
- `docs/hd2d/material_rules.md`
- `docs/hd2d/world_environment_profiles.md`
- `scenes/map3d/characters/hd2d_character_template.tscn`

本轮完成项：
- 建立目录规范：
  - `assets/source/map3d/blender/README.md`
  - `assets/generated/map3d/models/README.md`
- 新建地图材质资源：
  - `assets/generated/map3d/materials/mat_hd2d_ground.tres`
  - `assets/generated/map3d/materials/mat_hd2d_wall.tres`
  - `assets/generated/map3d/materials/mat_hd2d_foreground.tres`
  - `assets/generated/map3d/materials/mat_hd2d_background.tres`
  - `assets/generated/map3d/materials/mat_hd2d_emission_warm.tres`
  - `assets/generated/map3d/materials/mat_hd2d_emission_cool.tres`
- 新建资产流程文档：`docs/hd2d/map_asset_pipeline.md`
  - 记录 Blender 路径规范
  - 记录 GLB 命名规范
  - 记录导出规则
  - 记录原语回退策略
- 新建受光和阴影验证场景：`scenes/map3d/hd2d_map_asset_light_response_lab.tscn`
  - 当前使用 Godot 原语回退模块：
    - `Hd2dHexTileFallback`
    - `Hd2dWallLowFallback`
    - `Hd2dStairsShortFallback`
    - `Hd2dBridgeShortFallback`
    - `Hd2dForegroundPillarFallback`
    - `Hd2dBackgroundSilhouetteFallback`
    - `LandmarkBattleFallback`
    - `LandmarkShopFallback`
    - `LandmarkRestFallback`
    - `LandmarkEventFallback`
    - `LandmarkBossFallback`
  - 同屏包含主角色、主光、补光、默认环境和发光 landmark。
- 记录当前缺口：
  - `.blend` 源文件尚未实际创建。
  - `.glb` 运行时模型尚未生成。
  - 本阶段通过回退原语完成了验证链路，不把 `.blend` 作为运行时依赖。

本轮未完成项：
- `scripts/autotest/` 目录仍不存在，因此 `test_hd2d_map_asset_paths.gd`、`test_hd2d_material_resources.gd`、`test_hd2d_asset_light_response_scene.gd` 还没有实际补建；本阶段仅保留自动验证建议。

验证命令：
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --scene res://scenes/map3d/hd2d_map_asset_light_response_lab.tscn --quit-after 60`
- `D:\godot\Godot_v4.6.2\godot.exe --headless --path . --quit`
- `C:\Python313\python.exe .codex/skills/godot-headless/scripts/run_capture_scene.py --project-root . --godot D:\godot\Godot_v4.6.2\godot.exe --scene res://scenes/map3d/hd2d_map_asset_light_response_lab.tscn --output res://output/phase2a/hd2d-map-asset-light-response-1280x720.png --width 1280 --height 720`
- `rg -n "\\.blend" scenes assets/generated resources scripts`

验证结果：
- `hd2d_map_asset_light_response_lab.tscn` headless 加载成功，退出码 `0`。
- 项目 `godot --headless --quit` 成功，退出码 `0`。
- 截图 `output/phase2a/hd2d-map-asset-light-response-1280x720.png` 已生成。
- 人工验收结论：
  - 墙体、厚地块、台阶和桥面存在明确体积关系。
  - 发光 landmark 会触发 Glow，但当前强度没有压掉角色主体。
  - Sprite3D 角色与原语地块同屏时没有明显割裂或糊屏。
  - 当前画面仍是回退原语，不代表最终美术质量，但足以支撑后续 GLB 替换和正式地图接入。
- `rg` 未发现运行时场景或资源直接引用 `.blend`。

是否达到阶段完成标准：
是

下一阶段入口：
`tasks/hd2d-full-implementation-plan/phase-3-run-map-hd2d-integration.md`
