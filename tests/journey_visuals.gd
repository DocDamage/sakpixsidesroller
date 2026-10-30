extends "res://tests/controller_visuals.gd"

const Campaign = preload("res://scripts/campaign_state.gd")

func run() -> void:
	root.size = Vector2i(1280, 720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/journey-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	for chapter: int in range(1, 5):
		level = load(Campaign.SCENES[chapter - 1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.hud.intro_time = 0
		var stops: Array = [6100.0] if chapter <= 2 else ([600.0, 4200.0, 5200.0, 6100.0] if chapter == 3 else [600.0, 2100.0, 4200.0])
		for x: float in stops:
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
			await capture("journey_%d_%d" % [chapter, x])
		if chapter == 4:
			var guardian: Node2D = level.combat.guardian
			level.player.respawn(Vector2(5500, 598))
			level.player.animation.modulate.a = 1
			level.camera.position.x = 5500
			level.camera.reset_smoothing()
			level.camera.force_update_scroll()
			guardian.state = 1
			guardian.attack_direction = -1
			guardian.committed_windup = guardian.windup_duration()
			guardian.state_time = 0.48
			preload("res://scripts/enemy_animation.gd").update(guardian)
			guardian.queue_redraw()
			await capture("journey_guardian_warning")
			guardian.hit_timer = 0
			guardian.strike(guardian.position + Vector2(0, -30), 0, 2)
			await capture("journey_guardian_impact")
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("JOURNEY VISUALS: CAPTURED")
	quit()
