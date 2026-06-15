---
name: run-prd-acceptance
description: Use when asked to run, execute, verify, or record PRD acceptance tests for this Godot project from a PRD markdown path, including PRD测试, PRD验收, 跑PRD测试, or 技能+PRD路径.
---

# Run PRD Acceptance

## Purpose

Run the acceptance checks described by a PRD markdown file and write a truthful result report. The only user argument is the PRD path.

## Required Input

Accept exactly one required argument: the PRD markdown path.

Examples:

```text
run-prd-acceptance docs/PRD/prd-current-game-loop-and-feature-baseline.md
使用 run-prd-acceptance docs/PRD/prd-run-map-system.md
```

Defaults:

- Run the whole PRD.
- Do not modify or check boxes in the source PRD.
- Write results under `PRD_TEST/`.

If the path is missing or unreadable, stop and ask for a valid path. Do not guess a PRD.

## Workflow

1. Read the PRD and identify user stories, acceptance criteria, functional requirements, validation matrix, and any explicit manual flows.
2. Create a short execution plan from the PRD. Separate checks into automated, Godot/headless, MCP/interactive, and manual-observation buckets.
3. Before Godot/GodotIQ-specific execution, consult existing project debugging/Godot testing knowledge if available, especially `.claude/knowledge/debugging.md`.
4. Run project preflight when feasible:
   - `godot --headless --quit`
   - Any PRD-listed validation scripts that directly apply.
5. For runtime or debug failures, read `logs/godot.log` before drawing conclusions.
6. Execute every PRD item in scope. If a step blocks, make up to three meaningful attempts total for that blocked step.
7. Record the real result for every item: `PASS`, `FAIL`, `BLOCKED`, or `NOT_RUN`.
8. Write the report to `PRD_TEST/YYYYMMDD-HHMMSS-<prd-name>-acceptance.md`.
9. Summarize the report path and highest-priority failures. Do not claim the PRD passed unless every required item is `PASS`.

## Three-Attempt Rule

When a test path does not go through:

1. Attempt once using the most direct method from the PRD.
2. Attempt a second time using the best available alternate route, tool, or smaller reproduction.
3. Attempt a third time only if it can add new evidence.

After three attempts, stop retrying that item and record exactly where it is stuck. Do not keep looping, and do not convert a blocked item into a pass.

Each attempt record must include:

- What was attempted.
- What happened.
- Evidence checked, especially `logs/godot.log` for Godot debug/runtime issues.
- Why the next attempt was different or why attempts stopped.

## Result Report

Use `references/result-template.md` when writing the report.

## Output Language

Write PRD acceptance reports, test result summaries, generated follow-up documents, and user-facing acceptance conclusions in Chinese by default.

Keep technical identifiers unchanged when they are exact values from tools or code, including command names, file paths, enum names, signal names, status labels (`PASS`, `FAIL`, `BLOCKED`, `NOT_RUN`), and failure taxonomy categories.

Every PRD item should include:

- PRD item reference.
- Test method.
- Result.
- Evidence.
- Attempt history when not immediately passing.
- Failure/blocker category.
- Cause details.
- Suggested next step.

Use `references/failure-reason-taxonomy.md` for categories.

## Source PRD Checkboxes

Never update `- [ ]` to `- [x]` in the source PRD by default.

Only update PRD checkboxes if the user explicitly says to write back, check off, 勾选, or 回写 the PRD. Even then, only mark items with direct evidence as passed, and leave failed, blocked, ambiguous, or untested items unchecked.

## Important Project Rules

- Keep this skill focused on PRD acceptance workflow and report format. Put reusable Godot/headless/GodotIQ lessons in project knowledge, then consult that knowledge during execution.
- Debug/F5/runtime errors: inspect `logs/godot.log` first.
- Tool limits are not product failures. Record them as `TEST_TOOL_LIMITATION`.
- Godot/headless/input limits are not product failures. Record them as `GODOT_ENGINE_LIMITATION` or `ENVIRONMENT_LIMITATION`.
- Missing automation is not a pass. Record `NOT_RUN` or `BLOCKED` with cause.
- If execution is interrupted, still write a partial report with completed items and the interruption point.
- For UI flows, record the exact route, for example: `运行 -> StartBattle -> 战士 -> 第一个关卡 -> 战斗`.
