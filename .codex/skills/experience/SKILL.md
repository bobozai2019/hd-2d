---
name: experience
description: "Deprecated compatibility entry for /experience. Use when the user invokes /experience to capture lessons from the conversation; delegate the full extraction, verification, routing, deduplication, confirmation, and writing workflow to the summarize skill."
---

# Experience Compatibility Entry

告知用户 `/experience` 已由 `/summarize` 取代，然后执行 `summarize` 的完整流程。

从相邻的 `../summarize/SKILL.md` 读取规则；若当前安装使用独立链接，则从本技能的 hub 规范路径定位 `skills/summarize/SKILL.md`。必须完整遵循该文件，不能保留旧的 memory 路径、分类或逐条确认逻辑。

- `/experience` 等价于 `/summarize`。
- `/experience -auto` 等价于 `/summarize -auto`。

兼容入口暂不设置删除日期。
