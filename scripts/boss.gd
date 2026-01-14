extends VBoxContainer

signal health_changed(new_health: int, max_health: int)
signal boss_defeated()
signal phase_changed(new_phase: int)

@export var max_health: int = GameConfig.BOSS_DEFAULT_MAX_HEALTH
@export var boss_name: String = "Boss"
@export var boss_index: int = 0

var _current_health: int = 0
var _current_phase: int = GameConfig.BOSS_DEFAULT_PHASE
var _is_defeated: bool = false

@onready var _health_bar: ProgressBar = $HealthBar
@onready var _boss_name_label: Label = $BossNameLabel
@onready var _phase_indicator: Label = $PhaseIndicator
@onready var _combat: Node = $Combat

func _ready() -> void:
	_validate_nodes()
	_initialize_health()
	_setup_ui()
	_connect_signals()

func _validate_nodes() -> void:
	if _health_bar == null:
		push_warning("Boss: HealthBar not found")
	if _boss_name_label == null:
		push_warning("Boss: BossNameLabel not found")
	if _phase_indicator == null:
		push_warning("Boss: PhaseIndicator not found")
	if _combat == null:
		push_warning("Boss: Combat node not found")

func _initialize_health() -> void:
	_current_health = max_health

func _setup_ui() -> void:
	if _boss_name_label != null:
		_boss_name_label.text = boss_name
	if _phase_indicator != null:
		_update_phase_indicator()
	if _health_bar != null:
		_health_bar.max_value = max_health
		_health_bar.value = _current_health

func _connect_signals() -> void:
	if not health_changed.is_connected(_on_health_changed):
		health_changed.connect(_on_health_changed)
	health_changed.emit(_current_health, max_health)

func take_damage(amount: int) -> void:
	if _is_defeated or amount <= 0:
		return
	var old_health: int = _current_health
	_current_health = max(0, _current_health - amount)
	health_changed.emit(_current_health, max_health)
	if _current_health <= 0 and old_health > 0:
		_on_defeated()

func heal(amount: int) -> void:
	if _is_defeated or amount <= 0:
		return
	_current_health = min(max_health, _current_health + amount)
	health_changed.emit(_current_health, max_health)

func _on_health_changed(new_health: int, _max_hp: int) -> void:
	if _health_bar != null:
		_health_bar.value = new_health
		var health_percent: float = get_health_percentage()
		if health_percent <= 0.25:
			_health_bar.modulate = Color.RED
		elif health_percent <= 0.5:
			_health_bar.modulate = Color.ORANGE
		else:
			_health_bar.modulate = Color.WHITE

func _on_defeated() -> void:
	_is_defeated = true
	boss_defeated.emit()
	_play_defeat_animation()

func _play_defeat_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.3, 0.5)

func set_phase(new_phase: int) -> void:
	if new_phase < 1 or new_phase > GameConfig.BOSS_PHASE_COUNT:
		push_error("Boss: Invalid phase number: %d" % new_phase)
		return
	if new_phase == _current_phase:
		return
	var old_phase: int = _current_phase
	_current_phase = new_phase
	_update_phase_indicator()
	phase_changed.emit(_current_phase)
	_apply_phase_effects(old_phase, new_phase)

func _update_phase_indicator() -> void:
	if _phase_indicator == null:
		return
	_phase_indicator.text = "Phase %d" % _current_phase
	match _current_phase:
		1:
			_phase_indicator.modulate = Color.GREEN
		2:
			_phase_indicator.modulate = Color.YELLOW
		3:
			_phase_indicator.modulate = Color.RED

func _apply_phase_effects(old_phase: int, new_phase: int) -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	print("Boss %s transitioned from Phase %d to Phase %d" % [boss_name, old_phase, new_phase])

func update_phase_from_health() -> void:
	var health_percent: float = get_health_percentage()
	var new_phase: int = _current_phase
	if health_percent <= 0.33:
		new_phase = 3
	elif health_percent <= 0.66:
		new_phase = 2
	else:
		new_phase = 1
	if new_phase != _current_phase:
		set_phase(new_phase)

func on_shot() -> void:
	take_damage(GameConfig.DEFAULT_DAMAGE)

func get_combat() -> Node:
	return _combat

func get_current_health() -> int:
	return _current_health

func get_max_health() -> int:
	return max_health

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(_current_health) / float(max_health)

func get_current_phase() -> int:
	return _current_phase

func is_defeated() -> bool:
	return _is_defeated

func reset() -> void:
	_is_defeated = false
	_current_health = max_health
	_current_phase = GameConfig.BOSS_DEFAULT_PHASE
	_setup_ui()
	health_changed.emit(_current_health, max_health)
	modulate = Color.WHITE
	scale = Vector2.ONE
