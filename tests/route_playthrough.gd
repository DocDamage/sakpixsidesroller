extends SceneTree

var level: Node2D
var failed: bool = false
var controller_mode: bool = false

func press(action: String) -> void:
	if controller_mode:
		preload("res://tests/pad_driver.gd").button({"jump": JOY_BUTTON_A, "move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT, "interact": JOY_BUTTON_Y}[action], true)
	else:
		Input.action_press(action)

func release(action: String) -> void:
	if controller_mode:
		preload("res://tests/pad_driver.gd").button({"jump": JOY_BUTTON_A, "move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT, "interact": JOY_BUTTON_Y}[action], false)
	else:
		Input.action_release(action)

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame

func go(target: float, jumping: bool = false) -> void:
	var start_deaths: int = level.deaths
	var count: int = 0
	var direction: float = 1.0 if target >= level.player.position.x else -1.0
	if jumping:
		press("jump")
	press("move_right" if direction > 0 else "move_left")
	while (target - level.player.position.x) * direction > 0 and count < 800:
		await ticks(1)
		count += 1
		if jumping and count == 22:
			release("jump")
		if jumping and count == 24:
			press("jump")
		if jumping and count == 50:
			release("jump")
	release("move_right")
	release("move_left")
	# Finish the second jump even when horizontal travel ended first.
	if jumping and count < 24:
		release("jump")
		await ticks(2)
		press("jump")
		await ticks(24)
	release("jump")
	await ticks(75)
	if count >= 800 or level.deaths > start_deaths:
		failed = true
		push_error("Route failed reaching x=%d, current=%s, deaths=%d" % [target, level.player.position, level.deaths])
	print("ROUTE x=%d at=%s seals=%d" % [target, level.player.position, level.seals])

func interact() -> void:
	press("interact")
	await ticks(2)
	release("interact")
	await ticks(2)

func run() -> void:
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	level.audio.toggle()
	# Contact damage is disabled here to isolate route geometry and jump reachability.
	level.player.invincible = 1000.0
	await go(1120)
	await go(1280, true)
	await go(1480)
	await go(1850, true)
	await go(2310)
	await go(2496, true)
	await go(2770)
	await go(3190, true)
	await go(3720)
	await go(3904, true)
	await go(4170)
	await go(4600, true)
	await go(5430)
	if not await preload("res://tests/guardian_driver.gd").fight(self, level):
		failed = true
		push_error("Guardian encounter did not complete through attack inputs")
	await go(5520)
	await interact()
	await go(6190)
	await interact()
	if not level.completed or level.seals != 3:
		failed = true
		push_error("Continuous playthrough did not complete. Seals=%d key=%s" % [level.seals, level.key_found])
	print("CONTINUOUS PLAYTHROUGH: " + ("FAIL" if failed else "PASS"))
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failed else 0)
