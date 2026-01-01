extends AnimatedSprite3D

var camera : Camera3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera = get_tree().get_nodes_in_group("camera")[0] as Camera3D
	print(camera)
	pass # Replace with function body.

func _process(_delta: float) -> void:
	look_at(camera.global_transform.origin, Vector3.UP)
	pass # Replace with function body.
