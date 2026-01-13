## Player Controller
## Handles player movement on the grid with input buffering and smooth animations
## Uses a tile-based coordinate system for precise grid movement
extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when the player moves to a new tile
signal moved(from_position: Vector2i, to_position: Vector2i)

## Emitted when the player takes damage
signal damaged(amount: int, current_health: int)

## Emitted when the player is defeated
signal defeated()

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

## Maximum health points
@export var max_health: int = 100

## Current health points (for debugging/save system)
@export var current_health: int = 100

# ============================================================================
# NODE REFERENCES
# ============================================================================

@onready var _input_buffer_timer: Timer = $InputBuffer
@onready var _sprite: Sprite2D = $Sprite2D

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

## Current grid row position
var _current_row: int = -1

## Current grid column position
var _current_column: int = -1

## Whether the player is currently moving
var _is_moving: bool = false

## Buffered input direction to execute after current movement
var _buffered_direction: Vector2i = Vector2i.ZERO

## Cached tile references for O(1) lookups
var _tile_cache: Dictionary = {}

## Reference to InputManager singleton
var _input_manager: Node = null

## Current movement tween
var _movement_tween: Tween = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_validate_nodes()
	_setup_input_buffer()
	_connect_to_input_manager()
	_cache_tiles()

## Validates that all required nodes exist
func _validate_nodes() -> void:
	if _input_buffer_timer == null:
		push_error("Player: InputBuffer Timer not found! Add a Timer node named 'InputBuffer'")

	if _sprite == null:
		push_warning("Player: Sprite2D not found - player will be invisible")

## Sets up the input buffer timer
func _setup_input_buffer() -> void:
	if _input_buffer_timer == null:
		return

	_input_buffer_timer.wait_time = GameConfig.INPUT_BUFFER_DURATION
	_input_buffer_timer.one_shot = true

	if not _input_buffer_timer.timeout.is_connected(_on_buffer_timeout):
		_input_buffer_timer.timeout.connect(_on_buffer_timeout)

## Connects to the InputManager singleton
func _connect_to_input_manager() -> void:
	# Get InputManager from autoload
	_input_manager = get_node_or_null("/root/InputManager")

	if _input_manager == null:
		push_warning("Player: InputManager singleton not found - using fallback input")
		return

	# Connect to movement signal
	if not _input_manager.movement_requested.is_connected(_on_movement_requested):
		_input_manager.movement_requested.connect(_on_movement_requested)

## Caches all tiles for efficient lookup
func _cache_tiles() -> void:
	# Wait one frame to ensure tiles are spawned
	await get_tree().process_frame

	var tiles: Array[Node] = get_tree().get_nodes_in_group(GameConfig.GROUP_TILES)

	if tiles.is_empty():
		push_warning("Player: No tiles found in scene - movement will not work")
		return

	# Build cache dictionary
	for tile in tiles:
		if not tile.has_meta("grid_row") or not tile.has_meta("grid_column"):
			push_warning("Player: Tile missing grid metadata - skipping")
			continue

		var row: int = tile.get_meta("grid_row")
		var column: int = tile.get_meta("grid_column")
		var key := Vector2i(row, column)
		_tile_cache[key] = tile

# ============================================================================
# INPUT HANDLING (FALLBACK)
# ============================================================================

# Input processing è gestito da InputManager singleton
# Non c'è bisogno di _process qui

# ============================================================================
# MOVEMENT SYSTEM
# ============================================================================

## Called when InputManager requests movement
func _on_movement_requested(direction: Vector2i) -> void:
	if _is_moving:
		# Buffer the input and start timer
		_buffered_direction = direction
		if _input_buffer_timer != null:
			_input_buffer_timer.start()
	else:
		_try_move(direction)

## Attempts to move in the specified direction
func _try_move(direction: Vector2i) -> void:
	var target_row: int = _current_row + direction.y
	var target_column: int = _current_column + direction.x

	# Validate target position is within grid bounds
	if not GameConfig.is_valid_grid_position(target_row, target_column):
		return

	# Get target tile
	var target_tile: Node = _get_tile_at(target_row, target_column)

	if target_tile == null:
		push_warning("Player: Target tile (%d, %d) not found in cache" % [target_row, target_column])
		return

	# Check if tile is occupied
	if _is_tile_occupied(target_tile):
		return

	# Execute movement
	_move_to_tile(target_tile, target_row, target_column)

