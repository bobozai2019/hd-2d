---
description: 从当前对话中提取有价值的知识，分类保存到项目知识库。支持两种模式：(a) 显式指定分类和内容保存；(b) 无参数时自动分析对话，建议要保存的洞察。知识库位于 .claude/knowledge/，按领域分类存储。
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Remember — Project Knowledge Capture

$ARGUMENTS

## Mode Detection

Check if `$ARGUMENTS` is empty or contains only whitespace:

- **If arguments provided** → Explicit mode: parse category and content, save directly.
- **If no arguments** → Auto-extract mode: analyze conversation, suggest insights.

## Explicit Mode

Parse `$ARGUMENTS` as: `<category> <content>`

Valid categories (map to files in `.claude/knowledge/`):

| Keyword | File | Scope |
|---------|------|-------|
| `ui` | ui.md | UI 模式、布局、Control 节点、HTML 映射 |
| `conventions` | conventions.md | 代码风格、命名、架构决策 |
| `debugging` | debugging.md | 陷阱、错误、调试技巧 |
| `godot` | godot.md | 引擎怪癖、workaround、headless 限制 |

If the first word matches a category keyword, use it. Otherwise, infer the best category from the content and confirm with the user.

Steps:
1. Read the target category file (create if missing).
2. Generate a concise title (under 60 chars).
3. Insert a new entry at the top (after the H1 heading, before the first H2).
4. Format depends on content type:
   - **Anti-pattern** (if content describes a wrong approach, failed attempt, or "don't do this" pattern):
     `## {today}: {title} ⚠️\n**The trap:** ...\n**Why it's tempting:** ...\n**What breaks:** ...\n**Failed paths:** ...\n**The right way:** ...\n**How to spot it early:** ...\n`
   - **Problem-solution** (if content describes a bug/fix with investigation journey):
     `## {today}: {title}\n**Symptom:** ...\n**Investigation:** ...\n**Root cause:** ...\n**Fix:** ...\n**Failed approaches:** ...\n**How to apply:** ...\n`
   - **General insight**: `## {today}: {title}\n{content}\n**Why:** ...\n**How to apply:** ...\n`
5. Confirm what was saved and to which file.

## Auto-Extract Mode

When no arguments are provided, analyze the current conversation to identify valuable project knowledge.

### What counts as valuable

Look for these signals in the conversation:

1. **Problem-solution pairs** (highest priority) — any bug, error, or unexpected behavior that required investigation. Capture the full journey: symptom → investigation steps → root cause → fix. These are the most valuable knowledge entries because they prevent repeating the same debugging path.
2. **Anti-patterns and failure paths** (highest priority) — any approach that seemed correct but turned out wrong, or any code pattern that causes subtle bugs. Capture: what the wrong approach looks like, why it's tempting, what actually breaks, and the correct alternative. These prevent the most expensive category of repeated mistakes.
3. **Decisions made** — "we chose X over Y because Z"
4. **Discovered patterns** — "it turns out that...", "the correct way to..."
5. **Gotchas and pitfalls** — "this doesn't work", "watch out for", "the error was caused by"
6. **Non-obvious mappings** — HTML-to-Godot translations, CSS-to-Container decisions
7. **Architecture insights** — how systems interact, signal flow, state management patterns
8. **Debugging discoveries** — root causes found, error messages decoded, workarounds applied
9. **Performance findings** — what's slow, what helped, draw call counts
10. **Godot-specific knowledge** — engine behavior, version quirks, headless limitations

### Anti-Pattern Entry Format (for capturing what NOT to do)

When capturing a wrong approach, failed attempt, or code pattern that causes bugs:

```markdown
## {date}: {short title} ⚠️

**The trap:** The wrong code/approach that looks correct. Show the actual code or describe the pattern.

**Why it's tempting:** Why someone would write this — it seems logical, follows a common pattern, or is how other engines/languages work.

**What breaks:** The specific failure mode — error message, silent bug, race condition, performance cliff, etc.

**Failed paths:** Other approaches tried that also didn't work, and why. Each failed path is a separate bullet:
- `{approach A}` → fails because `{reason}`
- `{approach B}` → fails because `{reason}`

**The right way:** The correct pattern, with code if applicable.

**How to spot it early:** Red flags that signal you're heading into this trap — code patterns, error message prefixes, architectural smells.
```

