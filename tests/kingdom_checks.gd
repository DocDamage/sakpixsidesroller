extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")

func at(position: Vector2) -> void:
	Pad.release()
	level.player.respawn(position)
	level.player.invincible = 1000
	await ticks(8)

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/kingdom-check-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	Campaign.results.clear()
	Campaign.unlocked_chapter = 1
	for chapter: int in [3, 4]:
		level = load(Campaign.SCENES[chapter - 1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		check(level.chapter == chapter and level.profile.regions.size() == 4, "Kingdom stage %d loads a distinct four-region profile" % chapter)
		check(level.profile.builder.FLOORS.size() == 4 and level.profile.builder.LEDGES.size() == 12, "Stage %d provides its own floor spans and twelve traversable ledges" % chapter)
		check(level.items.size() == 37 and get_nodes_in_group("enemies").size() == 13, "Stage %d contains three objectives, 34 coins and thirteen encounters" % chapter)
		check(level.world_details.actors.size() == 3 and level.world_details.fires.size() == 4, "Stage %d uses three supplied NPC sheets and four animated camps" % chapter)
		check(get_nodes_in_group("water_surfaces").size() == 3 and level.get_node("WorldMotion").smoke.size() == 4, "Stage %d retains shader water and animated source smoke" % chapter)
		check(level.audio.music.playing and level.audio.now_playing().contains("Footsteps Upstairs" if chapter == 3 else "Whispers Between Pages"), "Stage %d plays its selected Haunted Manor soundtrack" % chapter)
		var guards: Array[Node2D] = []
		for enemy: Node2D in get_nodes_in_group("enemies"):
			if enemy.species == "guard":
				guards.append(enemy)
		check(guards.size() == (2 if chapter == 3 else 3) and guards[0].max_health == 3, "Stage %d introduces readable three-health guards" % chapter)
		var guard: Node2D = guards[-1]
		guard.state = 1
		guard.hit_timer = 0
		guard.strike(guard.position + Vector2(0, -30), 0, 1)
		check(guard.state == 3 and not guard.last_hit_armored and guard.health == 2, "Stage %d guards can be interrupted with light attacks" % chapter)
		var guardian: Node2D = level.combat.guardian
		guard.position = guardian.position + Vector2(-250, 0)
		guard.state = 1
		check(not level.combat.may_attack(guardian), "Stage %d guardian respects an already committed nearby enemy attack" % chapter)
		guard.reset_encounter()
		var sample := Enemy.new()
		sample.species = "guard"
		level.add_child(sample)
		sample.set_physics_process(false)
		check(animation_populated(sample), "Stage %d guard animation stays inside the real supplied sprite rows" % chapter)
		sample.queue_free()
		await ticks()
		check(guardian.max_health == (10 if chapter == 3 else 12), "Stage %d guardian has its own health total" % chapter)
		await at(Vector2(320, 598))
		await tap(JOY_BUTTON_Y)
		check(level.hud.notice.begins_with("Seamstress:" if chapter == 3 else "Knight:"), "Stage %d advice works with the controller interact button" % chapter)
		await at(Vector2(5520, 598))
		await tap(JOY_BUTTON_Y)
		check(not level.key_found, "Stage %d reward refuses opening before its objectives and guardian" % chapter)
		for item: Dictionary in level.items:
			if item["kind"] == "seal":
				await at(item["position"] + Vector2(0, 34))
		check(level.seals == 3, "Stage %d collects all three authored crests or sigils" % chapter)
		await at(Vector2(level.profile.checkpoints[1], 598))
		check(level.checkpoint_index == 1 and level.player.health == 5, "Stage %d activates its own checkpoint and restores vitality" % chapter)
		var previous_deaths: int = level.deaths
		await at(Vector2(level.profile.gaps[1].x + 80, 700))
		check(level.deaths == previous_deaths + 1 and absf(level.player.position.x - level.profile.checkpoints[1]) < 2 and level.seals == 3, "Stage %d stream recovery keeps objectives and uses the correct checkpoint" % chapter)
		await at(Vector2(5430, 598))
		guardian.health = guardian.max_health / 2
		guardian.state = 2
		guardian.state_time = 0.2
		guardian.volley_fired = false
		guardian.attack_direction = 1
		guardian.set_physics_process(true)
		await ticks(3)
		check(get_nodes_in_group("enemy_projectiles").size() == 2 and level.hud.boss_enraged, "Stage %d guardian enters its two-sided flame phase at half of its own health" % chapter)
		guardian.set_physics_process(false)
		level.combat.reset_after_fall()
		guardian.set_physics_process(true)
		check(await preload("res://tests/guardian_driver.gd").fight(self, level, true), "Stage %d guardian can be defeated with controller movement and combo inputs" % chapter)
		await at(Vector2(5520, 598))
		await tap(JOY_BUTTON_Y)
		check(level.key_found, "Stage %d objectives and guardian defeat unlock the stage reward" % chapter)
		await at(Vector2(6190, 598))
		await tap(JOY_BUTTON_Y)
		check(level.completed and Campaign.results.has(chapter), "Stage %d gate completes and records the stage through controller input" % chapter)
		var expected: Button = level.hud.continue_button
		check(expected.has_focus() and level.hud.continue_button.visible and not level.hud.first_button.visible, "Stage %d presents continuation into the expanded campaign" % chapter)
		await tap(JOY_BUTTON_BACK)
		await tap(JOY_BUTTON_B)
		check(expected.has_focus(), "Stage %d controls screen returns focus to the previous completion action" % chapter)
		if chapter == 4:
			await ticks(230)
			check(level.audio.music_blend > 0.99 and level.audio.now_playing().contains("The Locked Chamber"), "Crownward continues its Haunted Manor transition into the Ashen Ramparts")
		level.audio.toggle()
		var previous: WeakRef = weakref(level)
		level.hud.restart_button.pressed.emit()
		await ticks(25)
		level = current_scene
		check(previous.get_ref() == null and level.chapter == chapter and level.seals == 0 and level.combat.relics == 0, "Stage %d replay frees the previous world and resets its local objectives" % chapter)
		check(level.audio.muted and level.hud.muted and get_nodes_in_group("enemies").size() == 13, "Stage %d replay restores encounters and retains audio preferences" % chapter)
		level.audio.toggle()
		level.queue_free()
		await ticks()
	check(Campaign.results.has(3) and Campaign.results.has(4) and Campaign.unlocked_chapter == 5, "Campaign preserves kingdom results and unlocks the Ashen Ramparts")
	print("KINGDOM RESULT: %d/%d checks passed" % [checks - failures, checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
