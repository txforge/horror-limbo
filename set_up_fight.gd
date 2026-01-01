extends Node2D


@export_category("Player Settings")
@export var player_scene: PackedScene

@export_category("General Settings")
@export var base_dimension: int = 16
@export var game_scale: int = 4

@export_category("Tile Grid Settings")
@export var tile_scene: PackedScene
@export var rows: int = 5
@export var columns: int = 7
@export var bottom_margin: int = 5

var tile_size: int

func _ready() -> void:
	tile_size = base_dimension * game_scale
	set_up_tiles()
	spawn_player_at_tile(2, 3) # Spawn player at center tile (row 2, column 3)

func set_up_tiles() -> void:
	# Calculate the offset to position grid at bottom with margin
	var viewport_size = get_viewport_rect().size
	var grid_size = Vector2(columns * tile_size, rows * tile_size)

	# Center horizontally, align to bottom with margin
	var offset = Vector2(
		(viewport_size.x - grid_size.x) / 2,
		viewport_size.y - grid_size.y - bottom_margin
	)

	for row in range(rows):
		for column in range(columns):
			var tile_instance = tile_scene.instantiate()
			add_child(tile_instance)
			tile_instance.position = Vector2(column * tile_size, row * tile_size) + offset

			# Scale the tile according to game_scale
			tile_instance.scale = Vector2(game_scale, game_scale)

			# Add tile to group and store grid coordinates
			tile_instance.add_to_group("tiles")
			tile_instance.set_meta("grid_row", row)
			tile_instance.set_meta("grid_column", column)

func spawn_player_at_tile(row: int, column: int) -> void:
	var player_instance = player_scene.instantiate()
	add_child(player_instance)
	var viewport_size = get_viewport_rect().size
	var grid_size = Vector2(columns * tile_size, rows * tile_size)

	# Center horizontally, align to bottom with margin (same as tiles)
	var offset = Vector2(
		(viewport_size.x - grid_size.x) / 2,
		viewport_size.y - grid_size.y - bottom_margin
	)

	player_instance.position = Vector2(column * tile_size, row * tile_size) + offset

	# Scale the player according to game_scale (slightly smaller than tiles)
	var player_scale = game_scale - (0.1 * game_scale)
	player_instance.scale = Vector2(player_scale, player_scale)
