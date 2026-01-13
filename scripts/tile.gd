## Tile Entity
## Represents a single grid tile with damage zones and visual highlighting
## Can be targeted and apply damage to entities that enter its hitbox
extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when the tile damages a player
signal damage_player(damage: int)

## Emitted when the tile is shot/clicked
signal tile_shot(tile: Node2D)

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

## Amount of damage dealt to entities in the hitbox
@export var damage_amount: int = GameConfig.DEFAULT_DAMAGE

## Whether damage is applied continuously while in hitbox
@export var is_continuous_damage: bool = false

## Interval between continuous damage ticks (in seconds)
@export var continuous_damage_interval: float = GameConfig.CONTINUOUS_DAMAGE_INTERVAL

# ============================================================================
# NODE REFERENCES
# ============================================================================

@onready var _sprite: Sprite2D = get_node_or_null("Tile_")
@onready var _hitbox: Area2D = get_node_or_null("Hitbox")
@onready var _click_area: Area2D = get_node_or_null("ClickArea")

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

## Timer for continuous damage application
var _continuous_damage_timer: Timer = null

## List of entities currently in the hitbox
var _entities_in_hitbox: Array[Area2D] = []

## Current highlight state
var _current_state: HighlightState = HighlightState.IDLE

## Active highlight tween
var _highlight_tween: Tween = null

# ============================================================================
# ENUMS
# ============================================================================

enum HighlightState {
	IDLE,      ## No highlight
	TARGET,    ## Yellow highlight (being targeted)
	DAMAGE     ## Red highlight (dealing damage)
}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_validate_nodes()
	_setup_continuous_damage_timer()
	_connect_signals()

## Validates that all required nodes exist
func _validate_nodes() -> void:
	if _hitbox == null:
		push_error("Tile: Hitbox Area2D not found! Add a node named 'Hitbox'")

	if _sprite == null:
		push_warning("Tile: Sprite2D not found - tile will be invisible")

	if _click_area == null:
		push_warning("Tile: ClickArea not found - tile will not be clickable")

## Sets up the continuous damage timer
func _setup_continuous_damage_timer() -> void:
	_continuous_damage_timer = Timer.new()
	_continuous_damage_timer.wait_time = continuous_damage_interval
	_continuous_damage_timer.one_shot = false
	_continuous_damage_timer.timeout.connect(_on_continuous_damage_tick)
	add_child(_continuous_damage_timer)

## Connects all necessary signals
func _connect_signals() -> void:
	if _hitbox == null:
		return

	# Connect hitbox signals only if not already connected
	if not _hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		_hitbox.area_entered.connect(_on_hitbox_area_entered)

	if not _hitbox.area_exited.is_connected(_on_hitbox_area_exited):
		_hitbox.area_exited.connect(_on_hitbox_area_exited)

# ============================================================================
# HIGHLIGHTING SYSTEM
# ============================================================================

