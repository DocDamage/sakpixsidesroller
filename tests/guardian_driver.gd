extends RefCounted

static func fight(tree: SceneTree, level: Node2D, controller_mode: bool = false) -> bool:
	var frame: int = 0
	var captured: bool = false
	while not level.combat.warden_cleared and frame < 1200:
		var offset: float = level.combat.guardian.position.x - level.player.position.x
		var direction: float = signf(offset)
		var moving: bool = absf(offset) > 62 or (level.player.facing != direction and level.player.attack_time <= 0)
		if controller_mode:
			preload("res://tests/pad_driver.gd").axis(JOY_AXIS_LEFT_X, direction if moving else 0.0)
			if frame % 18 == 0 and absf(offset) < 145 and level.player.facing * direction > 0:
				preload("res://tests/pad_driver.gd").button(JOY_BUTTON_X, true)
			elif frame % 18 == 1:
				preload("res://tests/pad_driver.gd").button(JOY_BUTTON_X, false)
		else:
			Input.action_release("move_left")
			Input.action_release("move_right")
			if moving:
				Input.action_press("move_right" if direction > 0 else "move_left")
			if frame % 18 == 0 and absf(offset) < 145 and level.player.facing * direction > 0:
				Input.action_press("attack")
			elif frame % 18 == 1:
				Input.action_release("attack")
		await tree.physics_frame
		frame += 1
		if not captured and "--screenshots" in OS.get_cmdline_user_args() and level.combat.guardian.health <= 4:
			captured = true
			level.hud.intro_time = 0
			level.camera.position.x = clampf(level.player.position.x, 640, 5760)
			level.camera.reset_smoothing()
			level.camera.force_update_scroll()
			await RenderingServer.frame_post_draw
			tree.root.get_texture().get_image().save_png("res://artifacts/combat_gravekeeper.png")
	Input.action_release("attack")
	Input.action_release("move_left")
	Input.action_release("move_right")
	if controller_mode:
		preload("res://tests/pad_driver.gd").release()
	await tree.process_frame
	return level.combat.warden_cleared
