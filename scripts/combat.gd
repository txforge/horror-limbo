extends Node

signal pattern_executed(pattern_name: String, affected_tiles: Array[Node])
signal damage_applied(tile: Node, damage: int)

@export var debug_mode: bool = false

var _cached_tiles: Array[Node] = []
var _tile_lookup: Dictionary = {}
var _is_initialized: bool = false

func _ready() -> void:
	await _initialize_combat_system()

func _initialize_combat_system() -> void:
	await get_tree().process_frame
	_cache_tiles()
	_is_initialized = true
	if debug_mode:
		_run_debug_pattern()

func _cache_tiles() -> void:
	_cached_tiles = get_tree().get_nodes_in_group(GameConfig.GROUP_TILES)
	for tile in _cached_tiles:
		if not tile.has_meta("grid_row") or not tile.has_meta("grid_column"):
			continue
		var row: int = tile.get_meta("grid_row")
		var column: int = tile.get_meta("grid_column")
		var key: String = GameConfig.grid_position_to_key(row, column)
		_tile_lookup[key] = tile

func _run_debug_pattern() -> void:
	print("Combat: Running debug checkerboard pattern")
	target_checkerboard(false)

func get_tile_at(row: int, column: int) -> Node:
	var key: String = GameConfig.grid_position_to_key(row, column)
	return _tile_lookup.get(key, null)

func get_tiles_in_row(row_index: int) -> Array[Node]:
	var tiles: Array[Node] = []
	for tile in _cached_tiles:
		if tile.has_meta("grid_row") and tile.get_meta("grid_row") == row_index:
			tiles.append(tile)
	return tiles

func get_tiles_in_column(column_index: int) -> Array[Node]:
	var tiles: Array[Node] = []
	for tile in _cached_tiles:
		if tile.has_meta("grid_column") and tile.get_meta("grid_column") == column_index:
			tiles.append(tile)
	return tiles

func target_single_tile(tile: Node, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if not _validate_tile(tile):
		return
	if tile.has_method("target_highlight"):
		tile.target_highlight(duration)
	pattern_executed.emit("single_tile", [tile])

func target_column(column_index: int, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if not GameConfig.is_valid_grid_position(0, column_index):
		return
	var targeted_tiles: Array[Node] = []
	for tile in _cached_tiles:
		if tile.has_meta("grid_column") and tile.get_meta("grid_column") == column_index:
			if tile.has_method("target_highlight"):
				tile.target_highlight(duration)
				targeted_tiles.append(tile)
	pattern_executed.emit("column_%d" % column_index, targeted_tiles)

func target_row(row_index: int, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if not GameConfig.is_valid_grid_position(row_index, 0):
		return
	var targeted_tiles: Array[Node] = []
	for tile in _cached_tiles:
		if tile.has_meta("grid_row") and tile.get_meta("grid_row") == row_index:
			if tile.has_method("target_highlight"):
				tile.target_highlight(duration)
				targeted_tiles.append(tile)
	pattern_executed.emit("row_%d" % row_index, targeted_tiles)

func target_checkerboard(start_from_0: bool = true, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var targeted_tiles: Array[Node] = []
	var expected_remainder: int = 0 if start_from_0 else 1
	for tile in _cached_tiles:
		if not tile.has_meta("grid_row") or not tile.has_meta("grid_column"):
			continue
		var row: int = tile.get_meta("grid_row")
		var column: int = tile.get_meta("grid_column")
		if (row + column) % 2 == expected_remainder:
			if tile.has_method("target_highlight"):
				tile.target_highlight(duration)
				targeted_tiles.append(tile)
	var pattern_name: String = "checkerboard_white" if start_from_0 else "checkerboard_black"
	pattern_executed.emit(pattern_name, targeted_tiles)

func target_cross(center_row: int, center_column: int, radius: int = 1, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var targeted_tiles: Array[Node] = []
	for col in range(center_column - radius, center_column + radius + 1):
		var tile: Node = get_tile_at(center_row, col)
		if tile != null and tile.has_method("target_highlight"):
			tile.target_highlight(duration)
			targeted_tiles.append(tile)
	for row in range(center_row - radius, center_row + radius + 1):
		if row == center_row:
			continue
		var tile: Node = get_tile_at(row, center_column)
		if tile != null and tile.has_method("target_highlight"):
			tile.target_highlight(duration)
			targeted_tiles.append(tile)
	pattern_executed.emit("cross", targeted_tiles)

func target_x_pattern(center_row: int, center_column: int, radius: int = 1, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var targeted_tiles: Array[Node] = []
	for i in range(-radius, radius + 1):
		var tile1: Node = get_tile_at(center_row + i, center_column + i)
		if tile1 != null and tile1.has_method("target_highlight"):
			tile1.target_highlight(duration)
			if tile1 not in targeted_tiles:
				targeted_tiles.append(tile1)
		var tile2: Node = get_tile_at(center_row + i, center_column - i)
		if tile2 != null and tile2.has_method("target_highlight"):
			tile2.target_highlight(duration)
			if tile2 not in targeted_tiles:
				targeted_tiles.append(tile2)
	pattern_executed.emit("x_pattern", targeted_tiles)

func target_area(start_row: int, start_column: int, width: int, height: int, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var targeted_tiles: Array[Node] = []
	for row in range(start_row, start_row + height):
		for col in range(start_column, start_column + width):
			var tile: Node = get_tile_at(row, col)
			if tile != null and tile.has_method("target_highlight"):
				tile.target_highlight(duration)
				targeted_tiles.append(tile)
	pattern_executed.emit("area", targeted_tiles)

func target_random(count: int, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if count <= 0:
		return
	var available_tiles: Array[Node] = _cached_tiles.duplicate()
	var targeted_tiles: Array[Node] = []
	for i in range(min(count, available_tiles.size())):
		var random_index: int = randi() % available_tiles.size()
		var tile: Node = available_tiles[random_index]
		if tile.has_method("target_highlight"):
			tile.target_highlight(duration)
			targeted_tiles.append(tile)
		available_tiles.remove_at(random_index)
	pattern_executed.emit("random_%d" % count, targeted_tiles)

func dmg_on_tile(tile: Node, damage: int = GameConfig.DEFAULT_DAMAGE, hitbox_duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if not _validate_tile(tile) or damage <= 0:
		return
	if tile.has_method("apply_hitbox"):
		tile.apply_hitbox(hitbox_duration)
	damage_applied.emit(tile, damage)

func dmg_on_tiles(tiles: Array[Node], damage: int = GameConfig.DEFAULT_DAMAGE, hitbox_duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	for tile in tiles:
		dmg_on_tile(tile, damage, hitbox_duration)

func _validate_tile(tile: Node) -> bool:
	if tile == null or not is_instance_valid(tile):
		return false
	if not tile.is_in_group(GameConfig.GROUP_TILES):
		return false
	return true

func is_ready() -> bool:
	return _is_initialized

func get_tile_count() -> int:
	return _cached_tiles.size()

func clear_all_effects() -> void:
	for tile in _cached_tiles:
		if tile.has_method("stop_all_effects"):
			tile.stop_all_effects()

func recache_tiles() -> void:
	_cache_tiles()
