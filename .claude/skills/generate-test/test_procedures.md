# Test Procedures

## Overview

This document outlines the test procedures for verifying the generate-test skill functionality. Since the skill is implemented as a Claude Code skill (not executable code), testing involves running the skill through Claude Code and verifying the output matches expectations.

## Prerequisites

- Claude Code with generate-test skill loaded
- GodotIQ MCP tools available
- Project at `d:\godot\project\slg-card-test`
- Test target file: `scripts/systems/deck_system.gd`

## Test Cases

### Test 1: Basic Functionality

**Command:**
```bash
/generate-test scripts/systems/deck_system.gd
```

**Expected Behavior:**

1. **File Recognition**
   - Skill identifies `scripts/systems/deck_system.gd` as target
   - Determines test types: Unit + Integration (based on file pattern `scripts/systems/*.gd`)

2. **GodotIQ Analysis**
   - Calls `godotiq_file_context(file="scripts/systems/deck_system.gd", detail="full")`
   - Calls `godotiq_dependency_graph(file="scripts/systems/deck_system.gd", depth=2)`
   - Calls `godotiq_signal_map(scope="file:res://scripts/systems/deck_system.gd")`

3. **Test Generation**
   - Creates unit test: `scripts/tools/test_deck_system.gd`
   - Creates integration test: `scripts/tools/test_deck_system_integration.gd`
   - Tests follow template patterns from `templates/unit_test.gd` and `templates/integration_test.gd`
   - Test functions cover public API identified by GodotIQ

4. **Validation**
   - Runs `godotiq_validate(target="scripts/tools/test_deck_system.gd")`
   - Fixes any validation errors
   - Re-validates until clean

**Verification Checklist:**
- [ ] Target file correctly identified
- [ ] GodotIQ tools called with correct parameters
- [ ] Unit test file created with proper naming
- [ ] Integration test file created with proper naming
- [ ] Tests cover public functions identified by analysis
- [ ] Generated scripts pass validation
- [ ] Output follows project conventions (snake_case, extends SceneTree pattern)

---

### Test 2: Cache Mechanism

**Command:**
```bash
/generate-test scripts/systems/deck_system.gd
```

**Precondition:** Run Test 1 first to populate cache.

**Expected Behavior:**

1. **Cache Check**
   - Reads `.claude/knowledge/test_context/deck_system.json`
   - Compares `last_analyzed` timestamp with file modification time
   - Determines cache is valid (file not modified since last analysis)

2. **Cache Usage**
   - Skips GodotIQ analysis calls
   - Uses cached function list, dependencies, and signals
   - Generates tests from cached data

3. **Output**
   - Creates same test files as Test 1
   - Test content identical to Test 1 output
   - No GodotIQ calls made (verify via logs or timing)

**Verification Checklist:**
- [ ] Cache file exists at `.claude/knowledge/test_context/deck_system.json`
- [ ] Cache contains correct structure (file, functions, dependencies, signals, last_analyzed)
- [ ] No GodotIQ analysis calls made
- [ ] Generated tests identical to Test 1 output
- [ ] Performance improvement (faster execution)

---

### Test 3: Force Refresh

**Command:**
```bash
/generate-test scripts/systems/deck_system.gd --force-refresh
```

**Expected Behavior:**

1. **Cache Bypass**
   - Ignores existing cache file
   - Does not check `last_analyzed` timestamp

2. **GodotIQ Analysis**
   - Calls all GodotIQ tools (same as Test 1)
   - Fresh analysis of target file

3. **Cache Update**
   - Updates `.claude/knowledge/test_context/deck_system.json`
   - Sets new `last_analyzed` timestamp
   - Updates function list if file changed

4. **Output**
   - Creates test files (may differ if source file changed)
   - Validates generated scripts

**Verification Checklist:**
- [ ] `--force-refresh` flag recognized
- [ ] GodotIQ analysis calls made despite valid cache
- [ ] Cache file updated with new timestamp
- [ ] Tests regenerated from fresh analysis
- [ ] Output validated

---

### Test 4: Batch Generation

**Command:**
```bash
/generate-test scripts/systems/ --all
```

**Expected Behavior:**

1. **Directory Scanning**
   - Scans `scripts/systems/` directory
   - Identifies all `.gd` files
   - Expected files: `turn_flow_system.gd`, `card_resolution_system.gd`, `deck_system.gd`, `enemy_system.gd`, `outpost_system.gd`, `wave_system.gd`, `career_system.gd`, `status_system.gd`, `device_system.gd`, `relic_system.gd`, `battle_rule_service.gd`, `battle_query_service.gd`

