extends AnimatedSprite3D

var camera: Camera3D

func _ready() -> void:
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		camera = cameras[0] as Camera3D

func _process(_delta: float) -> void:
	if not camera:
		return

	look_at(camera.position, Vector3.UP)
