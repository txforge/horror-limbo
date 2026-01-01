extends Camera3D

@onready var path_follow = get_parent() # Gets the PathFollow3D node

func _process(delta):
    path_follow.progress_ratio += 0.1 * delta # Adjust speed here (0.0 to 1.0)
    # Or use path_follow.progress += 1.0 * delta for units
