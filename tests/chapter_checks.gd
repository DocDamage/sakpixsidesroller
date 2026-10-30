extends SceneTree

const Campaign = preload("res://scripts/campaign_state.gd")
var level: Node2D
var checks: int = 0
var failures: int = 0
var screenshots: bool = false

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame

func check(value: bool, title: String) -> void:
	checks += 1
	if value:
		print("PASS: " + title)
	else:
		failures += 1
		push_error("FAIL: " + title)

func place(at: Vector2) -> void:
	level.player.position = at
	level.player.velocity = Vector2.ZERO
	level.player.invincible = 1000
	await ticks(6)

func interact() -> void:
	Input.action_press("interact")
	await ticks(2)
	Input.action_release("interact")
	await ticks(2)

func capture(name: String) -> void:
	if not screenshots:
		return
	level.camera.position.x = clampf(level.player.position.x, 640, 5760)
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	level.player.animation.modulate.a = 1
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func run() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	Campaign.results.clear()
	Campaign.unlocked_chapter = 1
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	Campaign.next(level)
	await ticks(2)
	check(current_scene == level and level.chapter == 1, "Level two cannot be entered through an unfinished level-one result")
	for item: Dictionary in level.items:
		if item["kind"] == "seal":
			await place(item["position"] + Vector2(0, 34))
	await place(Vector2(5430, 598))
	check(await preload("res://tests/guardian_driver.gd").fight(self, level), "Level-one guardian falls through combat inputs before continuation")
	await place(Vector2(5520, 598))
	await interact()
	await place(Vector2(6190, 598))
	await interact()
	check(level.completed and Campaign.unlocked_chapter == 2, "Finishing Halloween Town unlocks chapter two")
	check(Campaign.results.has(1) and Campaign.results[1]["coins"] == level.coins, "Completed chapter keeps its own coin and combat results")
	check(level.hud.continue_button.visible and level.hud.continue_button.has_focus(), "Completion offers a keyboard-focused Continue to Level 2 button")
	await capture("chapter_one_continue")
	var old_level: WeakRef = weakref(level)
	level.hud.continue_button.pressed.emit()
	await ticks(25)
	level = current_scene
	check(level.chapter == 2 and level.profile.title == "THE LANTERN ROAD", "Continue button loads the second scene and its chapter profile")
	check(old_level.get_ref() == null, "Chapter transition frees the previous world")
	check(level.player.health == 5 and level.coins == 0 and level.seals == 0, "New chapter starts with restored vitality and fresh local objectives")
	check(Campaign.results.has(1), "Entering chapter two preserves chapter-one results")
	check(level.items.size() == 37 and get_nodes_in_group("enemies").size() == 13, "Lantern Road has three sparks, 34 coins and a full encounter roster")
	check(level.audio.village_music != null and level.audio.village_music.playing, "Local village soundtrack loads for the gradual music transition")
	await capture("level_two_start")
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var rats: Array[Node2D] = []
	for enemy: Node2D in get_nodes_in_group("enemies"):
		if enemy.species == "rat":
			rats.append(enemy)
	check(rats.size() == 2, "Village approach introduces two animated rat enemies")
	level.hud.intro_time = 0
	await place(Vector2(3000, 598))
	var middle_light: float = level.sky.road_blend
	await ticks(25)
	await capture("level_two_fields")
	await place(Vector2(4400, 598))
	await ticks(25)
	await capture("level_two_road")
	check(level.sky.road_blend > middle_light and level.atmosphere.warmth > 0.6, "Sky and airborne motes grow warmer along the village road")
	await place(Vector2(6100, 598))
	await ticks(25)
	check(level.audio.village_music.volume_db > level.audio.music.volume_db + 20, "Village music gradually replaces the haunted exploration track")
	await capture("level_two_village")
	level.audio.toggle()
	await ticks(2)
	check(level.audio.music.volume_db < -70 and level.audio.village_music.volume_db < -70, "Mute silences both sides of the music crossfade")
	level.audio.toggle()
	await place(Vector2(3700, 598))
	check(level.checkpoint_index == 1, "Second level activates its own relocated checkpoint")
	await place(Vector2(3300, 680))
	check(level.deaths == 1 and absf(level.player.position.x - 3700) < 2, "Second-level stream returns player to its active checkpoint")
	var rat: Node2D = rats[0]
	rat.reset_encounter()
	rat.alert_cooldown = 0
	await place(Vector2(4300, 598))
	rat.set_physics_process(true)
	await ticks(10)
	check(rat.state == 1, "Rat gives a visible windup before a fast ground attack")
	await ticks(32)
	check(rat.state == 1, "Rat's warning lasts long enough to react")
	await ticks(8)
	check(rat.state == 2 and rat.position.x > rat.home.x, "Rat scurries toward its captured attack direction")
	rat.set_physics_process(false)
	for item: Dictionary in level.items:
		if item["kind"] == "seal":
			await place(item["position"] + Vector2(0, 34))
	check(level.seals == 3, "All three second-level hearth sparks can be collected")
	await place(Vector2(5520, 598))
	await interact()
	check(not level.key_found, "Village ward remains closed until its guardian is defeated")
	level.combat.guardian.set_physics_process(true)
	check(await preload("res://tests/guardian_driver.gd").fight(self, level), "Thorn Marshal can be defeated with the shared combat controls")
	await place(Vector2(5520, 598))
	await interact()
	check(level.key_found, "Three sparks and guardian defeat allow opening the village ward")
	await place(Vector2(6190, 598))
	await interact()
	check(level.completed and Campaign.results.has(2), "Entering Emberwick completes and records chapter two")
	var total: Dictionary = Campaign.totals()
	check(total["coins"] == Campaign.results[1]["coins"] + level.coins, "Journey results include both chapters without discarding chapter-one progress")
	check(level.hud.continue_button.visible and not level.hud.first_button.visible and level.hud.continue_button.text.contains("3"), "Chapter-two completion now offers continuation into Emberwick Market")
	await capture("chapter_two_complete")
	level.restart()
	await ticks(25)
	level = current_scene
	check(level.chapter == 2 and level.seals == 0 and not level.completed, "Restart replays chapter two rather than returning to chapter one")
	check(Campaign.results.has(1), "Replaying chapter two retains previous chapter results")
	print("CHAPTER RESULT: %d/%d checks passed" % [checks - failures, checks])
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
