extends "res://tests/controller_visuals.gd"

const Pad = preload("res://tests/pad_driver.gd")

func shot(at: Vector2) -> void:
	Pad.release()
	level.player.respawn(at)
	level.player.traversal.reset()
	level.player.invincible = 0
	level.player.update_animation()
	preload("res://scripts/level_backdrop.gd").update(level)
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	level.weather.bake_shelter()
	level.hud.intro_time = 0
	level.hud.region_time = 0
	level.hud.notice_time = 0

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/district-movie-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(enemy.home.distance_to(Vector2(5030,600)) < 10)
	shot(Vector2(4880,590))
	for frame: int in 210:
		Pad.axis(JOY_AXIS_LEFT_X,0.6 if frame < 38 else 0)
		if frame%22 == 3:
			Pad.button(JOY_BUTTON_X,true)
		elif frame%22 == 5:
			Pad.button(JOY_BUTTON_X,false)
		await ticks(1)
	shot(Vector2(8220,1440))
	for frame: int in 190:
		Pad.axis(JOY_AXIS_LEFT_X,0.75)
		Pad.axis(JOY_AXIS_LEFT_Y,-0.2)
		Pad.button(JOY_BUTTON_A,frame%85 < 2)
		await ticks(1)
	shot(Vector2(12420,590))
	for frame: int in 240:
		Pad.axis(JOY_AXIS_LEFT_Y,-1)
		await ticks(1)
	Pad.release()
	level.queue_free()
	await ticks(6)
	print("DISTRICT MOVIE: COMBAT, WATER AND CLIMBING CAPTURED WITH LIVE SOURCE-KIT AUDIO")
	quit()
