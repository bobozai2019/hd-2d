# MCP 能力矩阵 — E2E 测试覆盖

本文档列出 GodotIQ MCP 工具在 E2E 测试中的能力覆盖和已知缺口。
录制过程中如遇到缺口，按中断机制处理。

## 核心能力

| 能力 | MCP 工具 | E2E 用途 | 状态 |
|------|----------|----------|------|
| 启动游戏 | `godotiq_run(action="play")` | 测试前置条件 | ✅ |
| 停止游戏 | `godotiq_run(action="stop")` | 测试清理 | ✅ |
| 指定场景启动 | `godotiq_run(scene="res://...")` | 直接进入目标场景 | ✅ |
| UI 元素发现 | `godotiq_ui_map` | 动态发现可交互元素 | ✅ |
| 点击/轻触 | `godotiq_input(tap=...)` | UI 交互 | ✅ |
| 按键输入 | `godotiq_input(key=...)` | 键盘操作 | ✅ |
| 动作触发 | `godotiq_input(actions=...)` | 游戏动作（如 move_left） | ✅ |
| 等待信号 | `godotiq_input(wait_for=...)` | 异步操作等待 | ✅ |
| 状态查询 | `godotiq_state_inspect` | 运行时值断言 | ✅ |
| 属性监控 | `godotiq_watch` | 跨步骤状态追踪 | ✅ |
| 运行时场景树 | `godotiq_game_scene_tree` | 运行时节点存在性验证（非编辑器缓存） | ✅ |
| 按钮按下触发 | `godotiq_press_button` | ScrollContainer 内按钮触发（直接 emit_signal） | ✅ |
| 插件热重载 | `godotiq_reload_addon` | 修改 addon 后热重载，无需重启编辑器 | ✅ |
| 编译检查 | `godotiq_check_errors` | 脚本无报错验证 | ✅ |
| 运行时错误 | `godotiq_read_debug_console` | 错误检测 | ✅ |
| 截图 | `godotiq_screenshot` | 视觉验证 | ✅ |
| 场景树检查 | `godotiq_scene_tree` | 节点存在性验证 | ✅ |
| 场景地图 | `godotiq_scene_map` | 空间布局验证 | ✅ |
| 依赖图 | `godotiq_dependency_graph` | 系统依赖验证 | ✅ |
| 信号图 | `godotiq_signal_map` | 信号连接验证 | ✅ |

## 场景导航能力

| 场景 | 导航方式 | MCP 支持 | 备注 |
|------|----------|----------|------|
| 主菜单 → 地图 | UI 点击 | ✅ `godotiq_input(tap=...)` | 需先 `ui_map` 发现按钮 |
| 地图 → 战斗 | UI 点击地图节点 | ✅ `godotiq_input(tap=...)` | 需 `ui_map` 发现节点 |
| 战斗 → 结算 | 自动（战斗结束） | ✅ `wait_for` 等待信号 | 等待结算信号 |
| 结算 → 地图 | UI 点击 | ✅ `godotiq_input(tap=...)` | 需 `ui_map` 发现按钮 |
| 地图 → 商店 | UI 点击商店节点 | ✅ `godotiq_input(tap=...)` | 同地图导航 |
| 地图 → 休息 | UI 点击休息节点 | ✅ `godotiq_input(tap=...)` | 同地图导航 |

## 已知缺口

| 缺口 | 描述 | 影响范围 | 替代方案 |
|------|------|----------|----------|
| 动画完成检测 | 无法等待动画播放完毕 | 视觉验证类验收标准 | 用 `wait_for` 信号 + `await` 帧等待替代 |
| 音频播放验证 | 无法检查音效是否播放 | 音效相关验收标准 | 暂无替代，需跳过 |
| 精确像素比对 | 截图只能人工判断 | UI 精确位置/颜色验证 | 用 `state_inspect` 检查属性值替代 |
| 跨场景状态持久化 | 无法直接查询存档数据 | Run 流程持久化验证 | 通过 `state_inspect` 查询 RunState 等 autoload |

## 中断报告模板

当录制遇到 MCP 不支持的能力时，输出以下格式：

```
⚠️ E2E 测试录制中断

缺失 MCP 能力:
  - [具体能力描述]

影响的验收标准:
  - [US-XXX]: [验收标准描述]

请选择:
  a) 先实现缺失的 MCP 能力，然后继续录制
  b) 跳过这些验收标准，只生成可测试的部分
  c) 中止录制
```
