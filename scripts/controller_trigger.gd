extends RefCounted

# Separate press/release thresholds prevent trigger travel jitter from re-dodging.
var latched: Dictionary = {}

func observe(event: InputEvent, enabled: bool) -> void:
	if not (event is InputEventJoypadMotion) or event.axis != JOY_AXIS_TRIGGER_RIGHT:
		return
	if not enabled:
		clear(event.device)
	elif event.axis_value >= 0.62 and not latched.has(event.device):
		latched[event.device] = true
		Input.action_press("dash")
	elif event.axis_value <= 0.30 and latched.has(event.device):
		clear(event.device)

func clear(device: int = -1) -> void:
	if device < 0:
		latched.clear()
	else:
		latched.erase(device)
	if latched.is_empty() and InputMap.has_action("dash"):
		Input.action_release("dash")
