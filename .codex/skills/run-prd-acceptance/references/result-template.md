# PRD 验收报告模板

```markdown
# PRD 验收报告：<PRD 标题>

- PRD: `<path>`
- 开始时间: `<YYYY-MM-DD HH:mm:ss>`
- 结束时间: `<YYYY-MM-DD HH:mm:ss>`
- 执行者: Codex
- 范围: 完整 PRD
- 是否回写源 PRD: 否

## 摘要

- PASS: 0
- FAIL: 0
- BLOCKED: 0
- NOT_RUN: 0

## 环境

- 项目根目录: `<path>`
- Godot 命令可用: `<是/否/版本信息>`
- OS/会话说明: `<notes>`
- 主要运行日志: `logs/godot.log`

## 使用的命令和工具

| 工具/命令 | 目的 | 结果 |
|---|---|---|
| `<command>` | `<purpose>` | `<result>` |

## 结果明细

### `<PRD item id/title>`

- 结果: `PASS|FAIL|BLOCKED|NOT_RUN`
- 测试方法: `headless|script|MCP|manual observation|document review`
- 证据:
  - `<command output summary, log excerpt summary, screenshot path, or file reference>`
- 尝试记录:
  1. `<attempt, observed result, evidence>`
  2. `<attempt, observed result, evidence>`
  3. `<attempt, observed result, evidence>`
- 失败/阻塞分类: `<category or N/A>`
- 原因详情: `<real reason; include where it got stuck>`
- 建议下一步: `<specific next action>`

## 日志检查

- 是否检查 `logs/godot.log`: `<是/否/不适用>`
- 相关发现: `<summary>`

## 未解决问题

- `<issue>`
```
```
