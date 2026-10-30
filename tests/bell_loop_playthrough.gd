extends "res://tests/district_journey.gd"

func fight_guard() -> bool:
	for frame: int in 700:
		var opponent: Node2D
		for enemy: Node2D in get_nodes_in_group("enemies"):
			if not enemy.dead and enemy.species == "guard" and absf(enemy.position.y-level.player.position.y) < 80 and absf(enemy.position.x-level.player.position.x) < 520:
				opponent = enemy
				break
		if opponent == null:
			Pad.release()
			return true
		var offset: float = opponent.position.x-level.player.position.x
		var direction: float = signf(offset)
		Pad.axis(JOY_AXIS_LEFT_X,direction if absf(offset) > 64 or level.player.facing != direction and level.player.attack_time <= 0 else 0)
		Pad.button(JOY_BUTTON_X,frame%18 == 0 and absf(offset) < 135)
		await ticks(1)
		if level.deaths > 0:
			break
	Pad.release()
	failed = true
	push_error("Live guard encounter failed at "+str(level.player.position))
	return false

func snapshot(name: String) -> void:
	if "--captures" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/bell-live-"+name+".png")

func run() -> void:
	var hub: Node = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/bell-live-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	Pad.keyboard = "--keyboard" in OS.get_cmdline_user_args()
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	# Normal health, all encounters active, continuous native input from spawn.
	if not await walk(1550) or not await fight_guard() or not await walk(2440) or not await climb(380) or not await walk(2720) or not await climb(120):
		await done()
		return
	await snapshot("stair")
	if not await walk(2800) or not await fight_guard() or not await walk(3500) or not await leap(3740,-80) or not await walk(4180) or not await leap(4510,-240) or not await leap(4140,-400) or not await leap(4370,-500):
		await done()
		return
	await snapshot("shaft")
	if not await walk(4780) or not await leap(5080,-500) or not await fight_guard() or not await walk(5420) or not await leap(5700,-700) or not await walk(6020):
		await done()
		return
	await use()
	if level.seals != 1 or not level.district.opened.has("bell_winch"):
		failed = true
		push_error("Belfry reward did not release the native-input return route")
		await done()
		return
	await snapshot("reward")
	if not await walk(5400,90) or not await walk(4915,20):
		await done()
		return
	await use()
	await ticks(520)
	if absf(level.player.position.y-600) > 8 or absf(level.player.position.x-4915) > 110:
		failed = true
		push_error("Bell cage did not carry the player to the street: "+str(level.player.position))
		await done()
		return
	await snapshot("cage")
	if not await walk(2920):
		await done()
		return
	failed = failed or level.deaths > 0 or level.combat.kills < 2
	await snapshot("court-return")
	print("LIVE BELL LOOP: ","FAIL" if failed else "PASS"," / health ",level.player.health," / kills ",level.combat.kills," / deaths ",level.deaths," / input ","keyboard" if Pad.keyboard else "controller")
	await done()