## Highlights the tile as a target (yellow), then transitions to damage
func target_highlight(duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	print("🎯 Tile [", row, ", ", column, "] targeting (yellow)")

	_set_highlight_state(HighlightState.TARGET)

	# Wait for target duration, then switch to damage
	await get_tree().create_timer(duration).timeout
	await dmg_highlight(duration)

	_set_highlight_state(HighlightState.IDLE)

## Highlights the tile as dealing damage (red) and enables hitbox
func dmg_highlight(duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	print("💥 Tile [", row, ", ", column, "] dealing damage (red) for ", duration, "s")

	_set_highlight_state(HighlightState.DAMAGE)
	apply_hitbox(duration)

	await get_tree().create_timer(duration).timeout
	_set_highlight_state(HighlightState.IDLE)

## Sets the visual highlight state
func _set_highlight_state(state: HighlightState) -> void:
	_current_state = state

	# Cancel any active tween
	if _highlight_tween != null and _highlight_tween.is_running():
		_highlight_tween.kill()

	# Apply color based on state
	var target_color: Color

	match state:
		HighlightState.IDLE:
			target_color = GameConfig.COLOR_TILE_IDLE
		HighlightState.TARGET:
			target_color = GameConfig.COLOR_TILE_TARGETED
		HighlightState.DAMAGE:
			target_color = GameConfig.COLOR_TILE_DAMAGE

	# Smooth color transition
	_highlight_tween = create_tween()
	_highlight_tween.set_ease(Tween.EASE_OUT)
	_highlight_tween.set_trans(Tween.TRANS_CUBIC)
	_highlight_tween.tween_property(self, "modulate", target_color, 0.2)

## Removes highlighting (returns to idle state)
func unhighlight() -> void:
	_set_highlight_state(HighlightState.IDLE)

# ============================================================================
# DAMAGE SYSTEM
# ============================================================================

## Enables the hitbox for a specified duration
func apply_hitbox(hitbox_duration: float) -> void:
	if _hitbox == null:
		push_warning("Tile: Cannot apply hitbox - Hitbox node not found")
		return

	_hitbox.monitoring = true

	await get_tree().create_timer(hitbox_duration).timeout

	if _hitbox != null and is_instance_valid(_hitbox):
		_hitbox.monitoring = false

## Called when an entity enters the hitbox
func _on_hitbox_area_entered(area: Area2D) -> void:
	if not _is_valid_damage_target(area):
		return

	_entities_in_hitbox.append(area)

	if is_continuous_damage:
		# Apply initial damage immediately
		_apply_damage_to_entity(area.owner)

		# Start continuous damage timer if not already running
		if _continuous_damage_timer.is_stopped():
			_continuous_damage_timer.start()
	else:
		# Single instance damage
		_apply_damage_to_entity(area.owner)

## Called when an entity exits the hitbox
func _on_hitbox_area_exited(area: Area2D) -> void:
	if area in _entities_in_hitbox:
		_entities_in_hitbox.erase(area)

	# Stop continuous damage timer if no entities remain
	if _entities_in_hitbox.is_empty() and _continuous_damage_timer != null:
		_continuous_damage_timer.stop()

## Called on each continuous damage tick
func _on_continuous_damage_tick() -> void:
	# Apply damage to all entities in hitbox
	for entity_area in _entities_in_hitbox:
		if entity_area != null and is_instance_valid(entity_area) and entity_area.owner != null:
			_apply_damage_to_entity(entity_area.owner)

## Checks if the area belongs to a valid damage target
func _is_valid_damage_target(area: Area2D) -> bool:
	if area == null or not is_instance_valid(area):
		return false

	var owner_node: Node = area.owner
	if owner_node == null or not is_instance_valid(owner_node):
		return false

	# Check if owner has take_damage method
	return owner_node.has_method("take_damage")

## Applies damage to an entity
func _apply_damage_to_entity(entity: Node) -> void:
	if entity == null or not is_instance_valid(entity):
		return

	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	print("💔 Tile [", row, ", ", column, "] dealing ", damage_amount, " damage to ", entity.name)

	# Emit signal
	damage_player.emit(damage_amount)

	# Call take_damage method if available
	if entity.has_method("take_damage"):
		entity.take_damage(damage_amount)

# ============================================================================
# COMBAT INTERFACE
# ============================================================================

## Called when the tile is shot/clicked (implements target interface)
func on_shot() -> void:
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)

	print("✅ TILE HIT at [", row, ", ", column, "] - Position: ", global_position)

	# Emit signal
	tile_shot.emit(self)

	# Optional: Visual feedback for being shot
	_play_shot_feedback()

## Provides visual feedback when shot
func _play_shot_feedback() -> void:
	if _sprite == null:
		return

	# Quick flash effect
	var original_scale: Vector2 = scale
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.2)

## Alternative damage interface (alias for compatibility)
func take_damage(_amount: int) -> void:
	# Tiles don't take damage themselves, but this maintains interface consistency
	# Could be used for destructible tiles in the future
	push_warning("Tile: take_damage called but tiles are indestructible")

# ============================================================================
# OCCUPATION SYSTEM
# ============================================================================

## Sets the entity currently occupying this tile
func set_occupant(entity: Node) -> void:
	if entity == null:
		remove_meta("occupied_by")
	else:
		set_meta("occupied_by", entity)

## Gets the entity currently occupying this tile (if any)
func get_occupant() -> Node:
	if has_meta("occupied_by"):
		var occupant: Node = get_meta("occupied_by")
		if occupant != null and is_instance_valid(occupant):
			return occupant
		else:
			# Clean up invalid reference
			remove_meta("occupied_by")

	return null

## Checks if the tile is currently occupied
func is_occupied() -> bool:
	return get_occupant() != null

# ============================================================================
# PUBLIC API
# ============================================================================

## Returns the tile's grid position
func get_grid_position() -> Vector2i:
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	return Vector2i(row, column)

## Sets the tile's grid position metadata
func set_grid_position(row: int, column: int) -> void:
	set_meta("grid_row", row)
	set_meta("grid_column", column)

## Returns the current highlight state
func get_highlight_state() -> HighlightState:
	return _current_state

## Forcefully stops all active effects
func stop_all_effects() -> void:
	# Stop highlight tween
	if _highlight_tween != null and _highlight_tween.is_running():
		_highlight_tween.kill()

	# Stop continuous damage
	if _continuous_damage_timer != null:
		_continuous_damage_timer.stop()

	# Clear entities in hitbox
	_entities_in_hitbox.clear()

	# Disable hitbox
	if _hitbox != null:
		_hitbox.monitoring = false

	# Reset to idle state
	_set_highlight_state(HighlightState.IDLE)
