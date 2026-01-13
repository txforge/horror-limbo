## Fight Setup Manager
## Initializes the game grid, spawns entities, and manages the fight scene setup
## Responsible for creating tiles, player, and bosses in their correct positions
extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when the fight setup is complete
signal setup_complete()

## Emitted when a tile is spawned
signal tile_spawned(tile: Node, row: int, column: int)

## Emitted when the player is spawned
signal player_spawned(player: Node)

## Emitted when all bosses are spawned
signal bosses_spawned(bosses: Array[Node])

# ============================================================================
# EXPORTED VARIABLES - PLAYER
# ============================================================================

@export_category("Player Settings")

## Scene to instantiate for the player
@export var player_scene: PackedScene

# ============================================================================
# EXPORTED VARIABLES - BOSSES
# ============================================================================

@export_category("Boss Settings")

## Boss 1: Re della Mensa
@export var boss_1_scene: PackedScene

## Boss 2: Petite Hulk
@export var boss_2_scene: PackedScene

## Boss 3: Boss dei Tetti
@export var boss_3_scene: PackedScene

## Boss 4: Presidente
@export var boss_4_scene: PackedScene

## Path to the boss container UI node
@export var boss_container_path: NodePath = "../Control/sfondo/boss container"

# ============================================================================
# EXPORTED VARIABLES - GRID
# ============================================================================

@export_category("Grid Settings")

## Scene to instantiate for each tile
@export var tile_scene: PackedScene

## Number of rows (overrides GameConfig if set)
@export var rows: int = 0

## Number of columns (overrides GameConfig if set)
@export var columns: int = 0

## Visual scale multiplier for entities (default 4x)
@export var visual_scale: int = 4

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

## Calculated tile size in pixels (base dimension * scale)
var _tile_size: int = 0

## Offset to center the grid on screen
var _grid_offset: Vector2 = Vector2.ZERO

## Reference to spawned player
var _player_instance: Node = null

## List of spawned bosses
var _boss_instances: Array[Node] = []

## Actual grid dimensions (from export or GameConfig)
var _grid_rows: int = 0
var _grid_columns: int = 0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_initialize_grid()
	_setup_entities()
	_emit_setup_complete()

## Initializes grid parameters
func _initialize_grid() -> void:
	# IMPORTANTE: usa i valori originali dalla versione precedente
	# rows = 5, columns = 17, game_scale = 6 erano hardcoded
	_grid_rows = 5
	_grid_columns = 17

	# Forza visual_scale a 6 se non impostato correttamente
	if visual_scale == 4:  # default value
		visual_scale = 6

	_tile_size = GameConfig.TILE_SIZE * visual_scale
	_grid_offset = _calculate_grid_offset()

## Sets up all entities in the scene
func _setup_entities() -> void:
	_setup_tiles()
	_spawn_player()
	_spawn_bosses()

## Emits setup complete signal
func _emit_setup_complete() -> void:
	setup_complete.emit()

# ============================================================================
# GRID CALCULATION
# ============================================================================

## Calculates grid offset to center the grid on screen
func _calculate_grid_offset() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_center: Vector2 = viewport_size / 2.0

	# Calculate center tile position in grid coordinates
	var center_row: int = _grid_rows / 2
	var center_column: int = _grid_columns / 2

	# Position of center tile in local grid space
	var center_tile_local_pos := Vector2(
		center_column * _tile_size,
		center_row * _tile_size
	)

	# Calculate offset to center the grid
	return screen_center - center_tile_local_pos

# ============================================================================
# TILE SPAWNING
# ============================================================================

## Creates and positions all tiles in the grid
func _setup_tiles() -> void:
	if tile_scene == null:
		push_error("SetUpFight: Tile scene not assigned!")
		return

	for row in range(_grid_rows):
		for column in range(_grid_columns):
			_spawn_tile_at(row, column)

## Spawns a single tile at the specified grid position
func _spawn_tile_at(row: int, column: int) -> void:
	# Instantiate tile
	var tile_instance: Node = tile_scene.instantiate()
	if tile_instance == null:
		push_error("SetUpFight: Failed to instantiate tile at (%d, %d)" % [row, column])
		return

	add_child(tile_instance)

	# Position tile - usa tile_size scalato direttamente
	var x: float = column * _tile_size
	var y: float = row * _tile_size
	tile_instance.position = Vector2(x, y) + _grid_offset

	# Scale tile
	tile_instance.scale = Vector2(visual_scale, visual_scale)

	# Add to group
	tile_instance.add_to_group(GameConfig.GROUP_TILES)

	# Set grid metadata
	if tile_instance.has_method("set_grid_position"):
		tile_instance.set_grid_position(row, column)
	else:
		# Fallback to metadata
		tile_instance.set_meta("grid_row", row)
		tile_instance.set_meta("grid_column", column)

	# Emit signal
	tile_spawned.emit(tile_instance, row, column)

