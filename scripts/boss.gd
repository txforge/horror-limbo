extends VBoxContainer

@export var max_health: int = GameConfig.BOSS_DEFAULT_MAX_HEALTH
@export var boss_name: String = "Boss"
@export var boss_index: int = 0

var _current_health: int = 0

@onready var _health_bar: ProgressBar = $HealthBar
@onready var _boss_name_label: Label = $BossNameLabel

func _ready() -> void:
	_validate_nodes()
	_initialize_health()
	_setup_ui()

func _validate_nodes() -> void:
	if _health_bar == null:
		push_warning("Boss: HealthBar not found")
	if _boss_name_label == null:
		push_warning("Boss: BossNameLabel not found")

func _initialize_health() -> void:
	_current_health = max_health

func _setup_ui() -> void:
	if _boss_name_label != null:
		_boss_name_label.text = boss_name
	if _health_bar != null:
		_health_bar.max_value = max_health
		_health_bar.value = _current_health

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	_current_health = max(0, _current_health - amount)
	if _health_bar != null:
		_health_bar.value = _current_health
