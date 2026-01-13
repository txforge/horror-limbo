## DEPRECATO - Non usare più questo file!
## Sostituito da InputManager singleton (scripts/input_manager.gd)
##
## Questo file è mantenuto solo per compatibilità con player.tscn
## Rimuovere il nodo InputHolder da player.tscn e usare InputManager invece

extends Node

const MOUSE_CURSOR = preload("res://assets/sprites/cursor.png")

func _ready() -> void:
	# Imposta solo il cursore custom
	Input.set_custom_mouse_cursor(MOUSE_CURSOR)

	# NON processare input - delegato a InputManager
	set_process(false)

	push_warning("InputHolder è deprecato! Usa InputManager singleton invece.")
