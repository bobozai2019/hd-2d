extends Node3D

@onready var _camera: Camera3D = $CameraRig/Camera3D
@onready var _info_label: Label3D = $InfoLabel


func _ready() -> void:
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_info_label.text = "Hex Map MVP Placeholder"
