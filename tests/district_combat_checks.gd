extends "res://tests/living_world_checks.gd"

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/district-combat-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	var district: Node2D = level.district
	var target: Node2D = district.jailer
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(enemy == target)
	level.player.respawn(Vector2(4690,1455))
	level.player.invincible = 0
	await ticks(12)
	check(district.jail_arena and district.gates.jail_left.body.collision_layer == 1 and district.gates.jail_right.body.collision_layer == 1,"Entering the jailer's floor seals a real combat arena; the upper bypass remains separate")
	var frame: int = 0
	while is_instance_valid(target) and not target.dead and frame < 1600 and level.player.health > 0:
		var offset: float = target.position.x-level.player.position.x
		var direction: float = signf(offset)
		Pad.axis(JOY_AXIS_LEFT_X,direction if absf(offset) > 62 or level.player.facing != direction else 0)
		if frame%18 == 0 and absf(offset) < 150 and level.player.facing*direction > 0:
			Pad.button(JOY_BUTTON_X,true)
		elif frame%18 == 1:
			Pad.button(JOY_BUTTON_X,false)
		await ticks(1)
		frame += 1
	Pad.release()
	await ticks(3)
	check(district.opened.has("jailer") and level.player.health > 0 and level.deaths == 0,"The eight-health jailer can be defeated through controller combat with normal player damage")
	check(district.gates.jail_left.body.collision_layer == 0 and district.gates.jail_right.body.collision_layer == 0,"Defeating the jailer releases both arena doors")
	level.player.respawn(Vector2(4530,1455))
	await ticks(8)
	Pad.button(JOY_BUTTON_Y,true)
	await ticks(2)
	Pad.button(JOY_BUTTON_Y,false)
	await ticks(2)
	check(district.upgrades.has("moon_hook"),"The earned moon hook is collected through controller interaction")
	level.player.respawn(Vector2(11520,-245))
	await ticks(8)
	Pad.button(JOY_BUTTON_Y,true)
	await ticks(2)
	Pad.button(JOY_BUTTON_Y,false)
	await ticks(2)
	check(district.upgrades.has("lantern_wick") and district.lighting.hero.texture_scale > 0.9,"The optional loft relic increases the actual character light radius")
	level.player.respawn(Vector2(13550,1455))
	await ticks(8)
	Pad.button(JOY_BUTTON_Y,true)
	await ticks(2)
	Pad.button(JOY_BUTTON_Y,false)
	await ticks(2)
	check(district.upgrades.has("grave_edge") and level.player.sword_bonus == 1,"The optional return-gallery relic upgrades real finisher damage")
	check(level.audio.variant_index.get("attack",0) > 0 and level.audio.variant_index.get("hit",0) > 0 and level.audio.variant_index.get("flesh_layer",0) > 0,"Sword swishes, body impacts and flesh layers use the supplied SFX variations during actual combat")
	Pad.release()
	level.queue_free()
	await ticks(6)
	OS.delay_msec(120)
	await ticks(6)
	print("DISTRICT COMBAT RESULT: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
