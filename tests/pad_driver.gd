extends RefCounted

const DEVICE: int = 77

static func button(index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = DEVICE
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)

static func axis(index: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = DEVICE
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)

static func release() -> void:
	for index: int in range(JOY_BUTTON_MAX):
		button(index, false)
	for index: int in range(JOY_AXIS_MAX):
		axis(index, 0)
