extends "res://tests/controller_visuals.gd"

const Campaign = preload("res://scripts/campaign_state.gd")

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/expedition-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	for chapter: int in range(5,9):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.player.set_physics_process(false)
		level.hud.intro_time = 0
		for x: float in [640.0,1840.0,3040.0,4240.0,5440.0,5760.0]:
			level.player.respawn(Vector2(x,600))
			hub.flush_gameplay()
			level.player.animation.play("Idle")
			level.player.animation.modulate.a = 1
			level.camera.position.x = x
			level.camera.reset_smoothing()
			level.camera.force_update_scroll()
			await ticks(10)
			level.hud.region_time = 0
			level.hud.notice_time = 0
			await capture("expedition_%d_%d" % [chapter,x])
		level.seals = 3
		level.key_found = true
		level.combat.warden_cleared = true
		level.completed = true
		level.player.locked = true
		level.hud.complete = true
		Campaign.record(level)
		await ticks(240)
		await capture("expedition_%d_complete" % chapter)
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("EXPEDITION VISUALS: CAPTURED FOUR NEW ROUTES AND RESULTS")
	quit()
