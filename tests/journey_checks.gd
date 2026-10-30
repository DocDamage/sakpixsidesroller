extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/journey-check-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	Input.use_accumulated_input = false
	for chapter: int in range(1, 5):
		level = load(Campaign.SCENES[chapter - 1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		level.player.set_physics_process(false)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		var details: Node2D = level.get_node("JourneyDetails")
		check(not details.signs.is_empty(), "Stage %d has a readable forward route sign" % chapter)
		var props_on_banks: bool = true
		for visual: Node in details.get_children():
			if not visual is Sprite2D:
				continue
			for gap: Vector2 in level.profile.gaps:
				if visual.position.x > gap.x and visual.position.x < gap.y:
					props_on_banks = false
		check(props_on_banks, "Stage %d new scenery stays on land and preserves open water gaps" % chapter)
		var guardian: Node2D = level.combat.guardian
		level.player.position = guardian.home + Vector2(-200, 0)
		guardian.health = guardian.max_health / 2 + 1
		guardian.state = 0
		guardian.alert_cooldown = 0
		guardian._physics_process(0.14)
		check(guardian.state == 1 and is_equal_approx(guardian.committed_windup, 0.70), "Stage %d guardian commits to its full initial warning" % chapter)
		guardian.state_time = 0.56
		guardian.strike(guardian.position + Vector2(0, -30), 0, 1)
		check(guardian.health * 2 <= guardian.max_health and guardian.state == 1, "Stage %d armored light hit crosses the enrage threshold without interrupting" % chapter)
		check(float(guardian.visual.material.get_shader_parameter("impact")) > 0.99, "Stage %d dark guardian sprite gets an immediate texture hit flash" % chapter)
		guardian.hit_pause = 0
		guardian._physics_process(0.016)
		check(guardian.state == 1 and is_equal_approx(guardian.committed_windup, 0.70), "Stage %d enrage cannot shorten a warning already underway" % chapter)
		guardian.state = 0
		guardian.alert_cooldown = 0
		guardian._physics_process(0.016)
		check(guardian.state == 1 and is_equal_approx(guardian.committed_windup, 0.55), "Stage %d next enraged attack uses the advertised shorter warning" % chapter)
		guardian.reset_encounter()
		check(is_zero_approx(float(guardian.visual.material.get_shader_parameter("impact"))), "Stage %d encounter reset clears the impact shader" % chapter)
		if chapter == 2 or chapter == 3:
			level.player.position.x = 400 if chapter == 3 else 1700
			await ticks(2)
			var beginning: String = level.audio.now_playing()
			level.player.position.x = 6300
			await ticks(2)
			check(level.audio.village_music.volume_db > level.audio.music.volume_db and level.audio.now_playing() != beginning, "Stage %d music changes naturally toward its destination" % chapter)
			paused = true
			await ticks(2)
			check(is_equal_approx(level.audio.village_music.volume_db,-28+float(level.audio.village_music.get_meta("gain_db",0.0))), "Stage %d destination music ducks while paused and retains its track gain" % chapter)
			paused = false
			level.audio.toggle()
			await ticks(2)
			check(level.audio.music.volume_db <= -80 and level.audio.village_music.volume_db <= -80, "Stage %d mute covers both sides of its crossfade" % chapter)
			level.audio.toggle()
		level.queue_free()
		await ticks(2)
	hub.feedback.clear()
	hub.using_pad = true
	hub.rumble("hurt")
	var pulses: int = hub.rumble_count
	var strength: Vector2 = hub.last_rumble_strength
	hub.rumble("land")
	hub.rumble("dash")
	check(hub.rumble_count == pulses and hub.last_rumble_strength == strength, "Landing and dodge cannot truncate an active hurt pulse")
	hub.rumble("success")
	check(hub.rumble_count == pulses + 1 and hub.feedback.active_kind == "success", "Victory feedback takes priority over damage")
	hub.feedback.advance(0.3)
	hub.rumble("land")
	check(hub.rumble_count == pulses + 2 and hub.feedback.active_kind == "land", "Small feedback resumes once a stronger pulse expires")
	hub.focus_lost()
	check(hub.feedback.active_kind.is_empty(), "Window focus loss clears feedback priority and vibration state")
	print("JOURNEY RESULT: %d/%d checks passed" % [checks - failures, checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
