extends Path3D

@export var RADIUS = 5.0 # Adjust this for your desired circle size
@export var NUM_POINTS = 128 # More points for a smoother circle

func _ready():
	# Ensure the curve is fresh
	curve = Curve3D.new()
	
	# Add points for a circle
	for i in range(NUM_POINTS +1): # +1 to close the loop
		var angle = float(i) / NUM_POINTS * TAU # TAU is 2 * PI
		var x = cos(angle) * RADIUS
		var y = 0.0 # Keep it flat on the XZ plane (or XY if 2D)
		var z = sin(angle) * RADIUS

		# Calculate tangent for smooth circular motion
		var tangent_angle = angle + PI / 2
		var tangent = Vector3(cos(tangent_angle), 0, sin(tangent_angle)) * RADIUS * 0.5

		curve.add_point(Vector3(x, y, z), -tangent, tangent)

	# Set the curve on the Path3D node
	self.curve = curve