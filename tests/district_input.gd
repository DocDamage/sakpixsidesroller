extends RefCounted

static var keyboard: bool = false
static var held: Dictionary = {}

static func key(code: int, pressed: bool) -> void:
	if bool(held.get(code,false)) == pressed:
		return
	held[code] = pressed
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

static func button(index: int, pressed: bool) -> void:
	if not keyboard:
		preload("res://tests/pad_driver.gd").button(index,pressed)
		return
	var keys: Dictionary = {JOY_BUTTON_A:KEY_SPACE,JOY_BUTTON_B:KEY_SHIFT,JOY_BUTTON_X:KEY_J,JOY_BUTTON_Y:KEY_E,JOY_BUTTON_LEFT_SHOULDER:KEY_TAB,JOY_BUTTON_START:KEY_ESCAPE}
	if keys.has(index):
		key(keys[index],pressed)

static func axis(index: int, value: float) -> void:
	if not keyboard:
		preload("res://tests/pad_driver.gd").axis(index,value)
		return
	if index == JOY_AXIS_LEFT_X:
		key(KEY_A,value < -0.1)
		key(KEY_D,value > 0.1)
	elif index == JOY_AXIS_LEFT_Y:
		key(KEY_W,value < -0.1)
		key(KEY_S,value > 0.1)

static func release() -> void:
	if not keyboard:
		preload("res://tests/pad_driver.gd").release()
	else:
		for code: int in held.keys():
			key(code,false)
