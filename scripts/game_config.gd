extends Node

const GRID_ROWS: int = 5
const GRID_COLUMNS: int = 17
const TILE_SIZE: int = 16
const TILE_SPACING: int = 0

const DEFAULT_DAMAGE: int = 10
const HIGHLIGHT_DURATION: float = 2.0
const COMBO_INPUT_WINDOW: float = 0.5
const CONTINUOUS_DAMAGE_INTERVAL: float = 0.5

const MOVE_ANIMATION_DURATION: float = 0.2
const INPUT_BUFFER_DURATION: float = 0.3
const MOVE_TWEEN_TRANS: Tween.TransitionType = Tween.TRANS_CUBIC
const MOVE_TWEEN_EASE: Tween.EaseType = Tween.EASE_IN_OUT

const MAX_PHYSICS_INTERSECTIONS: int = 32
const COLLISION_LAYER_PLAYER: int = 1
const COLLISION_LAYER_TILES: int = 2
const COLLISION_LAYER_BOSSES: int = 4

const BOSS_DEFAULT_MAX_HEALTH: int = 100
const BOSS_PHASE_COUNT: int = 3
const BOSS_DEFAULT_PHASE: int = 1

const BOSS_ICON_SIZE: Vector2 = Vector2(64, 64)
const HEALTH_BAR_SIZE: Vector2 = Vector2(180, 20)

const INPUT_MOVE_UP: String = "2D_Up"
const INPUT_MOVE_DOWN: String = "2D_Down"
const INPUT_MOVE_LEFT: String = "2D_Left"
const INPUT_MOVE_RIGHT: String = "2D_Right"
const INPUT_ATTACK: String = "attack"

const GROUP_TILES: String = "tiles"
const GROUP_SHOOTABLE_WORLD: String = "shootable_world"
const GROUP_TEXT_TARGET: String = "text_target"

const COLOR_TILE_TARGETED: Color = Color.YELLOW
const COLOR_TILE_DAMAGE: Color = Color.RED
const COLOR_TILE_IDLE: Color = Color.WHITE
const COLOR_TEXT_TARGET_FLASH: Color = Color.GREEN

const VIEWPORT_SIZE: Vector2 = Vector2(1920, 1080)
const VIEWPORT_CENTER: Vector2 = VIEWPORT_SIZE / 2.0

func get_grid_pixel_size() -> Vector2:
	var width: float = GRID_COLUMNS * TILE_SIZE + (GRID_COLUMNS - 1) * TILE_SPACING
	var height: float = GRID_ROWS * TILE_SIZE + (GRID_ROWS - 1) * TILE_SPACING
	return Vector2(width, height)

func grid_to_world(row: int, column: int, offset: Vector2) -> Vector2:
	var x: float = column * (TILE_SIZE + TILE_SPACING)
	var y: float = row * (TILE_SIZE + TILE_SPACING)
	return Vector2(x, y) + offset

func is_valid_grid_position(row: int, column: int) -> bool:
	return row >= 0 and row < GRID_ROWS and column >= 0 and column < GRID_COLUMNS

func grid_position_to_key(row: int, column: int) -> String:
	return "%d,%d" % [row, column]
