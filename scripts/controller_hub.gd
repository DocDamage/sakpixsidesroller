extends Node

const Bindings = preload("res://scripts/controller_bindings.gd")
const ControllerPanel = preload("res://scripts/controller_panel.gd")
const DeviceState = preload("res://scripts/controller_devices.gd")
var mapping: Dictionary = Bindings.DEFAULTS.duplicate()
var deadzone: float = 0.24
var rumble_enabled: bool = true
var rumble_strength: float = 0.75
var last_rumble_strength := Vector2.ZERO
var label_style: String = "Auto"
var using_pad: bool = false
var last_device: int = -1
var settings_path: String = "user://controller_settings.cfg"
var level: Node2D
var panel: Control
var waiting_action: String = ""
var was_paused: bool = false
var rumble_count: int = 0
var suppress_until_release: bool = false
var devices: RefCounted = DeviceState.new()
var focus_pause_enabled: bool = true
var trigger: RefCounted = preload("res://scripts/controller_trigger.gd").new()
var menu_focus: WeakRef
var feedback: RefCounted = preload("res://scripts/controller_feedback.gd").new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	Bindings.install(mapping, deadzone)
	Input.joy_connection_changed.connect(connection_changed)
	get_window().focus_exited.connect(focus_lost)
	var connected := Input.get_connected_joypads()
	if not connected.is_empty():
		last_device = connected[0]
		using_pad = true
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	add_child(canvas)
	panel = ControllerPanel.new()
	panel.hub = self
	canvas.add_child(panel)
	panel.hide()

func _process(delta: float) -> void:
	feedback.advance(delta)
	var scene := get_tree().current_scene
	if scene != null and scene != level and scene.get("player") != null:
		level = scene
		level.player.sound_requested.connect(player_sound)
		level.player.hurt.connect(func(_health: int) -> void: rumble("hurt"))
	if suppress_until_release:
		flush_gameplay()
		if not get_tree().paused and not devices.blocks_resume(last_device):
			suppress_until_release = false
			if using_pad:
				devices.restore_movement(last_device, deadzone)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		devices.observe(event, deadzone)
		trigger.observe(event, mapping["dash"] == JOY_BUTTON_B)
		var stick_intent: bool = event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] and absf(event.axis_value) > deadzone+0.02
		var trigger_intent: bool = event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT and event.axis_value >= 0.62 and mapping["dash"] == JOY_BUTTON_B
		if event is InputEventJoypadButton and event.pressed or stick_intent or trigger_intent:
			using_pad = true
			last_device = event.device
	elif event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
		using_pad = false
	# Let an open label picker consume navigation/back before the enclosing panel.
	if panel.visible and panel.style_option.get_popup().visible and not event.is_action_pressed("pause_level") and not event.is_action_pressed("controller_help"):
		return
	if panel.visible:
		if not waiting_action.is_empty():
			if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE or event.is_action_pressed("controller_help"):
				waiting_action = ""
				panel.refresh()
			elif event is InputEventJoypadButton and event.pressed:
				if rebind(waiting_action, event.button_index):
					waiting_action = ""
				panel.refresh()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel") or (event.is_action_pressed("pause_level") and not event.is_action_pressed("ui_accept")) or event.is_action_pressed("controller_help"):
			close_panel()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("controller_help") and is_instance_valid(level):
		open_panel()
		get_viewport().set_input_as_handled()
	elif is_instance_valid(level) and ((event.is_action_pressed("pause_level") and (not get_tree().paused or not event.is_action_pressed("ui_accept"))) or (get_tree().paused or level.completed and level.get("district") != null) and event.is_action_pressed("ui_cancel")):
		flush_gameplay()
		suppress_until_release = true
		level.toggle_pause()
		get_viewport().set_input_as_handled()

func style() -> String:
	if label_style != "Auto":
		return label_style
	var device_name: String = Input.get_joy_name(last_device).to_lower() if last_device >= 0 else ""
	if "playstation" in device_name or "dual" in device_name or "ps4" in device_name or "ps5" in device_name:
		return "PlayStation"
	if "nintendo" in device_name or "switch" in device_name:
		return "Nintendo"
	return "Xbox"

