extends SceneTree

const Enemy = preload("res://scripts/haunt.gd")
const Animator = preload("res://scripts/enemy_animation.gd")
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

func tap(button: int) -> void:
	Pad.button(button, true)
	await ticks()
	Pad.button(button, false)
	await ticks()

func place() -> void:
	Pad.release()
	level.player.respawn(Vector2(450, 598))
	level.player.invincible = 1000
	await ticks(10)

func animation_populated(enemy: Node2D) -> bool:
	var sheet: Image = enemy.visual.texture.get_image()
	if sheet.is_compressed():
		sheet.decompress()
	for state: int in [0, 1, 2, 3, 4]:
		for frame: int in range(60):
			enemy.state = state
			enemy.dead = state == 4
			enemy.awakened = true
			enemy.phase = frame / 10.0
			enemy.state_time = (frame / 60.0) * (0.65 if enemy.dead else 0.38)
			for speed: float in [0.0, -35.0]:
				Animator.update(enemy, speed)
				var region: Image = sheet.get_region(Rect2i(enemy.visual.region_rect))
				if not region.get_used_rect().has_area():
					return false
	return true

func has_label(value: String) -> bool:
	for node: Node in level.effects.get_children():
		if node is Label and node.text == value:
			return true
	return false

func second_button(device: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_A
	event.pressed = pressed
	Input.parse_input_event(event)

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/living-world-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for species: String in ["pumpkin", "bat", "plant", "warden", "mimic", "rat", "witch", "mosquito"]:
		var enemy := Enemy.new()
		enemy.species = species
		enemy.flying = species == "bat"
		enemy.position = Vector2(800, 600)
		level.add_child(enemy)
		enemy.set_physics_process(false)
		check(animation_populated(enemy), species.capitalize() + " idle, movement, attack and death stay inside populated source frames")
		enemy.dead = false
		enemy.state = 1
		enemy.hit_timer = 0.28
		Animator.update(enemy)
		check(enemy.flying or absf(enemy.visual.position.y + enemy.visual.scale.y * 32) < 0.01, species.capitalize() + " reaction keeps its feet anchored")
		enemy.queue_free()
	await ticks()
	var guardian: Node2D = level.combat.guardian
	guardian.state = 1
	guardian.hit_timer = 0
	guardian.strike(guardian.position + Vector2(0, -30), 0, 1)
	check(guardian.last_hit_armored and guardian.state == 1 and has_label("ARMOR"), "Light strikes show armor feedback without canceling a guardian charge")
	guardian.hit_timer = 0
	guardian.strike(guardian.position + Vector2(0, -30), 0, 2)
	check(guardian.last_hit_broke_guard and guardian.state == 3 and has_label("GUARD BREAK"), "Heavy strikes interrupt the charge and identify the guard break")
	var motion: Node2D = level.get_node("WorldMotion")
	check(motion.smoke.size() == 4, "All four chapter-one campfires emit supplied animated smoke")
	var first: Texture2D = motion.smoke[0]["visual"].texture
	await ticks(9)
	check(motion.smoke[0]["visual"].texture != first, "Camp smoke advances through source frames")
	await place()
	level.player.facing = 1
	Pad.axis(JOY_AXIS_LEFT_X, -0.28)
	await ticks(3)
	check(level.player.facing == 1 and level.player.velocity.x < 0, "A slight stick lean allows slow movement without flickering facing")
	await tap(JOY_BUTTON_B)
	check(level.player.facing == 1 and level.player.dash_time > 0, "A slight opposite stick lean cannot accidentally reverse a dodge")
	await place()
	Pad.axis(JOY_AXIS_LEFT_X, -0.8)
	await ticks(3)
	check(level.player.facing == -1, "A deliberate stick direction turns immediately")
	Pad.release()
	await tap(JOY_BUTTON_BACK)
	hub.panel.strength_slider.grab_focus()
	var strength: float = hub.rumble_strength
	await tap(JOY_BUTTON_DPAD_RIGHT)
	check(hub.rumble_strength > strength, "Controller navigation adjusts the rumble strength slider")
	hub.panel.strength_slider.value = 0.25
	hub.rumble("hurt")
	check(hub.last_rumble_strength.is_equal_approx(Vector2(0.65, 0.8) * 0.25), "Rumble intensity scales both vibration motors")
	hub.rumble_strength = 1
	hub.load_settings()
	check(is_equal_approx(hub.rumble_strength, 0.25), "Rumble intensity survives a settings reload")
	hub.rumble_strength = 0
	var pulses: int = hub.rumble_count
	hub.rumble("hit")
	check(hub.rumble_count == pulses and hub.last_rumble_strength == Vector2.ZERO, "Zero rumble strength produces no vibration request")
	hub.defaults()
	await tap(JOY_BUTTON_B)
	Pad.axis(JOY_AXIS_LEFT_X, 1)
	await ticks(3)
	var active: int = hub.last_device
	hub.connection_changed(78, true)
	check(hub.last_device == active, "Connecting an idle second pad does not steal the active controller")
	second_button(78, true)
	Pad.button(JOY_BUTTON_A, true)
	second_button(78, false)
	check(hub.devices.held(Pad.DEVICE) and not hub.devices.held(78), "A release from one pad does not clear another pad's held buttons")
	hub.connection_changed(78, false)
	check(not paused, "Unplugging an inactive controller does not pause the active player's game")
	Pad.release()
	await ticks()
	Pad.axis(JOY_AXIS_LEFT_X, 1)
	await ticks(3)
	root.focus_exited.emit()
	await ticks()
	check(paused and not Input.is_action_pressed("move_right") and not hub.devices.held(Pad.DEVICE), "Window focus loss pauses and clears held gameplay input")
	var stopped: Vector2 = level.player.position
	await ticks(12)
	check(level.player.position == stopped, "The player remains safe while the game window is away")
	await tap(JOY_BUTTON_START)
	await tap(JOY_BUTTON_BACK)
	hub.waiting_action = "attack"
	root.focus_exited.emit()
	check(hub.waiting_action.is_empty() and hub.panel.visible, "Changing windows cancels pending remapping while preserving the settings screen")
	await tap(JOY_BUTTON_B)
	Pad.release()
	paused = false
	level.queue_free()
	await ticks()
	level = load("res://scenes/lantern_road.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	motion = level.get_node("WorldMotion")
	check(motion.smoke.size() == 9 and motion.butterflies.size() == 3, "Chapter two adds chimney smoke and butterfly motion to camp smoke")
	var supported: bool = true
	for visual: Node in motion.hamlet.get_children():
		if visual is Sprite2D and not str(visual.texture.resource_path).contains("smoke_"):
			var on_land: bool = false
			for span: Vector2 in level.profile.builder.FLOORS:
				on_land = on_land or visual.position.x - 62 >= span.x and visual.position.x + 62 <= span.y
			supported = supported and on_land
	check(supported and motion.hamlet.position == Vector2.ZERO, "Roadside buildings remain on solid ground without drifting into stream gaps")
	var moving_plants: int = 0
	for visual: Node in level.get_node("RoadsideLife").get_children():
		if visual is Sprite2D and visual.material == motion.breeze:
			moving_plants += 1
	check(moving_plants >= 20, "Supplied orchard trees, crops and flowers share the anchored wind shader")
	level.toggle_pause()
	var clock_before: float = motion.clock
	var flutter_before: Vector2 = motion.butterflies[0]["visual"].position
	await ticks(15)
	check(motion.clock == clock_before and motion.butterflies[0]["visual"].position == flutter_before, "Wind, smoke and butterflies pause with the world")
	level.toggle_pause()
	hub.defaults()
	print("LIVING WORLD RESULT: %d/%d checks passed" % [checks - failures, checks])
	level.queue_free()
	await ticks()
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
