extends "res://tests/controller_visuals.gd"

const Enemy = preload("res://scripts/haunt.gd")

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/fauna-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	level = load("res://scenes/lumenwood_trail.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.hide()
	level.player.respawn(Vector2(2350,600))
	level.player.set_physics_process(false)
	level.camera.position.x = 2500
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	level.hud.intro_time = 0
	level.hud.region_time = 0
	await ticks(10)
	for species: String in ["witch","mosquito"]:
		var enemy := Enemy.new()
		enemy.species = species
		enemy.position = Vector2(2580,390)
		level.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.target = level.player.position
		enemy.attack_direction = -1
		enemy.state = 1
		enemy.state_time = enemy.committed_windup*0.7
		enemy.visual.flip_h = true
		preload("res://scripts/enemy_animation.gd").update(enemy)
		enemy.queue_redraw()
		await capture("fauna_"+species+"_warning")
		enemy.state = 2
		enemy.state_time = 0.15
		preload("res://scripts/enemy_animation.gd").update(enemy)
		if species == "witch":
			level.combat.spawn_bolt(enemy.position+Vector2(-100,-35),Vector2(-1,0.6).normalized(),false,enemy)
			for spell: Node2D in get_nodes_in_group("enemy_projectiles"):
				spell.set_physics_process(false)
				spell._physics_process(0.01)
		else:
			level.effects.play("enemy_dive",enemy.position+Vector2(0,-35),-1)
		enemy.queue_redraw()
		await capture("fauna_"+species+"_attack")
		for spell: Node2D in get_nodes_in_group("enemy_projectiles"):
			spell.queue_free()
		enemy.queue_free()
		await ticks(2)
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("FAUNA VISUALS: CAPTURED BOTH NEW ENEMIES AND THEIR WARNINGS")
	quit()