## Moves the player to the specified tile
func _move_to_tile(tile: Node, row: int, column: int) -> void:
	var old_position := Vector2i(_current_row, _current_column)

	_is_moving = true
	_current_row = row
	_current_column = column

	# Cancel any existing tween
	if _movement_tween != null and _movement_tween.is_running():
		_movement_tween.kill()

	# Create new tween for smooth movement
	_movement_tween = create_tween()
	_movement_tween.set_ease(GameConfig.MOVE_TWEEN_EASE)
	_movement_tween.set_trans(GameConfig.MOVE_TWEEN_TRANS)
	_movement_tween.tween_property(
		self,
		"position",
		tile.position,
		GameConfig.MOVE_ANIMATION_DURATION
	)
	_movement_tween.finished.connect(_on_movement_finished)

	# Emit signal
	moved.emit(old_position, Vector2i(row, column))

## Called when movement animation finishes
func _on_movement_finished() -> void:
	_is_moving = false

	# Process buffered input if exists
	if _buffered_direction != Vector2i.ZERO:
		var direction_to_execute := _buffered_direction
		_buffered_direction = Vector2i.ZERO

		if _input_buffer_timer != null:
			_input_buffer_timer.stop()

		_try_move(direction_to_execute)

## Called when input buffer timer times out
func _on_buffer_timeout() -> void:
	_buffered_direction = Vector2i.ZERO

# ============================================================================
# TILE QUERIES
# ============================================================================

## Gets tile at specified grid position (O(1) lookup)
func _get_tile_at(row: int, column: int) -> Node:
	var key := Vector2i(row, column)
	return _tile_cache.get(key, null)

## Checks if a tile is occupied by another entity
func _is_tile_occupied(tile: Node) -> bool:
	# Check if tile has any occupants via metadata
	if tile.has_meta("occupied_by"):
		var occupant: Node = tile.get_meta("occupied_by")
		if occupant != null and is_instance_valid(occupant) and occupant != self:
			return true

	# Additional check: look for entities at this tile position
	# This is a fallback in case metadata is not set correctly
	var entities_at_tile: Array[Node] = get_tree().get_nodes_in_group("entities")
	for entity in entities_at_tile:
		if entity == self or not is_instance_valid(entity):
			continue

		# Check if entity has grid position
		if entity.has_method("get_grid_position"):
			var entity_pos: Vector2i = entity.get_grid_position()
			if entity_pos == Vector2i(_current_row, _current_column):
				return true

	return false

# ============================================================================
# COMBAT SYSTEM
# ============================================================================

## Applies damage to the player
func take_damage(amount: int) -> void:
	if current_health <= 0:
		return  # Already dead

	current_health = max(0, current_health - amount)

	# Emit damage signal
	damaged.emit(amount, current_health)

	# Visual feedback (optional - can be connected to animation)
	_flash_damage_effect()

	# Check for defeat
	if current_health <= 0:
		_on_defeated()

## Heals the player
func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)

## Visual feedback for taking damage
func _flash_damage_effect() -> void:
	if _sprite == null:
		return

	# Flash red briefly
	var original_modulate: Color = _sprite.modulate
	_sprite.modulate = Color.RED

	await get_tree().create_timer(0.1).timeout

	if _sprite != null and is_instance_valid(_sprite):
		_sprite.modulate = original_modulate

## Called when player is defeated
func _on_defeated() -> void:
	defeated.emit()
	# Disable input processing
	set_process(false)

	# Optional: play death animation
	# Optional: disable collision

# ============================================================================
# PUBLIC API
# ============================================================================

## Sets the player's grid position (called during spawn)
func set_grid_position(row: int, column: int) -> void:
	if not GameConfig.is_valid_grid_position(row, column):
		push_error("Player: Invalid grid position (%d, %d)" % [row, column])
		return

	_current_row = row
	_current_column = column

	# Update tile occupation metadata
	var tile: Node = _get_tile_at(row, column)
	if tile != null:
		tile.set_meta("occupied_by", self)

## Gets the player's current grid position
func get_grid_position() -> Vector2i:
	return Vector2i(_current_row, _current_column)

## Returns whether the player is currently moving
func is_moving() -> bool:
	return _is_moving

## Gets player health percentage (0.0 - 1.0)
func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

## Forcefully stops any current movement
func stop_movement() -> void:
	if _movement_tween != null and _movement_tween.is_running():
		_movement_tween.kill()

	_is_moving = false
	_buffered_direction = Vector2i.ZERO

	if _input_buffer_timer != null:
		_input_buffer_timer.stop()