func aim_direction() -> float:
	var direction: float = horizontal_direction()
	return 0.0 if using_pad and absf(direction) < 0.20 else direction

func horizontal_direction() -> float:
	return devices.movement(last_device,deadzone).x if using_pad else Input.get_axis("move_left","move_right")

func down_pressed() -> bool:
	return devices.deliberate_down(last_device,deadzone) if using_pad else Input.is_action_pressed("move_down")

func focus_lost() -> void:
	quiet_feedback()
	devices.clear()
	trigger.clear()
	flush_gameplay()
	if focus_pause_enabled and is_instance_valid(level) and not level.completed and not get_tree().paused:
		level.toggle_pause()
		level.hud.notify_player("Game paused while the window was away.")
	if panel.visible:
		waiting_action = ""
		panel.refresh()

func quiet_feedback() -> void:
	feedback.clear()
	last_rumble_strength = Vector2.ZERO
	for device: int in Input.get_connected_joypads():
		Input.stop_joy_vibration(device)

func prompt(action: String) -> String:
	if using_pad:
		return Bindings.label(int(mapping[action]), style())
	return {"jump": "SPACE", "attack": "J", "dash": "SHIFT", "interact": "E", "pause_level": "ESC"}.get(action, "F1")

func caption(value: String) -> String:
	return value.replace("[E]", "[" + prompt("interact") + "]")

func footer() -> String:
	if not using_pad:
		return "A D MOVE   SPACE JUMP / DOUBLE JUMP   J COMBO / REFLECT   SHIFT DASH   E USE"
	return "LS / D-PAD MOVE   %s JUMP / DOUBLE JUMP   %s COMBO / REFLECT   %s DODGE   %s USE" % [prompt("jump"), prompt("attack"), prompt("dash"), prompt("interact")]

func special_footer() -> String:
	if is_instance_valid(level) and level.district != null:
		return "W / S CLIMB / SWIM   W + E MOON HOOK   TAB MAP   S + SPACE DROP" if not using_pad else "UP / DOWN CLIMB / SWIM   UP + %s HOOK   %s MAP   DOWN + %s DROP" % [prompt("interact"),district_map_prompt(),prompt("jump")]
	if not using_pad:
		return "S + J AIR PLUNGE    S + SPACE LEDGE DROP    M MUTE / UNMUTE"
	var text: String = "DOWN + %s AIR PLUNGE    DOWN + %s LEDGE DROP" % [prompt("attack"),prompt("jump")]
	var alternate: String = alternate_dodge_label()
	return text + ("    " + alternate + " DODGE" if not alternate.is_empty() else "")

func district_map_prompt() -> String:
	if not using_pad:
		return "TAB"
	return Bindings.label(JOY_BUTTON_LEFT_SHOULDER,style()) if JOY_BUTTON_LEFT_SHOULDER not in mapping.values() else "DOWN + "+prompt("interact")

func alternate_dodge_label() -> String:
	if mapping["dash"] != JOY_BUTTON_B:
		return ""
	var trigger_label: String = {"Xbox":"RT","PlayStation":"R2","Nintendo":"ZR"}[style()]
	if JOY_BUTTON_RIGHT_SHOULDER not in mapping.values():
		return Bindings.label(JOY_BUTTON_RIGHT_SHOULDER,style())+" / "+trigger_label
	return trigger_label

func open_panel() -> void:
	if not is_instance_valid(level) or panel.visible:
		return
	var focused: Control = get_viewport().gui_get_focus_owner()
	menu_focus = weakref(focused) if focused != null and focused.is_visible_in_tree() else null
	was_paused = get_tree().paused
	if not was_paused and not level.completed:
		level.toggle_pause()
	panel.show()
	panel.refresh()
	panel.back_button.grab_focus()
	flush_gameplay()

