extends "res://tests/living_world_checks.gd"

func energy(water: Node2D) -> float:
	var result: float = 0
	for value: float in water.heights:
		result += absf(value)
	return result

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/shader-encounter-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	var eye: Node2D
	var mushroom: Node2D
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.species == "eye":
			eye = enemy
		elif enemy.species == "mushroom":
			mushroom = enemy
	check(eye != null and mushroom != null and get_nodes_in_group("enemies").size() == 13, "Chapter one mixes a flying eye and rolling mushroom into its thirteen encounters")
	for species: String in ["eye", "mushroom"]:
		var sample := Enemy.new()
		sample.species = species
		level.add_child(sample)
		sample.set_physics_process(false)
		check(animation_populated(sample), species.capitalize() + " animation paths use populated source frames")
		sample.queue_free()
	await ticks()
	level.player.respawn(Vector2(eye.home.x - 180, 598))
	level.player.invincible = 1000
	eye.alert_cooldown = 0
	eye.set_physics_process(true)
	await ticks(10) # Includes the shared 0.12-second acquisition interval.
	check(eye.state == 1 and eye.max_health == 2, "Flying eye starts with two health and a visible casting windup")
	var captured: Vector2 = eye.target
	var casting_at: Vector2 = eye.position
	level.player.position.x -= 65
	await ticks(38)
	check(eye.state == 1 and eye.target == captured, "Eye gives a long reaction window and retains its captured aim point")
	await ticks(14)
	var bolts: Array[Node] = get_nodes_in_group("enemy_projectiles")
	check(bolts.size() == 1 and bolts[0].eye_orb and bolts[0].velocity.length() < 240, "Eye releases one distinct, slow projectile")
	check(eye.position.distance_to(casting_at) < 2, "Eye casts from its hover position rather than silently diving")
	await ticks(8)
	check(get_nodes_in_group("enemy_projectiles").size() == 1, "Eye cannot fire multiple shots during one attack")
	eye.set_physics_process(false)
	level.combat.clear_projectiles()
	await ticks()
	level.player.respawn(Vector2(450, 598))
	level.player.invincible = 1000
	level.player.facing = 1
	# Isolate the return path from the spitter that normally patrols below the eye.
	eye.position = Vector2(700, 500)
	eye.hit_timer = 0
	await ticks(8)
	level.combat.spawn_bolt(level.player.position + Vector2(125, -35), Vector2.LEFT, false, eye)
	var orb: Node2D = get_nodes_in_group("enemy_projectiles")[0]
	Pad.button(JOY_BUTTON_X, true)
	await ticks(12)
	Pad.button(JOY_BUTTON_X, false)
	check(is_instance_valid(orb) and orb.friendly, "Controller melee reflects the eye's orb")
	await ticks(55)
	check(eye.health == 1 and not is_instance_valid(orb), "Reflected eye orb damages its caster once and cleans up")
	level.player.respawn(mushroom.home + Vector2(-180, -2))
	level.player.invincible = 1000
	mushroom.alert_cooldown = 0
	mushroom.set_physics_process(true)
	await ticks(10)
	var roll_at: Vector2 = mushroom.position
	await ticks(30)
	check(mushroom.state == 1 and mushroom.position.distance_to(roll_at) < 1, "Mushroom warns while stationary before rolling")
	await ticks(18)
	check(mushroom.state == 2 and mushroom.position.x < roll_at.x - 25, "Mushroom rolls toward its captured direction after the warning")
	await ticks(80)
	check(absf(mushroom.position.x - mushroom.home.x) <= mushroom.patrol + 70, "Mushroom rolls remain inside the supported encounter bounds")
	mushroom.set_physics_process(false)
	for kind: String in ["reflect", "guard_break", "armor", "water_splash", "mushroom_roll", "eye_charge", "clean_dodge"]:
		check(level.effects.extras.clips.has(kind) and level.effects.extras.clips[kind].get_frame_count("default") >= 3, "Supplied VFX clip loads: " + kind)
	level.effects.play("reflect", Vector2(400, 540))
	await ticks(80)
	check(level.effects.get_child_count() == 0, "Additional VFX and combat labels leave no persistent effect nodes")
	var sounds_valid: bool = true
	for kind: String in ["reflect", "guard_break", "armor", "eye_warning", "mushroom_warning", "water", "finisher", "heavy_hit", "eye_fire"]:
		var stream: AudioStreamWAV = level.audio.streams[kind]
		sounds_valid = sounds_valid and stream != null and stream.get_length() > 0 and stream.get_length() < 1.5
	check(sounds_valid and level.audio.effects.size() == 8, "Nine new local SFX cues load as bounded, playable WAVs with eight voices")
	var water: Node2D = get_nodes_in_group("water_surfaces")[0]
	check(get_nodes_in_group("water_surfaces").size() == 3 and water.water_material.shader.resource_path.ends_with("river_surface.gdshader"), "All chapter-one gaps use the adapted supplied side-view water shader")
	water.splash(water.position.x + water.width / 2, 10)
	await ticks(8)
	var initial_energy: float = energy(water)
	check(initial_energy > 1, "A water impact creates visible spring ripples")
	await ticks(180)
	check(energy(water) < initial_energy * 0.25, "Water ripples damp naturally after an impact")
	level.toggle_pause()
	var frozen_time: Variant = water.water_material.get_shader_parameter("game_time")
	var frozen_springs: PackedFloat32Array = water.heights.duplicate()
	await ticks(15)
	check(water.water_material.get_shader_parameter("game_time") == frozen_time and water.heights == frozen_springs, "Water shader time and ripple physics both freeze when paused")
	level.toggle_pause()
	var splashes: int = water.splash_count
	level.player.respawn(Vector2(water.position.x + 80, 620))
	level.player.velocity.y = 540
	await ticks(3)
	check(water.splash_count == splashes + 1, "Entering a stream creates one splash before checkpoint recovery")
	await ticks(30)
	check(level.player.position.x < 200, "Shader water preserves the existing fall and checkpoint rules")
	await place()
	Pad.axis(JOY_AXIS_TRIGGER_RIGHT, 0.58)
	await ticks(3)
	check(level.player.dash_time <= 0, "A partly squeezed trigger does not accidentally dodge")
	Pad.axis(JOY_AXIS_TRIGGER_RIGHT, 0.70)
	await ticks(3)
	check(level.player.dash_time > 0 and hub.trigger.latched.has(Pad.DEVICE), "A clear trigger press starts one dodge")
	await ticks(65)
	for value: float in [0.48, 0.55, 0.46, 0.56, 0.50, 0.65]:
		Pad.axis(JOY_AXIS_TRIGGER_RIGHT, value)
		await ticks(2)
	check(level.player.dash_time <= 0 and level.player.dash_cooldown <= 0, "Trigger jitter cannot retrigger a dodge after recharge")
	Pad.axis(JOY_AXIS_TRIGGER_RIGHT, 0.20)
	await ticks(2)
	Pad.axis(JOY_AXIS_TRIGGER_RIGHT, 0.70)
	await ticks(3)
	check(level.player.dash_time > 0, "Releasing and squeezing the trigger permits the next dodge")
	hub.connection_changed(Pad.DEVICE, false)
	await ticks()
	check(paused and hub.trigger.latched.is_empty() and not Input.is_action_pressed("dash"), "Disconnect clears a latched trigger and pauses safely")
	await tap(JOY_BUTTON_START)
	await place()
	hub.rebind("dash", JOY_BUTTON_Y)
	Pad.axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	await ticks(3)
	check(level.player.dash_time <= 0, "Custom dodge bindings do not retain the default trigger shortcut")
	Pad.release()
	hub.defaults()
	level.queue_free()
	await ticks()
	level = load("res://scenes/lantern_road.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	var species: Array[String] = []
	for enemy: Node2D in get_nodes_in_group("enemies"):
		species.append(enemy.species)
	check(species.count("mushroom") == 1 and species.count("eye") == 1 and species.count("rat") == 2, "Chapter two combines forest enemies with the village rats")
	var waters: Array[Node] = get_nodes_in_group("water_surfaces")
	check(waters[0].purity < waters[1].purity and waters[1].purity < waters[2].purity, "Stream colors and refraction grow progressively clearer toward Emberwick")
	var windows: Array[ShaderMaterial] = level.get_node("WorldMotion").windows
	check(windows.size() == 5 and windows[0].get_shader_parameter("warmth") < windows[-1].get_shader_parameter("warmth"), "Cottage panes become warmer and more inhabited along the village approach")
	print("SHADER ENCOUNTER RESULT: %d/%d checks passed" % [checks - failures, checks])
	level.queue_free()
	await ticks()
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
