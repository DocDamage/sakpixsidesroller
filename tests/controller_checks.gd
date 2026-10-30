extends SceneTree

const Pad = preload("res://tests/pad_driver.gd")
var level: Node2D
var hub: Node
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame

func check(value: bool, title: String) -> void:
	checks += 1
	if value:
		print("PASS: " + title)
	else:
		failures += 1
		push_error("FAIL: " + title)

func tap(index: int, count: int = 2) -> void:
	Pad.button(index, true)
	await ticks(count)
	Pad.button(index, false)
	await ticks(2)

func place(at: Vector2) -> void:
	Pad.release()
	level.player.respawn(at)
	level.player.invincible = 1000
	await ticks(10)

func run() -> void:
	root.size = Vector2i(1280, 720)
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/controller-test.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	print("PHYSICAL CONTROLLERS: ", Input.get_connected_joypads())
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	await place(Vector2(450, 598))
	var x: float = level.player.position.x
	Pad.axis(JOY_AXIS_LEFT_X, 0.15)
	await ticks(20)
	check(absf(level.player.position.x - x) < 1, "Stick drift inside deadzone does not move the player")
	Pad.axis(JOY_AXIS_LEFT_X, 0.60)
	await ticks(20)
	var partial: float = level.player.position.x - x
	check(partial > 10 and partial < 90, "Analog movement responds proportionally outside the deadzone")
	Pad.axis(JOY_AXIS_LEFT_X, 1)
	await ticks(20)
	check(level.player.position.x - x > partial + 90, "Full stick gives full running speed")
	Pad.release()
	await ticks()
	check(hub.using_pad and hub.prompt("jump") == "A", "Joypad input selects controller button prompts")
	hub.label_style = "PlayStation"
	check(hub.prompt("dash") == "Circle" and hub.caption("[E] Speak") == "[Triangle] Speak", "PlayStation prompts match face-button positions and world interactions")
	hub.label_style = "Nintendo"
	check(hub.prompt("jump") == "B" and hub.prompt("attack") == "Y", "Nintendo labels preserve the same physical positions")
	hub.label_style = "Xbox"
	await place(Vector2(450, 598))
	await tap(JOY_BUTTON_DPAD_LEFT, 12)
	check(level.player.position.x < 410 and level.player.facing < 0, "D-pad movement and facing work")
	await tap(JOY_BUTTON_A, 8)
	check(level.player.position.y < 550 and level.player.jumps == 1, "South face button jumps")
	await tap(JOY_BUTTON_A)
	check(level.player.jumps == 2 and level.player.velocity.y < 0, "Second south-button press double jumps")
	Pad.button(JOY_BUTTON_DPAD_DOWN, true)
	await tap(JOY_BUTTON_X)
	check(level.player.attack_mode == "plunge", "Down plus attack performs the aerial plunge")
	Pad.release()
	await place(Vector2(610, 478))
	Pad.button(JOY_BUTTON_DPAD_DOWN, true)
	await tap(JOY_BUTTON_A)
	check(level.player.drop_time > 0 and not level.player.get_collision_mask_value(3), "Down plus jump drops through one-way ledges")
	await place(Vector2(450, 598))
	var pulses: int = hub.rumble_count
	await tap(JOY_BUTTON_B)
	check(level.player.dash_time > 0 and level.player.dash_cooldown > 0, "East face button dodges with invulnerability")
	check(hub.rumble_count > pulses, "Dodge requests controller rumble")
	var charge: float = level.player.dash_cooldown
	pulses = hub.rumble_count
	level.player.take_damage(level.player.position + Vector2(20, 0))
	check(level.player.health == 5 and level.player.dodge_rewarded and level.player.dash_cooldown < charge - 0.17 and hub.rumble_count > pulses, "Dodging incoming damage rewards timing with feedback and a shorter recharge")
	charge = level.player.dash_cooldown
	level.player.take_damage(level.player.position + Vector2(20, 0))
	check(is_equal_approx(level.player.dash_cooldown, charge), "A single dodge cannot award repeated recharge bonuses")
	await place(Vector2(450, 598))
	await tap(JOY_BUTTON_RIGHT_SHOULDER)
	check(level.player.dash_time > 0, "Right shoulder also dodges with the default layout")
	await place(Vector2(450, 598))
	Pad.axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	await ticks()
	check(level.player.dash_time > 0, "Right trigger provides an alternate dodge")
	Pad.axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	await place(Vector2(640, 598))
	var supplies: int = get_nodes_in_group("breakables").size()
	await tap(JOY_BUTTON_X, 12)
	check(get_nodes_in_group("breakables").size() == supplies-1, "West face button breaks urns through timed melee")
	var pumpkin: Node2D = get_nodes_in_group("enemies")[0]
	await place(pumpkin.position + Vector2(-65, -2))
	level.player.facing = 1
	pulses = hub.rumble_count
	await tap(JOY_BUTTON_X, 16)
	check(pumpkin.health < pumpkin.max_health and hub.rumble_count > pulses, "Controller attack damages enemies and gives hit feedback")
	await place(Vector2(320, 598))
	await tap(JOY_BUTTON_Y)
	check(level.hud.notice.begins_with("Cartographer:"), "North face button speaks to NPCs")
	await tap(JOY_BUTTON_START)
	check(paused and level.hud.resume_button.has_focus(), "Menu button pauses and focuses Resume")
	var stopped: Vector2 = level.player.position
	Pad.axis(JOY_AXIS_LEFT_X, 1)
	await ticks(10)
	check(level.player.position == stopped, "Gameplay stops while controller menus are open")
	Pad.axis(JOY_AXIS_LEFT_X, 0)
	await tap(JOY_BUTTON_A)
	check(not paused and level.player.position == stopped, "Menu confirm resumes without leaking into a jump")
	await tap(JOY_BUTTON_START)
	await tap(JOY_BUTTON_B)
	check(not paused and level.player.dash_time <= 0, "Menu back resumes without leaking into dodge")
	await tap(JOY_BUTTON_BACK)
	check(hub.panel.visible and paused and hub.panel.back_button.has_focus(), "View opens a controller-focused settings screen and pauses")
	hub.panel.deadzone_slider.grab_focus()
	var old_zone: float = hub.deadzone
	await tap(JOY_BUTTON_DPAD_RIGHT)
	check(hub.deadzone > old_zone, "D-pad adjusts the stick deadzone slider")
	var focus_contained: bool = true
	for i: int in range(12):
		await tap(JOY_BUTTON_DPAD_UP)
		focus_contained = focus_contained and hub.panel.is_ancestor_of(root.gui_get_focus_owner())
	check(focus_contained and not level.hud.menu.visible, "Settings navigation stays inside its modal panel")
	hub.panel.style_option.grab_focus()
	await tap(JOY_BUTTON_A)
	check(hub.panel.style_option.get_popup().visible, "Controller opens the button-label picker")
	await tap(JOY_BUTTON_DPAD_DOWN)
	await tap(JOY_BUTTON_A)
	check(hub.label_style == "PlayStation", "Controller selects a label style through the picker")
	await tap(JOY_BUTTON_A)
	await tap(JOY_BUTTON_B)
	check(hub.panel.visible and not hub.panel.style_option.get_popup().visible, "Back dismisses the label picker before closing settings")
	hub.panel.rows["jump"].grab_focus()
	await tap(JOY_BUTTON_A)
	check(hub.waiting_action == "jump", "Controller can enter button remapping")
	await tap(JOY_BUTTON_Y)
	check(hub.mapping["jump"] == JOY_BUTTON_Y and hub.mapping["interact"] == JOY_BUTTON_A, "Conflicting remaps swap buttons rather than losing actions")
	hub.panel.deadzone_slider.value = 0.32
	hub.panel.rumble_check.button_pressed = false
	hub.mapping = hub.Bindings.DEFAULTS.duplicate()
	hub.load_settings()
	check(hub.mapping["jump"] == JOY_BUTTON_Y and is_equal_approx(hub.deadzone, 0.32) and not hub.rumble_enabled, "Remaps, deadzone and rumble preference persist to disk")
	pulses = hub.rumble_count
	hub.rumble("hurt")
	check(hub.rumble_count == pulses, "Disabling rumble suppresses vibration requests")
	hub.defaults()
	hub.rebind("attack", JOY_BUTTON_RIGHT_SHOULDER)
	var overlap: bool = false
	for event: InputEvent in InputMap.action_get_events("dash"):
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			overlap = true
	check(not overlap, "Remapping an action to RB removes the alternate dodge conflict")
	hub.defaults()
	await tap(JOY_BUTTON_B)
	check(not hub.panel.visible and not paused, "Back closes settings and restores the prior gameplay state")
	await tap(JOY_BUTTON_START)
	await tap(JOY_BUTTON_BACK)
	await tap(JOY_BUTTON_B)
	check(paused and not hub.panel.visible and level.hud.resume_button.has_focus(), "Closing settings opened from pause keeps it paused and restores menu focus")
	level.hud.mute_button.grab_focus()
	await tap(JOY_BUTTON_A)
	check(level.audio.muted and level.hud.muted, "Controller can mute through the pause menu")
	await tap(JOY_BUTTON_A)
	check(not level.audio.muted, "Controller can unmute through the pause menu")
	await tap(JOY_BUTTON_DPAD_DOWN)
	check(level.hud.quit_button.has_focus(), "Controller can reach Quit Game from the pause menu")
	await tap(JOY_BUTTON_START)
	Pad.axis(JOY_AXIS_LEFT_X, 1)
	await ticks(4)
	hub.connection_changed(Pad.DEVICE, false)
	await ticks()
	check(paused and not Input.is_action_pressed("move_right") and not hub.using_pad, "Unplugging the active pad pauses and clears held gameplay input")
	await tap(JOY_BUTTON_START)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_A
	key.pressed = true
	Input.parse_input_event(key)
	await ticks()
	key.pressed = false
	Input.parse_input_event(key)
	check(not hub.using_pad and hub.prompt("interact") == "E", "Keyboard input restores keyboard prompts immediately")
	hub.rebind("pause_level", JOY_BUTTON_A)
	await tap(JOY_BUTTON_A)
	check(paused, "Remapping pause to the south button still opens the menu")
	await tap(JOY_BUTTON_A)
	check(not paused and level.player.jumps == 0, "Menu confirm takes priority over a remapped south-button pause")
	hub.defaults()
	Pad.release()
	paused = false
	print("CONTROLLER RESULT: %d/%d checks passed" % [checks - failures, checks])
	level.queue_free()
	await ticks()
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
