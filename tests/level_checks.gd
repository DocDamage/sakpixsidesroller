extends SceneTree

var level: Node2D
var failures: int = 0
var checks: int = 0
var screenshots: bool = false

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame

func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func interact() -> void:
	Input.action_press("interact")
	await ticks(2)
	Input.action_release("interact")
	await ticks(2)

func capture(filename: String) -> void:
	if screenshots:
		level.player.animation.modulate.a = 1.0
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/" + filename + ".png")

func run() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	check(level.player.is_on_floor(), "Player spawns on solid ground")
	check(level.items.size() == 37, "Three seals and 34 optional bat coins exist")
	check(get_nodes_in_group("enemies").size() == 13, "Thirteen enemies include pumpkins, bats, mushroom, eye, spitters, mimics and the Gravekeeper")
	check(level.audio.music.playing, "Local soundtrack loads and plays")
	await capture("level_start")
	var start: float = level.player.position.x
	Input.action_press("move_right")
	await ticks(20)
	Input.action_release("move_right")
	check(level.player.position.x > start + 70, "Horizontal movement uses physics")
	Input.action_press("jump")
	await ticks(16)
	check(level.player.position.y < 500, "First jump lifts player off ground")
	Input.action_release("jump")
	await ticks(3)
	Input.action_press("jump")
	await ticks(4)
	check(level.player.jumps == 2 and level.player.velocity.y < 0, "Second jump resets upward velocity")
	Input.action_release("jump")
	Input.action_press("dash")
	await ticks(3)
	check(level.player.dash_cooldown > 0.0 and absf(level.player.velocity.x) > 700, "Dash applies speed and cooldown")
	Input.action_release("dash")
	await ticks(65)
	level.player.position = Vector2(5520, 600)
	level.player.velocity = Vector2.ZERO
	await ticks(3)
	await interact()
	check(not level.key_found, "Chest refuses opening before all seals are collected")
	level.player.position = Vector2(6190, 600)
	await ticks(3)
	await interact()
	check(not level.completed, "Portal refuses completion without Moon Key")
	# Exercise each mandatory jump from the ground, using the actual player controller.
	for index: int in range(3):
		var item: Dictionary = level.items[index]
		var target: Vector2 = item["position"]
		level.player.position = Vector2(target.x, 598)
		level.player.velocity = Vector2.ZERO
		level.player.invincible = 5.0
		await ticks(4)
		Input.action_press("jump")
		await ticks(24)
		Input.action_release("jump")
		await ticks(2)
		Input.action_press("jump")
		await ticks(24)
		Input.action_release("jump")
		await ticks(35)
		check(item["taken"], "Seal %d is reachable with double jump from ground" % (index + 1))
	check(level.seals == 3, "All three seals count exactly once")
	var enemy: Node2D = get_nodes_in_group("enemies")[0]
	var enemy_start_health: int = enemy.health
	level.player.position = enemy.position + Vector2(-65, 0)
	level.player.velocity = Vector2.ZERO
	level.player.facing = 1.0
	Input.action_press("attack")
	await ticks(10)
	Input.action_release("attack")
	check(enemy.health == enemy_start_health - 1, "Attack input and timed melee hit damage enemy")
	await ticks(24)
	Input.action_press("attack")
	await ticks(12)
	Input.action_release("attack")
	await ticks(2)
	check(get_nodes_in_group("enemies").size() == 12, "Second hit defeats pumpkin")
	level.player.invincible = 0.0
	level.player.take_damage(level.player.position + Vector2(-50, 0))
	check(level.player.health == 4, "Enemy or hazard contact removes one health")
	level.player.take_damage(level.player.position)
	check(level.player.health == 4, "Damage invulnerability prevents repeated contact hits")
	level.player.health = 5
	level.player.invincible = 0.0
	level.player.position = Vector2(790, 600)
	level.player.velocity = Vector2.ZERO
	await ticks(2)
	check(level.player.health == 4, "Standing on spike geometry applies contact damage")
	level.player.position = Vector2(3650, 598)
	level.player.velocity = Vector2.ZERO
	await ticks(5)
	check(level.checkpoint_index == 1 and level.player.health == 5, "Lantern checkpoint activates and heals")
	await ticks(40)
	await capture("level_swamp")
	level.player.position.y = 960
	await ticks(3)
	check(level.deaths == 1 and absf(level.player.position.x - 3650) < 2, "Falling returns player to the active checkpoint")
	check(level.seals == 3, "Respawn preserves collected seals")
	var frozen_time: float = level.elapsed
	level.toggle_pause()
	await ticks(5)
	check(paused and is_equal_approx(level.elapsed, frozen_time), "Pause freezes world and level timer")
	await capture("level_paused")
	level.toggle_pause()
	level.audio.toggle()
	check(level.audio.muted, "Mute silences music and sound effects")
	level.audio.toggle()
	level.player.position = Vector2(5520, 600)
	level.player.velocity = Vector2.ZERO
	level.player.invincible = 1000
	await ticks(3)
	await interact()
	check(not level.key_found, "Ritual chest remains sealed while the Gravekeeper lives")
	var won_fight: bool = await preload("res://tests/guardian_driver.gd").fight(self, level)
	check(won_fight, "Actual attack inputs defeat the Gravekeeper")
	level.player.position = Vector2(5520, 600)
	level.player.velocity = Vector2.ZERO
	await ticks(40)
	await interact()
	check(level.key_found, "Three seals and the Gravekeeper's defeat unlock the Moon Key")
	await capture("level_ritual")
	level.player.position = Vector2(6190, 600)
	await ticks(40)
	await interact()
	check(level.completed and level.hud.complete and level.player.locked, "Portal triggers completion and locks player control")
	await capture("level_complete")
	if screenshots:
		await ticks(180)
		await capture("level_dawn")
	var finish_time: float = level.elapsed
	await ticks(10)
	check(is_equal_approx(finish_time, level.elapsed), "Completion freezes result time")
	# Reload through the same path used by both restart buttons and the R key.
	level.restart()
	await ticks(20)
	level = current_scene
	check(level.seals == 0 and level.coins == 0 and not level.completed and not paused, "Restart resets objective, score, completion and pause state")
	print("RESULT: %d/%d checks passed" % [checks - failures, checks])
	level.queue_free()
	await ticks(2)
	# Let the audio mix thread release stopped playbacks before a fast test exit.
	OS.delay_msec(120)
	await ticks(6)
	quit(0 if failures == 0 else 1)
