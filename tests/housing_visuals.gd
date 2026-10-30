extends "res://tests/district_visuals.gd"

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/housing-visual-controller.cfg"
	hub.defaults()
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.player.set_physics_process(false)
	for entry: Array in [["housing_street",Vector2(1260,600)],["housing_interior",Vector2(2920,600)],["housing_loft",Vector2(3030,120)],["housing_annex",Vector2(3900,-80)]]:
		await look(entry[1],entry[0])
	# Whole-building render demonstrates the same roof, facade and foundations.
	level.set_physics_process(false)
	level.player.position = Vector2(2864,80)
	level.player.hide()
	level.camera.zoom = Vector2(0.62,0.62)
	level.camera.position = Vector2(2864,30)
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	for building: Node2D in get_nodes_in_group("district_buildings"):
		building.set_process(false)
		building.facade.modulate.a = 1
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.hide()
	level.hud.region_time = 0
	await ticks(6)
	await capture("housing_complete_exterior")
	level.queue_free()
	await ticks(6)
	print("HOUSING VISUALS: COMPLETE EXTERIOR, STREET AND PLAYABLE INTERIORS")
	quit()
