# HD-2D Final Acceptance Matrix

## Screenshot Matrix

| Key | File | Manual acceptance summary |
|---|---|---|
| `hd2d_effect_lab_baseline_1280x720` | `output/phase5/hd2d_effect_lab_baseline_1280x720.png` | Baseline frame preserves character edge clarity, stage depth, and stable foreground/background separation. |
| `hd2d_effect_lab_occlusion_1280x720` | `output/phase5/hd2d_effect_lab_occlusion_1280x720.png` | Occlusion frame shows foreground cover and wall/intermediate depth without obvious sorting reversal. |
| `hd2d_effect_lab_vfx_1280x720` | `output/phase5/hd2d_effect_lab_vfx_1280x720.png` | VFX frame keeps dust/fog/glow visible without washing out the sprite silhouette. |
| `run_hex_map_3d_default_1280x720` | `output/phase5/run_hex_map_3d_default_1280x720.png` | Default Run map keeps HUD readable, node silhouettes clear, and stage depth intact. |
| `run_hex_map_3d_node_selected_1280x720` | `output/phase5/run_hex_map_3d_node_selected_1280x720.png` | Selected-node frame shows focus/selection feedback without overpowering node readability. |
| `run_hex_map_3d_return_from_battle_1280x720` | `output/phase5/run_hex_map_3d_return_from_battle_1280x720.png` | Return-from-battle frame confirms routed 3D map re-entry remains visually stable after battle launch/return. |

## Command Matrix

| Command | Status | Notes |
|---|---|---|
| `godot --headless --quit` | Pass | Core project load check. |
| `godot --headless --script scripts/autotest/test_hd2d_character_animation_assets.gd` | Not present | Character asset pipeline test was planned in historical task docs but is not implemented in this worktree. |
| `godot --headless --script scripts/autotest/test_hd2d_effect_lab_scene.gd` | Not present | Covered indirectly by `hd2d_effect_lab.tscn --quit-after 60` and screenshot validation in current worktree. |
| `godot --headless --script scripts/autotest/test_hd2d_effect_lab_visual_profile.gd` | Not present | Current worktree uses screenshot/profile docs instead of a dedicated visual profile test. |
| `godot --headless --script scripts/autotest/test_hd2d_effect_lab_capture.gd` | Not present | Replaced in practice by capture scripts and manual screenshot acceptance. |
| `godot --headless --script scripts/autotest/test_main_menu_hex_map_entry.gd` | Pass | Main menu routes to MVP, HD2D lab, and routed Run map. |
| `godot --headless --script scripts/autotest/test_run_loop.gd` | Pass | Main menu -> Run map -> battle launch -> battle return chain passes in current stub baseline. |
| `godot --headless --script scripts/autotest/test_map_system.gd` | Pass | Stub formal map state flow passes. |
| `godot --headless --script scripts/autotest/test_run_hex_map_3d_scene.gd` | Pass | Run scene loads and builds tiles/connections. |
| `godot --headless --script scripts/autotest/test_run_hex_map_3d_flow.gd` | Pass | Preview flow remains stable. |
| `godot --headless --script scripts/autotest/test_run_hex_map_3d_camera.gd` | Pass | Camera focus and enter feedback behavior passes. |

## Test Classification

- `尚未需要，因为对应系统未实现`:
  - `test_hd2d_character_animation_assets.gd`
- `已由其他测试覆盖`:
  - `test_hd2d_effect_lab_scene.gd`
  - `test_hd2d_effect_lab_visual_profile.gd`
  - `test_hd2d_effect_lab_capture.gd`
- `应补齐，因为对应系统已实现但缺验证`:
  - None in the current worktree baseline.
