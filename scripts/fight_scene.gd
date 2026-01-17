extends Node2D

@onready var setup_fight = $SetUpFight

func _ready() -> void:
	print("DEBUG: fight_scene _ready() chiamato")
	print("DEBUG: setup_fight esiste? ", setup_fight != null)

	if setup_fight:
		print("DEBUG: Collegamento al segnale setup_complete")
		setup_fight.setup_complete.connect(_on_setup_complete)
		print("DEBUG: Segnale collegato!")

		# Il setup potrebbe essere già completo, chiamiamo direttamente
		print("DEBUG: Chiamo direttamente _on_setup_complete")
		call_deferred("_on_setup_complete")
	else:
		print("ERROR: setup_fight è null!")

func _on_setup_complete() -> void:
	print("DEBUG: _on_setup_complete CHIAMATO!")

	# Avvia la timeline di Dialogic
	print("DEBUG: Avvio timeline...")
	var layout = Dialogic.start("timeline")
	print("DEBUG: Layout creato: ", layout)

	if layout:
		# Registra i boss per le text bubble
		_register_bosses_with_dialogic(layout)

func _register_bosses_with_dialogic(layout: Node) -> void:
	print("DEBUG: Registro i boss con Dialogic...")

	# Ottieni i boss dallo setup
	var bosses = setup_fight.get_bosses()
	print("DEBUG: Trovati ", bosses.size(), " boss")

	# Carica le risorse dei personaggi e registrale
	var boss_characters = {
		"Boss1": load("res://Boss1.dch"),
		"Boss2": load("res://Boss2.dch"),
		"Boss3": load("res://Boss3.dch"),
		"Boss4": load("res://Boss4.dch")
	}

	for i in range(bosses.size()):
		var boss_node = bosses[i]
		var boss_name = "Boss" + str(i + 1)

		if boss_characters.has(boss_name):
			# Usa il marker al centro del boss invece del boss stesso
			var marker = boss_node.dialogue_marker if boss_node.dialogue_marker != null else boss_node
			print("DEBUG: Registro ", boss_name, " con marker ", marker)
			print("DEBUG: Posizione marker: ", marker.global_position if marker is Control or marker is Node2D else "N/A")
			layout.register_character(boss_characters[boss_name], marker)
		else:
			print("ERROR: Personaggio ", boss_name, " non trovato!")

	print("DEBUG: Registrazione boss completata!")
