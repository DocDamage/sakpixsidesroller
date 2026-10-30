extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Pocket = preload("res://scripts/pocket_ui.gd")
const Journal = preload("res://scripts/journey_journal.gd")

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/pocket-check-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	check(Pocket.book().get_size() == Vector2(488,312) and Pocket.cropped("icons/7.png").get_size() == Vector2(10,9),"Journal and hearts use the supplied UI pack with transparent padding removed")
	check(Pocket.make_theme().get_stylebox("normal","Button") is StyleBoxTexture,"Menu controls inherit the supplied pixel frames")
	for chapter: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.player.invincible = 1000
		var details: Node2D = level.world_details
		check(details.advice(0) == details.actors[0].line,"Stage %d retains its authored opening route advice" % chapter)
		level.seals = 3
		check(details.advice(0).begins_with(level.profile.boss_objective.capitalize()),"Stage %d NPCs direct a completed collection toward its guardian" % chapter)
		level.combat.warden_cleared = true
		check(details.advice(0).begins_with(level.profile.key_objective.capitalize()),"Stage %d NPCs direct a defeated guardian toward the correct reward" % chapter)
		level.key_found = true
		check(details.advice(0).begins_with(level.profile.exit_objective.capitalize()),"Stage %d NPCs point to its own next-stage exit once the ward is claimed" % chapter)
		level.seals = 0
		level.key_found = false
		level.combat.warden_cleared = false
		# An overhead test ledge must not trigger a lantern on the path below.
		var ledge := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(180,20)
		collision.shape = shape
		ledge.add_child(collision)
		ledge.position = Vector2(level.profile.checkpoints[0],410)
		level.add_child(ledge)
		level.player.respawn(ledge.position+Vector2(0,-12))
		level.player.health = 2
		await ticks(12)
		check(level.player.is_on_floor() and level.checkpoint_index == -1 and level.player.health == 2,"Stage %d passing above a lantern cannot silently activate or heal" % chapter)
		ledge.queue_free()
		level.player.respawn(Vector2(level.profile.checkpoints[0],598))
		await ticks(12)
		check(level.checkpoint_index == 0 and level.player.health == 5 and level.hud.checkpoint_index == 0,"Stage %d ground-level lantern heals and updates the journal" % chapter)
		level.player.respawn(Vector2(450,598))
		await ticks(8)
		check(level.hud.checkpoint_index == 0,"Stage %d journal retains the activated lantern when backtracking" % chapter)
		await tap(JOY_BUTTON_START)
		var visible: Array[Control] = []
		for button: Control in level.hud.menu.get_children():
			if button.visible:
				visible.append(button)
		var inside: bool = visible.size() == 5 and level.hud.resume_button.has_focus()
		for i: int in visible.size():
			inside = inside and Rect2(680,270,400,312).encloses(visible[i].get_global_rect())
			if i > 0:
				inside = inside and not visible[i].get_global_rect().intersects(visible[i-1].get_global_rect())
		check(inside,"Stage %d pause controls fit the right page and focus Resume" % chapter)
		hub.open_panel()
		await ticks(3)
		await tap(JOY_BUTTON_DPAD_DOWN)
		check(hub.panel.rows.jump.has_focus(),"Stage %d controller focus wraps from Back to the first binding" % chapter)
		await tap(JOY_BUTTON_DPAD_DOWN)
		check(hub.panel.rows.attack.has_focus(),"Stage %d controller focus follows the binding order across the book" % chapter)
		hub.panel.deadzone_slider.grab_focus()
		var before: float = hub.deadzone
		await tap(JOY_BUTTON_DPAD_RIGHT)
		check(hub.deadzone > before,"Stage %d horizontal pad input still adjusts the themed slider" % chapter)
		var controls_fit: bool = true
		for control: Control in [hub.panel.back_button,hub.panel.style_option,hub.panel.rumble_check,hub.panel.deadzone_slider,hub.panel.strength_slider]:
			controls_fit = controls_fit and Rect2(200,145,875,490).encloses(control.get_global_rect())
		check(controls_fit,"Stage %d settings controls stay inside their parchment pages" % chapter)
		await tap(JOY_BUTTON_B)
		check(not hub.panel.visible and paused and level.hud.resume_button.has_focus(),"Stage %d closing settings restores the journal focus" % chapter)
		await tap(JOY_BUTTON_B)
		check(not paused,"Stage %d the physical back button resumes from the journal" % chapter)
		var guardian: Node2D = level.combat.guardian
		level.player.position = guardian.home+Vector2(-160,0)
		guardian.strike(guardian.position+Vector2(0,-30),0,2,0)
		level.combat._physics_process(0)
		check(level.hud.boss_visible and level.hud.boss_health == guardian.max_health-2 and level.hud.boss_damage_trail == guardian.max_health,"Stage %d guardian UI retains the just-lost vitality after a heavy hit" % chapter)
		guardian.hit_pause = 0
		guardian.hit_timer = 0
		guardian._physics_process(0.5)
		level.combat._physics_process(0)
		check(level.hud.boss_damage_trail == level.hud.boss_health,"Stage %d guardian UI damage trail settles to its real health" % chapter)
		guardian.reset_encounter()
		level.completed = true
		level.hud.complete = true
		Campaign.record(level)
		await ticks(3)
		check(Journal.task(level.hud) == level.profile.completed_objective and (level.hud.continue_button.has_focus() if chapter < Campaign.STAGES else level.hud.restart_button.has_focus()),"Stage %d completion journal presents the correct task and next action" % chapter)
		var font: Font = level.hud.font
		var text_fits: bool = true
		for value: String in [level.profile.title,level.profile.victory,level.profile.victory_text]:
			for line: String in Pocket.lines(font,value,26 if value != level.profile.victory_text else 16,368):
				text_fits = text_fits and font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,26 if value != level.profile.victory_text else 16).x <= 368
		check(text_fits,"Stage %d long journal titles and descriptions wrap inside one page" % chapter)
		level.queue_free()
		await ticks(2)
	var dialogue: String = "Archivist: Claim the Sanctum Sigil. Your reward waits beside the guardian's arena, beyond the sunken cloister. Follow the lanterns right and the forgotten woodland trail will open."
	var wrapped: PackedStringArray = Pocket.lines(ThemeDB.fallback_font,dialogue,16,1000)
	check(wrapped.size() == 2,"Long NPC dialogue wraps above the footer instead of extending beyond the screen")
	print("POCKET UI RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
