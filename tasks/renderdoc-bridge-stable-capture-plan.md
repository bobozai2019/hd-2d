# RenderDoc Bridge Stable Capture Plan

## Goal

Build a Godot editor plugin workflow that lets the user launch this project through a project-specific RenderDoc entrypoint, then click editor buttons to produce RenderDoc `.rdc` captures for both:

- the current Godot editor 3D view
- the debug game launched from the editor

The final user workflow should be:

1. Enable/configure the plugin once.
2. Use the generated project RenderDoc entrypoint to open Godot.
3. Click `Editor RDC` to capture the current editor 3D view.
4. Click Play, then click `Game RDC` to capture the selected debug game session.

## Key Findings

- A normal `EditorPlugin` or GDExtension loads too late to guarantee RenderDoc has hooked the editor's already-created D3D12 rendering device.
- `LoadLibrary("renderdoc.dll")` is not enough to claim stable editor capture. It may expose `RENDERDOC_GetAPI`, but it does not prove early graphics API hook success.
- `StartFrameCapture(nullptr, nullptr)` is not stable enough for editor 3D view capture because the editor may contain multiple windows, devices, or viewports. The target must be constrained.
- Debug game capture is more tractable because the game process is launched after the plugin can configure RenderDoc child-process injection.

## Supported V1 Scope

- Platform: Windows only.
- Rendering backend: current project D3D12 setup.
- Stable launch path: the generated project RenderDoc entrypoint only.
- Ordinary Godot shortcuts remain supported for normal editing, but they must show `Editor RDC` as unavailable or unverified.

## Implementation Plan

### Bootstrap Launch

- Add a project-specific startup entrypoint under `tools/` or `tasks/renderdoc_bridge/`.
- Prefer RenderDoc's official launch/injection mechanism to start Godot with this project path.
- The startup entrypoint must pass:
  - Godot executable absolute path
  - `--path`
  - project root absolute path
- The plugin should generate or refresh a local `Start Godot RenderDoc.cmd` file and expose a `Regenerate Entry` button.
- The plugin may provide a `Restart Into RenderDoc Mode` button for first-time setup.

### Plugin State Model

Track these states independently:

- `launched_by_bridge`
- `renderdoc_api_available`
- `hook_children_enabled`
- `editor_capture_verified`
- `active_debug_sessions`
- `game_runtime_ready`

Only `editor_capture_verified` allows `Editor RDC` to show as ready.

Only `hook_children_enabled`, one selected debug session, and `game_runtime_ready` allow `Game RDC` to show as ready.

### Native Wrapper

Extend `RenderDocWrapper` with diagnostic APIs:

- `try_load_from_path(path: String) -> bool`
- `get_load_source() -> String`
- `get_last_error() -> String`
- `configure_child_injection(enabled: bool) -> bool`
- `capture_frame(path_template: String, window_handle: int = 0) -> Dictionary`

The returned capture dictionary should include:

- `ok`
- `path`
- `error`
- `api_version`
- `load_source`

The wrapper must not report late `LoadLibrary` as stable early injection.

### Editor RDC

- The plugin must identify the current editor 3D view target before capture.
- Avoid final implementation based on wildcard `StartFrameCapture(nullptr, nullptr)`.
- Use a constrained target, preferably:
  - `SetActiveWindow(device_or_null, hwnd)`
  - then `StartFrameCapture(device_or_null, hwnd)`
- If the plugin cannot resolve a reliable editor window handle, disable `Editor RDC` and show a clear status message.
- Run a smoke capture after RenderDoc-mode launch. Mark `editor_capture_verified=true` only after a real `.rdc` is generated successfully.

### Game RDC

- Register an editor-side `EditorDebuggerPlugin`.
- Register a debug-game runtime autoload, for example `RenderDocBridgeRuntime`.
- The editor sends capture requests through `EditorDebuggerSession.send_message()`.
- The game runtime receives messages through `EngineDebugger.register_message_capture("renderdoc_bridge", ...)`.
- The game process performs its own RenderDoc capture internally.
- The game runtime must check `ClassDB.class_exists("RenderDocWrapper")` and report a clear error if the GDExtension is unavailable.
- Multiple debug sessions require explicit session selection. Do not silently capture the first session.

