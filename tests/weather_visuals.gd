extends "res://tests/rebuild_visuals.gd"

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/weather-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/weather-motion"))
	for stage: int in range(1,13):
		level = load(Campaign.SCENES[stage-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.player.set_physics_process(false)
		var at: Vector2 = Vector2(3800,600)
		if stage == 6:
			at = level.extension.rooms[0].peak
		elif stage == 10:
			at = Vector2(12160,600)
		await look(at,"weather_stage_%02d" % stage)
		if stage == 5:
			level.set_physics_process(false)
			for frame: int in 48:
				await capture("weather-motion/frame_%03d" % frame)
			level.set_physics_process(true)
		for room: Dictionary in level.extension.rooms:
			if room.lower:
				await look(room.peak,"weather_stage_%02d_shelter" % stage)
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("WEATHER VISUALS: CAPTURED ALL TWELVE STAGES, THEIR SHELTERS AND 48 MOTION FRAMES")
	quit()
