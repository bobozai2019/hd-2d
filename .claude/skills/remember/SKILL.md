---
name: remember
description: "Deprecated compatibility entry for /remember. Use when the user invokes /remember or explicitly asks through this legacy entry to save conversation knowledge; delegate the complete workflow to the summarize skill."
---

# Remember Compatibility Entry

告知用户 `/remember` 已由 `/summarize` 取代，然后执行 `summarize` 的完整流程。此入口不再强制只写 hub，也不接受旧的显式 `<category> <content>` 模式。

从相邻的 `../summarize/SKILL.md` 读取规则；若当前安装使用独立链接，则从本技能的 hub 规范路径定位 `skills/summarize/SKILL.md`。必须完整遵循该文件。

- `/remember` 等价于 `/summarize`。
- `/remember -auto` 等价于 `/summarize -auto`。

兼容入口暂不设置删除日期。
