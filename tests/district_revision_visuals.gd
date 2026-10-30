extends "res://tests/district_visuals.gd"

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/district-revision-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.player.set_physics_process(false)
	level.seals = 3
	for item: Dictionary in level.items:
		if item.kind == "seal":
			item.taken = true
			item.visual.hide()
	level.district.activate_switch("quarter_ritual")
	level.combat.guardian.strike(level.combat.guardian.position-Vector2(40,35),1,100,0,true)
	await ticks(65)
	for entry: Array in [["chapel_return",Vector2(18520,600)],["crypt_landing",Vector2(18390,1040)],["chapel_undercroft",Vector2(17650,1460)],["bell_landing",Vector2(4060,200)],["ossuary_landing",Vector2(6810,1030)],["service_landing",Vector2(10170,980)]]:
		await look(entry[1],entry[0])
	level.district.waters[1].ripple(13400,4)
	level.district.waters[1].ripple(13650,5)
	await look(Vector2(13430,640),"water_wakes")
	await look(Vector2(19000,600),"results_return")
	level.key_found = true
	level.completed = true
	level.hud.complete = true
	await ticks(4)
	await capture("district_results_return")
	level.completed = false
	level.hud.complete = false
	await look(Vector2(18520,600),"return_map")
	level.district.map_overlay.open_map()
	await capture("district_return_map")
	paused = false
	level.queue_free()
	await ticks(8)
	print("DISTRICT REVISION VISUALS: CAPTURED RETURN ROUTE, LANDINGS, WATER AND RESULTS")
	quit()