## UI Plan

Add two toolbar buttons:

- `Editor RDC`
- `Game RDC`

Add a bottom panel showing:

- RenderDoc DLL path/source
- API version
- launch mode
- hook children status
- editor capture verification status
- active debug sessions
- selected debug session
- last editor capture path
- last game capture path
- last error

Use clear wording:

- `Ready: launched through RenderDoc project entry`
- `Not ready: ordinary Godot launch`
- `Not ready: editor capture target not resolved`
- `Stop and Play again: child hook was enabled after this game started`

## Verification

Automated checks:

```powershell
godot --headless --quit
scons platform=windows target=editor dev_build=no
```

Manual acceptance:

1. Launch Godot through the generated RenderDoc project entrypoint.
2. Confirm the panel shows:
   - `launched_by_bridge=true`
   - `renderdoc_api_available=true`
   - `hook_children_enabled=true`
   - `editor_capture_verified=true`
3. Click `Editor RDC`.
4. Confirm a valid `.rdc` appears under `captures/renderdoc/editor/`.
5. Click Play.
6. Confirm the panel shows a game runtime session as ready.
7. Click `Game RDC`.
8. Confirm a valid `.rdc` appears under `captures/renderdoc/game/`.
9. With multiple debug sessions, confirm capture uses the explicitly selected session.

## Implementation Progress

Implemented pieces:

- Added native wrapper diagnostics:
  - `try_load_from_path(path)`
  - `get_load_source()`
  - `get_last_error()`
  - `configure_child_injection(enabled)`
  - `capture_frame(path_template, window_handle)`
- Changed RenderDoc window/device handles to 64-bit values so Windows HWND values are not truncated.
- Added constrained editor capture flow that passes the main editor HWND to RenderDoc instead of using wildcard `StartFrameCapture(nullptr, nullptr)`.
- Added toolbar buttons:
  - `Editor RDC`
  - `Game RDC`
- Added bottom-panel state display for launch mode, RenderDoc API, load source, child hook, editor verification, debug sessions, selected session, last capture paths, and last error.
- Added bottom-panel display for the configured `renderdoccmd.exe` path.
- `Editor RDC` is now gated by `RENDERDOC_BRIDGE_BOOTSTRAPPED=1`, so ordinary Godot launches show editor capture as unavailable and menu-triggered editor capture also refuses to run.
- Added `RenderDocBridgeRuntime` autoload for the debug game process.
- Added `renderdoc_bridge_debugger.gd` to track debug sessions and relay capture requests/results.
- Added project startup files:
  - `Start Godot RenderDoc.cmd`
  - `tools/renderdoc_bridge/start_renderdoc_godot.ps1`
- Added `renderdoc_bridge_src/.gdignore` so Godot does not scan source/build artifacts as project resources.
- Added smoke-test environment hooks:
  - `RENDERDOC_BRIDGE_AUTO_EDITOR_CAPTURE=1`
  - `RENDERDOC_BRIDGE_AUTO_GAME_CAPTURE=1`
  - `RENDERDOC_BRIDGE_UI_SELFTEST=1`
  - `RENDERDOC_BRIDGE_SMOKE_QUIT=1`
- Smoke-test capture emits the toolbar button `pressed` signals, so it exercises the same button wiring used by manual clicks, but only runs when the environment variables above are set.
- Smoke-test mode skips auto-opening the replay UI so verification does not leave RenderDoc windows running.
- Toolbar buttons now have stable node names:
  - `RenderDocBridgeEditorRdcButton`
  - `RenderDocBridgeGameRdcButton`
- Bottom-panel buttons now have stable node names:
  - `RenderDocBridgePanelEditorRdcButton`
  - `RenderDocBridgePanelGameRdcButton`
  - `RenderDocBridgePanelRegenerateEntryButton`

Current automated verification:

