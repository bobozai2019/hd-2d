# Conventions Knowledge

## 2026-05-14: 类型注解必须用 preload 常量，不能用 class_name

所有跨文件的类型注解必须使用 `preload()` 常量，不能直接引用 `class_name` 注册的类型名。

标准模式：
```gdscript
# 文件顶部
const SomeModuleScript = preload("res://scripts/some_module.gd")

# 变量和参数
var _module: SomeModuleScript = null
func setup(module: SomeModuleScript) -> void:
```

**Why:** Godot 4 的文本解析器无法在解析阶段跨文件解析 class_name 类型，会抛出 74+ 个 "Could not find type in current scope" 错误和级联的 ERR_CYCLING_LINK (error 43) 失败。

**How to apply:** 新增任何跨文件类型引用时，先添加 `const XxxScript = preload(...)` 再用 `XxxScript` 作类型标注。同文件内的 class_name 引用（如返回类型）是安全的例外。

## 2026-05-15: 能固化到场景里的，别用脚本

**规则：** 能在 .tscn 场景中完成的控件创建和属性设置，禁止用脚本代码做。

具体来说：
- **节点创建**：Button、Label、Container 等静态 UI 元素必须在场景树中创建，不许 `_build_ui()` 里 `Xxx.new()` + `add_child()`
- **属性设置**：text、custom_minimum_size、size_flags、theme_override 等固定属性在 Inspector 里设好，不许脚本里 `node.xxx = yyy`
- **信号连接**：静态信号连接在场景的"信号"面板完成，只有动态信号（运行时才知道目标）才在脚本里 `.connect()`
- **例外**：数据驱动的 UI 列表（如动态列表、运行时生成的内容）是合理的脚本生成场景，因为内容是运行时数据

**Why:** 脚本创建 UI 代码量大、难维护、Inspector 看不到全貌、无法在编辑器里预览布局。场景化后设计师能直接看到结构，改属性不用改代码，也不会出现"脚本创建了但忘记设置某个属性"的 bug。

**How to apply:** 写 `_build_ui()` 或类似函数前先问自己——这个节点结构是固定的还是运行时动态的？固定的就做进场景。只有"数量和内容取决于数据"的部分才留给脚本。
