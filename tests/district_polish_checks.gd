extends "res://tests/living_world_checks.gd"

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/district-polish-controller.cfg"
	hub.defaults()
	var bus_count: int = AudioServer.bus_count
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.player.set_physics_process(false)
	var district: Node2D = level.district
	var water: Node2D = district.waters[0]
	water.ripple(8100,3)
	water.ripple(8290,5)
	water.ripple(8450,2)
	await ticks(2)
	var active: int = 0
	for event: Vector4 in water.ripples:
		if event.z > 0 and event.y < 0.5:
			active += 1
	check(active == 3,"Successive water contacts preserve several overlapping wakes instead of replacing the previous splash")
	level.player.position = Vector2(2500,600)
	level.audio.play_at("water_drip",Vector2(2800,550))
	var slot: Dictionary = {}
	for candidate: Dictionary in level.audio.acoustics.slots:
		if candidate.voice.get_meta("kind","") == "water_drip":
			slot = candidate
	check(not slot.is_empty() and slot.pan.pan > 0.25 and not slot.voice.get_meta("occluded"),"A nearby source pans toward its physical position without muffling an open room")
	level.audio.play_at("water_drip",Vector2(2800,680))
	var blocked: bool = false
	for candidate: Dictionary in level.audio.acoustics.slots:
		blocked = blocked or candidate.voice.get_meta("occluded",false) and candidate.filter.cutoff_hz < 3000
	check(blocked,"Stone between a source and listener muffles that voice instead of sounding equally close")
	level.player.position = Vector2(8200,1560)
	level.audio.play("swim")
	var submerged: bool = false
	for candidate: Dictionary in level.audio.acoustics.slots:
		if candidate.voice.get_meta("kind","") == "swim":
			submerged = candidate.voice.get_meta("underwater",false) and candidate.filter.cutoff_hz < 5000
	check(submerged,"Entering deep water filters the local SFX while leaving the soundtrack on its own bus")
	level.audio.play("map_open")
	var clear_ui: bool = false
	for candidate: Dictionary in level.audio.acoustics.slots:
		if candidate.voice.get_meta("kind","") == "map_open":
			clear_ui = candidate.filter.cutoff_hz > 15000
	check(clear_ui,"Map feedback stays clear even when the character is underwater")
	var supports: Array[Rect2] = level.profile.builder.LEDGES
	var landed: int = 0
	for at: Vector2 in [Vector2(4070,200),Vector2(6770,1030),Vector2(10140,980),Vector2(18320,1040)]:
		for floor: Rect2 in supports:
			if absf(floor.position.y-at.y) < 1 and at.x > floor.position.x and at.x < floor.end.x:
				landed += 1
				break
	check(landed == 4,"Long bell, ossuary, service and chapel climbs have real dismount landings")
	var blank: Array[String] = []
	var bad_crop: Array[String] = []
	for panel: Sprite2D in get_nodes_in_group("district_panels"):
		var crop: Rect2 = panel.get_meta("source_crop")
		if not Rect2(Vector2.ZERO,Vector2(panel.get_meta("source_size"))).encloses(crop):
			bad_crop.append(str(panel.position))
		if not panel.texture.get_image().get_used_rect().has_area():
			blank.append(str(panel.position))
	check(bad_crop.is_empty() and blank.is_empty(),"Every structural panel crops inside its source asset and contains visible pixels: "+str(bad_crop)+str(blank))
	district.ritual_ready = true
	district.opened["sluice"] = true
	level.player.position = Vector2(16380,1460)
	district.activate_switch("quarter_tram")
	await ticks(1150)
	check(not district.tram.enabled and district.tram.position.distance_to(district.tram.finish) < 1,"Calling the tram from the chapel brings it to that station and leaves it docked")
	district.activate_switch("quarter_tram")
	await ticks(15)
	check(not district.tram.enabled and district.tram.position.distance_to(district.tram.finish) < 1,"Using the call control from below a docked tram cannot send it away without its passenger")
	level.queue_free()
	await ticks(8)
	check(AudioServer.bus_count == bus_count,"Leaving the district releases its sound buses before another stage loads")
	# Let the audio mixer consume deferred stop commands before process exit.
	OS.delay_msec(120)
	await ticks(6)
	print("DISTRICT POLISH RESULT: %d/%d checks passed" % [checks-failures,checks])
	call_deferred("quit",1 if failures else 0)
