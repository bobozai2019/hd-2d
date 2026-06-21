# #6 get_node 路径解析错误（已解决）

## 问题描述

脚本中 `get_node(^"CharacterViewport")` 从根子节点调用时找不到节点，返回 null。

## 问题场景

- 场景：`scenes/map3d/hd2d_market_plaza_lighting_lab2.tscn`
- CharacterViewportSync 是场景根的直接子节点（parent="."）
- 脚本中使用 `get_node_or_null(^"CharacterViewport")` 查找兄弟节点
- 运行时三个引用变量全部为 null
- 验证：`get_node_or_null(^"../CharacterViewport")` 能正确找到
- godotiq_exec 实测确认：`sync.get_node_or_null(^"CharacterViewport")` → null，`sync.get_node_or_null(^"../CharacterViewport")` → SubViewport

## 可能原因

- Godot 中 `get_node(^"X")` 从当前节点开始查找**子节点** X，不是兄弟节点。要访问兄弟节点需要 `get_node(^"../X")`。（**确定**）

## 修复方式

- 改为 `get_node_or_null(^"../CharacterViewport")` 等带 `../` 的路径
