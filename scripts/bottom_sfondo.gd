extends ColorRect

func on_shot() -> void:
	print("Bottom sfondo clicked!")
	# Cambia colore per feedback visivo
	var original_color = color
	color = Color(0.3, 0.3, 0.8, 1)
	await get_tree().create_timer(0.1).timeout
	color = original_color

	# Puoi aggiungere qui la logica che vuoi quando si clicca sull'area
