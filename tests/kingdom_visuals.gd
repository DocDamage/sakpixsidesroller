extends "res://tests/controller_visuals.gd"

const Campaign = preload("res://scripts/campaign_state.gd")

func run() -> void:
	root.size = Vector2i(1280, 720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/kingdom-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	for chapter: int in [3, 4]:
		level = load(Campaign.SCENES[chapter - 1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.hud.intro_time = 0
		for x: float in [600.0, 2600.0, 4200.0, 5700.0]:
			level.player.set_physics_process(true)
			level.player.respawn(Vector2(x, 598))
			hub.flush_gameplay()
			level.player.invincible = 1000
			level.camera.position.x = clampf(x, 640, 5760)
			level.camera.reset_smoothing()
			level.camera.force_update_scroll()
			await ticks(20)
			level.player.set_physics_process(false)
			level.player.animation.play("Idle")
			level.player.animation.modulate.a = 1
			level.hud.region_time = 0
			level.hud.notice_time = 0
			await capture("kingdom_%d_%d" % [chapter, x])
		level.completed = true
		level.player.locked = true
		level.seals = 3
		level.key_found = true
		level.combat.warden_cleared = true
		level.hud.complete = true
		Campaign.record(level)
		await ticks(240)
		await capture("kingdom_%d_complete" % chapter)
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("KINGDOM VISUALS: CAPTURED")
	quit()
