extends Node3D

@export var radius: float = 5.0  # Adjust this for your desired circle size
@export var num_desks: int = 5  # Number of desks to spawn
@export var starting_angle_degrees: float = 0.0  # Angle offset in degrees

var desk_positions: Array = []  # Cached positions to avoid recalculation

func _ready() -> void:
	desk_positions = _calculate_desk_positions()
	_spawn_desks()

func _calculate_desk_positions() -> Array:
	var positions: Array = []
	var angle_offset = deg_to_rad(starting_angle_degrees)

	for i in range(num_desks):
		var angle = float(i) / num_desks * TAU + angle_offset  # TAU is 2 * PI
		var x = cos(angle) * radius
		var y = 0.0  # Keep it flat on the XZ plane
		var z = sin(angle) * radius
		positions.append(Vector3(x, y, z))

	return positions

func _spawn_desks() -> void:
	for desk_position in desk_positions:
		var desk_instance = preload("res://scenes/Desk.tscn").instantiate()
		add_child(desk_instance)
		desk_instance.look_at_from_position(desk_position, self.position, Vector3.UP)
