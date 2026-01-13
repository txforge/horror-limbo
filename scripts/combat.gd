## Combat Controller
## Manages targeting patterns and damage application for boss attacks
## Provides various tile targeting strategies (single, row, column, patterns)
extends Node

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when a tile targeting pattern is executed
signal pattern_executed(pattern_name: String, affected_tiles: Array[Node])

## Emitted when damage is applied to a tile
signal damage_applied(tile: Node, damage: int)

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

## Whether to enable debug visual effects
@export var debug_mode: bool = false

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

## Cached references to all tiles in the grid
var _cached_tiles: Array[Node] = []

## Dictionary for O(1) tile lookups by grid position
var _tile_lookup: Dictionary = {}

## Whether the combat system is initialized
var _is_initialized: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	await _initialize_combat_system()

## Initializes the combat system by caching tiles
func _initialize_combat_system() -> void:
	# Wait for tiles to be spawned
	await get_tree().process_frame

	_cache_tiles()
	_is_initialized = true

	# DEBUG: Execute test pattern if in debug mode
	if debug_mode:
		_run_debug_pattern()

## Caches all tiles for efficient lookup
func _cache_tiles() -> void:
	_cached_tiles = get_tree().get_nodes_in_group(GameConfig.GROUP_TILES)

	# Build lookup dictionary
	for tile in _cached_tiles:
		if not tile.has_meta("grid_row") or not tile.has_meta("grid_column"):
			push_warning("Combat: Tile missing grid metadata - skipping")
			continue

		var row: int = tile.get_meta("grid_row")
		var column: int = tile.get_meta("grid_column")
		var key: String = GameConfig.grid_position_to_key(row, column)
		_tile_lookup[key] = tile

## Runs a debug targeting pattern
func _run_debug_pattern() -> void:
	print("Combat: Running debug checkerboard pattern")
	target_checkerboard(false)

# ============================================================================
# TILE LOOKUP
# ============================================================================

## Gets a tile at the specified grid position
func get_tile_at(row: int, column: int) -> Node:
	var key: String = GameConfig.grid_position_to_key(row, column)
	return _tile_lookup.get(key, null)

## Gets all tiles in a specific row
func get_tiles_in_row(row_index: int) -> Array[Node]:
	var tiles: Array[Node] = []

	for tile in _cached_tiles:
		if tile.has_meta("grid_row") and tile.get_meta("grid_row") == row_index:
			tiles.append(tile)

	return tiles

## Gets all tiles in a specific column
func get_tiles_in_column(column_index: int) -> Array[Node]:
	var tiles: Array[Node] = []

	for tile in _cached_tiles:
		if tile.has_meta("grid_column") and tile.get_meta("grid_column") == column_index:
			tiles.append(tile)

	return tiles

# ============================================================================
# TARGETING PATTERNS
# ============================================================================

