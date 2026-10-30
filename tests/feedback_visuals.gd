extends "res://tests/controller_visuals.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Animator = preload("res://scripts/enemy_animation.gd")

func run() -> void:
	root.size = Vector2i(1280, 720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/feedback-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	for chapter: int in range(1, 5):
		level = load(Campaign.SCENES[chapter - 1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		var target: Node2D
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
			if target == null and enemy.species == ("guard" if chapter >= 3 else "plant"):
				target = enemy
		level.player.set_physics_process(false)
		level.player.respawn(target.position + Vector2(-100, 0))
		level.player.facing = 1
		level.player.start_attack()
		level.player.attack_time = 0.22
		level.player.update_animation()
		level.player.animation.frame = 1
		level.player.animation.pause()
		level.player.queue_redraw()
		target.strike(target.position + Vector2(0, -30), 0, 1, 0)
		target.hit_timer = 0.16
		target.state_time = 0.1
		Animator.update(target)
		target.queue_redraw()
		level.hud.intro_time = 0
		level.camera.position.x = clampf(target.position.x - 120, 640, 5760)
		level.camera.reset_smoothing()
		level.camera.force_update_scroll()
		level.hud.region_time = 0
		await capture("feedback_%d" % chapter)
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("COMBAT FEEDBACK VISUALS: CAPTURED ALL FOUR STAGES")
	quit()
