extends Node2D

signal damage_player(damage: int)
signal tile_shot(tile: Node2D)

@export var damage_amount: int = GameConfig.DEFAULT_DAMAGE
@export var is_continuous_damage: bool = false
@export var continuous_damage_interval: float = GameConfig.CONTINUOUS_DAMAGE_INTERVAL

@onready var _sprite: Sprite2D = get_node_or_null("Tile_")
@onready var _hitbox: Area2D = get_node_or_null("Hitbox")
@onready var _click_area: Area2D = get_node_or_null("ClickArea")

var _continuous_damage_timer: Timer = null
var _entities_in_hitbox: Array[Area2D] = []
var _current_state: HighlightState = HighlightState.IDLE
var _highlight_tween: Tween = null

enum HighlightState { IDLE, TARGET, DAMAGE }

func _ready() -> void:
	_validate_nodes()
	_setup_continuous_damage_timer()
	_connect_signals()

func _validate_nodes() -> void:
	if _hitbox == null:
		push_error("Tile: Hitbox Area2D not found!")
	if _sprite == null:
		push_warning("Tile: Sprite2D not found")
	if _click_area == null:
		push_warning("Tile: ClickArea not found")

func _setup_continuous_damage_timer() -> void:
	_continuous_damage_timer = Timer.new()
	_continuous_damage_timer.wait_time = continuous_damage_interval
	_continuous_damage_timer.one_shot = false
	_continuous_damage_timer.timeout.connect(_on_continuous_damage_tick)
	add_child(_continuous_damage_timer)

func _connect_signals() -> void:
	if _hitbox == null:
		return
	if not _hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		_hitbox.area_entered.connect(_on_hitbox_area_entered)
	if not _hitbox.area_exited.is_connected(_on_hitbox_area_exited):
		_hitbox.area_exited.connect(_on_hitbox_area_exited)

func target_highlight(duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	print("🎯 Tile [", row, ", ", column, "] targeting (yellow)")
	_set_highlight_state(HighlightState.TARGET)
	await get_tree().create_timer(duration).timeout
	await dmg_highlight(duration)
	_set_highlight_state(HighlightState.IDLE)

func dmg_highlight(duration: float = GameConfig.HIGHLIGHT_DURATION) -> void:
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	print("💥 Tile [", row, ", ", column, "] dealing damage (red) for ", duration, "s")
	_set_highlight_state(HighlightState.DAMAGE)
	apply_hitbox(duration)
	await get_tree().create_timer(duration).timeout
	_set_highlight_state(HighlightState.IDLE)

func _set_highlight_state(state: HighlightState) -> void:
	_current_state = state
	if _highlight_tween != null and _highlight_tween.is_running():
		_highlight_tween.kill()
	var target_color: Color
	match state:
		HighlightState.IDLE:
			target_color = GameConfig.COLOR_TILE_IDLE
		HighlightState.TARGET:
			target_color = GameConfig.COLOR_TILE_TARGETED
		HighlightState.DAMAGE:
			target_color = GameConfig.COLOR_TILE_DAMAGE
	_highlight_tween = create_tween()
	_highlight_tween.set_ease(Tween.EASE_OUT)
	_highlight_tween.set_trans(Tween.TRANS_CUBIC)
	_highlight_tween.tween_property(self, "modulate", target_color, 0.2)

func unhighlight() -> void:
	_set_highlight_state(HighlightState.IDLE)

func apply_hitbox(hitbox_duration: float) -> void:
	if _hitbox == null:
		return
	_hitbox.monitoring = true
	await get_tree().create_timer(hitbox_duration).timeout
	if _hitbox != null and is_instance_valid(_hitbox):
		_hitbox.monitoring = false

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not _is_valid_damage_target(area):
		return
	_entities_in_hitbox.append(area)
	if is_continuous_damage:
		_apply_damage_to_entity(area.owner)
		if _continuous_damage_timer.is_stopped():
			_continuous_damage_timer.start()
	else:
		_apply_damage_to_entity(area.owner)

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area in _entities_in_hitbox:
		_entities_in_hitbox.erase(area)
	if _entities_in_hitbox.is_empty() and _continuous_damage_timer != null:
		_continuous_damage_timer.stop()

func _on_continuous_damage_tick() -> void:
	for entity_area in _entities_in_hitbox:
		if entity_area != null and is_instance_valid(entity_area) and entity_area.owner != null:
			_apply_damage_to_entity(entity_area.owner)

func _is_valid_damage_target(area: Area2D) -> bool:
	if area == null or not is_instance_valid(area):
		return false
	var owner_node: Node = area.owner
	if owner_node == null or not is_instance_valid(owner_node):
		return false
	return owner_node.has_method("take_damage")

func _apply_damage_to_entity(entity: Node) -> void:
	if entity == null or not is_instance_valid(entity):
		return
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	print("💔 Tile [", row, ", ", column, "] dealing ", damage_amount, " damage to ", entity.name)
	damage_player.emit(damage_amount)
	if entity.has_method("take_damage"):
		entity.take_damage(damage_amount)

func on_shot() -> void:
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	print("✅ TILE HIT at [", row, ", ", column, "] - Position: ", global_position)
	tile_shot.emit(self)
	_play_shot_feedback()

func _play_shot_feedback() -> void:
	if _sprite == null:
		return
	var original_scale: Vector2 = scale
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.2)

func take_damage(_amount: int) -> void:
	push_warning("Tile: take_damage called but tiles are indestructible")

func set_occupant(entity: Node) -> void:
	if entity == null:
		remove_meta("occupied_by")
	else:
		set_meta("occupied_by", entity)

func get_occupant() -> Node:
	if has_meta("occupied_by"):
		var occupant: Node = get_meta("occupied_by")
		if occupant != null and is_instance_valid(occupant):
			return occupant
		else:
			remove_meta("occupied_by")
	return null

func is_occupied() -> bool:
	return get_occupant() != null

func get_grid_position() -> Vector2i:
	var row: int = get_meta("grid_row", -1)
	var column: int = get_meta("grid_column", -1)
	return Vector2i(row, column)

func set_grid_position(row: int, column: int) -> void:
	set_meta("grid_row", row)
	set_meta("grid_column", column)

func get_highlight_state() -> HighlightState:
	return _current_state

func stop_all_effects() -> void:
	if _highlight_tween != null and _highlight_tween.is_running():
		_highlight_tween.kill()
	if _continuous_damage_timer != null:
		_continuous_damage_timer.stop()
	_entities_in_hitbox.clear()
	if _hitbox != null:
		_hitbox.monitoring = false
	_set_highlight_state(HighlightState.IDLE)
