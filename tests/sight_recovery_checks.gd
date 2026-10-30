extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Backdrop = preload("res://scripts/level_backdrop.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/sight-recovery-controller.cfg"
	hub.defaults()
	for chapter: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.player.set_physics_process(false)
		var guardian: Node2D = level.combat.guardian
		guardian.state = 1
		guardian.strike(guardian.position+Vector2(0,-30),0,2,0)
		guardian.hit_pause = 0
		guardian.hit_timer = 0
		guardian.state_time = 0.3
		level.player.position = guardian.position
		level.player.health = 5
		level.player.invincible = 0
		guardian._physics_process(0.01)
		check(level.player.health == 5 and guardian.guard_broken,"Stage %d guard-break recovery permits a close counterattack without contact damage" % chapter)
		guardian.state = 0
		guardian.guard_broken = false
		guardian.alert_cooldown = 10
		guardian._physics_process(0.01)
		check(level.player.health == 5,"Stage %d a resting guardian cannot bypass its telegraph with body damage" % chapter)
		guardian.state = 2
		guardian.state_time = guardian.BLADE_START-0.01
		guardian.attack_direction = 1
		level.player.position = guardian.position+Vector2(55,0)
		guardian._physics_process(0.01)
		check(level.player.health == 4,"Stage %d the visible active blade frames still damage a player in reach" % chapter)
		if chapter == 10:
			var samples: Array[float] = []
			for x: float in [4300.0,5100.0,5800.0,6200.0]:
				level.player.position.x = x
				Backdrop.update(level)
				samples.append(level.get_node("DistantTown").modulate.a)
			check(samples[0] == 1 and samples[1] < samples[0] and samples[2] < samples[1] and samples[3] < 0.1,"Vault masonry recedes smoothly across the final region, including its parallax layers")
		if chapter >= 11:
			var wisp: Sprite2D = level.world_details.wisps[0].visual
			var start: Vector2 = wisp.position
			await ticks(10)
			var moving: Vector2 = wisp.position
			level.toggle_pause()
			await ticks(8)
			check(start != moving and wisp.position == moving,"Stage %d sourced spirit wisps animate and freeze with the journal" % chapter)
			level.toggle_pause()
		if chapter == 1:
			await ranged_sight()
		level.queue_free()
		await ticks(2)
	print("SIGHT RECOVERY RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)

func ranged_sight() -> void:
	level.player.position = Vector2(700,600)
	level.player.invincible = 1000
	for species: String in ["plant","eye","witch"]:
		var wall := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(40,240)
		collision.shape = shape
		wall.position = Vector2(840,500)
		wall.add_child(collision)
		level.add_child(wall)
		var enemy: Node2D = Enemy.new()
		enemy.species = species
		enemy.position = Vector2(1000,600)
		level.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.patrol = 0
		enemy.alert_cooldown = 0
		await ticks(3)
		check(not enemy.can_see_player(level.player),"%s cannot see a player behind solid masonry" % species)
		enemy._physics_process(0.01)
		check(enemy.state == 0 and not enemy.awakened,"%s does not warn or spend an attack through the wall" % species)
		wall.queue_free()
		await ticks(3)
		check(enemy.can_see_player(level.player),"%s reacquires an unobstructed target" % species)
		enemy._physics_process(0.14)
		check(enemy.state == 1 and enemy.target == level.player.position,"%s commits to a captured aim point once the path is clear" % species)
		var captured: Vector2 = enemy.target
		level.player.position.x -= 50
		enemy._physics_process(0.02)
		check(enemy.target == captured,"%s preserves its visible warning aim when the player dodges" % species)
		enemy.queue_free()
		level.player.position = Vector2(700,600)
		await ticks(2)
