extends Node3D

@export var RADIUS = 5.0 # Adjust this for your desired circle size
@export var NUM_POINTS = 5 # More points for a smoother circle
@export var STARTING_ANGLE = 0.0 # Angle offset in radians siccome noi vorremmo ottenere z = 90 per il primo punto usiamo -18 perche la creazione lo porterebbe a -72 e -72 -18 = -90

func _ready():
	calculate_points()
	Spawn_Desk()	
	
func calculate_points() -> Array:
	var points : Array = []
	var angle_offset = deg_to_rad(STARTING_ANGLE) # Converti gradi in radianti
	for i in range(NUM_POINTS + 1): # +1 to close the loop
		var angle = float(i) / NUM_POINTS * TAU + angle_offset # TAU is 2 * PI
		var x = cos(angle) * RADIUS
		var y = 0.0 # Keep it flat on the XZ plane (or XY if 2D)
		var z = sin(angle) * RADIUS
		points.append(Vector3(x, y, z))
	return points

func Spawn_Desk():
	var points = calculate_points()
	for point in points:
		var desk_instance = preload("res://Desk.tscn").instantiate()
		add_child(desk_instance)
		desk_instance.look_at_from_position(point, self.position, Vector3.UP)
