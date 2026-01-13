extends Node2D

@onready var text_container = $"Boss HUD/bottom sfondo/text container"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TEST: Spawn some test text targets
	await get_tree().create_timer(0.5).timeout
	spawn_text_target("SPARA QUI!")
	spawn_text_target("TARGET 1")
	spawn_text_target("TARGET 2")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# Helper function to spawn shootable text in the bottom area
func spawn_text_target(text: String) -> void:
	var text_label = Label.new()
	text_label.set_script(preload("res://scripts/text_target.gd"))
	text_label.call_deferred("set_target_text", text)

	# Connect signal if needed
	text_label.text_shot.connect(_on_text_shot)

	text_container.add_child(text_label)

func _on_text_shot(text: String) -> void:
	print("Player shot text: ", text)
	# Add your logic here (score, combo, etc.)
