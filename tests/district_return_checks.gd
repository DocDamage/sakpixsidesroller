extends "res://tests/district_journey.gd"

func require(value: bool, title: String) -> void:
	print(("FAIL: " if not value else "PASS: ")+title)
	failed = failed or not value

func fight_return_boss() -> bool:
	for frame: int in 1200:
		if level.combat.warden_cleared:
			Pad.release()
			return true
		var offset: float = level.combat.guardian.position.x-level.player.position.x
		var direction: float = signf(offset)
		var moving: bool = absf(offset) > 62 or level.player.facing != direction and level.player.attack_time <= 0
		Pad.axis(JOY_AXIS_LEFT_X,direction if moving else 0.0)
		if frame%18 == 0 and absf(offset) < 145 and level.player.facing*direction > 0:
			Pad.button(JOY_BUTTON_X,true)
		elif frame%18 == 1:
			Pad.button(JOY_BUTTON_X,false)
		await ticks(1)
	Pad.release()
	return false

func run() -> void:
	var hub: Node = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/district-return-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	Pad.keyboard = "--keyboard" in OS.get_cmdline_user_args()
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	# Begin at the boss encounter. After this fixture setup, the entire route
	# uses native input, including the fight, exit, return stair and tram ride.
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.seals = 3
	for item: Dictionary in level.items:
		if item.kind == "seal":
			item.taken = true
			item.visual.hide()
	level.district.activate_switch("quarter_ritual")
	level.district.tram.position = level.district.tram.finish
	level.district.tram.direction = -1
	level.player.respawn(Vector2(17500,600))
	level.player.invincible = 0
	level.combat.guardian.set_physics_process(true)
	await ticks(10)
	var won: bool = await fight_return_boss()
	require(won and level.combat.warden_cleared,"Normal-damage boss fight opens both ends of the chapel undercroft")
	require(level.district.opened.has("chapel_hatch") and level.district.opened.has("chapel_passage") and level.district.opened.has("trapdoor") and level.district.opened.has("sluice"),"Victory opens a complete physical return loop even when the pump and prison switches were missed")
	if failed:
		await done()
		return
	await walk(18260)
	await use()
	await walk(19000)
	await use()
	await ticks(8)
	require(level.completed and level.player.locked and level.hud.resume_button.visible,"Results screen exposes Keep exploring after claiming the key and exiting")
	# Escape / controller B is also a recovery path out of the results screen.
	if Pad.keyboard:
		Pad.key(KEY_ESCAPE,true)
		await ticks(2)
		Pad.key(KEY_ESCAPE,false)
	else:
		Pad.button(JOY_BUTTON_B,true)
		await ticks(2)
		Pad.button(JOY_BUTTON_B,false)
	await ticks(10)
	require(not level.completed and not level.player.locked and level.key_found and level.combat.warden_cleared,"Back resumes the same cleared district without resetting the key or boss")
	await walk(18520)
	await climb(1460)
	require(level.player.position.y > 1440,"Marked chapel stair is reachable from the exit and descends through both real floors")
	await climb(600)
	await walk(19000)
	await use()
	await ticks(8)
	require(level.completed and level.hud.resume_button.has_focus(),"Re-entering the portal refreshes results and focuses Keep exploring")
	if Pad.keyboard:
		Pad.key(KEY_ENTER,true)
		await ticks(2)
		Pad.key(KEY_ENTER,false)
	else:
		Pad.button(JOY_BUTTON_A,true)
		await ticks(2)
		Pad.button(JOY_BUTTON_A,false)
	await ticks(10)
	require(not level.completed and not level.player.locked,"Keep exploring accepts keyboard Enter and controller A without replaying the stage")
	await walk(18520)
	await climb(1460)
	await walk(16430)
	require(level.player.position.x < 16500 and level.deaths == 0,"Undercroft crosses the former dead-end wall into the existing return gallery")
	await walk(16380)
	await leap(16380,1390)
	await use()
	for frame: int in 1500:
		await ticks(1)
		if level.player.position.x < 3820:
			break
	require(level.player.position.x < 3820,"Tram carries the returning player west to the prison hub")
	await walk(3570)
	await climb(600)
	await walk(2920)
	require(absf(level.player.position.x-2920) < 40 and absf(level.player.position.y-600) < 5 and level.key_found and level.district.ritual_ready,"Player physically returns to the quarter after the boss with progress intact")
	print("DISTRICT RETURN RESULT: ","FAIL" if failed else "PASS"," / native ","keyboard" if Pad.keyboard else "controller"," / deaths ",level.deaths)
	await done()
