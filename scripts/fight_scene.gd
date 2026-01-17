extends Node2D

@onready var setup_fight = $SetUpFight
@onready var boss_container = $"Boss HUD/top sfondo/boss container"

func _ready() -> void:
	# Avvia direttamente la timeline - i boss sono già nell'editor
	call_deferred("_start_intro")

func _start_intro() -> void:
	# Carica lo stile text bubble
	var layout = Dialogic.Styles.load_style("text_buble_style")

	if layout and layout.has_method("register_character"):
		# Registra tutti i boss con Dialogic
		_register_bosses_with_layout(layout)

	# Avvia la timeline intro
	Dialogic.start("intro timeline")

func _register_bosses_with_layout(layout: Node) -> void:
	# Ottieni tutti i boss dal container
	for boss in boss_container.get_children():
		# Aspetta che il boss sia pronto (per il dialogue_marker)
		if not boss.is_node_ready():
			await boss.ready

		# Registra il boss se ha un character assegnato
		if boss.dialogic_character and boss.dialogue_marker:
			layout.register_character(boss.dialogic_character, boss.dialogue_marker)
