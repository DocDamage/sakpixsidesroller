extends "res://tests/route_playthrough.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Expand = preload("res://scripts/stage_expansion.gd")
const Pad = preload("res://tests/pad_driver.gd")

func steer(target: float) -> void:
	release("move_left")
	release("move_right")
	if absf(target-level.player.position.x) > 5:
		press("move_right" if target > level.player.position.x else "move_left")

func hop(platform: Rect2) -> bool:
	var target: float = platform.end.x-64
	var ascending: bool = platform.position.y < level.player.position.y-60
	if ascending:
		var right: float = level.player.position.x+40
		for rect: Rect2 in level.profile.builder.LEDGES:
			if absf(rect.position.y-level.player.position.y) < 4 and level.player.position.x >= rect.position.x and level.player.position.x <= rect.end.x:
				right = maxf(right,rect.end.x)
		if absf(level.player.position.y-600) < 4:
			for repeat: int in 4:
				for span: Vector2 in level.profile.builder.FLOORS:
					if span.x <= right and span.y >= level.player.position.x:
						right = maxf(right,span.y)
		var launch: float = minf(right-40,platform.position.x-60)
		if launch > level.player.position.x+5:
			await go(launch)
		press("jump")
	var deaths: int = level.deaths
	for frame: int in 240:
		steer(target)
		if ascending:
			if frame == 14:
				release("jump")
			if frame == 17:
				press("jump")
			if frame == 42:
				release("jump")
		await ticks(1)
		if level.deaths != deaths:
			break
		if absf(level.player.position.x-target) < 12 and level.player.is_on_floor() and absf(level.player.position.y-platform.position.y) < 4:
			release("jump")
			release("move_right")
			release("move_left")
			await ticks(3)
			return true
	release("jump")
	release("move_right")
	release("move_left")
	push_error("Vertical route failed at %s, wanted %s, deaths %d" % [level.player.position,platform,level.deaths])
	return false

func run() -> void:
	controller_mode = "--keyboard" not in OS.get_cmdline_user_args()
	var hub: Node = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/extended-journey-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	var first: int = 1
	var last: int = 12
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			first = int(argument.trim_prefix("--stage="))
			last = first
	for stage: int in range(first,last+1):
		level = load(Campaign.SCENES[stage-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		level.player.invincible = 10000
		var route: Array = [[1120,false],[1280,true],[1480,false],[1850,true],[2310,false],[2496,true],[2770,false],[3190,true],[3720,false],[3904,true],[4170,false],[4600,true],[5430,false]] if stage == 1 else [[1120,false],[1280,true],[1600,false],[1970,true],[2700,false],[2880,true],[3090,false],[3500,true],[4200,false],[4384,true],[4560,false],[4910,true],[5430,false]]
		if stage >= 3:
			var builders: Array[Script] = [preload("res://scripts/market_builder.gd"),preload("res://scripts/keep_builder.gd"),preload("res://scripts/ashen_builder.gd"),preload("res://scripts/cathedral_builder.gd"),preload("res://scripts/briarwood_builder.gd"),preload("res://scripts/elderroot_builder.gd"),preload("res://scripts/rootbound_catacombs_builder.gd"),preload("res://scripts/prism_vault_builder.gd"),preload("res://scripts/lumenwood_trail_builder.gd"),preload("res://scripts/starfall_glade_builder.gd")]
			route = builders[stage-3].ROUTE
		for waypoint: Array in route:
			if waypoint[0] < Expand.CUT:
				await go(waypoint[0],waypoint[1])
		await go(Expand.CUT+192,true)
		for room: Dictionary in level.extension.rooms:
			for platform: Rect2 in room.platforms:
				if not await hop(platform):
					failed = true
					break
				if absf(platform.get_center().x-room.peak.x) < 1:
					await go(room.peak.x)
			if failed:
				break
			if not await hop(Rect2(room.start+2800,600,400,220)):
				failed = true
				break
		if failed:
			level.queue_free()
			await ticks(2)
			break
		for waypoint: Array in route:
			if waypoint[0] >= Expand.CUT:
				await go(Expand.map_x(waypoint[0]),waypoint[1])
		if not await preload("res://tests/guardian_driver.gd").fight(self,level,controller_mode):
			failed = true
		await go(level.chest.position.x)
		await interact()
		await go(level.portal.position.x)
		await interact()
		if not level.completed or level.seals != 3 or level.deaths != 0:
			failed = true
			push_error("Stage %d extended completion failed, seals=%d deaths=%d" % [stage,level.seals,level.deaths])
		print("EXTENDED STAGE %d: %s / %s" % [stage,"FAIL" if failed else "PASS",level.player.position])
		level.queue_free()
		await ticks(2)
		if failed:
			break
	OS.delay_msec(120)
	await ticks(6)
	print("EXTENDED CAMPAIGN: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
