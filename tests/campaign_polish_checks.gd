extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Borders = preload("res://scripts/border_details.gd")
const Atmosphere = preload("res://scripts/town_atmosphere.gd")

func motion(device: int, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/campaign-polish-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	for stage: int in range(1,Campaign.STAGES):
		check(Atmosphere.tint(stage,6400).is_equal_approx(Atmosphere.tint(stage+1,0)),"Boundary %d/%d carries the same atmospheric mote color across the gateway" % [stage,stage+1])
	for stage: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[stage-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		var fauna: bool = false
		for enemy: Node2D in get_nodes_in_group("enemies"):
			fauna = fauna or enemy.species in ["witch","mosquito"]
		check(fauna and get_nodes_in_group("enemies").size() == 13,"Stage %d introduces supplied witch/mosquito art while preserving thirteen encounters" % stage)
		var sides: Dictionary = {}
		var sourced: bool = true
		for detail: Sprite2D in get_nodes_in_group("border_details"):
			var border: int = detail.get_meta("border")
			sides[border] = int(sides.get(border,0))+1
			sourced = sourced and detail.texture.resource_path == Borders.SOURCES[border-1] and detail.modulate.a >= 0.3 and detail.modulate.a <= 0.95
		var enough: bool = sides.size() == (1 if stage in [1,Campaign.STAGES] else 2)
		for count: int in sides.values():
			enough = enough and count >= 2
		check(sourced and enough,"Stage %d echoes at least two low, sourced details on each adjoining border: %s" % [stage,str(sides)])
		Pad.axis(JOY_AXIS_LEFT_X,0.9)
		await ticks(2)
		motion(78,JOY_AXIS_RIGHT_X,0.95)
		motion(78,JOY_AXIS_TRIGGER_LEFT,0.95)
		motion(78,JOY_AXIS_TRIGGER_RIGHT,0.55)
		await ticks(2)
		check(hub.last_device == Pad.DEVICE and hub.horizontal_direction() > 0.8 and not Input.is_action_pressed("dash"),"Stage %d unused axes and a partial idle-pad trigger cannot steal movement or dodge" % stage)
		Pad.axis(JOY_AXIS_LEFT_X,0.2)
		await ticks(2)
		hub.open_panel()
		hub.panel.deadzone_slider.value = 0.1
		check(hub.horizontal_direction() > 0.1,"Stage %d lowering deadzone immediately uses the held raw stick sample" % stage)
		hub.panel.deadzone_slider.value = 0.4
		check(hub.horizontal_direction() == 0,"Stage %d raising deadzone immediately suppresses the same held stick sample" % stage)
		hub.panel.deadzone_slider.value = 0.24
		hub.close_panel()
		Pad.release()
		hub.devices.clear(78)
		hub.trigger.clear(78)
		await ticks(3)
		if stage == 1:
			await new_encounters()
		level.queue_free()
		await ticks(2)
	print("CAMPAIGN POLISH RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)

func new_encounters() -> void:
	level.player.set_physics_process(false)
	level.player.position = Vector2(700,600)
	level.player.invincible = 1000
	var witch := Enemy.new()
	witch.species = "witch"
	witch.position = Vector2(900,350)
	level.add_child(witch)
	witch.set_physics_process(false)
	witch.patrol = 0
	witch.alert_cooldown = 0
	level.combat.connect_enemy(witch,false)
	witch._physics_process(0.14)
	check(witch.state == 1 and witch.max_health == 3 and is_equal_approx(witch.committed_windup,0.95),"Flying witch has three health and a long, captured-aim cast warning")
	witch._physics_process(0.94)
	check(witch.state == 1,"Witch holds its readable warning before releasing a spell")
	witch._physics_process(0.02)
	witch._physics_process(0.01)
	witch._physics_process(0.01)
	check(get_nodes_in_group("enemy_projectiles").is_empty(),"Witch's initial attack cells anticipate the release rather than firing early")
	witch._physics_process(0.14)
	var spells: Array[Node] = get_nodes_in_group("enemy_projectiles")
	check(spells.size() == 1 and spells[0].witch_orb and is_equal_approx(spells[0].velocity.length(),210),"Witch releases exactly one slower spell per cast")
	if not spells.is_empty():
		var spell: Node2D = spells[0]
		spell.set_physics_process(false)
		check(not spell.visual.region_enabled and spell.visual.texture.resource_path.ends_with("purple_swirl_orb.png"),"Witch spell uses the supplied Magic Forest orb without invalid atlas frames")
		check(spell.deflect(spell.position,0) and spell.friendly and is_equal_approx(spell.velocity.length(),480),"Witch spells reflect through the shared melee/plunge mechanic")
		spell._physics_process(0.1)
		check(spell.spent and witch.health == 2,"Returned witch spell damages its caster once and cleans up")
	await ticks(2)
	level.player.respawn(Vector2(700,598))
	level.player.invincible = 1000
	level.player.facing = 1
	level.player.set_physics_process(true)
	await ticks(4)
	level.combat.spawn_bolt(level.player.position+Vector2(100,-35),Vector2.LEFT,false,witch)
	var live_spell: Node2D = get_nodes_in_group("enemy_projectiles")[0]
	Pad.button(JOY_BUTTON_X,true)
	await ticks(12)
	Pad.button(JOY_BUTTON_X,false)
	check(is_instance_valid(live_spell) and live_spell.friendly and hub.using_pad,"Native controller melee reflects the new witch spell during normal projectile flight")
	level.combat.clear_projectiles()
	level.player.set_physics_process(false)
	witch.queue_free()
	await ticks(2)
	level.player.position = Vector2(1000,600)
	var mosquito := Enemy.new()
	mosquito.species = "mosquito"
	mosquito.position = Vector2(1000,400)
	level.add_child(mosquito)
	mosquito.set_physics_process(false)
	mosquito.state = 1
	mosquito.target = level.player.position
	mosquito._physics_process(0.73)
	var before: Vector2 = mosquito.position
	mosquito._physics_process(0.1)
	check(mosquito.max_health == 1 and is_equal_approx(before.distance_to(mosquito.position),36),"Mosquito commits to a fast dive after its 0.72-second warning")
	mosquito._physics_process(0.3)
	before = mosquito.position
	mosquito._physics_process(0.1)
	check(mosquito.state == 3 and mosquito.position.distance_to(mosquito.home) < before.distance_to(mosquito.home) and is_equal_approx(mosquito.recovery_duration(),1.05),"Mosquito retreats toward its hover point during a longer recovery")
	check(mosquito.strike(mosquito.position+Vector2(0,-30),0,1,0) and mosquito.dead,"A committed mosquito remains vulnerable to a single well-timed strike")
	mosquito.queue_free()
