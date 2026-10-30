extends RefCounted

var buttons: Dictionary = {}
var axes: Dictionary = {}
var raw_axes: Dictionary = {}

func observe(event: InputEvent, deadzone: float) -> void:
	if event is InputEventJoypadButton:
		var key := Vector2i(event.device, event.button_index)
		if event.pressed:
			buttons[key] = true
		else:
			buttons.erase(key)
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_TRIGGER_RIGHT]:
		var key := Vector2i(event.device, event.axis)
		if absf(event.axis_value) > 0.001:
			raw_axes[key] = event.axis_value
		else:
			raw_axes.erase(key)
		if absf(event.axis_value) > deadzone:
			axes[key] = event.axis_value
		else:
			axes.erase(key)

func held(device: int) -> bool:
	for key: Vector2i in buttons:
		if key.x == device:
			return true
	for key: Vector2i in axes:
		if key.x == device:
			return true
	return false

func blocks_resume(device: int) -> bool:
	for key: Vector2i in buttons:
		if key.x == device and key.y not in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
			return true
	return float(axes.get(Vector2i(device, JOY_AXIS_TRIGGER_RIGHT), 0.0)) > 0.30

func restore_movement(device: int, deadzone: float) -> void:
	var motion: Vector2 = movement(device,deadzone)
	var values: Dictionary = {"move_left":maxf(0,-motion.x),"move_right":maxf(0,motion.x),"move_down":maxf(0,motion.y)}
	for action: String in values:
		if values[action] > 0:
			Input.action_press(action,values[action])

func movement(device: int, deadzone: float) -> Vector2:
	var horizontal: float = float(raw_axes.get(Vector2i(device, JOY_AXIS_LEFT_X), 0.0))
	var vertical: float = float(raw_axes.get(Vector2i(device, JOY_AXIS_LEFT_Y), 0.0))
	var result := Vector2(signf(horizontal)*maxf(0,(absf(horizontal)-deadzone)/(1-deadzone)),signf(vertical)*maxf(0,(absf(vertical)-deadzone)/(1-deadzone)))
	var left: bool = buttons.has(Vector2i(device,JOY_BUTTON_DPAD_LEFT))
	var right: bool = buttons.has(Vector2i(device,JOY_BUTTON_DPAD_RIGHT))
	var up: bool = buttons.has(Vector2i(device,JOY_BUTTON_DPAD_UP))
	var down: bool = buttons.has(Vector2i(device,JOY_BUTTON_DPAD_DOWN))
	if left or right:
		result.x = float(right)-float(left)
	if up or down:
		result.y = float(down)-float(up)
	return result

func deliberate_down(device: int, deadzone: float) -> bool:
	if buttons.has(Vector2i(device,JOY_BUTTON_DPAD_UP)):
		return false
	return buttons.has(Vector2i(device,JOY_BUTTON_DPAD_DOWN)) or float(raw_axes.get(Vector2i(device,JOY_AXIS_LEFT_Y),0)) >= maxf(0.50,deadzone+0.12)

func clear(device: int = -1) -> void:
	for history: Dictionary in [buttons, axes, raw_axes]:
		for key: Vector2i in history.keys():
			if device < 0 or key.x == device:
				history.erase(key)
