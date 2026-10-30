extends "res://tests/controller_visuals.gd"

func run() -> void:
	root.size = Vector2i(1280, 720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/living-visual-controller.cfg"
	hub.defaults()
	for chapter: int in [1, 2]:
		level = load("res://scenes/halloween_town.tscn" if chapter == 1 else "res://scenes/lantern_road.tscn").instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.hud.intro_time = 0
		hub.using_pad = true
		var views: Array = [[600.0, "living_halloween_camp"], [2140.0, "living_graveyard_camp"]] if chapter == 1 else [[2200.0, "living_first_homes"], [3780.0, "living_orchard"]]
		for entry: Array in views:
			level.player.respawn(Vector2(entry[0], 598))
			hub.flush_gameplay()
			level.player.invincible = 0
			level.camera.position.x = clampf(entry[0], 640, 5760)
			level.camera.reset_smoothing()
			level.camera.force_update_scroll()
			await ticks(20)
			level.hud.region_time = 0
			level.hud.notice_time = 0
			await capture(entry[1])
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("LIVING WORLD VISUALS: CAPTURED")
	quit()
