extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Assets = preload("res://scripts/level_assets.gd")

func at(point: Vector2) -> void:
	Pad.release()
	level.player.respawn(point)
	level.player.invincible = 1000
	await ticks(8)

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/expedition-check-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	Campaign.results.clear()
	Campaign.unlocked_chapter = 1
	check(Campaign.STAGES == 12 and Campaign.SCENES.size() == 12,"Campaign registers all twelve playable scenes")
	level = load(Campaign.SCENES[3]).instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	level.completed = true
	level.hud.complete = true
	Campaign.record(level)
	await ticks(2)
	check(level.hud.continue_button.has_focus() and not level.hud.first_button.visible,"Castle completion offers the new fifth stage")
	var previous: WeakRef = weakref(level)
	await tap(JOY_BUTTON_A)
	await ticks(25)
	level = current_scene
	check(previous.get_ref() == null and level.chapter == 5,"Controller continuation loads Ashen Ramparts and frees the castle")
	level.queue_free()
	await ticks(2)
	for chapter: int in range(5,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		check(level.chapter == chapter and level.profile.regions.size() == 4,"Stage %d loads its own four-region profile" % chapter)
		check(level.profile.builder.FLOORS.size() == 4 and level.profile.builder.LEDGES.size() == 12,"Stage %d has four floor spans and twelve authored ledges" % chapter)
		check(level.items.size() == 37 and get_nodes_in_group("enemies").size() == 13,"Stage %d provides three objectives, 34 coins and thirteen encounters" % chapter)
		check(get_nodes_in_group("water_surfaces").size() == 3 and level.world_details.fires.size() == 3,"Stage %d provides three shader-water gaps and three supported camps" % chapter)
		check(level.audio.music.playing and not level.audio.now_playing().is_empty(),"Stage %d plays its supplied album track" % chapter)
		var actors_valid: bool = level.world_details.actors.size() == 3
		for actor: Dictionary in level.world_details.actors:
			var pixels: Image = actor["visual"].texture.get_image()
			if pixels.is_compressed():
				pixels.decompress()
			for frame: int in actor["frames"]:
				actors_valid = actors_valid and pixels.get_region(Rect2i(frame*64,0,64,64)).get_used_rect().has_area()
		check(actors_valid,"Stage %d uses populated frames for three supplied NPCs" % chapter)
		var sources: Dictionary = {}
		for sprite: Sprite2D in level.find_children("*","Sprite2D",true,false):
			var path: String = sprite.texture.resource_path
			if path.begins_with(("res://Stages/Dark Fantasy/" if chapter < 7 else "res://Stages/Abandonded Forest/") if chapter < 9 else ("res://Stages/Dungeon/" if chapter <= 10 else "res://Stages/Magic Forest/")):
				sources[path] = true
		check(sources.size() >= 10,"Stage %d builds its scenery from the requested asset pack" % chapter)
		check(level.combat.guardian.max_health == [10,12,10,14,10,12,12,14][chapter-5],"Stage %d has its own guardian health profile" % chapter)
		await at(Vector2(320,598))
		await tap(JOY_BUTTON_Y)
		check(level.hud.notice.begins_with(str(level.world_details.actors[0]["name"])+":"),"Stage %d NPC advice responds to controller interaction" % chapter)
		await at(Vector2(5520,598))
		await tap(JOY_BUTTON_Y)
		check(not level.key_found,"Stage %d reward remains sealed until its objectives and guardian are cleared" % chapter)
		for item: Dictionary in level.items:
			if item["kind"] == "seal":
				await at(item["position"]+Vector2(0,34))
		check(level.seals == 3,"Stage %d objectives collect at the authored ledge positions" % chapter)
		await at(Vector2(3640,598))
		var deaths_before: int = level.deaths
		await at(Vector2(level.profile.gaps[1].x+80,700))
		check(level.deaths == deaths_before+1 and absf(level.player.position.x-3640)<2 and level.seals == 3,"Stage %d water recovery preserves objectives and returns to its own checkpoint" % chapter)
		await at(Vector2(590,598))
		Pad.button(JOY_BUTTON_X,true)
		await ticks(16)
		Pad.release()
		check(get_nodes_in_group("healing_vials").size() == 1,"Stage %d pack-specific supply container breaks and drops one heart" % chapter)
		await at(Vector2(5430,598))
		level.combat.guardian.set_physics_process(true)
		check(await preload("res://tests/guardian_driver.gd").fight(self,level,true),"Stage %d guardian can be defeated with native controller events" % chapter)
		await at(Vector2(5520,598))
		await tap(JOY_BUTTON_Y)
		check(level.key_found and absf(Assets.visible_rect(level.chest).end.y-600)<0.1,"Stage %d reward opens and its changed art remains grounded" % chapter)
		check(absf(Assets.visible_rect(level.portal).end.y-600)<0.1,"Stage %d open gate art remains grounded" % chapter)
		await at(Vector2(6190,598))
		await tap(JOY_BUTTON_Y)
		check(level.completed and Campaign.results.has(chapter),"Stage %d gate records a completed campaign result" % chapter)
		var expected: Button = level.hud.continue_button if chapter < Campaign.STAGES else level.hud.restart_button
		check(expected.has_focus() and level.hud.first_button.visible == (chapter == Campaign.STAGES),"Stage %d has the correct continuation or final return menu" % chapter)
		await tap(JOY_BUTTON_BACK)
		await tap(JOY_BUTTON_B)
		check(expected.has_focus(),"Stage %d controls return to the correct completion button" % chapter)
		if chapter == Campaign.STAGES:
			await ticks(230)
			check(level.audio.ending_blend > 0.99 and level.audio.now_playing().contains("The Morning After"),"Final victory fades into Haunted Manor's true ending soundtrack")
		level.queue_free()
		await ticks(2)
	check(Campaign.unlocked_chapter == Campaign.STAGES and Campaign.results.size() == Campaign.STAGES-3,"Campaign preserves new stage results and caps unlocking at twelve")
	print("EXPEDITION RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
