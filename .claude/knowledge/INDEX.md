# Project Knowledge Base

开发会话中沉淀的项目知识，按领域分类存储。

## Categories

- [UI](ui.md) — Control 节点选择、布局模式、Container 用法、主题覆盖、交互模式（暂空）
- [Conventions](conventions.md) — 代码风格决策、命名模式、架构选择、preload 类型注解、场景化 UI
- [Debugging](debugging.md) — 常见错误模式、陷阱描述、调试流程、测试策略、headless 验证注意事项
- [Godot](godot.md) — 引擎怪癖、Godot 4.6 workaround、headless 模式限制、导出注意事项、编辑器行为

## How to use

- 显式保存: `/remember ui Always use MarginContainer for padding`
- 自动提取: `/remember`（分析当前对话，建议要保存的洞察）
- 浏览: 直接读取分类文件，或问 Claude "what do we know about X?"
- 问题回顾: `/recall problems` — 查看所有问题-解决方案历史
- 最近动态: `/recall recent` — 查看最近 7 天的知识条目

## Problem-Solution Format

调试类条目使用结构化格式，便于按症状搜索、按根因学习：

```
## {date}: {title}
**Symptom:** 错误信息或异常行为
**Investigation:** 排查过程（最有价值的部分）
**Root cause:** 根本原因
**Fix:** 具体修复
**How to apply:** 预防措施
```
