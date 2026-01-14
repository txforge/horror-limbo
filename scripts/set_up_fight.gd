extends Node2D

signal setup_complete()
signal tile_spawned(tile: Node, row: int, column: int)
signal player_spawned(player: Node)
signal bosses_spawned(bosses: Array[Node])

@export_category("Player Settings")
@export var player_scene: PackedScene

@export_category("Boss Settings")
@export var boss_1_scene: PackedScene
@export var boss_2_scene: PackedScene
@export var boss_3_scene: PackedScene
@export var boss_4_scene: PackedScene
@export var boss_container_path: NodePath = "../Control/sfondo/boss container"

@export_category("Grid Settings")
@export var tile_scene: PackedScene
@export var rows: int = 0
@export var columns: int = 0
@export var visual_scale: int = 4
@export var horizontal_offset_adjustment: float = 0.0

var _tile_size: int = 0
var _grid_offset: Vector2 = Vector2.ZERO
var _player_instance: Node = null
var _boss_instances: Array[Node] = []
var _grid_rows: int = 0
var _grid_columns: int = 0

func _ready() -> void:
	_initialize_grid()
	_setup_entities()
	_emit_setup_complete()

func _initialize_grid() -> void:
	_grid_rows = 5
	_grid_columns = 17
	# Override visual scale if set to 4 - adjust to 6 for better display
	if visual_scale == 4:
		visual_scale = 6
	_tile_size = GameConfig.TILE_SIZE * visual_scale
	_grid_offset = _calculate_grid_offset()

func _setup_entities() -> void:
	_setup_tiles()
	_spawn_player()
	_spawn_bosses()

func _emit_setup_complete() -> void:
	setup_complete.emit()

func _calculate_grid_offset() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var grid_width: float = _grid_columns * _tile_size
	var grid_height: float = _grid_rows * _tile_size

	# Center the grid horizontally and align to bottom
	var x_offset: float = (viewport_size.x - grid_width) / 2.0
	var y_offset: float = viewport_size.y - grid_height

	return Vector2(x_offset, y_offset)

func _setup_tiles() -> void:
	if tile_scene == null:
		push_error("SetUpFight: Tile scene not assigned!")
		return
	for row in range(_grid_rows):
		for column in range(_grid_columns):
			_spawn_tile_at(row, column)

func _spawn_tile_at(row: int, column: int) -> void:
	var tile_instance: Node = tile_scene.instantiate()
	if tile_instance == null:
		return
	add_child(tile_instance)
	# Add half tile size to X for centered positioning
	var x: float = column * _tile_size + (_tile_size / 2.0)
	var y: float = row * _tile_size
	tile_instance.position = Vector2(x, y) + _grid_offset
	tile_instance.scale = Vector2(visual_scale, visual_scale)
	tile_instance.add_to_group(GameConfig.GROUP_TILES)
	if tile_instance.has_method("set_grid_position"):
		tile_instance.set_grid_position(row, column)
	else:
		tile_instance.set_meta("grid_row", row)
		tile_instance.set_meta("grid_column", column)
	tile_spawned.emit(tile_instance, row, column)

func _spawn_player() -> void:
	var center_row: int = int(_grid_rows / 2.0)
	var center_column: int = int(_grid_columns / 2.0)
	_spawn_player_at(center_row, center_column)

func _spawn_player_at(row: int, column: int) -> void:
	if player_scene == null:
		push_error("SetUpFight: Player scene not assigned!")
		return
	if row < 0 or row >= _grid_rows or column < 0 or column >= _grid_columns:
		return
	_player_instance = player_scene.instantiate()
	if _player_instance == null:
		return
	add_child(_player_instance)
	var x: float = column * _tile_size
	var y: float = row * _tile_size
	_player_instance.position = Vector2(x, y) + _grid_offset
	if _player_instance.has_method("set_grid_position"):
		_player_instance.set_grid_position(row, column)
	var player_scale: float = visual_scale * 0.9
	_player_instance.scale = Vector2(player_scale, player_scale)
	_player_instance.add_to_group("player")
	_player_instance.add_to_group("entities")
	player_spawned.emit(_player_instance)

func _spawn_bosses() -> void:
	var boss_container: Node = get_node_or_null(boss_container_path)
	if boss_container == null:
		return
	var boss_configs: Array[Dictionary] = [
		{"name": "Re della Mensa", "scene": boss_1_scene},
		{"name": "Petite Hulk", "scene": boss_2_scene},
		{"name": "Boss dei Tetti", "scene": boss_3_scene},
		{"name": "Presidente", "scene": boss_4_scene}
	]
	_boss_instances.clear()
	for i in range(boss_configs.size()):
		var boss: Node = _spawn_boss(i, boss_configs[i]["name"], boss_configs[i]["scene"], boss_container)
		if boss != null:
			_boss_instances.append(boss)
	bosses_spawned.emit(_boss_instances)

func _spawn_boss(index: int, display_name: String, boss_scene: PackedScene, container: Node) -> Node:
	if boss_scene == null or container == null:
		return null
	var boss_instance: Node = boss_scene.instantiate()
	if boss_instance == null:
		return null
	container.add_child(boss_instance)
	if boss_instance.has_method("set"):
		boss_instance.set("boss_index", index)
		boss_instance.set("boss_name", display_name)
	boss_instance.add_to_group("bosses")
	boss_instance.add_to_group("entities")
	return boss_instance

func get_player() -> Node:
	return _player_instance

func get_bosses() -> Array[Node]:
	return _boss_instances.duplicate()

func get_boss(index: int) -> Node:
	if index < 0 or index >= _boss_instances.size():
		return null
	return _boss_instances[index]

func get_tile_size() -> int:
	return _tile_size

func get_grid_offset() -> Vector2:
	return _grid_offset

func grid_to_world_position(row: int, column: int) -> Vector2:
	var x: float = column * _tile_size
	var y: float = row * _tile_size
	return Vector2(x, y) + _grid_offset
