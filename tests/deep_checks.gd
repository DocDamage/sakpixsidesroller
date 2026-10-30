extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Assets = preload("res://scripts/level_assets.gd")
const Biome = preload("res://scripts/deep_biome.gd")
const Ribbon = preload("res://scripts/stage_ribbon.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/deep-check-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	Campaign.results.clear()
	Campaign.unlocked_chapter = 1
	level = load(Campaign.SCENES[7]).instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	level.completed = true
	level.hud.complete = true
	Campaign.record(level)
	await ticks(3)
	check(level.hud.continue_button.has_focus() and not level.hud.first_button.visible,"Elderroot now offers Continue to stage nine instead of ending the campaign")
	await tap(JOY_BUTTON_A)
	await ticks(25)
	level = current_scene
	check(level.chapter == 9 and level.player.jumps == 0,"Controller continuation descends into Rootbound Catacombs without a leaked jump")
	level.queue_free()
	await ticks(2)
	var layouts: Dictionary = {}
	for chapter: int in range(9,13):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		layouts[str(level.profile.builder.LEDGES)] = true
		check(level.profile.regions.size() == 4 and level.profile.builder.ROUTE.size() == 13,"Stage %d has four named regions and an authored continuous route" % chapter)
		check(level.items.size() == 37 and get_nodes_in_group("enemies").size() == 13,"Stage %d supplies three markers, 34 coins and thirteen encounters" % chapter)
		check(level.combat.guardian.max_health == [10,12,12,14][chapter-9],"Stage %d guardian uses the intended difficulty profile" % chapter)
		check(Ribbon.icons.size() == 12,"Stage %d HUD and journal load all twelve supplied journey icons" % chapter)
		var title: String = level.audio.now_playing()
		check(title.contains(["Behind the Walls","Beneath the Manor","Moonlight Through Broken Glass","The Haunted Manor"][chapter-9]),"Stage %d plays its selected Haunted Manor soundtrack" % chapter)
		var sources: Dictionary = {}
		for visual: Sprite2D in level.find_children("*","Sprite2D",true,false):
			if visual.texture.resource_path.begins_with(Biome.DUNGEON if chapter <= 10 else Biome.MAGIC):
				sources[visual.texture.resource_path] = true
		check(sources.size() >= 15,"Stage %d builds its visual identity from at least fifteen assets in the requested pack" % chapter)
		var valid_tops: bool = true
		for visual: Sprite2D in level.get_children().filter(func(node: Node) -> bool: return node is Sprite2D):
			if visual.z_index == 1 and visual.region_enabled:
				var pixels: Image = visual.texture.get_image()
				if pixels.is_compressed():
					pixels.decompress()
				var crop: Rect2i = Rect2i(visual.region_rect)
				for x: int in range(crop.position.x,crop.end.x):
					valid_tops = valid_tops and pixels.get_pixel(x,crop.position.y).a > 0.5
		check(valid_tops,"Stage %d platform art has a continuous visible top beneath its one-way collision" % chapter)
		if chapter >= 11:
			check(level.world_details.drifting.size() == 6,"Stage %d adds restrained supplied butterflies and fireflies" % chapter)
			var sprite: Sprite2D = level.world_details.drifting[0].visual
			var before: Vector2 = sprite.position
			await ticks(8)
			var moving: Vector2 = sprite.position
			await tap(JOY_BUTTON_START)
			await ticks(5)
			check(moving != before and sprite.position == moving,"Stage %d forest wildlife animates and freezes with the controller journal" % chapter)
			await tap(JOY_BUTTON_B)
		level.player.respawn(Vector2(590,598))
		level.player.invincible = 1000
		await ticks(8)
		Pad.button(JOY_BUTTON_X,true)
		await ticks(15)
		Pad.release()
		var broken: Node2D
		for node: Node in level.get_children():
			if node.get_script() == preload("res://scripts/breakable_urn.gd") and node.position.x == 650:
				broken = node
		check(broken != null and broken.broken and get_nodes_in_group("healing_vials").size() == 1,"Stage %d own-pack supplies break with the controller and drop one healing heart" % chapter)
		check(broken.visual.texture.resource_path.begins_with(Biome.DUNGEON if chapter <= 10 else Biome.MAGIC) and absf(Assets.visible_rect(broken.visual).end.y-600)<0.1,"Stage %d debris uses its own pack and remains grounded" % chapter)
		level.player.health = 4
		level.player.position.x = 650
		await ticks(12)
		check(level.player.health == 5 and get_nodes_in_group("healing_vials").is_empty(),"Stage %d dropped supplies restore exactly one vitality" % chapter)
		level.queue_free()
		await ticks(2)
	check(layouts.size() == 4,"All four new stages have distinct platform layouts")
	print("DEEP RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