## Targets a single tile with highlight
func target_single_tile(tile: Node, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if not _validate_tile(tile):
		return

	if tile.has_method("target_highlight"):
		tile.target_highlight(duration)
	else:
		push_warning("Combat: Tile does not have target_highlight method")

	# Emit signal
	pattern_executed.emit("single_tile", [tile])

## Targets an entire column of tiles
func target_column(column_index: int, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if not GameConfig.is_valid_grid_position(0, column_index):
		push_error("Combat: Invalid column index: %d" % column_index)
		return

	var targeted_tiles: Array[Node] = []

	for tile in _cached_tiles:
		if tile.has_meta("grid_column") and tile.get_meta("grid_column") == column_index:
			if tile.has_method("target_highlight"):
				tile.target_highlight(duration)
				targeted_tiles.append(tile)

	# Emit signal
	pattern_executed.emit("column_%d" % column_index, targeted_tiles)

## Targets an entire row of tiles
func target_row(row_index: int, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if not GameConfig.is_valid_grid_position(row_index, 0):
		push_error("Combat: Invalid row index: %d" % row_index)
		return

	var targeted_tiles: Array[Node] = []

	for tile in _cached_tiles:
		if tile.has_meta("grid_row") and tile.get_meta("grid_row") == row_index:
			if tile.has_method("target_highlight"):
				tile.target_highlight(duration)
				targeted_tiles.append(tile)

	# Emit signal
	pattern_executed.emit("row_%d" % row_index, targeted_tiles)

## Targets tiles in a checkerboard pattern
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

	# Emit signal
	var pattern_name: String = "checkerboard_white" if start_from_0 else "checkerboard_black"
	pattern_executed.emit(pattern_name, targeted_tiles)

## Targets tiles in a cross pattern (plus sign) centered at a position
func target_cross(center_row: int, center_column: int, radius: int = 1, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var targeted_tiles: Array[Node] = []

	# Horizontal line
	for col in range(center_column - radius, center_column + radius + 1):
		var tile: Node = get_tile_at(center_row, col)
		if tile != null and tile.has_method("target_highlight"):
			tile.target_highlight(duration)
			targeted_tiles.append(tile)

	# Vertical line
	for row in range(center_row - radius, center_row + radius + 1):
		if row == center_row:
			continue  # Skip center (already done in horizontal)

		var tile: Node = get_tile_at(row, center_column)
		if tile != null and tile.has_method("target_highlight"):
			tile.target_highlight(duration)
			targeted_tiles.append(tile)

	# Emit signal
	pattern_executed.emit("cross", targeted_tiles)

## Targets tiles in an X pattern (diagonal cross) centered at a position
func target_x_pattern(center_row: int, center_column: int, radius: int = 1, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var targeted_tiles: Array[Node] = []

	# Diagonal lines
	for i in range(-radius, radius + 1):
		# Top-left to bottom-right diagonal
		var tile1: Node = get_tile_at(center_row + i, center_column + i)
		if tile1 != null and tile1.has_method("target_highlight"):
			tile1.target_highlight(duration)
			if tile1 not in targeted_tiles:
				targeted_tiles.append(tile1)

		# Top-right to bottom-left diagonal
		var tile2: Node = get_tile_at(center_row + i, center_column - i)
		if tile2 != null and tile2.has_method("target_highlight"):
			tile2.target_highlight(duration)
			if tile2 not in targeted_tiles:
				targeted_tiles.append(tile2)

	# Emit signal
	pattern_executed.emit("x_pattern", targeted_tiles)

## Targets a rectangular area of tiles
func target_area(start_row: int, start_column: int, width: int, height: int, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var targeted_tiles: Array[Node] = []

	for row in range(start_row, start_row + height):
		for col in range(start_column, start_column + width):
			var tile: Node = get_tile_at(row, col)
			if tile != null and tile.has_method("target_highlight"):
				tile.target_highlight(duration)
				targeted_tiles.append(tile)

	# Emit signal
	pattern_executed.emit("area", targeted_tiles)

## Targets random tiles
func target_random(count: int, duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if count <= 0:
		push_warning("Combat: Invalid count for random targeting: %d" % count)
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

	# Emit signal
	pattern_executed.emit("random_%d" % count, targeted_tiles)

# ============================================================================
# DAMAGE APPLICATION
# ============================================================================

## Applies damage to a specific tile
func dmg_on_tile(tile: Node, damage: int = GameConfig.DEFAULT_DAMAGE, hitbox_duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	if not _validate_tile(tile):
		return

	if damage <= 0:
		push_warning("Combat: Invalid damage amount: %d" % damage)
		return

	# Apply hitbox to tile
	if tile.has_method("apply_hitbox"):
		tile.apply_hitbox(hitbox_duration)
	else:
		push_warning("Combat: Tile does not have apply_hitbox method")

	# Emit signal
	damage_applied.emit(tile, damage)

## Applies damage to multiple tiles
func dmg_on_tiles(tiles: Array[Node], damage: int = GameConfig.DEFAULT_DAMAGE, hitbox_duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	for tile in tiles:
		dmg_on_tile(tile, damage, hitbox_duration)

# ============================================================================
# VALIDATION
# ============================================================================

## Validates that a tile is valid for combat operations
func _validate_tile(tile: Node) -> bool:
	if tile == null:
		push_warning("Combat: Null tile provided")
		return false

	if not is_instance_valid(tile):
		push_warning("Combat: Invalid tile instance")
		return false

	if not tile.is_in_group(GameConfig.GROUP_TILES):
		push_warning("Combat: Node is not in tiles group")
		return false

	return true

# ============================================================================
# PUBLIC API
# ============================================================================

## Returns whether the combat system is ready
func is_ready() -> bool:
	return _is_initialized

## Returns the number of cached tiles
func get_tile_count() -> int:
	return _cached_tiles.size()

## Clears all active tile effects
func clear_all_effects() -> void:
	for tile in _cached_tiles:
		if tile.has_method("stop_all_effects"):
			tile.stop_all_effects()

## Forces a recache of tiles (useful if tiles are added/removed dynamically)
func recache_tiles() -> void:
	_cache_tiles()
