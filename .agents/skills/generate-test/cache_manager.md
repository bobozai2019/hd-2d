# Cache Manager

## Overview

Manages analysis cache for generate-test skill to avoid redundant GodotIQ calls.

## Cache Location

`.claude/knowledge/test_context/`

## Cache File Format

```json
{
  "file": "scripts/systems/my_system.gd",
  "functions": ["process_action", "update_state", "emit_event"],
  "dependencies": ["GameContext", "PlayerState"],
  "signals": ["item_added", "state_changed"],
  "last_analyzed": "2026-05-15T10:30:00Z"
}
```

## Cache Operations

### Check Cache Validity

1. Read cache file for target
2. Get file modification time
3. Compare `last_analyzed` vs modification time
4. If modification time > `last_analyzed`, cache is stale

### Update Cache

1. Call GodotIQ tools to analyze file
2. Extract functions, dependencies, signals
3. Write to cache file with current timestamp

### Force Refresh

When `--force-refresh` option used:
1. Skip cache check
2. Call GodotIQ tools
3. Update cache file

## Integration with SKILL.md

In the generate-test workflow:

1. Parse target file path
2. Check cache validity
3. If valid, use cached data
4. If stale or missing, call GodotIQ and update cache
5. Generate test cases using analysis data
