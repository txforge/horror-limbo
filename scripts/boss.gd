extends VBoxContainer

@export var max_health: int = GameConfig.BOSS_DEFAULT_MAX_HEALTH
@export var boss_name: String = "Boss"
@export var boss_index: int = 0
@export var dialogic_character: Resource  # DialogicCharacter - assegna nell'editor

var _current_health: int = 0

@onready var _health_bar: ProgressBar = $HealthBar
@onready var _boss_name_label: Label = $BossNameLabel
@onready var _boss_sprite: TextureRect = $BossIconSprite

var dialogue_marker: Control = null

func _ready() -> void:
	_validate_nodes()
	_initialize_health()
	_setup_ui()
	_create_dialogue_marker()

func _validate_nodes() -> void:
	if _health_bar == null:
		push_warning("Boss: HealthBar not found")
	if _boss_name_label == null:
		push_warning("Boss: BossNameLabel not found")
	if _boss_sprite == null:
		push_warning("Boss: BossIconSprite not found")

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

func _create_dialogue_marker() -> void:
	# Crea un marker al centro del boss sprite per le text bubble
	if _boss_sprite != null:
		dialogue_marker = Control.new()
		dialogue_marker.name = "DialogueMarker"
		_boss_sprite.add_child(dialogue_marker)

		# Posiziona il marker al centro del TextureRect
		dialogue_marker.position = _boss_sprite.size / 2.0
		dialogue_marker.set_anchors_preset(Control.PRESET_CENTER)

		print("DEBUG: Marker creato per boss al centro: ", dialogue_marker.global_position)
