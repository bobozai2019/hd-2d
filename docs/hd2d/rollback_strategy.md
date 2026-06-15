# HD-2D Rollback Strategy

## Stable Entrypoints To Preserve

- Legacy 2D fallback:
  - `res://scenes/map/map_screen.tscn`
- Formal 3D Run map:
  - `res://scenes/map3d/run_hex_map_3d.tscn`
- HD2D experiment lab:
  - `res://scenes/map3d/hd2d_effect_lab.tscn`
- MVP experiment entry:
  - `res://scenes/map3d/hex_map_mvp.tscn`

## Primary Rollback Mechanism

- Change `RunMapSceneRouter.USE_3D_RUN_MAP` to `false`.
- This returns formal Run routing to `res://scenes/map/map_screen.tscn` while preserving the 3D Run files and experiment scenes.

## Rollback Rules

- Do not delete HD-2D assets or scenes during rollback.
- Do not revert unrelated systems.
- Prefer routing/config rollback over scene deletion.
- Keep `hd2d_effect_lab.tscn` available for parameter tuning even if formal Run routing returns to 2D.

## When To Roll Back

- Formal Run map readability drops below legacy 2D fallback.
- Node flow, battle return, or HUD stability regresses.
- Performance budget cannot be met after following the degrade order.
