extends "res://tests/route_playthrough.gd"

func run() -> void:
	for chapter: int in [3, 4]:
		level = load("res://scenes/emberwick_market.tscn" if chapter == 3 else "res://scenes/crownward_keep.tscn").instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		level.player.invincible = 1000
		for waypoint: Array in level.profile.builder.ROUTE:
			await go(waypoint[0], waypoint[1])
		if not await preload("res://tests/guardian_driver.gd").fight(self, level):
			failed = true
			push_error("Kingdom guardian did not fall through attack inputs")
		await go(5520)
		await interact()
		await go(6190)
		await interact()
		if not level.completed or level.seals != 3 or not level.key_found or level.deaths > 0:
			failed = true
			push_error("Kingdom chapter %d route failed" % chapter)
		level.queue_free()
		await ticks(2)
	print("KINGDOM CONTINUOUS ROUTES: " + ("FAIL" if failed else "PASS"))
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failed else 0)