This format is the most valuable type of knowledge entry because:
- **The trap** is searchable by code pattern — you can grep for it
- **Why it's tempting** prevents the "but this should work" debugging spiral
- **What breaks** connects symptom to cause
- **Failed paths** saves the most time — knowing N things that DON'T work prevents hours of re-exploration
- **The right way** is the actionable takeaway
- **How to spot it early** enables prevention, not just cure

### Problem-Solution Entry Format (preferred for debugging conversations)

When capturing a problem that was solved during the conversation, use this structured format:

```markdown
## {date}: {short title}

**Symptom:** What went wrong — the error message, visual bug, or unexpected behavior.

**Investigation:** What we tried first, what we checked, dead ends. This is the most valuable part — it saves future debugging time. Include failed paths as sub-bullets:
- Tried `{approach}` → didn't help because `{reason}`
- Checked `{thing}` → ruled out because `{evidence}`

**Root cause:** The actual underlying reason.

**Fix:** The specific change that resolved it.

**Failed approaches:** (optional but encouraged) Things that seemed promising but didn't work or made things worse:
- `{approach}` → result: `{what happened}`, why wrong: `{reason}`

**How to apply:** When to watch out for this pattern, how to detect it early.
```

### Signal detection for anti-patterns

In auto-extract mode, specifically watch for these conversation signals that indicate an anti-pattern worth capturing:

- User corrects an approach: "no, don't do X", "that won't work because..."
- Claude tries something that fails: "that approach didn't work", "still getting the same error"
- A seemingly correct solution has hidden problems: "this compiles but breaks at runtime", "works in editor but not in game"
- Cross-paradigm confusion: using patterns from another language/engine that don't apply in Godot
- Silent failures: code that runs without errors but produces wrong results
- Cascading fixes: fixing one thing breaks another, revealing a deeper anti-pattern

### What to skip

- Routine code changes with no broader insight
- Information already captured in CLAUDE.md or existing knowledge files
- Temporary debugging state (variable values, stack traces) unless they reveal a pattern
- User preferences that belong in auto-memory (type: user/feedback)

### Process

1. Scan the conversation for the signal types listed above.
2. For each candidate insight, determine:
   - Entry type: anti-pattern (⚠️), problem-solution, or general insight
   - Category (from the 8 valid categories)
   - Title (under 60 chars, descriptive)
   - Content (2-6 lines, actionable, includes the "why")
3. Read existing knowledge files to check for duplicates or overlapping entries.
4. **<HARD-GATE> 必须等待用户确认后才能继续。禁止跳过此步骤直接保存。**
   Present findings to the user as a numbered list:
   ```
   Found N insights worth saving:

   1. [category] ⚠️ Title — one-line summary
      Trap: {what the wrong approach looks like}
      Right way: {the correct approach}
   2. [category] Title — one-line summary
      Problem: {what went wrong}
      Solution: {how it was fixed}
   3. [category] Title — one-line summary

   Save all? Or specify numbers (e.g., "1,3"):
   ```
   For anti-pattern entries, always include Trap/Right way preview.
   For problem-solution entries, include Problem/Solution preview.
   This lets the user verify accuracy before saving.
   **等待用户回复后再执行步骤 5。用户可能说 "all"、指定数字、或要求修改。**
5. On confirmation, insert selected entries to their respective files (newest first, after H1, before first H2).
   - Anti-pattern entries use the ⚠️ format (Trap → Why tempting → What breaks → Failed paths → Right way → How to spot).
   - Problem-solution entries use the structured format (Symptom → Investigation → Root cause → Fix → Failed approaches → How to apply).
   - General insights use the standard format (content → Why → How to apply).
6. Confirm what was saved.

## File Operations

When writing to any knowledge file:

- If the file doesn't exist, create it with the H1 heading: `# {Category} Knowledge`
- Read the file first to check for duplicate/similar entries.
- Insert new entries after the H1, before the first existing H2 (newest first).
- Use `Edit` tool for inserting, not `Write` (preserves existing content).
- Always use absolute paths: `.claude/knowledge/{file}.md`

## Integration Notes

- This knowledge base complements Claude's auto-memory (`.claude/projects/.../memory/`).
- Auto-memory is for session-level preferences and feedback.
- This knowledge base is for project-level domain knowledge that persists across sessions.
- If an insight is both a "user preference" and "project knowledge", save it here (more discoverable).
