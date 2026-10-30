extends "res://tests/controller_visuals.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Animator = preload("res://scripts/enemy_animation.gd")

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/border-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	for chapter: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		level.player.set_physics_process(false)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.hud.intro_time = 0
		for edge: String in ["entry","exit"]:
			level.player.respawn(Vector2(180 if edge == "entry" else 6190,600))
			level.player.animation.play("Idle")
			level.player.animation.modulate.a = 1
			level.camera.position.x = 640 if edge == "entry" else 5760
			level.camera.reset_smoothing()
			level.camera.force_update_scroll()
			await ticks(8)
			level.hud.region_time = 0
			level.hud.notice_time = 0
			await capture("border_%d_%s" % [chapter,edge])
		level.player.position = level.profile.boss_at+Vector2(-170,0)
		level.camera.position.x = clampf(level.player.position.x,640,5760)
		level.camera.reset_smoothing()
		level.camera.force_update_scroll()
		var guardian: Node2D = level.combat.guardian
		guardian.state = 1
		guardian.strike(guardian.position+Vector2(0,-30),0,2,0)
		guardian.hit_timer = 0.12
		Animator.update(guardian)
		await ticks(3)
		level.hud.region_time = 0
		await capture("border_%d_guard_break" % chapter)
		if chapter in [4,6,8]:
			hub.label_style = {4:"Xbox",6:"PlayStation",8:"Nintendo"}[chapter]
			hub.open_panel()
			await capture("border_%d_controller" % chapter)
			hub.close_panel()
		paused = false
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("BORDER VISUALS: CAPTURED TWENTY-FOUR STAGE BOUNDARIES, TWELVE GUARD BREAKS AND THREE CONTROLLER LAYOUTS")
	quit()
