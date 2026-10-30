extends Control

var hub: Node
var back_button: Button
var rows: Dictionary = {}
var style_option: OptionButton
var deadzone_slider: HSlider
var rumble_check: CheckButton
var guide: Label
var deadzone_label: Label
var strength_slider: HSlider
var strength_label: Label
var status: Label
var refreshing: bool = false

const Pocket = preload("res://scripts/pocket_ui.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Pocket.make_theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	guide = label(self, "", 15)
	guide.position = Vector2(212,153)
	guide.size = Vector2(368,214)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i: int in hub.Bindings.ACTIONS.size():
		var action: String = hub.Bindings.ACTIONS[i]
		var row := HBoxContainer.new()
		row.position = Vector2(696,176+i*53)
		row.add_theme_constant_override("separation", 8)
		add_child(row)
		var title := label(row, {"jump":"Jump / double jump", "attack":"Combo / reflect", "dash":"Dodge / air dash", "interact":"Interact / speak", "pause_level":"Pause"}[action],15)
		title.custom_minimum_size.x = 166
		var button := Button.new()
		button.custom_minimum_size = Vector2(194,40)
		button.add_theme_font_size_override("font_size",14)
		button.pressed.connect(func() -> void: hub.waiting_action = action; refresh())
		row.add_child(button)
		rows[action] = button
	var layout_label := label(self,"Button labels",15)
	layout_label.position = Vector2(212,383)
	style_option = OptionButton.new()
	style_option.position = Vector2(365,375)
	style_option.custom_minimum_size = Vector2(215,38)
	for item: String in ["Auto","Xbox","PlayStation","Nintendo"]:
		style_option.add_item(item)
	style_option.item_selected.connect(func(index: int) -> void: hub.label_style = style_option.get_item_text(index); hub.save_settings(); refresh())
	add_child(style_option)
	rumble_check = CheckButton.new()
	rumble_check.position = Vector2(212,427)
	rumble_check.custom_minimum_size = Vector2(368,38)
	rumble_check.text = "Controller rumble: ON"
	rumble_check.toggled.connect(func(enabled: bool) -> void:
		rumble_check.text = "Controller rumble: " + ("ON" if enabled else "OFF")
		if not refreshing:
			hub.rumble_enabled = enabled
			hub.save_settings()
			if not enabled and hub.last_device >= 0:
				Input.stop_joy_vibration(hub.last_device)
			else:
				hub.rumble("hit"))
	add_child(rumble_check)
	deadzone_label = label(self,"",15)
	deadzone_label.position = Vector2(212,479)
	deadzone_slider = HSlider.new()
	deadzone_slider.position = Vector2(212,508)
	deadzone_slider.min_value = 0.1
	deadzone_slider.max_value = 0.4
	deadzone_slider.step = 0.01
	deadzone_slider.custom_minimum_size = Vector2(368,24)
	deadzone_slider.value_changed.connect(func(value: float) -> void:
		if not refreshing:
			hub.deadzone = value
			hub.Bindings.install(hub.mapping,value)
			hub.save_settings()
			deadzone_label.text = "Stick deadzone: %d%%" % roundi(value*100))
	add_child(deadzone_slider)
	strength_label = label(self,"",15)
	strength_label.position = Vector2(696,479)
	strength_slider = HSlider.new()
	strength_slider.position = Vector2(696,508)
	strength_slider.min_value = 0
	strength_slider.max_value = 1
	strength_slider.step = 0.05
	strength_slider.custom_minimum_size = Vector2(368,24)
	strength_slider.value_changed.connect(func(value: float) -> void:
		if not refreshing:
			hub.rumble_strength = value
			hub.save_settings()
			strength_label.text = "Rumble strength: %d%%" % roundi(value*100)
			hub.rumble("hit"))
	add_child(strength_slider)
	status = label(self,"",12)
	status.position = Vector2(696,544)
	status.size = Vector2(368,46)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var reset := Button.new()
	reset.text = "RESTORE DEFAULTS"
	reset.position = Vector2(212,589)
	reset.custom_minimum_size = Vector2(368,42)
	reset.pressed.connect(hub.defaults)
	add_child(reset)
	back_button = Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(696,589)
	back_button.custom_minimum_size = Vector2(368,42)
	back_button.pressed.connect(hub.close_panel)
	add_child(back_button)
	var order: Array[Control] = []
	for action: String in hub.Bindings.ACTIONS:
		order.append(rows[action])
	order.append_array([style_option,rumble_check,deadzone_slider,strength_slider,reset,back_button])
	for i: int in order.size():
		var previous: NodePath = order[i].get_path_to(order[(i+order.size()-1)%order.size()])
		var following: NodePath = order[i].get_path_to(order[(i+1)%order.size()])
		order[i].focus_previous = previous
		order[i].focus_next = following
		order[i].focus_neighbor_top = previous
		order[i].focus_neighbor_bottom = following
	reset.focus_neighbor_right = reset.get_path_to(back_button)
	back_button.focus_neighbor_left = back_button.get_path_to(reset)
	refresh()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("080b16f5"))
	draw_texture_rect(Pocket.book(),Rect2(152,48,976,624),false)
	Pocket.paragraph(self,"CONTROLS & CONTROLLER",Vector2(212,112),368,24)
	Pocket.paragraph(self,"BUTTON BINDINGS",Vector2(696,112),368,24)
	Pocket.paragraph(self,"Select an action, then press its new button.",Vector2(696,147),368,14,Pocket.MUTED)

func label(parent: Node, value: String, size: int) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", Pocket.INK)
	parent.add_child(result)
	return result

func refresh() -> void:
	if guide == null:
		return
	refreshing = true
	guide.text = "Left stick / D-pad: move\nDown + attack: aerial plunge\nDown + jump: drop through a ledge\nRB / R1 or RT / R2: alternate dodge*\nSouth face: confirm · East face: back\nHelp: View / Touchpad / Minus / F1\nKeyboard: A/D move · Space jump · J attack\nShift dodge · E use · Esc pause · M mute"
	var alternate: String = hub.alternate_dodge_label()
	guide.text = guide.text.replace("RB / R1 or RT / R2: alternate dodge*",alternate+": alternate dodge*" if not alternate.is_empty() else "Alternate dodge: disabled by this layout")
	for action: String in rows:
		rows[action].text = "PRESS NEW BUTTON..." if hub.waiting_action == action else hub.Bindings.label(hub.mapping[action], hub.style()) + "   /   REMAP"
	style_option.select(["Auto", "Xbox", "PlayStation", "Nintendo"].find(hub.label_style))
	rumble_check.button_pressed = hub.rumble_enabled
	deadzone_slider.value = hub.deadzone
	strength_slider.value = hub.rumble_strength
	strength_label.text = "Rumble strength: %d%%" % roundi(hub.rumble_strength * 100)
	deadzone_label.text = "Stick deadzone: %d%%" % roundi(hub.deadzone * 100)
	status.text = "Press a face, shoulder, stick-click or Menu button.\nView / F1 / Esc cancels. Existing bindings swap." if not hub.waiting_action.is_empty() else "*Shoulder dodge uses the default east-button binding.\nSettings save automatically. Menu confirm/back stay fixed."
	refreshing = false
