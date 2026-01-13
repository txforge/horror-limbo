## GameConfig Singleton
## Centralized configuration for game constants and settings
## This singleton provides a single source of truth for all game parameters
extends Node

# ============================================================================
# GRID CONFIGURATION
# ============================================================================

## Number of rows in the game grid
const GRID_ROWS: int = 5

## Number of columns in the game grid
const GRID_COLUMNS: int = 17

## Size of each tile in pixels
const TILE_SIZE: int = 16

## Spacing between tiles in pixels
const TILE_SPACING: int = 0

# ============================================================================
# COMBAT CONFIGURATION
# ============================================================================

## Default damage dealt by basic attacks
const DEFAULT_DAMAGE: int = 10

## Duration in seconds for highlighting tiles after damage
const HIGHLIGHT_DURATION: float = 2.0

## Time window in seconds for combo inputs
const COMBO_INPUT_WINDOW: float = 0.5

## Interval in seconds between continuous damage ticks
const CONTINUOUS_DAMAGE_INTERVAL: float = 0.5

# ============================================================================
# MOVEMENT CONFIGURATION
# ============================================================================

## Duration in seconds for movement animation
const MOVE_ANIMATION_DURATION: float = 0.2

## Duration in seconds for input buffering window
const INPUT_BUFFER_DURATION: float = 0.3

## Tween transition type for movement
const MOVE_TWEEN_TRANS: Tween.TransitionType = Tween.TRANS_CUBIC

## Tween ease type for movement
const MOVE_TWEEN_EASE: Tween.EaseType = Tween.EASE_IN_OUT

# ============================================================================
# PHYSICS CONFIGURATION
# ============================================================================

## Maximum number of objects to check in physics queries
const MAX_PHYSICS_INTERSECTIONS: int = 32

## Collision layer for player entities
const COLLISION_LAYER_PLAYER: int = 1

## Collision layer for tiles
const COLLISION_LAYER_TILES: int = 2

## Collision layer for bosses
const COLLISION_LAYER_BOSSES: int = 4

# ============================================================================
# BOSS CONFIGURATION
# ============================================================================

## Default maximum health for bosses
const BOSS_DEFAULT_MAX_HEALTH: int = 100

## Number of phases each boss has
const BOSS_PHASE_COUNT: int = 3

## Default starting phase for bosses
const BOSS_DEFAULT_PHASE: int = 1

# ============================================================================
# UI CONFIGURATION
# ============================================================================

## Size of the boss icon in the UI
const BOSS_ICON_SIZE: Vector2 = Vector2(64, 64)

## Size of the health bar in the UI
const HEALTH_BAR_SIZE: Vector2 = Vector2(180, 20)

# ============================================================================
# INPUT CONFIGURATION
# ============================================================================

## Input action names (matching project.godot)
const INPUT_MOVE_UP: String = "2D_Up"
const INPUT_MOVE_DOWN: String = "2D_Down"
const INPUT_MOVE_LEFT: String = "2D_Left"
const INPUT_MOVE_RIGHT: String = "2D_Right"
const INPUT_ATTACK: String = "attack"

# ============================================================================
# GROUP NAMES
# ============================================================================

## Group name for tile entities
const GROUP_TILES: String = "tiles"

## Group name for entities that can be shot in the world
const GROUP_SHOOTABLE_WORLD: String = "shootable_world"

## Group name for text target UI elements
const GROUP_TEXT_TARGET: String = "text_target"

# ============================================================================
# COLOR DEFINITIONS
# ============================================================================

## Color for tile when targeted (yellow)
const COLOR_TILE_TARGETED: Color = Color.YELLOW

## Color for tile when dealing damage (red)
const COLOR_TILE_DAMAGE: Color = Color.RED

## Color for tile in idle state (white)
const COLOR_TILE_IDLE: Color = Color.WHITE

## Color for text target flash effect (green)
const COLOR_TEXT_TARGET_FLASH: Color = Color.GREEN

# ============================================================================
# VIEWPORT CONFIGURATION
# ============================================================================

## Default viewport size
const VIEWPORT_SIZE: Vector2 = Vector2(1920, 1080)

## Center point of the viewport
const VIEWPORT_CENTER: Vector2 = VIEWPORT_SIZE / 2.0

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Returns the total grid size in pixels
func get_grid_pixel_size() -> Vector2:
	var width: float = GRID_COLUMNS * TILE_SIZE + (GRID_COLUMNS - 1) * TILE_SPACING
	var height: float = GRID_ROWS * TILE_SIZE + (GRID_ROWS - 1) * TILE_SPACING
	return Vector2(width, height)

## Converts grid coordinates to world position
func grid_to_world(row: int, column: int, offset: Vector2) -> Vector2:
	var x: float = column * (TILE_SIZE + TILE_SPACING)
	var y: float = row * (TILE_SIZE + TILE_SPACING)
	return Vector2(x, y) + offset

## Validates if grid coordinates are within bounds
func is_valid_grid_position(row: int, column: int) -> bool:
	return row >= 0 and row < GRID_ROWS and column >= 0 and column < GRID_COLUMNS

## Converts grid position to a unique string key for dictionary lookups
func grid_position_to_key(row: int, column: int) -> String:
	return "%d,%d" % [row, column]
