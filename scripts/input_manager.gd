## InputManager Singleton
## Centralized input handling and combo detection system
## Manages both movement and combat inputs with proper priority handling
extends Node

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when a movement input is detected
signal movement_requested(direction: Vector2i)

## Emitted when a basic attack input is detected
signal attack_requested(target_position: Vector2)

## Emitted when a combo attack is triggered
signal combo_triggered(combo_name: String, target_position: Vector2)

# ============================================================================
# COMBO DEFINITIONS
# ============================================================================

## Combo structure: name -> array of input sequences
## Each sequence is an array of input strings that can trigger the combo
const COMBO_DEFINITIONS: Dictionary = {
	"light_atk": [
		["down", "right", "attack"],
		["down", "left", "attack"]
	],
	# Add more combos here as needed
}

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

## Current input sequence for combo detection
var _input_sequence: Array[String] = []

## Timer for clearing input sequence
var _combo_timer: Timer = null

## Reference to the main camera for coordinate conversion
var _camera: Camera2D = null

## Input processing enabled/disabled state
var _input_enabled: bool = true

# ============================================================================
# CONSTANTS
# ============================================================================

const MOUSE_CURSOR = preload("res://assets/sprites/cursor.png")

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_setup_custom_cursor()
	_setup_combo_timer()
	_find_camera()

## Sets up custom mouse cursor
func _setup_custom_cursor() -> void:
	if MOUSE_CURSOR != null:
		Input.set_custom_mouse_cursor(MOUSE_CURSOR)

## Sets up the timer for combo input window
func _setup_combo_timer() -> void:
	_combo_timer = Timer.new()
	_combo_timer.wait_time = GameConfig.COMBO_INPUT_WINDOW
	_combo_timer.one_shot = true
	_combo_timer.timeout.connect(_on_combo_timer_timeout)
	add_child(_combo_timer)

## Finds and caches the main camera reference
func _find_camera() -> void:
	# Aspetta un frame per permettere alla scena di caricare completamente
	await get_tree().process_frame

	# Try to find camera in the scene tree - prima cerca nei gruppi
	var cameras: Array[Node] = get_tree().get_nodes_in_group("main_camera")
	if cameras.size() > 0 and cameras[0] is Camera2D:
		_camera = cameras[0] as Camera2D
		print("InputManager: Found camera in 'main_camera' group")
	else:
		# Fallback: search for any Camera2D
		_camera = _find_camera_in_tree(get_tree().root)
		if _camera != null:
			print("InputManager: Found camera by searching tree")

	if _camera == null:
		push_error("InputManager: No Camera2D found in scene tree!")
	else:
		print("InputManager: Camera found successfully at ", _camera.get_path())

## Recursively searches for a Camera2D node
func _find_camera_in_tree(node: Node) -> Camera2D:
	if node is Camera2D:
		return node as Camera2D

	for child in node.get_children():
		var found: Camera2D = _find_camera_in_tree(child)
		if found != null:
			return found

	return null

# ============================================================================
# INPUT PROCESSING
# ============================================================================

func _process(_delta: float) -> void:
	if not _input_enabled:
		return

	_process_movement_input()
	_process_attack_input()

## Processes directional movement inputs
func _process_movement_input() -> void:
	var direction := Vector2i.ZERO

	# Check movement inputs - use just_pressed to trigger only once per keypress
	if Input.is_action_just_pressed(GameConfig.INPUT_MOVE_UP):
		direction.y -= 1
		_add_to_input_sequence("up")
	elif Input.is_action_just_pressed(GameConfig.INPUT_MOVE_DOWN):
		direction.y += 1
		_add_to_input_sequence("down")
	elif Input.is_action_just_pressed(GameConfig.INPUT_MOVE_LEFT):
		direction.x -= 1
		_add_to_input_sequence("left")
	elif Input.is_action_just_pressed(GameConfig.INPUT_MOVE_RIGHT):
		direction.x += 1
		_add_to_input_sequence("right")

	# Emit movement request if there's a direction
	if direction != Vector2i.ZERO:
		movement_requested.emit(direction)

## Processes attack inputs and handles targeting
func _process_attack_input() -> void:
	if not Input.is_action_just_pressed(GameConfig.INPUT_ATTACK):
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	# Find target at click position
	var target: Node = find_target_at_position(mouse_pos)

	# Add attack to input sequence for combo detection
	_add_to_input_sequence("attack")

	# Check if this completes a combo
	var combo_name: String = _check_for_combo()

	if combo_name != "":
		# Combo detected
		print("🎯 COMBO: ", combo_name, " at ", mouse_pos)
		if target != null:
			print("   Target: ", target.name, " (", target.get_class(), ")")
		else:
			print("   No target at position")
		combo_triggered.emit(combo_name, mouse_pos)
		_clear_input_sequence()
	else:
		# Regular attack
		print("⚔️ ATTACK at ", mouse_pos)
		if target != null:
			print("   Hit: ", target.name, " (", target.get_class(), ")")
		else:
			print("   Miss - no target")
		attack_requested.emit(mouse_pos)

