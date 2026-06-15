---
description: 搜索项目知识库中的相关洞察。开始某领域工作前使用，检查是否有先验知识。知识库位于 .claude/knowledge/，按领域分类存储。
allowed-tools: Read, Grep, Glob
---

# Recall — Knowledge Search

$ARGUMENTS

Search `.claude/knowledge/*.md` for entries matching the query.

## Process

1. If `$ARGUMENTS` is empty, list all categories with entry counts:
   - Read each `{category}.md` file, count H2 headings (`## `)
   - Present summary table

2. If `$ARGUMENTS` contains a query:
   - Use `Grep` to search all `.claude/knowledge/*.md` files for the query (case-insensitive)
   - Return matching entries with their category, date, and content
   - If no matches, suggest related categories to browse manually

3. If `$ARGUMENTS` matches a category keyword (`ui`, `resources`, `logic`, `data`, `conventions`, `debugging`, `performance`, `godot`):
   - Read that category file and list all entries as a summary

4. If `$ARGUMENTS` is `problems` or `issues` or `fixes`:
   - Search all knowledge files for entries containing `**Symptom:**` or `**Root cause:**` or `**Fix:**`
   - Present as a problem-solution index:
     ```
     Problem-Solution History:

     1. [category | date] Title
        Symptom: ...
        Fix: ...

     2. [category | date] Title
        Symptom: ...
        Fix: ...
     ```
   - This provides a quick overview of all debugging journeys across the project

5. If `$ARGUMENTS` is `recent` or `latest`:
   - Read all knowledge files, extract entries from the last 7 days
   - Present grouped by date, newest first
   - Problem-solution entries are shown with full structure; others shown as summaries
