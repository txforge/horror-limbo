## Boss Entity
## Manages boss health, phases, and UI display
## Emits signals for health changes, phase transitions, and defeat
extends VBoxContainer

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when boss health changes
signal health_changed(new_health: int, max_health: int)

## Emitted when boss is defeated (health reaches 0)
signal boss_defeated()

## Emitted when boss transitions to a new phase
signal phase_changed(new_phase: int)

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

## Maximum health points for this boss
@export var max_health: int = GameConfig.BOSS_DEFAULT_MAX_HEALTH

## Display name for this boss
@export var boss_name: String = "Boss"

## Unique index for this boss (0-3 for the 4 bosses)
@export var boss_index: int = 0

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

## Current health points
var _current_health: int = 0

## Current phase (1-3)
var _current_phase: int = GameConfig.BOSS_DEFAULT_PHASE

## Whether the boss is defeated
var _is_defeated: bool = false

# ============================================================================
# NODE REFERENCES
# ============================================================================

@onready var _health_bar: ProgressBar = $HealthBar
@onready var _boss_name_label: Label = $BossNameLabel
@onready var _phase_indicator: Label = $PhaseIndicator
@onready var _combat: Node = $Combat

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_validate_nodes()
	_initialize_health()
	_setup_ui()
	_connect_signals()

## Validates that all required nodes exist
func _validate_nodes() -> void:
	if _health_bar == null:
		push_warning("Boss: HealthBar not found - health will not be displayed")

	if _boss_name_label == null:
		push_warning("Boss: BossNameLabel not found - name will not be displayed")

	if _phase_indicator == null:
		push_warning("Boss: PhaseIndicator not found - phase will not be displayed")

	if _combat == null:
		push_warning("Boss: Combat node not found - combat abilities unavailable")

## Initializes health to maximum
func _initialize_health() -> void:
	_current_health = max_health

## Sets up UI elements
func _setup_ui() -> void:
	# Set boss name
	if _boss_name_label != null:
		_boss_name_label.text = boss_name

	# Set phase indicator
	if _phase_indicator != null:
		_update_phase_indicator()

	# Setup health bar
	if _health_bar != null:
		_health_bar.max_value = max_health
		_health_bar.value = _current_health

## Connects internal signals
func _connect_signals() -> void:
	if not health_changed.is_connected(_on_health_changed):
		health_changed.connect(_on_health_changed)

	# Emit initial health state
	health_changed.emit(_current_health, max_health)

# ============================================================================
# HEALTH SYSTEM
# ============================================================================

## Applies damage to the boss
func take_damage(amount: int) -> void:
	if _is_defeated:
		return  # Already defeated, ignore damage

	if amount <= 0:
		push_warning("Boss: Invalid damage amount: %d" % amount)
		return

	var old_health: int = _current_health
	_current_health = max(0, _current_health - amount)

	# Emit health changed signal
	health_changed.emit(_current_health, max_health)

	# Check for defeat
	if _current_health <= 0 and old_health > 0:
		_on_defeated()

## Heals the boss
func heal(amount: int) -> void:
	if _is_defeated:
		return  # Cannot heal defeated boss

	if amount <= 0:
		push_warning("Boss: Invalid heal amount: %d" % amount)
		return

	_current_health = min(max_health, _current_health + amount)
	health_changed.emit(_current_health, max_health)

## Called when health bar is updated
func _on_health_changed(new_health: int, _max_hp: int) -> void:
	if _health_bar != null:
		_health_bar.value = new_health

		# Optional: Change health bar color based on health percentage
		var health_percent: float = get_health_percentage()
		if health_percent <= 0.25:
			_health_bar.modulate = Color.RED
		elif health_percent <= 0.5:
			_health_bar.modulate = Color.ORANGE
		else:
			_health_bar.modulate = Color.WHITE

## Called when boss is defeated
func _on_defeated() -> void:
	_is_defeated = true
	boss_defeated.emit()

	# Optional: Visual effects for defeat
	_play_defeat_animation()

## Plays defeat animation (placeholder)
func _play_defeat_animation() -> void:
	# Fade out effect
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.3, 0.5)

# ============================================================================
# PHASE SYSTEM
# ============================================================================

## Sets the boss's current phase
func set_phase(new_phase: int) -> void:
	# Validate phase number
	if new_phase < 1 or new_phase > GameConfig.BOSS_PHASE_COUNT:
		push_error("Boss: Invalid phase number: %d (must be 1-%d)" % [new_phase, GameConfig.BOSS_PHASE_COUNT])
		return

	# Check if phase actually changed
	if new_phase == _current_phase:
		return

	var old_phase: int = _current_phase
	_current_phase = new_phase

	# Update UI
	_update_phase_indicator()

	# Emit signal
	phase_changed.emit(_current_phase)

	# Apply phase-specific changes
	_apply_phase_effects(old_phase, new_phase)

## Updates the phase indicator label
func _update_phase_indicator() -> void:
	if _phase_indicator == null:
		return

	_phase_indicator.text = "Phase %d" % _current_phase

	# Optional: Color code phases
	match _current_phase:
		1:
			_phase_indicator.modulate = Color.GREEN
		2:
			_phase_indicator.modulate = Color.YELLOW
		3:
			_phase_indicator.modulate = Color.RED

## Applies visual and mechanical effects for phase transitions
func _apply_phase_effects(old_phase: int, new_phase: int) -> void:
	# Phase transition animation
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)

	# Scale pulse effect
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)

	# TODO: Add phase-specific visual mutations
	# - Phase 2: Could add particle effects, change sprite tint
	# - Phase 3: Could add pulsing glow, screen shake

	print("Boss %s transitioned from Phase %d to Phase %d" % [boss_name, old_phase, new_phase])

## Automatically advances phase based on health percentage
func update_phase_from_health() -> void:
	var health_percent: float = get_health_percentage()

	var new_phase: int = _current_phase

	# Determine phase based on health thresholds
	if health_percent <= 0.33:
		new_phase = 3  # Critical phase
	elif health_percent <= 0.66:
		new_phase = 2  # Danger phase
	else:
		new_phase = 1  # Normal phase

	# Only update if phase changed
	if new_phase != _current_phase:
		set_phase(new_phase)

# ============================================================================
# COMBAT INTERFACE
# ============================================================================

## Makes the boss shootable (implements target interface)
func on_shot() -> void:
	take_damage(GameConfig.DEFAULT_DAMAGE)

## Returns the combat controller for this boss
func get_combat() -> Node:
	return _combat

# ============================================================================
# PUBLIC API
# ============================================================================

## Returns current health value
func get_current_health() -> int:
	return _current_health

## Returns maximum health value
func get_max_health() -> int:
	return max_health

## Returns current health as a percentage (0.0 - 1.0)
func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(_current_health) / float(max_health)

## Returns current phase number
func get_current_phase() -> int:
	return _current_phase

## Returns whether the boss is defeated
func is_defeated() -> bool:
	return _is_defeated

## Resets the boss to initial state (for game restart)
func reset() -> void:
	_is_defeated = false
	_current_health = max_health
	_current_phase = GameConfig.BOSS_DEFAULT_PHASE

	# Reset UI
	_setup_ui()
	health_changed.emit(_current_health, max_health)

	# Reset visual effects
	modulate = Color.WHITE
	scale = Vector2.ONE