# ============================================================================
# PLAYER SPAWNING
# ============================================================================

## Spawns the player at the center of the grid
func _spawn_player() -> void:
	var center_row: int = _grid_rows / 2
	var center_column: int = _grid_columns / 2

	_spawn_player_at(center_row, center_column)

## Spawns the player at a specific grid position
func _spawn_player_at(row: int, column: int) -> void:
	if player_scene == null:
		push_error("SetUpFight: Player scene not assigned!")
		return

	# Validate position
	if row < 0 or row >= _grid_rows or column < 0 or column >= _grid_columns:
		push_error("SetUpFight: Invalid player spawn position (%d, %d)" % [row, column])
		return

	# Instantiate player
	_player_instance = player_scene.instantiate()
	if _player_instance == null:
		push_error("SetUpFight: Failed to instantiate player")
		return

	add_child(_player_instance)

	# Position player - usa tile_size scalato direttamente
	var x: float = column * _tile_size
	var y: float = row * _tile_size
	_player_instance.position = Vector2(x, y) + _grid_offset

	# Set grid position
	if _player_instance.has_method("set_grid_position"):
		_player_instance.set_grid_position(row, column)

	# Scale player (slightly smaller than tiles for visual distinction)
	var player_scale: float = visual_scale * 0.9
	_player_instance.scale = Vector2(player_scale, player_scale)

	# Add to group
	_player_instance.add_to_group("player")
	_player_instance.add_to_group("entities")

	# Emit signal
	player_spawned.emit(_player_instance)

# ============================================================================
# BOSS SPAWNING
# ============================================================================

## Spawns all bosses in the UI container
func _spawn_bosses() -> void:
	# Get boss container
	var boss_container: Node = get_node_or_null(boss_container_path)
	if boss_container == null:
		push_error("SetUpFight: Boss container not found at path: %s" % boss_container_path)
		return

	# Boss configuration data
	var boss_configs: Array[Dictionary] = [
		{"name": "Re della Mensa", "scene": boss_1_scene},
		{"name": "Petite Hulk", "scene": boss_2_scene},
		{"name": "Boss dei Tetti", "scene": boss_3_scene},
		{"name": "Presidente", "scene": boss_4_scene}
	]

	# Spawn each boss
	_boss_instances.clear()
	for i in range(boss_configs.size()):
		var boss: Node = _spawn_boss(i, boss_configs[i]["name"], boss_configs[i]["scene"], boss_container)
		if boss != null:
			_boss_instances.append(boss)

	# Emit signal
	bosses_spawned.emit(_boss_instances)

## Spawns a single boss with the given configuration
func _spawn_boss(index: int, display_name: String, boss_scene: PackedScene, container: Node) -> Node:
	if boss_scene == null:
		push_error("SetUpFight: Boss %d scene not assigned" % index)
		return null

	if container == null:
		push_error("SetUpFight: Boss container is null")
		return null

	# Instantiate boss
	var boss_instance: Node = boss_scene.instantiate()
	if boss_instance == null:
		push_error("SetUpFight: Failed to instantiate boss %d" % index)
		return null

	container.add_child(boss_instance)

	# Configure boss properties
	if boss_instance.has_method("set"):
		boss_instance.set("boss_index", index)
		boss_instance.set("boss_name", display_name)

	# Add to groups
	boss_instance.add_to_group("bosses")
	boss_instance.add_to_group("entities")

	return boss_instance

# ============================================================================
# PUBLIC API
# ============================================================================

## Returns the spawned player instance
func get_player() -> Node:
	return _player_instance

## Returns all spawned boss instances
func get_bosses() -> Array[Node]:
	return _boss_instances.duplicate()

## Returns a specific boss by index (0-3)
func get_boss(index: int) -> Node:
	if index < 0 or index >= _boss_instances.size():
		push_warning("SetUpFight: Invalid boss index: %d" % index)
		return null

	return _boss_instances[index]

## Returns the calculated tile size in pixels
func get_tile_size() -> int:
	return _tile_size

## Returns the grid offset used for centering
func get_grid_offset() -> Vector2:
	return _grid_offset

## Converts grid coordinates to world position
func grid_to_world_position(row: int, column: int) -> Vector2:
	var x: float = column * _tile_size
	var y: float = row * _tile_size
	return Vector2(x, y) + _grid_offset
