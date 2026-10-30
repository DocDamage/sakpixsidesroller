extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Bolt = preload("res://scripts/cursed_bolt.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/responsive-check-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	# Each supplied silhouette needs room for a health bar during its hit pose.
	for species: String in ["pumpkin", "bat", "plant", "warden", "mimic", "rat", "mushroom", "eye", "guard", "witch", "mosquito"]:
		var sample := Enemy.new()
		sample.species = species
		sample.flying = species in ["bat", "eye"]
		root.add_child(sample)
		sample.set_physics_process(false)
		var sheet: Image = sample.visual.texture.get_image()
		if sheet.is_compressed():
			sheet.decompress()
		var readable: bool = true
		for frame: int in range(int(Animator.IDLE[species])):
			sample.phase = float(frame) / 10.0
			sample.state = 3
			sample.hit_timer = 0.16
			Animator.update(sample)
			var occupied: Rect2i = sheet.get_region(Rect2i(sample.visual.region_rect)).get_used_rect()
			var visible_top: float = sample.visual.position.y + (occupied.position.y - 32) * sample.visual.scale.y
			readable = readable and sample.ui_top + 4 < visible_top - 2
		check(readable, species.capitalize() + " health feedback clears every supplied idle/hit silhouette")
		sample.queue_free()
	await ticks(2)
	for chapter: int in range(1, 5):
		level = load(Campaign.SCENES[chapter - 1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		await place()
		level.player.facing = 1
		level.player.hit_pause = 0.08
		Pad.axis(JOY_AXIS_LEFT_X, -0.9)
		Pad.button(JOY_BUTTON_X, true)
		await ticks(2)
		Pad.release()
		await ticks(7)
		check(level.player.attack_time > 0 and level.player.facing == -1, "Stage %d keeps a buffered attack's direction after the stick is released" % chapter)
		level.player.respawn(Vector2(450, 350))
		await ticks(2)
		level.player.hit_pause = 0.08
		Pad.axis(JOY_AXIS_LEFT_Y, 1)
		Pad.button(JOY_BUTTON_X, true)
		await ticks(2)
		Pad.release()
		await ticks(7)
		check(level.player.attack_mode == "plunge" and level.player.velocity.y >= 670, "Stage %d retains an aerial plunge tap through hit pause" % chapter)
		await place()
		Pad.axis(JOY_AXIS_LEFT_X, 0.8)
		await ticks(3)
		await tap(JOY_BUTTON_START)
		await tap(JOY_BUTTON_B)
		check(not paused and not hub.suppress_until_release and level.player.velocity.x > 0 and level.player.dash_time == 0, "Stage %d resumes an already-held stick without requiring neutral or leaking a dodge" % chapter)
		Pad.release()
		await ticks(10)
		check(not Input.is_action_pressed("move_right") and absf(level.player.velocity.x) < 1, "Stage %d releases restored stick movement without sticking" % chapter)
		await place()
		Pad.button(JOY_BUTTON_DPAD_RIGHT, true)
		await ticks(3)
		await tap(JOY_BUTTON_START)
		await tap(JOY_BUTTON_B)
		check(not paused and not hub.suppress_until_release and level.player.velocity.x > 0 and level.player.jumps == 0, "Stage %d resumes a held D-pad direction without a menu-confirm jump" % chapter)
		Pad.release()
		await ticks(10)
		check(not Input.is_action_pressed("move_right") and absf(level.player.velocity.x) < 1, "Stage %d releases restored D-pad movement without sticking" % chapter)
		level.player.respawn(Vector2(450, 350))
		await ticks(2)
		await tap(JOY_BUTTON_START)
		Pad.button(JOY_BUTTON_B, true)
		await ticks(2)
		var before: float = level.player.position.y
		await ticks(10)
		check(not paused and hub.suppress_until_release and level.player.position.y > before + 10 and level.player.dash_time == 0, "Stage %d keeps gravity running while menu-back is held after resuming in the air" % chapter)
		Pad.release()
		await ticks(3)
		check(not hub.suppress_until_release and level.player.attack_buffer == 0 and level.player.dash_buffer == 0, "Stage %d resumes cleanly once the held menu button is released" % chapter)
		var sample: Node2D
		for enemy: Node2D in get_nodes_in_group("enemies"):
			if enemy.species == "plant":
				sample = enemy
				break
		sample.reset_encounter()
		sample.strike(sample.position + Vector2(0, -30), 0, 1, 0)
		check(sample.health == 2 and sample.damage_trail == 3, "Stage %d damage feedback retains the lost portion of an enemy health bar" % chapter)
		sample.hit_pause = 0
		sample._physics_process(0.04)
		check(sample.damage_trail == 3, "Stage %d health trail waits for the impact before draining" % chapter)
		sample._physics_process(0.4)
		check(sample.damage_trail == sample.health and sample.visual.scale.y < sample.body_scale, "Stage %d health trail settles and recovery has a grounded, readable pose" % chapter)
		sample.reset_encounter()
		check(sample.damage_trail == sample.max_health, "Stage %d encounter reset restores all health feedback" % chapter)
		var bolt: Node2D = Bolt.new()
		bolt.position = level.player.position + Vector2(30, -30)
		bolt.velocity = Vector2.ZERO
		bolt.lifetime = 0.01
		level.add_child(bolt)
		bolt._physics_process(0.02)
		check(bolt.spent and not bolt.deflect(bolt.position, 1), "Stage %d expired projectiles cannot award a late reflection" % chapter)
		var windows: Array = level.get_node("WorldMotion").windows
		if chapter >= 3:
			check(windows.size() == (5 if chapter == 3 else 1), "Stage %d lights supplied shop windows without adding ground clutter" % chapter)
			var clock_before: float = float(windows[0].get_shader_parameter("clock"))
			paused = true
			await ticks(4)
			check(is_equal_approx(float(windows[0].get_shader_parameter("clock")), clock_before), "Stage %d new window lighting pauses with the world" % chapter)
			paused = false
		Pad.release()
		level.queue_free()
		await ticks(2)
	print("RESPONSIVE RESULT: %d/%d checks passed" % [checks - failures, checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