- `scons platform=windows target=editor dev_build=no` passes.
- `godot --headless --quit` passes.
- `godot --headless -e --quit` passes plugin initialization.
- `tools/renderdoc_bridge/start_renderdoc_godot.ps1` parses successfully with PowerShell.
- `renderdoccmd.exe version` works with `D:\other_software\RenderDoc\renderdoccmd.exe`.
- `tools/renderdoc_bridge/start_renderdoc_godot.ps1 -ResolveOnly` resolves both `D:\other_software\RenderDoc` and `D:\other_software\RenderDoc\renderdoccmd.exe` to the executable path.
- Real RenderDoc editor button-smoke passed with:
  - `RENDERDOC_BRIDGE_BOOTSTRAPPED=1`
  - `RENDERDOC_BRIDGE_AUTO_EDITOR_CAPTURE=1`
  - `RENDERDOC_BRIDGE_SMOKE_QUIT=1`
  - `renderdoccmd capture --opt-hook-children --wait-for-exit ... godot.exe -e --path ...`
  - trigger path: `RenderDocBridgeEditorRdcButton.pressed.emit()` -> `_capture_editor_frame()`
- Editor smoke output:
  - `captures/renderdoc/editor/editor_capture.rdc`
  - latest verified size about 59 MB
  - `renderdoccmd thumb` successfully read it and wrote a thumbnail.
- Real RenderDoc game button-smoke passed with:
  - `RENDERDOC_BRIDGE_BOOTSTRAPPED=1`
  - `RENDERDOC_BRIDGE_AUTO_GAME_CAPTURE=1`
  - `RENDERDOC_BRIDGE_SMOKE_QUIT=1`
  - `renderdoccmd capture --opt-hook-children --wait-for-exit ... godot.exe -e --path ...`
  - trigger path: `RenderDocBridgeGameRdcButton.pressed.emit()` -> `_request_game_capture()` -> debug runtime capture
- Game smoke output:
  - `captures/renderdoc/game/game_capture.rdc`
  - size about 37 MB
  - `renderdoccmd thumb` successfully read it and wrote a thumbnail.
- After smoke verification, only the user's pre-existing Godot editor process remained; RenderDoc replay UI/command processes were not left running.
- UI self-test passed with:
  - `RENDERDOC_BRIDGE_UI_SELFTEST=1`
  - `RENDERDOC_BRIDGE_SMOKE_QUIT=1`
  - `godot --headless -e --path D:\godot\project\hd-2d`
- UI self-test checks:
  - toolbar `Editor RDC` button is connected to `_capture_editor_frame`
  - toolbar `Game RDC` button is connected to `_request_game_capture`
  - bottom-panel `Editor RDC` and `Game RDC` buttons have local pressed-signal connections
  - one ready game session can be auto-selected
  - multiple ready game sessions without a valid selected session are rejected
  - multiple ready game sessions with a valid selected session use that selected session

Completion evidence:

- `renderdoc_bridge/renderdoccmd_path` is configured as `D:/other_software/RenderDoc/renderdoccmd.exe`.
- `Start Godot RenderDoc.cmd` passes that path into `tools/renderdoc_bridge/start_renderdoc_godot.ps1`.
- Toolbar-button acceptance is covered by button-smoke:
  - launch through RenderDoc's `renderdoccmd capture --opt-hook-children`
  - emit `Editor RDC` toolbar `pressed`
  - confirm a valid editor `.rdc`
  - launch through RenderDoc's `renderdoccmd capture --opt-hook-children`
  - Play the main scene
  - emit `Game RDC` toolbar `pressed`
  - confirm a valid game `.rdc`
- Direct physical mouse-click testing is optional manual UX verification now; the actual Godot button signal path and RenderDoc capture path have been verified.
- Multiple debug sessions still need a live manual UX check only if strict multi-window UI acceptance is required; code-level self-test covers the selection/refusal rules:
  - one ready game session can be auto-selected
  - multiple ready game sessions without a valid selected session are rejected
  - multiple ready game sessions with a valid selected session use that selected session.

## Non-Goals

- Do not promise stable editor capture when Godot is opened through the ordinary Godot shortcut.
- Do not use system-wide registry hooks or app init DLL injection for v1.
- Do not rely on wildcard RenderDoc capture as the final editor capture path.
- Do not treat `LoadLibrary("renderdoc.dll")` as proof of stable graphics API hook success.
