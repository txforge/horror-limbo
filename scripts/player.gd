extends Node2D

signal moved(from_position: Vector2i, to_position: Vector2i)
signal damaged(amount: int, current_health: int)
signal defeated()

@export var max_health: int = 100
@export var current_health: int = 100

@onready var _input_buffer_timer: Timer = $InputBuffer
@onready var _sprite: Sprite2D = $Sprite2D

var _current_row: int = -1
var _current_column: int = -1
var _is_moving: bool = false
var _buffered_direction: Vector2i = Vector2i.ZERO
var _tile_cache: Dictionary = {}
var _entities_cache: Array[Node] = []
var _input_manager: Node = null
var _movement_tween: Tween = null

func _ready() -> void:
	_validate_nodes()
	_setup_input_buffer()
	_connect_to_input_manager()
	_cache_tiles()
	_cache_entities()

func _validate_nodes() -> void:
	if _input_buffer_timer == null:
		push_error("Player: InputBuffer Timer not found")
	if _sprite == null:
		push_warning("Player: Sprite2D not found")

func _setup_input_buffer() -> void:
	if _input_buffer_timer == null:
		return
	_input_buffer_timer.wait_time = GameConfig.INPUT_BUFFER_DURATION
	_input_buffer_timer.one_shot = true
	if not _input_buffer_timer.timeout.is_connected(_on_buffer_timeout):
		_input_buffer_timer.timeout.connect(_on_buffer_timeout)

func _connect_to_input_manager() -> void:
	_input_manager = get_node_or_null("/root/InputManager")
	if _input_manager == null:
		push_warning("Player: InputManager singleton not found")
		return
	if not _input_manager.movement_requested.is_connected(_on_movement_requested):
		_input_manager.movement_requested.connect(_on_movement_requested)

func _cache_tiles() -> void:
	await get_tree().process_frame
	var tiles: Array[Node] = get_tree().get_nodes_in_group(GameConfig.GROUP_TILES)
	if tiles.is_empty():
		push_warning("Player: No tiles found")
		return
	for tile in tiles:
		if not tile.has_meta("grid_row") or not tile.has_meta("grid_column"):
			continue
		var row: int = tile.get_meta("grid_row")
		var column: int = tile.get_meta("grid_column")
		var key := Vector2i(row, column)
		_tile_cache[key] = tile

func _cache_entities() -> void:
	await get_tree().process_frame
	_entities_cache = get_tree().get_nodes_in_group("entities")
	if _entities_cache.is_empty():
		push_warning("Player: No entities found")

func _on_movement_requested(direction: Vector2i) -> void:
	if _is_moving:
		_buffered_direction = direction
		if _input_buffer_timer != null:
			_input_buffer_timer.start()
	else:
		_try_move(direction)

func _try_move(direction: Vector2i) -> void:
	var target_row: int = _current_row + direction.y
	var target_column: int = _current_column + direction.x
	if not GameConfig.is_valid_grid_position(target_row, target_column):
		return
	var target_tile: Node = _get_tile_at(target_row, target_column)
	if target_tile == null or _is_tile_occupied(target_tile):
		return
	_move_to_tile(target_tile, target_row, target_column)

func _move_to_tile(tile: Node, row: int, column: int) -> void:
	var old_position := Vector2i(_current_row, _current_column)
	_is_moving = true
	_current_row = row
	_current_column = column
	if _movement_tween != null and _movement_tween.is_running():
		_movement_tween.kill()
	_movement_tween = create_tween()
	_movement_tween.set_ease(GameConfig.MOVE_TWEEN_EASE)
	_movement_tween.set_trans(GameConfig.MOVE_TWEEN_TRANS)
	_movement_tween.tween_property(self, "position", tile.position, GameConfig.MOVE_ANIMATION_DURATION)
	_movement_tween.finished.connect(_on_movement_finished)
	moved.emit(old_position, Vector2i(row, column))

func _on_movement_finished() -> void:
	_is_moving = false
	if _buffered_direction != Vector2i.ZERO:
		var direction_to_execute := _buffered_direction
		_buffered_direction = Vector2i.ZERO
		if _input_buffer_timer != null:
			_input_buffer_timer.stop()
		_try_move(direction_to_execute)

func _on_buffer_timeout() -> void:
	_buffered_direction = Vector2i.ZERO

func _get_tile_at(row: int, column: int) -> Node:
	var key := Vector2i(row, column)
	return _tile_cache.get(key, null)

func _is_tile_occupied(tile: Node) -> bool:
	if tile.has_meta("occupied_by"):
		var occupant: Node = tile.get_meta("occupied_by")
		if occupant != null and is_instance_valid(occupant) and occupant != self:
			return true
	for entity in _entities_cache:
		if entity == self or not is_instance_valid(entity):
			continue
		if entity.has_method("get_grid_position"):
			var entity_pos: Vector2i = entity.get_grid_position()
			var tile_pos: Vector2i = Vector2i(tile.get_meta("grid_row", -1), tile.get_meta("grid_column", -1))
			if entity_pos == tile_pos:
				return true
	return false

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = max(0, current_health - amount)
	damaged.emit(amount, current_health)
	_flash_damage_effect()
	if current_health <= 0:
		_on_defeated()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)

func _flash_damage_effect() -> void:
	if _sprite == null:
		return
	var original_modulate: Color = _sprite.modulate
	_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if _sprite != null and is_instance_valid(_sprite):
		_sprite.modulate = original_modulate

func _on_defeated() -> void:
	defeated.emit()
	set_process(false)

func set_grid_position(row: int, column: int) -> void:
	if not GameConfig.is_valid_grid_position(row, column):
		push_error("Player: Invalid grid position (%d, %d)" % [row, column])
		return
	_current_row = row
	_current_column = column
	var tile: Node = _get_tile_at(row, column)
	if tile != null:
		tile.set_meta("occupied_by", self)

func get_grid_position() -> Vector2i:
	return Vector2i(_current_row, _current_column)

func is_moving() -> bool:
	return _is_moving

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func stop_movement() -> void:
	if _movement_tween != null and _movement_tween.is_running():
		_movement_tween.kill()
	_is_moving = false
	_buffered_direction = Vector2i.ZERO
	if _input_buffer_timer != null:
		_input_buffer_timer.stop()
