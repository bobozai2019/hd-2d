---
name: ralph
description: "将 PRD 转换为 Ralph 自主 agent 系统的 prd.json 格式。当你有现有 PRD 并需要转换为 Ralph 的 JSON 格式时使用。触发词：convert this prd, turn this into ralph format, create prd.json from this, ralph json。"
user-invocable: true
---

# Ralph PRD 转换器

将现有 PRD 转换为 Ralph 用于自主执行的 prd.json 格式。

---

## 工作内容

获取 PRD（markdown 文件或文本）并将其转换为你的 ralph 目录中的 `prd.json`。

---

## 输出格式

```json
{
  "project": "[项目名称]",
  "branchName": "ralph/[feature-name-kebab-case]",
  "description": "[来自 PRD 标题/简介的功能描述]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[故事标题]",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "标准 1",
        "标准 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## 故事大小：第一规则

**每个故事必须能在 Ralph 的一次迭代中完成（一个上下文窗口）。**

Ralph 每次迭代启动一个新的 Amp 实例，没有之前工作的记忆。如果故事太大，LLM 在完成前就会耗尽上下文，产生有问题的代码。

### 大小合适的故事：
- 添加数据库列和迁移
- 为现有页面添加 UI 组件
- 用新逻辑更新 server action
- 为列表添加过滤下拉菜单

### 太大（需要拆分）：
- "构建整个仪表板" - 拆分为：schema、queries、UI 组件、filters
- "添加认证" - 拆分为：schema、middleware、登录 UI、session 处理
- "重构 API" - 按端点或模式拆分为独立故事

**经验法则：** 如果你无法用 2-3 句话描述变更，那就太大了。

---

## 故事排序：依赖优先

故事按优先级顺序执行。较早的故事不能依赖较晚的故事。

**正确顺序：**
1. Schema/数据库变更（migrations）
2. Server actions / 后端逻辑
3. 使用后端的 UI 组件
4. 聚合数据的仪表板/汇总视图

**错误顺序：**
1. UI 组件（依赖尚不存在的 schema）
2. Schema 变更

---

## 验收标准：必须可验证

每个标准必须是 Ralph 可以检查的，而不是模糊的。

### 好的标准（可验证）：
- "为 tasks 表添加 `status` 列，默认 'pending'"
- "过滤下拉菜单选项：全部、进行中、已完成"
- "点击删除显示确认对话框"
- "Typecheck passes"
- "Tests pass"

### 差的标准（模糊）：
- "正常工作"
- "用户可以轻松做 X"
- "好的用户体验"
- "处理边界情况"

### 始终作为最后一条标准包含：
```
"Typecheck passes"
```

对于有可测试逻辑的故事，还需包含：
```
"Tests pass"
```

### 对于更改 UI 的故事，还需包含：
```
"Verify in browser using dev-browser skill"
```

前端故事在视觉验证之前不算完成。Ralph 将使用 dev-browser 技能导航到页面，与 UI 交互，并确认变更有效。

---

## 转换规则

1. **每个用户故事变成一个 JSON 条目**
2. **ID**：顺序编号（US-001、US-002 等）
3. **优先级**：基于依赖顺序，然后文档顺序
4. **所有故事**：`passes: false` 和空 `notes`
5. **branchName**：从功能名称派生，kebab-case，前缀 `ralph/`
6. **始终添加**：在每个故事的验收标准中加入 "Typecheck passes"

---

## 拆分大型 PRD

如果 PRD 有大型功能，请拆分它们：

**原始：**
> "添加用户通知系统"

**拆分为：**
1. US-001: 为数据库添加通知表
2. US-002: 创建通知服务用于发送通知
3. US-003: 为头部添加通知铃铛图标
4. US-004: 创建通知下拉面板
5. US-005: 添加标记已读功能
6. US-006: 添加通知偏好设置页面

每个都是一个专注的变更，可以独立完成和验证。

---

## 示例

**输入 PRD：**
```markdown
# 任务状态功能

添加用不同状态标记任务的能力。

## 需求
- 在任务列表上切换 pending/in-progress/done
- 按状态过滤列表
- 在每个任务上显示状态徽章
- 在数据库中持久化状态
```

**输出 prd.json：**
```json
{
  "project": "TaskApp",
  "branchName": "ralph/task-status",
  "description": "任务状态功能 - 使用状态指示器跟踪任务进度",
  "userStories": [
    {
      "id": "US-001",
      "title": "为 tasks 表添加 status 字段",
      "description": "As a developer, I need to store task status in the database.",
      "acceptanceCriteria": [
        "Add status column: 'pending' | 'in_progress' | 'done' (default 'pending')",
        "Generate and run migration successfully",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-002",
      "title": "在任务卡片上显示状态徽章",
      "description": "As a user, I want to see task status at a glance.",
      "acceptanceCriteria": [
        "Each task card shows colored status badge",
        "Badge colors: gray=pending, blue=in_progress, green=done",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 2,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-003",
      "title": "为任务列表行添加状态切换",
      "description": "As a user, I want to change task status directly from the list.",
      "acceptanceCriteria": [
        "Each row has status dropdown or toggle",
        "Changing status saves immediately",
        "UI updates without page refresh",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 3,
      "passes": false,
      "notes": ""
    },
    {
      "id": "US-004",
      "title": "按状态过滤任务",
      "description": "As a user, I want to filter the list to see only certain statuses.",
      "acceptanceCriteria": [
        "Filter dropdown: All | Pending | In Progress | Done",
        "Filter persists in URL params",
        "Typecheck passes",
        "Verify in browser using dev-browser skill"
      ],
      "priority": 4,
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## 归档之前的运行

**在写入新的 prd.json 之前，检查是否已有来自不同功能的现有文件：**

1. 读取当前 `prd.json`（如果存在）
2. 检查 `branchName` 是否与新功能的分支名不同
3. 如果不同且 `progress.txt` 有头部之外的内容：
   - 创建归档文件夹：`archive/YYYY-MM-DD-feature-name/`
   - 将当前 `prd.json` 和 `progress.txt` 复制到归档
   - 用新头部重置 `progress.txt`

**ralph.sh 脚本在运行时会自动处理**，但如果你在运行之间手动更新 prd.json，请先归档。

---

## 保存前检查清单

在写入 prd.json 之前，验证：

- [ ] **已归档之前的运行**（如果 prd.json 存在且 branchName 不同，先归档）
- [ ] 每个故事可在一次迭代中完成（足够小）
- [ ] 故事按依赖顺序排列（schema 到后端到 UI）
- [ ] 每个故事都有 "Typecheck passes" 作为标准
- [ ] UI 故事有 "Verify in browser using dev-browser skill" 作为标准
- [ ] 验收标准可验证（不模糊）
- [ ] 没有故事依赖较晚的故事
