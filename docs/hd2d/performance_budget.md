# HD-2D Performance Budget

## Default Budget

- Default camera profile:
  - Perspective
  - `FOV 34`
  - Run map target framing from `run_hex_map_3d.gd`
- Default post-processing posture:
  - Glow visible but restrained
  - Fog kept to thin layered planes
  - DOF only as a light depth cue
- Suggested upper bounds per screen:
  - Local lights: `<= 3`
  - Particle emitters/groups: `<= 3`
  - Transparent fog/effect layers: `<= 3`
  - Visible `Sprite3D` / `AnimatedSprite3D`: `<= 12`
  - Glow landmark sources: `<= 3`

## Pressure Result Reference

### Phase 6 Lighting Boundary

Source: `res://scenes/map3d/hd2d_lighting_validation_lab.tscn`

- `1` local light: minimum torch proof.
- `3` local lights: recommended default upper bound for a formal HD-2D map screen.
- `6` local lights: pressure boundary only. Use it to judge overexposure, shadow cost, and downgrade rules, not as a default template.
- Torch pressure behavior: secondary pressure torches keep the light but disable their own shadow in the six-light profile, while the default three torches keep shadows enabled.

Interpretation:

- Keep production screens at or below three local dynamic lights unless a specific map proves it can afford more.
- If a screen needs more than three visible flame props, prefer reducing actual dynamic lights and letting non-key flames use emission/glow only.

### Phase 7 Torch Template Boundary

Source:

- `res://scenes/map3d/vfx/hd2d_torch_effect.tscn`
- `res://scenes/map3d/hd2d_lighting_validation_lab.tscn`
- `res://scenes/map3d/run_hex_map_3d.tscn`

- Validation lab default: `3` Phase 7 torch templates with real `TorchLight`.
- Validation lab pressure profile: `6` templates remains a stress case only.
- Run map sample: scene-placed `VfxRoot/TorchSamples/RunTorch_Key` enables a real `TorchLight`; `RunTorch_Atmosphere` keeps flame/glow only.

Interpretation:

- The reusable torch template is allowed in formal maps.
- Keep real torch lights at `<= 3` per screen.
- Extra visible torches should disable `light_enabled` and rely on emission/glow unless a local scene proves a higher budget.

Source: `output/phase4/hd2d-phase4-pressure-report.json`

- Average FPS: `20.98`
- Minimum FPS: `1.0`
- Character count: `31`
- Tile count: `20`
- Local light count: `8`
- Particle group count: `3`
- Transparent layer count: `5`
- Glow source count: `3`

Interpretation:

- The pressure profile is intentionally beyond the recommended default template budget.
- The default template should stay under the upper bounds above unless a scene proves stable on target hardware.

## Degrade Order

1. Disable or reduce DOF.
2. Reduce Glow strength.
3. Lower torch `OmniLight3D.light_energy`.
4. Disable small torch shadows and keep shadows only on key torches.
5. Merge or reduce local lights.
6. Reduce transparent fog, glow volumes, and particle emitters.
7. Simplify distant/background materials.
