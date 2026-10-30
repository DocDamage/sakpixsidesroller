extends "res://tests/controller_visuals.gd"

const Animator = preload("res://scripts/enemy_animation.gd")

func stage(chapter: int, x: float) -> void:
	level = load("res://scenes/halloween_town.tscn" if chapter == 1 else "res://scenes/lantern_road.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.player.respawn(Vector2(x, 598))
	hub.flush_gameplay()
	level.player.invincible = 0
	level.hud.intro_time = 0
	level.camera.position.x = clampf(x, 640, 5760)
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	await ticks(20)
	level.hud.region_time = 0
	level.hud.notice_time = 0

func run() -> void:
	root.size = Vector2i(1280, 720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/shader-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	await stage(1, 3700)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		if enemy.species in ["eye", "mushroom"]:
			enemy.state = 1
			enemy.state_time = 0.42
			enemy.attack_direction = signf(level.player.position.x - enemy.position.x)
			enemy.target = level.player.position
			Animator.update(enemy)
			enemy.queue_redraw()
	await capture("shader_forest_encounters")
	level.queue_free()
	await ticks(2)
	await stage(2, 3000)
	var eye: Node2D
	for enemy: Node2D in get_nodes_in_group("enemies"):
		if enemy.species == "eye":
			eye = enemy
	eye.state = 1
	eye.state_time = 0.5
	eye.target = level.player.position
	eye.attack_direction = -1
	Animator.update(eye)
	eye.queue_redraw()
	await capture("shader_village_eye")
	var water: Node2D = get_nodes_in_group("water_surfaces")[1]
	water.splash(water.position.x + 90, 10)
	await capture("shader_stream_splash")
	level.queue_free()
	await ticks(2)
	await stage(2, 4400)
	await capture("shader_village_stream")
	level.queue_free()
	await ticks(2)
	await stage(2, 3780)
	await capture("shader_lit_orchard")
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("SHADER ENCOUNTER VISUALS: CAPTURED")
	quit()
