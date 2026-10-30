extends "res://tests/district_visuals.gd"

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/attack-visual-controller.cfg"
	hub.defaults()
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	var guard: Node2D
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.species == "guard" and absf(enemy.home.x-3100) < 200:
			guard = enemy
	level.player.set_physics_process(false)
	await look(Vector2(3160,120),"attack_approach")
	guard.position = Vector2(3100,120)
	guard.home = guard.position
	guard.state = 1
	guard.state_time = 0
	guard.committed_windup = 0.4
	guard.attack_direction = 1
	guard.attack_fx_fired = false
	guard.hit_timer = 0
	guard.set_physics_process(true)
	await ticks(31)
	await capture("enemy_guard_active")
	guard.set_physics_process(false)
	await look(Vector2(660,600),"campfire_contact")
	await look(Vector2(1430,600),"street_lantern")
	level.queue_free()
	await ticks(6)
	level = load("res://scenes/lantern_road.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.player.set_physics_process(false)
	await look(Vector2(730,600),"village_road_lamp")
	await look(Vector2(12000,600),"village_gate_lamp")
	level.queue_free()
	await ticks(6)
	print("ATTACK/FIXTURE VISUALS: CAPTURED")
	quit()
