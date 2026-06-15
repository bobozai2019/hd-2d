# 代码质量审查者提示模板

在派遣代码质量审查子代理时使用此模板。

**目的：** 验证实现是否构建良好（干净、可测试、可维护）

**仅在规格合规审查通过后派遣。**

```
Task tool (general-purpose):
  Use template at requesting-code-review/code-reviewer.md

  DESCRIPTION: [task summary, from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
```

**除了标准代码质量关注点外，审查者还应检查：**
- 每个文件是否有一个清晰的职责和明确定义的接口？
- 单元是否被分解为可以独立理解和测试的形式？
- 实现是否遵循计划中的文件结构？
- 此实现是否创建了已经很大的新文件，或显著增长了现有文件？（不要标记已有的文件大小 — 关注此更改贡献了什么。）

**代码审查者返回：** 优势、问题（严重/重要/次要）、评估
