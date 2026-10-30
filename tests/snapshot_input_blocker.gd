extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	# Movie fixtures use the dedicated synthetic pad. Preserve those events
	# while keeping unrelated desktop input out of reproducible captures.
	if event.device == 77 and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	# Render fixtures are snapshots; desktop keystrokes must not activate their menus.
	get_viewport().set_input_as_handled()
	for action: String in ["move_left", "move_right", "move_down", "jump", "attack", "dash", "interact"]:
		if InputMap.has_action(action):
			Input.action_release(action)
