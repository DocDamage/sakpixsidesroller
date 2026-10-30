extends Node

var controller: Node:
	get:
		return get_node("/root/Controller")

signal pause_requested
signal restart_requested
signal mute_requested

static func install(level: Node2D) -> void:
	var bindings: Dictionary = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_down": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE, KEY_W, KEY_UP], "attack": [KEY_J, KEY_X], "dash": [KEY_SHIFT, KEY_K], "interact": [KEY_E], "pause_level": [KEY_ESCAPE], "restart_level": [KEY_R], "mute_level": [KEY_M]}
	bindings["move_up"] = [KEY_W,KEY_UP]
	bindings["district_map"] = [KEY_TAB]
	if level.district_mode:
		bindings["jump"] = [KEY_SPACE]
		for event: InputEvent in InputMap.action_get_events("jump"):
			if event is InputEventKey and event.physical_keycode in [KEY_W,KEY_UP]:
				InputMap.action_erase_event("jump",event)
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	var controls: Node = Node.new()
	controls.set_script(load("res://scripts/level_controls.gd"))
	controls.process_mode = Node.PROCESS_MODE_ALWAYS
	level.add_child(controls)
	controls.pause_requested.connect(level.toggle_pause)
	controls.restart_requested.connect(level.restart)
	controls.mute_requested.connect(func() -> void: level.audio.toggle(); level.hud.muted = level.audio.muted)

func _unhandled_input(event: InputEvent) -> void:
	if controller.panel.visible:
		return
	if event.is_action_pressed("pause_level") or (get_tree().paused and event.is_action_pressed("ui_cancel")):
		controller.flush_gameplay()
		controller.suppress_until_release = true
		pause_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart_level"):
		restart_requested.emit()
	elif event.is_action_pressed("mute_level"):
		mute_requested.emit()
