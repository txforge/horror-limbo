extends Label

signal text_shot(text: String)

var target_text: String = ""

func _ready() -> void:
	# Add to shootable group
	add_to_group("text_target")

	# Set some default styling to make it visible
	add_theme_font_size_override("font_size", 32)
	add_theme_color_override("font_color", Color.WHITE)

func set_target_text(text: String) -> void:
	target_text = text
	self.text = text

func on_shot() -> void:
	print("Text target shot: ", target_text)
	text_shot.emit(target_text)

	# Visual feedback
	modulate = Color.GREEN
	await get_tree().create_timer(0.2).timeout

	# Remove the label or hide it
	queue_free()

func take_damage(_amount: int = 0) -> void:
	# Alternative method that can be called
	on_shot()
