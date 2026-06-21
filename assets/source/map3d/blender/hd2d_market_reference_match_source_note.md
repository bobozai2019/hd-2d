# HD2D Market Reference Match Source Note

This source entry belongs to Phase 8B and Phase 8C.

## Files

- `hd2d_market_reference_match.blend`
- `hd2d_market_reference_match_artpass.blend`
- Runtime scene: `res://scenes/map3d/hd2d_market_reference_match_lab.tscn`
- Art pass scene: `res://scenes/map3d/hd2d_market_reference_artpass_lab.tscn`
- Runtime GLB: `res://assets/generated/map3d/models/hd2d_market_reference_match.glb`
- Art pass GLB: `res://assets/generated/map3d/models/hd2d_market_reference_match_artpass.glb`
- Generator: `scripts/tools/generate_phase8b_market_glb_assets.py`
- Art pass generator: `scripts/tools/generate_phase8c_market_artpass_glb_assets.py`

## Source Pipeline

The current `.blend` was created through BlenderMCP by importing the generated Phase 8B runtime GLB and saving it as a Blender source file. It is a traceable source handoff for the second market-reference iteration, not a final hand-authored art pass.

The authoritative shape list for this iteration is still the Python generator. The Blender file is useful for visual inspection, later manual refinement, and replacing the procedural low-poly blocks with richer hand-made geometry.

Phase 8C keeps `hd2d_market_reference_match.blend` as the 8B baseline and copies it to `hd2d_market_reference_match_artpass.blend` as the art pass handoff source. The first 8C geometry pass is still generated from `generate_phase8c_market_artpass_glb_assets.py` so the named runtime nodes can be validated in Godot. It adds right tower volume, balcony rails, hanging cloth, three stall clusters, wall trims, window/door frames, foreground steps, and rear lantern shells. This is a controlled batch-art pass source, not a claim that the `.blend` has already received final manual sculpting.

Generated 8C object names intentionally preserve these runtime fragments:

- `RightTowerBalconyRail`
- `RightTowerPlatform`
- `RightVisibleHighLadder`
- `RightHangingCloth`
- `BackLanternShell`
- `ForegroundStep`
- `ForegroundLowWall`
- `StallClusterA`
- `StallClusterB`
- `StallClusterC`
- `WallTrim`
- `WindowFrame`
- `DoorFrame`

Material slot names used by the art pass GLB are `wall_trim`, `ceramic`, `fabric_red`, `fabric_teal`, `shadow_wood`, `emission_lantern`, and `emission_window`. Godot applies stable `.tres` overrides for the non-emissive art pass slots in `hd2d_market_reference_artpass_lab.gd`.

## Runtime Constraints

- Godot runtime does not load `.blend` directly for this lab.
- Runtime models use `.glb`, `.tres`, and `.png`.
- The lab scene disables imported runtime lights under GLB subtrees.
- The default profile keeps visible real local `OmniLight3D` / `SpotLight3D` count at `<= 3`.
- Phase 8C GLBs do not contain runtime lights; lantern/window glow is emissive mesh only.
- Detail sets are exported for local migration and debugging. The art pass lab uses `hd2d_market_reference_match_artpass.glb` as the combined runtime asset.

## Remaining Art Pass

The second iteration proves the asset-density and material-lighting pipeline, but the reference image still needs a later hand-authored pass for:

- deeper right-side building mass and balcony silhouette,
- richer market prop variation,
- less blocky wall/window/eave detail,
- more natural patch and distant glow shapes,
- stronger street depth without increasing real-light count.
