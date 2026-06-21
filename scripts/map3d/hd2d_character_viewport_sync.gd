extends Node3D

## 最小化 SubViewport 同步：World3D 共享 + 相机 transform 同步。
## RemoteTransform3D 跨 SubViewport 失效，own_world_3d=false 不自动继承，
## 因此必须用脚本处理这两项。

var _viewport: SubViewport
var _char_cam: Camera3D
var _main_cam: Camera3D

func _ready() -> void:
	_viewport = get_node(^"../CharacterViewport") as SubViewport
	_char_cam = get_node(^"../CharacterViewport/CharacterCamera") as Camera3D
	_main_cam = get_node(^"../CameraRig/Camera3D") as Camera3D
	if _viewport:
		_viewport.world_3d = get_viewport().world_3d

func _process(_delta: float) -> void:
	if _char_cam and _main_cam:
		_char_cam.global_transform = _main_cam.global_transform
