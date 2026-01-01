extends Node2D

@export var move_duration: float = 0.2

@onready var input_buffer_timer: Timer = $InputBuffer

var current_row: int = 2
var current_column: int = 3
var is_moving: bool = false
var buffered_direction: Vector2i = Vector2i.ZERO

func _ready() -> void:
	input_buffer_timer.timeout.connect(_on_buffer_timeout)

func _process(_delta: float) -> void:
	# Check for input
	var direction = Vector2i.ZERO

	if Input.is_action_just_pressed("2D_Up"):
		direction = Vector2i(-1, 0) # Move up (decrease row)
	elif Input.is_action_just_pressed("2D_Down"):
		direction = Vector2i(1, 0) # Move down (increase row)
	elif Input.is_action_just_pressed("2D_Left"):
		direction = Vector2i(0, -1) # Move left (decrease column)
	elif Input.is_action_just_pressed("2D_Right"):
		direction = Vector2i(0, 1) # Move right (increase column)

	if direction != Vector2i.ZERO:
		if is_moving:
			# Buffer the input and start timer
			buffered_direction = direction
			input_buffer_timer.start()
		else:
			try_move(direction)

func try_move(direction: Vector2i) -> void:
	var target_row = current_row + direction.x
	var target_column = current_column + direction.y

	# Find the target tile
	var target_tile = get_tile_at(target_row, target_column)

	if target_tile == null:
		return # Tile doesn't exist

	if is_tile_occupied(target_tile):
		return # Tile is occupied

	# Move to the target tile
	move_to_tile(target_tile, target_row, target_column)

func get_tile_at(row: int, column: int) -> Node:
	var tiles = get_tree().get_nodes_in_group("tiles")
	for tile in tiles:
		if tile.get_meta("grid_row") == row and tile.get_meta("grid_column") == column:
			return tile
	return null

func is_tile_occupied(_tile: Node) -> bool:
	# Check if there's any player or enemy on this tile
	# For now, we'll assume tiles are not occupied
	# You can add logic here to check for other entities
	return false

func move_to_tile(tile: Node, row: int, column: int) -> void:
	is_moving = true
	current_row = row
	current_column = column

	# Create tween for smooth movement
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", tile.position, move_duration)
	tween.finished.connect(_on_movement_finished)

func _on_movement_finished() -> void:
	is_moving = false
	# Check if there's a buffered input to execute
	if buffered_direction != Vector2i.ZERO:
		var direction_to_execute = buffered_direction
		buffered_direction = Vector2i.ZERO
		input_buffer_timer.stop()
		try_move(direction_to_execute)

func _on_buffer_timeout() -> void:
	# Clear buffered input if timer expires
	buffered_direction = Vector2i.ZERO