# ============================================================================
# COMBO SYSTEM
# ============================================================================

## Adds an input to the sequence and resets the timer
func _add_to_input_sequence(input: String) -> void:
	# Only add if it's different from the last input (prevent holding)
	if _input_sequence.is_empty() or _input_sequence[-1] != input:
		_input_sequence.append(input)
		_combo_timer.start()

## Checks if current input sequence matches any combo
func _check_for_combo() -> String:
	for combo_name in COMBO_DEFINITIONS:
		var sequences: Array = COMBO_DEFINITIONS[combo_name]

		for sequence in sequences:
			if _matches_sequence(sequence):
				return combo_name

	return ""

## Checks if current input sequence ends with the given sequence
func _matches_sequence(sequence: Array) -> bool:
	if _input_sequence.size() < sequence.size():
		return false

	# Check if the last N inputs match the sequence
	var start_index: int = _input_sequence.size() - sequence.size()

	for i in range(sequence.size()):
		if _input_sequence[start_index + i] != sequence[i]:
			return false

	return true

## Clears the input sequence
func _clear_input_sequence() -> void:
	_input_sequence.clear()
	_combo_timer.stop()

## Called when combo timer times out
func _on_combo_timer_timeout() -> void:
	_clear_input_sequence()

# ============================================================================
# TARGETING SYSTEM
# ============================================================================

## Finds the target at the given screen position
## Returns the target node or null if none found
func find_target_at_position(screen_pos: Vector2) -> Node:
	# First, check GUI layer (text targets, boss UI)
	var gui_target: Node = _find_gui_target_at_position(screen_pos)
	if gui_target != null:
		return gui_target

	# Then, check world layer (tiles, entities)
	var world_target: Node = _find_world_target_at_position(screen_pos)
	return world_target

## Finds GUI targets (Control nodes) at the given position
func _find_gui_target_at_position(screen_pos: Vector2) -> Node:
	# Get the root of the GUI tree
	var root: Window = get_tree().root

	# Recursively search for Control nodes at this position
	return _find_control_at_position(root, screen_pos)

## Recursively searches for a Control node at the given position
func _find_control_at_position(node: Node, pos: Vector2) -> Node:
	# Check children in reverse order (front to back)
	var children: Array[Node] = node.get_children()
	children.reverse()

	for child in children:
		# Check visibility only for CanvasItem nodes
		if child is CanvasItem:
			if not (child as CanvasItem).is_visible_in_tree():
				continue

		# Recursively check children first (for layering)
		var found: Node = _find_control_at_position(child, pos)
		if found != null:
			return found

		# Check if this node itself is a valid target
		if child is Control:
			var control: Control = child as Control
			if _is_valid_gui_target(control, pos):
				return control

	return null

## Checks if a Control node is a valid target at the given position
func _is_valid_gui_target(control: Control, pos: Vector2) -> bool:
	# Check if position is within bounds
	var rect: Rect2 = control.get_global_rect()
	if not rect.has_point(pos):
		return false

	# Check if it has the required methods or is in the correct group
	var has_method: bool = control.has_method("on_shot") or control.has_method("take_damage")
	var in_group: bool = control.is_in_group(GameConfig.GROUP_TEXT_TARGET)

	return has_method or in_group

## Finds world targets (physics bodies) at the given position
func _find_world_target_at_position(_screen_pos: Vector2) -> Node:
	if _camera == null:
		push_error("InputManager: Cannot find world target - no camera reference")
		return null

	# Convert screen position to world position (usa mouse position direttamente)
	var world_pos: Vector2 = _camera.get_global_mouse_position()

	# Set up physics query
	var viewport: Viewport = get_viewport()
	if viewport == null or viewport.get_world_2d() == null:
		push_error("InputManager: Cannot access World2D")
		return null

	var space_state: PhysicsDirectSpaceState2D = viewport.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = true

	# Query for intersecting objects
	var results: Array[Dictionary] = space_state.intersect_point(query, GameConfig.MAX_PHYSICS_INTERSECTIONS)

	# Find the first valid target
	for result in results:
		var collider: Node = result["collider"]
		if _is_valid_world_target(collider):
			return collider

	return null

## Checks if a physics object is a valid world target
func _is_valid_world_target(node: Node) -> bool:
	# Check if it has the required method
	var owner_node: Node = node.owner if node.owner != null else node

	if owner_node.has_method("on_shot"):
		return true

	# Check if it's in the shootable world group
	if owner_node.is_in_group(GameConfig.GROUP_SHOOTABLE_WORLD):
		return true

	return false

# ============================================================================
# PUBLIC API
# ============================================================================

## Enables or disables input processing
func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		_clear_input_sequence()

## Returns whether input is currently enabled
func is_input_enabled() -> bool:
	return _input_enabled

## Returns the current input sequence (for debugging/UI)
func get_current_input_sequence() -> Array[String]:
	return _input_sequence.duplicate()

## Manually clears the input sequence
func clear_input_sequence() -> void:
	_clear_input_sequence()
