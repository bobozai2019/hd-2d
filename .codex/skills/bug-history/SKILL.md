---
name: bug-history
description: "Deprecated compatibility entry for /bug-history. Use when the user invokes /bug-history to capture debugging lessons; delegate the full conversation knowledge workflow to the summarize skill instead of writing a separate bug_history store."
---

# Bug History Compatibility Entry

告知用户 `/bug-history` 已由 `/summarize` 取代，然后执行 `summarize` 的完整流程。此入口不再只提取 bug，也不再写入新的 `bug_history/`。

从相邻的 `../summarize/SKILL.md` 读取规则；若当前安装使用独立链接，则从本技能的 hub 规范路径定位 `skills/summarize/SKILL.md`。必须完整遵循该文件。

- `/bug-history` 等价于 `/summarize`。
- `/bug-history -auto` 等价于 `/summarize -auto`。

兼容入口暂不设置删除日期。
