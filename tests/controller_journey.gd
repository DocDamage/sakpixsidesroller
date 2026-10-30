extends "res://tests/route_playthrough.gd"

const Pad = preload("res://tests/pad_driver.gd")
const Campaign = preload("res://scripts/campaign_state.gd")
var hub: Node

func confirm() -> void:
	Pad.button(JOY_BUTTON_A, true)
	await ticks(2)
	Pad.button(JOY_BUTTON_A, false)
	await ticks(25)

func expect(value: bool, title: String) -> void:
	print(("PASS: " if value else "FAIL: ") + title)
	if not value:
		failed = true
		push_error(title)

func run() -> void:
	root.size = Vector2i(1280, 720)
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/controller-journey.cfg"
	hub.defaults()
	controller_mode = true
	Input.use_accumulated_input = false
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	for chapter: int in range(1,Campaign.STAGES+1):
		level.player.invincible = 1000
		var route: Array = [[1120, false], [1280, true], [1480, false], [1850, true], [2310, false], [2496, true], [2770, false], [3190, true], [3720, false], [3904, true], [4170, false], [4600, true], [5430, false]] if chapter == 1 else [[1120, false], [1280, true], [1600, false], [1970, true], [2700, false], [2880, true], [3090, false], [3500, true], [4200, false], [4384, true], [4560, false], [4910, true], [5430, false]]
		if chapter >= 3:
			route = level.profile.builder.ROUTE
		for waypoint: Array in route:
			await go(waypoint[0], waypoint[1])
		expect(await preload("res://tests/guardian_driver.gd").fight(self, level, true), "Chapter %d guardian defeated with joypad attack and stick events" % chapter)
		await go(5520)
		await interact()
		await go(6190)
		await interact()
		expect(level.completed and level.seals == 3 and level.key_found and level.deaths == 0, "Chapter %d route, ledges, sparks, ward and exit completed entirely with controller input" % chapter)
		expect(hub.using_pad, "Chapter %d keeps controller prompts active" % chapter)
		if chapter < Campaign.STAGES:
			expect(level.hud.continue_button.has_focus(), "Continue receives focus at chapter %d completion" % chapter)
			Pad.button(JOY_BUTTON_BACK, true)
			await ticks(2)
			Pad.button(JOY_BUTTON_BACK, false)
			await ticks(2)
			Pad.button(JOY_BUTTON_B, true)
			await ticks(2)
			Pad.button(JOY_BUTTON_B, false)
			await ticks(2)
			expect(level.hud.continue_button.has_focus(), "Closing controls restores Continue focus at chapter %d" % chapter)
			await confirm()
			level = current_scene
			expect(level.chapter == chapter + 1 and level.player.jumps == 0, "Controller confirm loads chapter %d without jumping on arrival" % (chapter + 1))
		else:
			expect(level.hud.restart_button.has_focus(), "Replay receives focus at final completion")
			# Navigate to the previous-chapter button using a pad, then activate it.
			Pad.button(JOY_BUTTON_DPAD_DOWN, true)
			await ticks(2)
			Pad.button(JOY_BUTTON_DPAD_DOWN, false)
			await ticks(2)
			expect(level.hud.first_button.has_focus(), "D-pad navigates completion options")
			await confirm()
			level = current_scene
			expect(level.chapter == 1 and not level.completed, "Controller returns to the first chapter from final results")
	Pad.release()
	print("CONTROLLER TWELVE-CHAPTER JOURNEY: " + ("FAIL" if failed else "PASS"))
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failed else 0)
