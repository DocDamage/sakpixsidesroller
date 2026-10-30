extends "res://tests/route_playthrough.gd"

const Pad = preload("res://tests/district_input.gd")

func walk(x: float, settle: int = 8) -> bool:
	var direction: float = signf(x-level.player.position.x)
	Pad.axis(JOY_AXIS_LEFT_X,direction)
	var count: int = 0
	while (x-level.player.position.x)*direction > 7 and count < 1800:
		await ticks(1)
		count += 1
	Pad.axis(JOY_AXIS_LEFT_X,0)
	await ticks(settle)
	print("DISTRICT WALK ",x," at ",level.player.position)
	if count >= 1800:
		push_error("Blocked walking to "+str(x)+" at "+str(level.player.position))
		failed = true
	return not failed

func leap(x: float, y: float) -> bool:
	var direction: float = signf(x-level.player.position.x)
	var long_gap: bool = absf(x-level.player.position.x) > 360
	Pad.axis(JOY_AXIS_LEFT_X,direction)
	Pad.button(JOY_BUTTON_A,true)
	for frame: int in 120:
		if frame == 15:
			Pad.button(JOY_BUTTON_A,false)
		if frame == 18:
			Pad.button(JOY_BUTTON_A,true)
		if frame == 48:
			Pad.button(JOY_BUTTON_A,false)
		if long_gap and frame == 40:
			Pad.button(JOY_BUTTON_B,true)
		if frame == 42:
			Pad.button(JOY_BUTTON_B,false)
		if absf(level.player.position.x-x) < 10 or (x-level.player.position.x)*direction < 0:
			Pad.axis(JOY_AXIS_LEFT_X,0)
		await ticks(1)
	Pad.release()
	await ticks(15)
	print("DISTRICT LEAP ",Vector2(x,y)," at ",level.player.position)
	if is_finite(y) and absf(level.player.position.y-y) > 35:
		failed = true
		push_error("Jump missed its actual landing: "+str(level.player.position))
	return not failed

func climb(y: float) -> bool:
	var direction: float = signf(y-level.player.position.y)
	Pad.axis(JOY_AXIS_LEFT_Y,direction)
	var count: int = 0
	while (y-level.player.position.y)*direction > (-6 if direction < 0 else 2) and count < 800:
		await ticks(1)
		count += 1
	Pad.axis(JOY_AXIS_LEFT_Y,0)
	await ticks(6)
	print("DISTRICT CLIMB ",y," at ",level.player.position)
	if count >= 800:
		failed = true
		push_error("Blocked climbing: "+str(level.player.position))
	return not failed

func use() -> void:
	Pad.button(JOY_BUTTON_Y,true)
	await ticks(2)
	Pad.button(JOY_BUTTON_Y,false)
	await ticks(3)

func done() -> void:
	Pad.release()
	print("DISTRICT CONTINUOUS JOURNEY: ","FAIL" if failed else "PASS"," / seals ",level.seals," / deaths ",level.deaths," / simulated seconds ",level.elapsed)
	level.queue_free()
	await ticks(6)
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failed else 0)

