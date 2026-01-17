extends Node

## Script di debug per visualizzare le hitbox e aree cliccabili

@export var enabled: bool = true
@export var show_collision_shapes: bool = true
@export var show_control_rects: bool = true

func _ready() -> void:
	if enabled:
		get_tree().debug_collisions_hint = show_collision_shapes
		print("🔍 Debug Hitboxes ATTIVO")
		print("  - Collision shapes visibili: ", show_collision_shapes)
		print("  - Control rects visibili: ", show_control_rects)

func _draw() -> void:
	if not enabled or not show_control_rects:
		return

	# Disegna i rettangoli dei Control nodes
	_draw_control_rects(get_tree().root)

func _draw_control_rects(node: Node) -> void:
	if node is Control:
		var control := node as Control
		if control.is_visible_in_tree():
			var rect := control.get_global_rect()
			# Converti in coordinate locali
			draw_rect(Rect2(rect.position, rect.size), Color.GREEN, false, 2.0)

	for child in node.get_children():
		_draw_control_rects(child)

func _process(_delta: float) -> void:
	if enabled and show_control_rects:
		queue_redraw()
