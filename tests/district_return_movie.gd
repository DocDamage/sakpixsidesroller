extends "res://tests/district_movie.gd"

func walk_to(x: float) -> void:
	var direction: float = signf(x-level.player.position.x)
	Pad.axis(JOY_AXIS_LEFT_X,direction)
	for frame: int in 600:
		if (x-level.player.position.x)*direction <= 7:
			break
		await ticks(1)
	Pad.axis(JOY_AXIS_LEFT_X,0)
	await ticks(10)

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/district-return-movie-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.seals = 3
	for item: Dictionary in level.items:
		if item.kind == "seal":
			item.taken = true
			item.visual.hide()
	level.district.activate_switch("quarter_ritual")
	level.combat.guardian.strike(level.combat.guardian.position-Vector2(40,35),1,100,0,true)
	level.district.tram.position = level.district.tram.finish
	level.district.tram.direction = -1
	level.key_found = true
	level.chest.texture = preload("res://scripts/level_assets.gd").texture(level.profile.open_texture)
	preload("res://scripts/level_assets.gd").anchor_base(level.chest,600)
	shot(Vector2(18260,600))
	# One continuous input sequence from the cleared boss area to the return
	# station. No repositioning or camera cuts after this initial fixture.
	await walk_to(18520)
	Pad.axis(JOY_AXIS_LEFT_Y,1)
	for frame: int in 340:
		await ticks(1)
		if level.player.position.y > 1458:
			break
	Pad.axis(JOY_AXIS_LEFT_Y,0)
	await ticks(12)
	await walk_to(16380)
	Pad.button(JOY_BUTTON_A,true)
	await ticks(12)
	Pad.button(JOY_BUTTON_A,false)
	await ticks(48)
	Pad.button(JOY_BUTTON_Y,true)
	await ticks(2)
	Pad.button(JOY_BUTTON_Y,false)
	await ticks(90)
	Pad.release()
	var passed: bool = level.player.position.x < 15800 and level.player.position.y < 1410 and level.deaths == 0
	print("RETURN MOVIE: ","PASS" if passed else "FAIL"," / final ",level.player.position)
	level.queue_free()
	await ticks(6)
	OS.delay_msec(120)
	await ticks(6)
	quit(0 if passed else 1)
