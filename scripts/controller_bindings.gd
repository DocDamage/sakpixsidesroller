extends RefCounted

const ACTIONS: Array[String] = ["jump", "attack", "dash", "interact", "pause_level"]
const DEFAULTS: Dictionary = {"jump": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "dash": JOY_BUTTON_B, "interact": JOY_BUTTON_Y, "pause_level": JOY_BUTTON_START}
const GAMEPLAY: Array[String] = ["move_left", "move_right", "move_down","move_up", "jump", "attack", "dash", "interact","district_map"]

static func can_bind(index: int) -> bool:
	return index >= 0 and index < JOY_BUTTON_MAX and index not in [JOY_BUTTON_BACK, JOY_BUTTON_GUIDE, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]

static func button(action: String, index: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = index
	InputMap.action_add_event(action, event)

static func axis(action: String, index: int, direction: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = index
	event.axis_value = direction
	InputMap.action_add_event(action, event)

static func install(mapping: Dictionary, deadzone: float) -> void:
	var actions: Array = ACTIONS + ["move_left", "move_right", "move_down","move_up","district_map", "controller_help", "ui_accept", "ui_cancel", "ui_left", "ui_right", "ui_up", "ui_down"]
	for action: String in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
		InputMap.action_set_deadzone(action, deadzone if action.begins_with("move_") else 0.5)
	for action: String in ACTIONS:
		button(action, int(mapping[action]))
	button("move_up",JOY_BUTTON_DPAD_UP)
	axis("move_up",JOY_AXIS_LEFT_Y,-1)
	if JOY_BUTTON_LEFT_SHOULDER not in mapping.values():
		button("district_map",JOY_BUTTON_LEFT_SHOULDER)
	if mapping["dash"] == JOY_BUTTON_B:
		if JOY_BUTTON_RIGHT_SHOULDER not in mapping.values():
			button("dash", JOY_BUTTON_RIGHT_SHOULDER)
	for pair: Array in [["move_left", JOY_BUTTON_DPAD_LEFT], ["move_right", JOY_BUTTON_DPAD_RIGHT], ["move_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT], ["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["controller_help", JOY_BUTTON_BACK]]:
		button(pair[0], pair[1])
	for pair: Array in [["move_left", JOY_AXIS_LEFT_X, -1], ["move_right", JOY_AXIS_LEFT_X, 1], ["move_down", JOY_AXIS_LEFT_Y, 1], ["ui_left", JOY_AXIS_LEFT_X, -1], ["ui_right", JOY_AXIS_LEFT_X, 1], ["ui_up", JOY_AXIS_LEFT_Y, -1], ["ui_down", JOY_AXIS_LEFT_Y, 1]]:
		axis(pair[0], pair[1], pair[2])
	var help_key := InputEventKey.new()
	help_key.physical_keycode = KEY_F1
	if not InputMap.action_has_event("controller_help", help_key):
		InputMap.action_add_event("controller_help", help_key)

static func label(index: int, style: String) -> String:
	var xbox: Array[String] = ["A", "B", "X", "Y", "View", "Guide", "Menu", "LS", "RS", "LB", "RB", "D-Up", "D-Down", "D-Left", "D-Right", "Share", "P1", "P2", "P3", "P4", "Touchpad"]
	var ps: Array[String] = ["Cross", "Circle", "Square", "Triangle", "Touchpad", "PS", "Options", "L3", "R3", "L1", "R1"]
	var nintendo: Array[String] = ["B", "A", "Y", "X", "Minus", "Home", "Plus", "LS", "RS", "L", "R"]
	if index < 0 or index >= xbox.size():
		return "Button %d" % index
	if style == "PlayStation" and index < ps.size():
		return ps[index]
	if style == "Nintendo" and index < nintendo.size():
		return nintendo[index]
	return xbox[index]