func run() -> void:
	var hub: Node = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/district-journey-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	controller_mode = true
	Pad.keyboard = "--keyboard" in OS.get_cmdline_user_args()
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	# A route audit isolates physical connectivity from combat. Every movement
	# below uses native pad input; there are no relocations or simulated pickups.
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.player.invincible = 10000
	if not await walk(2440):
		await done()
		return
	if not await climb(380):
		await done()
		return
	if not await walk(2720):
		await done()
		return
	if not await climb(120):
		await done()
		return
	if not await walk(3500):
		await done()
		return
	if not await leap(3740,-80):
		await done()
		return
	if not await walk(4180):
		await done()
		return
	if not await leap(4510,-240):
		await done()
		return
	if not await leap(4140,-400):
		await done()
		return
	if not await leap(4370,-500):
		await done()
		return
	if not await walk(4780):
		await done()
		return
	if not await leap(5080,-500):
		await done()
		return
	if not await walk(5420):
		await done()
		return
	if not await leap(5700,-700):
		await done()
		return
	if not await walk(6020):
		await done()
		return
	await use()
	if level.seals != 1:
		failed = true
		push_error("Belfry objective was not collected by the real player")
		await done()
		return
	if not await walk(6270,120):
		await done()
		return
	if not await walk(6500):
		await done()
		return
	if not await leap(6920,600):
		await done()
		return
	if not await walk(7140):
		await done()
		return
	if not await climb(1100):
		await done()
		return
	if not await walk(7410):
		await done()
		return
	await use()
	await ticks(520)
	if not await walk(9850,80):
		await done()
		return
	if not await walk(9760):
		await done()
		return
	Pad.axis(JOY_AXIS_LEFT_Y,1)
	Pad.button(JOY_BUTTON_A,true)
	await ticks(2)
	Pad.button(JOY_BUTTON_A,false)
	Pad.axis(JOY_AXIS_LEFT_Y,0)
	await ticks(65)
	if level.seals != 2:
		failed = true
		push_error("Cistern objective was not collected by the real player")
		await done()
		return
	if not await walk(10000):
		await done()
		return
	if not await climb(1100):
		await done()
		return
	if not await walk(10250):
		await done()
		return
	if not await climb(600):
		await done()
		return
	if not await walk(11600):
		await done()
		return
	if not await climb(80):
		await done()
		return
	if not await walk(12050):
		await done()
		return
	if not await leap(12420,INF):
		await done()
		return
	if not await climb(-120):
		await done()
		return
	if not await leap(12640,-120):
		await done()
		return
	# The ground route through the floodgarden is a full alternative to the
	# upper ferry/grapple route, and reaches the sanctum by a climbable vine.
	if not await walk(13350,100):
		await done()
		return
	Pad.axis(JOY_AXIS_LEFT_X,1)
	Pad.axis(JOY_AXIS_LEFT_Y,-0.4)
	for i: int in 900:
		await ticks(1)
		if level.player.position.x >= 14740:
			break
	Pad.release()
	if level.player.position.x < 14680:
		failed = true
		push_error("Floodgarden current route blocked")
		await done()
		return
	if not await walk(14740):
		await done()
		return
	if not await climb(-120):
		await done()
		return
	if not await walk(15020):
		await done()
		return
	if level.seals != 3:
		failed = true
		push_error("Garden objective was not collected by the real player")
		await done()
		return
	if not await walk(15500,100):
		await done()
		return
	# Return by a different route: lower gallery, drained canal, prison rafters
	# and the trapdoor back to the quarter. Restore the hub ritual, then ride
	# the unlocked tram to the chapel. This audits the full backtracking loop.
	if not await walk(16430):
		await done()
		return
	if not await climb(1460):
		await done()
		return
	if not await walk(10200):
		await done()
		return
	if not await walk(7560,100):
		await done()
		return
	if not await climb(1100):
		await done()
		return
	if not await walk(6970,100):
		await done()
		return
	if not await walk(5240):
		await done()
		return
	if not await climb(1120):
		await done()
		return
	if not await walk(4460):
		await done()
		return
	if not await climb(1460):
		await done()
		return
	if not await walk(3500):
		await done()
		return
	await use()
	if not await walk(3570):
		await done()
		return
	if not await climb(600):
		await done()
		return
	if not await walk(2920):
		await done()
		return
	await use()
	if not level.district.ritual_ready:
		failed = true
		push_error("The three recovered seals did not restore the quarter ritual")
		await done()
		return
	if not await walk(3570):
		await done()
		return
	if not await climb(1460):
		await done()
		return
	if not await leap(3780,1390):
		await done()
		return
	await use()
	for frame: int in 1600:
		await ticks(1)
		if level.player.position.x > 16330:
			break
	if level.player.position.x < 16330:
		print("TRAM DIAGNOSTIC player=",level.player.position," platform=",level.district.tram.position," enabled=",level.district.tram.enabled," floor velocity=",level.player.get_platform_velocity()," open=",level.district.opened)
		failed = true
		push_error("The return tram did not carry its passenger across the real world")
		await done()
		return
	if not await walk(16430):
		await done()
		return
	if not await climb(600):
		await done()
		return
	if not await walk(16680):
		await done()
		return
	if not await walk(17500):
		await done()
		return
	# Defeat through the same combat driver used for the campaign, then claim
	# the ward and exit using controller interaction.
	level.combat.guardian.set_physics_process(true)
	if not await preload("res://tests/guardian_driver.gd").fight(self,level,not Pad.keyboard):
		failed = true
		push_error("District guardian did not fall through combat input")
		await done()
		return
	if not await walk(18260):
		await done()
		return
	await use()
	if not await walk(19000):
		await done()
		return
	await use()
	failed = failed or not level.completed or not level.key_found or level.deaths != 0
	await done()