func close_panel() -> void:
	waiting_action = ""
	panel.style_option.get_popup().hide()
	panel.hide()
	if not was_paused and is_instance_valid(level) and not level.completed and get_tree().paused:
		level.toggle_pause()
	elif is_instance_valid(level):
		level.hud.menu.show()
		var previous: Control = menu_focus.get_ref() if menu_focus != null else null
		if previous != null and previous.is_visible_in_tree() and level.hud.menu.is_ancestor_of(previous):
			previous.grab_focus()
		else:
			(level.hud.continue_button if level.completed and level.hud.continue_button.visible else (level.hud.restart_button if level.completed else level.hud.resume_button)).grab_focus()
	flush_gameplay()
	suppress_until_release = true

func flush_gameplay() -> void:
	for action: String in Bindings.GAMEPLAY:
		Input.action_release(action)
	if is_instance_valid(level):
		level.player.jump_buffer = 0
		level.player.jump_wants_drop = false
		level.player.attack_buffer = 0
		level.player.buffered_attack_direction = 0
		level.player.attack_wants_plunge = false
		level.player.dash_buffer = 0
		level.player.buffered_dash_direction = 0

func rebind(action: String, index: int) -> bool:
	if action not in Bindings.ACTIONS or not Bindings.can_bind(index):
		return false
	var previous: int = mapping[action]
	for other: String in mapping:
		if other != action and mapping[other] == index:
			mapping[other] = previous
	mapping[action] = index
	trigger.clear()
	Bindings.install(mapping, deadzone)
	save_settings()
	return true

func defaults() -> void:
	feedback.clear()
	trigger.clear()
	mapping = Bindings.DEFAULTS.duplicate()
	deadzone = 0.24
	rumble_enabled = true
	rumble_strength = 0.75
	label_style = "Auto"
	Bindings.install(mapping, deadzone)
	save_settings()
	panel.refresh()

func connection_changed(device: int, connected: bool) -> void:
	if not connected:
		devices.clear(device)
		trigger.clear(device)
	if connected:
		if last_device < 0:
			last_device = device
		if is_instance_valid(level):
			level.hud.notify_player("Controller connected. Press any button to use it.")
	elif device == last_device:
		feedback.clear()
		Input.stop_joy_vibration(device)
		flush_gameplay()
		using_pad = false
		last_device = -1
		if is_instance_valid(level):
			if not get_tree().paused and not level.completed:
				level.toggle_pause()
			level.hud.notify_player("Controller disconnected. Reconnect or use the keyboard.")

func player_sound(kind: String) -> void:
	if kind in ["dash", "land"]:
		rumble(kind)

func rumble(kind: String) -> void:
	if not rumble_enabled or not using_pad or rumble_strength <= 0:
		last_rumble_strength = Vector2.ZERO
		feedback.clear()
		return
	var values: Vector3 = feedback.request(kind)
	if values == Vector3.ZERO:
		return
	rumble_count += 1
	last_rumble_strength = Vector2(values.x, values.y) * rumble_strength
	if last_device in Input.get_connected_joypads():
		Input.start_joy_vibration(last_device, last_rumble_strength.x, last_rumble_strength.y, values.z)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("controller", "mapping", mapping)
	config.set_value("controller", "deadzone", deadzone)
	config.set_value("controller", "rumble", rumble_enabled)
	config.set_value("controller", "rumble_strength", rumble_strength)
	config.set_value("controller", "labels", label_style)
	config.save(settings_path)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var saved: Variant = config.get_value("controller", "mapping", {})
	var used: Array[int] = []
	var valid: bool = saved is Dictionary and saved.size() == Bindings.ACTIONS.size()
	for action: String in Bindings.ACTIONS:
		var index: Variant = saved.get(action, -1) if saved is Dictionary else -1
		if not (index is int) or not Bindings.can_bind(index) or index in used:
			valid = false
		else:
			used.append(index)
	if valid:
		mapping = saved.duplicate()
	deadzone = clampf(float(config.get_value("controller", "deadzone", 0.24)), 0.1, 0.4)
	rumble_enabled = bool(config.get_value("controller", "rumble", true))
	rumble_strength = clampf(float(config.get_value("controller", "rumble_strength", 0.75)), 0, 1)
	var labels: String = str(config.get_value("controller", "labels", "Auto"))
	label_style = labels if labels in ["Auto", "Xbox", "PlayStation", "Nintendo"] else "Auto"