2. **Per-File Processing**
   - For each `.gd` file:
     - Check cache validity
     - If cache valid, use cached data
     - If cache stale or missing, call GodotIQ
     - Generate unit test: `test_{system_name}.gd`
     - Generate integration test: `test_{system_name}_integration.gd`
     - Validate generated script

3. **Output**
   - Creates 24 test files (12 systems x 2 test types)
   - All files in `scripts/tools/` directory
   - Naming follows convention: `test_{system_name}.gd` and `test_{system_name}_integration.gd`

4. **Progress Reporting**
   - Reports progress for each file processed
   - Summarizes total files processed and tests generated
   - Reports any failures or validation errors

**Verification Checklist:**
- [ ] `--all` flag recognized
- [ ] All `.gd` files in directory identified
- [ ] Each file processed independently
- [ ] Cache used when valid, GodotIQ called when stale
- [ ] All test files created with correct naming
- [ ] All generated scripts pass validation
- [ ] Progress summary provided

---

### Test 5: Business-Driven Mode

**Command:**
```bash
/generate-test --business "Player AP decreases after card use"
```

**Expected Behavior:**

1. **Scenario Parsing**
   - Recognizes business scenario description
   - Identifies key concepts: Player, AP, card use

2. **Runtime Analysis**
   - Starts game with `godotiq_run`
   - Simulates card play with `godotiq_input`
   - Checks AP before and after with `godotiq_state_inspect`
   - Captures state with `godotiq_screenshot`

3. **Test Generation**
   - Creates `scripts/tools/test_player_ap_decreases_after_card_use.gd`
   - Test verifies AP decreases when card is played
   - Uses runtime verification pattern from `templates/runtime_test.gd`

4. **Cleanup**
   - Stops game with `godotiq_run(action='stop')`

**Verification Checklist:**
- [ ] `--business` flag recognized
- [ ] Scenario description parsed correctly
- [ ] Game started and stopped cleanly
- [ ] Runtime state verified
- [ ] Test file created with descriptive name
- [ ] Test covers the business scenario

---

## Cache File Structure

Expected cache file at `.claude/knowledge/test_context/deck_system.json`:

```json
{
  "file": "scripts/systems/deck_system.gd",
  "functions": ["draw_cards", "shuffle_discard", "add_card", "discard_hand_end_turn", "resolve_card_after_use"],
  "dependencies": ["BattleContext", "DeckState", "CardInstance"],
  "signals": ["card_drawn", "deck_shuffled", "card_moved"],
  "last_analyzed": "2026-05-15T10:30:00Z"
}
```

## Output File Naming Convention

| Test Type | Pattern | Example |
|-----------|---------|---------|
| Unit | `test_{system_name}.gd` | `test_deck_system.gd` |
| Integration | `test_{system_name}_integration.gd` | `test_deck_system_integration.gd` |
| Runtime | `test_{system_name}_runtime.gd` | `test_deck_system_runtime.gd` |
| Visual | `test_{scene_name}_visual.gd` | `test_main_menu_visual.gd` |
| Business | `test_{description}.gd` | `test_player_ap_decreases_after_card_use.gd` |

## Success Criteria

All tests pass when:

1. **Basic Functionality**: Skill correctly identifies files, calls GodotIQ, generates valid tests
2. **Cache Mechanism**: Cache prevents redundant GodotIQ calls, produces identical output
3. **Force Refresh**: `--force-refresh` bypasses cache, regenerates tests
4. **Batch Generation**: All files in directory processed, tests generated for each
5. **Business-Driven**: Scenario parsed, runtime verified, test generated

## Troubleshooting

### Common Issues

1. **GodotIQ tools not available**
   - Verify MCP server is running
   - Check tool permissions in Claude Code settings

2. **Cache directory missing**
   - Create `.claude/knowledge/test_context/` manually
   - Or let skill create it on first run

3. **Validation errors in generated tests**
   - Check generated script syntax
   - Verify preloaded paths exist
   - Ensure function signatures match target file

4. **Batch generation stops early**
   - Check for file permission issues
   - Verify all target files exist
   - Look for validation failures in output

---

*This document describes expected behavior for manual verification. Actual skill execution requires Claude Code with the generate-test skill loaded.*
