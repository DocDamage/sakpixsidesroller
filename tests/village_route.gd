extends "res://tests/route_playthrough.gd"

func run() -> void:
	level = load("res://scenes/lantern_road.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	level.audio.toggle()
	level.player.invincible = 1000
	await go(1120)
	await go(1280, true)
	await go(1600)
	await go(1970, true)
	await go(2700)
	await go(2880, true)
	await go(3090)
	await go(3500, true)
	await go(4200)
	await go(4384, true)
	await go(4560)
	await go(4910, true)
	await go(5430)
	if not await preload("res://tests/guardian_driver.gd").fight(self, level):
		failed = true
		push_error("Thorn Marshal did not fall to actual attack inputs")
	await go(5520)
	await interact()
	await go(6190)
	await interact()
	if not level.completed or level.seals != 3 or not level.key_found:
		failed = true
		push_error("Village route did not complete. Sparks=%d, ward=%s" % [level.seals, level.key_found])
	print("VILLAGE CONTINUOUS PLAYTHROUGH: " + ("FAIL" if failed else "PASS"))
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failed else 0)
