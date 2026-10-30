extends "res://tests/district_visuals.gd"

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/bell-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.player.set_physics_process(false)
	for entry: Array in [["bell_court_new",Vector2(2920,600)],["bell_stair_new",Vector2(2440,380)],["bell_loft_new",Vector2(3040,120)],["bell_roof_new",Vector2(3900,-80)],["bell_shaft_new",Vector2(4510,-240)],["bell_upper_new",Vector2(5210,-500)],["bell_reward_new",Vector2(6020,-700)]]:
		await look(entry[1],entry[0])
	level.district.activate_switch("bell_winch")
	await look(Vector2(4370,-500),"bell_cage_new")
	level.district.map_overlay.open_map()
	await capture("bell_loop_map")
	paused = false
	level.queue_free()
	await ticks(8)
	print("BELL LOOP VISUALS CAPTURED")
	quit()
