extends "res://tests/living_world_checks.gd"

const Assets = preload("res://scripts/level_assets.gd")

func supported(bounds: Rect2) -> bool:
	for floor: Rect2 in level.profile.builder.LEDGES:
		if absf(bounds.end.y-floor.position.y) <= 1.1 and bounds.position.x >= floor.position.x and bounds.end.x <= floor.end.x:
			return true
	return false

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/fixture-controller.cfg"
	hub.defaults()
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	level.player.set_physics_process(false)
	var guard: Node2D
	var rat: Node2D
	var witch: Node2D
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.species == "guard" and absf(enemy.home.x-3100) < 200:
			guard = enemy
		elif enemy.species == "rat":
			rat = enemy
		elif enemy.species == "witch":
			witch = enemy
	var matching: bool = true
	var terrains: Array[Node] = get_nodes_in_group("contour_terrain")
	for body: StaticBody2D in terrains:
		var contour: PackedVector2Array = body.get_meta("terrain_contour")
		matching = matching and body.get_child(0).polygon == contour and body.get_child(1).polygon == contour
		var shadow_found: bool = false
		for shadow: LightOccluder2D in get_nodes_in_group("district_shadows"):
			shadow_found = shadow_found or shadow.occluder.polygon == contour
		matching = matching and shadow_found
	check(terrains.size() == 14 and matching,"Ferr2D-style foundations share one exact contour for fill, collision and cast shadows")
	var ladders: bool = true
	for section: Sprite2D in get_nodes_in_group("district_ladder_sections"):
		ladders = ladders and not section.texture.resource_path.contains("scaffold") and section.region_rect.size.x*section.scale.x == 48 and section.scale == Vector2(3,3)
	check(ladders and not get_nodes_in_group("district_ladder_sections").is_empty(),"Climbs use clean 48px ladder rails at a uniform pixel scale, with no scaffold/table image")
	var furniture: bool = true
	var count: int = 0
	for building: Node2D in get_nodes_in_group("district_buildings"):
		for entry: Dictionary in building.furnishings:
			furniture = furniture and supported(entry.bounds) and building.interior.has_point(entry.feet-Vector2(0,10))
			count += 1
	check(furniture and count == 4,"All four interior furnishings have complete supported footprints inside the cutaway building")
	var lamps: bool = true
	var mounted: bool = true
	for fixture: Node2D in get_nodes_in_group("district_light_fixtures"):
		if fixture is Sprite2D and fixture.texture.resource_path.ends_with("lantern_post.png"):
			lamps = lamps and supported(Assets.visible_rect(fixture))
		elif fixture is AnimatedSprite2D:
			var wall_found: bool = false
			for panel: Sprite2D in get_nodes_in_group("district_panels"):
				var rect := Rect2(panel.position-panel.region_rect.size*panel.scale/2,panel.region_rect.size*panel.scale)
				wall_found = wall_found or panel.z_index <= -8 and rect.has_point(fixture.position)
			for building: Node2D in get_nodes_in_group("district_buildings"):
				wall_found = wall_found or building.interior.has_point(fixture.position)
			mounted = mounted and wall_found
	check(lamps,"Every exterior lantern post stands on an actual floor, including upper open balconies")
	check(mounted,"Every wall torch has architectural backing instead of hanging in open sky")
	var emitters: bool = true
	for fire: Sprite2D in level.world_details.fires:
		var emitter: Vector2 = fire.global_position+Vector2(fire.get_meta("emitter_offset"))
		var pixels: Image = fire.flame.sprite_frames.get_frame_texture("default",fire.flame.frame).get_image()
		if pixels.is_compressed():
			pixels.decompress()
		var flame_bounds: Rect2 = fire.flame.global_transform*Rect2(Vector2(pixels.get_used_rect().position)-Vector2(pixels.get_size())/2,Vector2(pixels.get_used_rect().size))
		var found_light: bool = false
		var found_glow: bool = false
		for light: PointLight2D in level.district.lighting.lights:
			if light.has_meta("follow") and light.get_meta("follow").get_ref() == fire:
				found_light = found_light or light.global_position.distance_to(emitter) < 0.1
		for point: Dictionary in level.lighting.points:
			found_glow = found_glow or point.follow == fire and point.visual.global_position.distance_to(emitter) < 0.1
		emitters = emitters and found_light and found_glow and flame_bounds.has_point(emitter) and supported(Assets.visible_rect(fire))
	check(emitters,"Every campfire rests on its floor and its real light/halo originate inside the animated flame")
	var sounds: bool = true
	for event: String in ["guard_swing","witch_fire","eye_fire","mosquito_dive","armor_ready","beast_ready","warden_swing","rat_lunge","bat_dive","mimic_snap","mushroom_rush","spit","spell_impact","enemy_contact"]:
		sounds = sounds and level.audio.variants[event].size() == 2 and level.audio.variants[event][0].data.size() > 0
	check(sounds,"Fourteen enemy-specific events load two nonempty supplied-kit SFX variations each")
	# Exercise real state transitions rather than calling the presentation handlers.
	guard.position = Vector2(3100,120)
	guard.home = guard.position
	level.player.position = guard.position+Vector2(60,0)
	level.player.invincible = 0
	level.player.health = 5
	guard.state = 1
	guard.state_time = 0
	guard.committed_windup = 0.4
	guard.attack_direction = 1
	guard.attack_fx_fired = false
	guard.hit_timer = 0
	guard.set_physics_process(true)
	await ticks(12)
	check(level.player.health == 5,"Standing inside a guard's reach during anticipation does not cause a premature body hit")
	await ticks(22)
	var trail: AnimatedSprite2D
	for effect: Node in level.effects.get_children():
		if effect.get_meta("effect_kind","") == "enemy_swing":
			trail = effect
	check(level.player.health == 4 and trail != null and level.audio.variant_index.get("guard_swing",0) == 1,"The guard's active frames produce one swish, a blade trail and one actual damage contact")
	guard.strike(guard.position-Vector2(50,30),1,1,0,true)
	await ticks(2)
	check(not is_instance_valid(trail),"Interrupting an attack immediately removes its attached blade trail")
	guard.set_physics_process(false)
	level.player.position = rat.position+Vector2(45,0)
	level.player.invincible = 0
	level.player.health = 5
	rat.state = 1
	rat.state_time = 0
	rat.committed_windup = 0.1
	rat.attack_direction = 1
	rat.hit_timer = 0
	rat.set_physics_process(true)
	var previous_contact: int = level.audio.variant_index.get("enemy_contact",0)
	await ticks(18)
	check(level.audio.variant_index.get("rat_lunge",0) == 1 and level.audio.variant_index.get("enemy_contact",0) == previous_contact+1 and level.player.health == 4,"A real rat lunge produces its own launch cue and a single impact while player invulnerability prevents repeats")
	rat.set_physics_process(false)
	level.player.position = witch.position+Vector2(180,0)
	witch.state = 2
	witch.state_time = 0
	witch.target = level.player.position
	witch.volley_fired = false
	witch.set_physics_process(true)
	await ticks(12)
	check(level.audio.variant_index.get("witch_fire",0) == 1,"The caster's actual projectile release uses its casting sound")
	level.queue_free()
	await ticks(6)
	OS.delay_msec(120)
	await ticks(6)
	print("FIXTURE/ATTACK RESULT: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
