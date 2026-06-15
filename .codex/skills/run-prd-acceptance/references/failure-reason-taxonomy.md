# Failure And Blocker Categories

Use exactly one primary category per non-passing item.

| Category | Use when |
|---|---|
| `PRODUCT_GAP` | The PRD expects a product behavior that is intentionally not implemented yet. |
| `IMPLEMENTATION_BUG` | The intended behavior exists or should exist, but code/runtime behavior is wrong. |
| `TEST_TOOL_LIMITATION` | MCP, automation, recorder, browser/computer control, or test harness cannot perform the required action. |
| `GODOT_ENGINE_LIMITATION` | Godot, headless mode, viewport/input simulation, or engine behavior prevents the test from being executed as written. |
| `ENVIRONMENT_LIMITATION` | Local environment blocks the test: missing Godot command, bad PATH, unavailable display driver, locked files, missing assets, permissions, or machine-specific issue. |
| `PRD_AMBIGUITY` | The PRD acceptance item can be interpreted multiple ways and cannot be fairly judged without clarification. |
| `NOT_COVERED` | The item was outside the requested run scope or no credible test was available in this run. |
| `INTERRUPTED` | The run stopped because the user interrupted or redirected before the item could complete. |

Rules:

- Do not use `IMPLEMENTATION_BUG` for missing test tooling.
- Do not use `PASS` when evidence is only "no one observed a failure".
- Prefer `BLOCKED` plus a limitation category when the behavior might work but the test could not reach it.
- Include the exact stuck point, such as `MCP could not click Godot window`, `godot command missing`, or `logs/godot.log showed null instance at battlefield setup`.
