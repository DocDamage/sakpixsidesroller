extends "res://tests/controller_visuals.gd"

const Campaign = preload("res://scripts/campaign_state.gd")

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/pocket-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	for chapter: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.player.set_physics_process(false)
		level.player.position = Vector2(450,600)
		level.hud.region_time = 0
		await capture("pocket_%d_intro" % chapter)
		level.hud.intro_time = 0
		level.hud.notify_player("Archivist: Claim the Sanctum Sigil. Your reward waits beside the guardian's arena, beyond the sunken cloister. Follow the lanterns right and the forgotten woodland trail will open.")
		await capture("pocket_%d_dialogue" % chapter)
		level.toggle_pause()
		await capture("pocket_%d_journal" % chapter)
		if chapter == 8:
			hub.open_panel()
			for style: String in ["Xbox","PlayStation","Nintendo"]:
				hub.label_style = style
				hub.panel.refresh()
				await capture("pocket_settings_"+style.to_lower())
			hub.waiting_action = "attack"
			hub.panel.refresh()
			await capture("pocket_remap")
			hub.waiting_action = ""
			hub.panel.refresh()
			hub.panel.style_option.show_popup()
			await capture("pocket_label_picker")
			hub.close_panel()
		level.toggle_pause()
		if chapter in [1,4,8]:
			level.player.position = level.profile.boss_at+Vector2(-160,0)
			level.player.health = 2
			level.hud.notice_time = 0
			level.camera.position.x = level.player.position.x
			level.camera.reset_smoothing()
			level.camera.force_update_scroll()
			level.combat.guardian.strike(level.profile.boss_at+Vector2(0,-30),0,2,0)
			await ticks(3)
			level.hud.region_time = 0
			await capture("pocket_%d_guardian" % chapter)
		level.completed = true
		level.seals = 3
		level.key_found = true
		level.hud.complete = true
		level.player.locked = true
		Campaign.record(level)
		await ticks(5)
		await capture("pocket_%d_complete" % chapter)
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("POCKET UI VISUALS: CAPTURED ALL TWELVE STAGES, JOURNALS, RESULTS AND CONTROLLER LAYOUTS")
	quit()
