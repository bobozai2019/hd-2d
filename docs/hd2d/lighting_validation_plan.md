# HD-2D Lighting Validation Plan

## Current Gap

The previous VFX sample proves that a glow source and one `OmniLight3D` can exist in the scene, but it is not enough to judge the final look. The next validation pass must answer three production questions:

- Torch effect: what parts make a usable torch, which tools produce them, and how far the first implementation should go.
- Lit wall/floor materials: whether masonry and stone floor surfaces respond clearly to local warm light.
- Multi-light behavior: whether several dynamic local lights can coexist without washing out the sprite or breaking the HD-2D mood.

## P0 Target

- `3` dynamic torch lights on screen.
- Each torch contains a holder mesh, flame core, transparent halo, sparks particles, and one warm `OmniLight3D`.
- Torch flame is built from Godot-native mesh, additive material, glow volume, particles, and light nodes. Do not use texture flames, `Sprite3D` flames, or generated `ImageTexture` flames for the default validation template.
- Wall and floor use shaded `StandardMaterial3D`, high roughness, low specular, and no unshaded override.
- Night profile keeps the scene readable: cool moon/key light plus warm local torch gradients.
- Screenshot proof is captured at `1280x720`.

## Tool Choice

Use Godot primitives first:

- Fastest for checking lighting, shadow, glow, and exposure.
- Keeps the test deterministic and scriptable.
- Lets us tune numeric limits before producing final art.

Use Blender after P0:

- Torch bracket, wall blocks, floor modules, and reusable props should become low-poly `.glb` modules.
- Keep simple UVs and small repeatable texture areas.

Use pixel/texture tools after the material response is proven:

- Aseprite, Krita, or Photoshop can produce pixel-style albedo tiles.
- Godot imports them as nearest-filtered textures when the final art pass starts.

## Validation Scene

Scene:

`res://scenes/map3d/hd2d_lighting_validation_lab.tscn`

Script:

`res://scripts/map3d/hd2d_lighting_validation_lab.gd`

Automated check:

`res://scripts/autotest/test_hd2d_lighting_validation_lab.gd`

Supported profiles:

- `lighting_profile=1`: minimum single-torch proof.
- `lighting_profile=3`: recommended default template and production upper bound.
- `lighting_profile=6`: pressure boundary only; do not enable by default in a formal map template.

Screenshot matrix:

- `output/lighting_validation/torch-effect-p0-1280x720.png`: default P0 torch composition.
- `output/lighting_validation/material-light-response-1280x720.png`: shaded wall/floor response under the default three-light setup.
- `output/lighting_validation/dynamic-lights-1-1280x720.png`: minimum single-light comparison.
- `output/lighting_validation/dynamic-lights-3-1280x720.png`: recommended three-light comparison.
- `output/lighting_validation/dynamic-lights-6-pressure-1280x720.png`: pressure comparison only.

## What Good Looks Like

- Torch flame is visible as a small animated source, not a large flat decal.
- The halo reads as warmth around the torch, not as a screen-space blob.
- Wall blocks show a warm falloff near torches and a cooler tone away from them.
- The floor catches light gradients without becoming glossy.
- Three dynamic torches remain the default upper bound. More lights should be treated as a stress case.

## Phase 6 Result

- Torch approach: accepted for P0. Use Godot-native primitive holder meshes, additive flame meshes, additive glow volumes, restrained `GPUParticles3D` sparks, and one warm `OmniLight3D` per torch.
- Material approach: accepted. Walls, floors, grooves, and blocks stay on shaded `StandardMaterial3D` with high roughness and low specular.
- Dynamic-light limit: `3` local lights is the default upper bound. `6` local lights remains a pressure profile for downgrade decisions and should not be copied into the default Run map template.
- Formal map carry-forward: the three-light profile, shaded wall/floor materials, and native torch effect structure can enter the next Run-map template pass. Extra pressure torches and the six-light profile stay in the validation lab.

## Phase 7 Result

- Reusable template: accepted. Use `res://scenes/map3d/vfx/hd2d_torch_effect.tscn` and `res://scripts/map3d/vfx/hd2d_torch_effect.gd` as the default native 3D torch template.
- Editor posture: the template scene owns its visible prop, flame, glow, sparks, and light nodes. The script only binds existing nodes, applies exported values, and drives flicker.
- Template contents: primitive prop layers, natural pixel sprite-sheet flame layers, sprite glow, restrained sparks, and one optional warm `TorchLight`.
- Natural flame assets: generated under `res://assets/generated/hd2d/fire/natural_torch/`, with separate sheets for outer flame, middle flame, core flame, top wisp, ember sparks, torch glow, and wall light patch.
- Validation lab: `torch_variant=phase6|phase7` can switch the same scene and camera between `VfxRoot/Torches` and `VfxRoot/Phase7Torches`.
- Run map carry-forward: small formal-map samples are placed in the scene under `VfxRoot/TorchSamples`; only key torches should enable real dynamic lights.
- Comparison result: Phase 7 is closer to the reference image than Phase 6 because the fire bowl/cup silhouette is clearer and the effect is reusable. Low-poly `.glb` torch props remain a later art pass, not a blocker.

## Extra Follow-Up Worth Testing

- Sprite readability under torch light: compare unshaded sprite, shaded sprite, and rim-lit sprite.
- Shadow softness: decide whether torch shadows should be real shadows, fake blob shadows, or disabled for smaller props.
- Exposure and Glow presets: tune night scenes separately from daylight scenes.
- Occluder readability: test whether foreground pillars remain readable when a torch sits behind them.
- Torch art pass: replace primitive cup/bracket with low-poly `.glb` only after the current template budget and comparison workflow stay stable.
