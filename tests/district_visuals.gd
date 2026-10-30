extends "res://tests/controller_visuals.gd"

func look(at: Vector2, name: String) -> void:
	level.player.respawn(at)
	level.player.invincible = 0
	level.player.update_animation()
	preload("res://scripts/level_backdrop.gd").update(level)
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	level.weather.bake_shelter()
	await ticks(8)
	level.hud.intro_time = 0
	level.hud.region_time = 0
	level.hud.notice_time = 0
	await capture("district_"+name)

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/district-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.player.set_physics_process(false)
	for entry: Array in [["court",Vector2(680,600)],["quarter",Vector2(2890,600)],["loft",Vector2(2800,120)],["gantry",Vector2(4610,-500)],["belfry",Vector2(5900,-700)],["graveyard",Vector2(5340,600)],["prison",Vector2(4450,1460)],["pump",Vector2(7340,1100)],["drowned",Vector2(8280,1460)],["shrine",Vector2(9740,1420)],["watchhouse",Vector2(11400,600)],["chimney",Vector2(11480,-240)],["aqueduct",Vector2(12840,-120)],["garden",Vector2(13430,640)],["deep_garden",Vector2(14000,960)],["sanctum",Vector2(15060,-120)],["return",Vector2(15440,1460)],["chapel",Vector2(17300,600)],["exit",Vector2(18700,600)]]:
		await look(entry[1],entry[0])
	level.district.activate_switch("sluice_control")
	await ticks(520)
	await look(Vector2(8530,1760),"drained")
	level.district.map_overlay.open_map()
	await capture("district_map")
	paused = false
	level.queue_free()
	await ticks(6)
	OS.delay_msec(120)
	print("DISTRICT VISUALS: CAPTURED NINETEEN SPACES, DRAINED WATERWAY AND MAP")
	quit()
