extends SceneTree

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
	level.player.respawn(at)
	level.player.invincible = 1000
	await ticks(5)

func capture(name: String) -> void:
	if not screenshots:
		return
	level.hud.intro_time = 0
	level.camera.position.x = clampf(level.player.position.x, 640, 5760)
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func interact(pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = "interact"
	event.pressed = pressed
	Input.parse_input_event(event)
	await ticks(2)

func run() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var mimics: Array[Node2D] = []
	for enemy: Node2D in get_nodes_in_group("enemies"):
		if enemy.species == "mimic":
			mimics.append(enemy)
	check(mimics.size() == 2, "Two optional mimics occupy the elevated routes")
	var mimic: Node2D = mimics[0]
	await place(Vector2(930, 598))
	mimic.alert_cooldown = 0
	mimic.set_physics_process(true)
	await ticks(12)
	check(not mimic.awakened and mimic.state == 0, "Mimic ignores the player walking below its platform")
	await place(Vector2(865, 398))
	await ticks(2)
	check(mimic.awakened and mimic.state == 1, "Mimic reveals itself when approached on its ledge")
	await ticks(28)
	check(mimic.state == 1, "Mimic gives a long visible windup before lunging")
	await capture("refined_mimic")
	await ticks(19)
	check(mimic.state == 2, "Mimic lunge follows its warning")
	await ticks(100)
	check(mimic.position.x >= 860 and mimic.position.x <= 1000, "Mimic movement remains within its supported ledge")
	mimic.set_physics_process(false)
	mimic.hit_timer = 0
	mimic.hit_pause = 0
	mimic.strike(mimic.position + Vector2(0, -30), 0, 4)
	check(level.combat.relics == 1 and level.combat.kills == 1, "Defeating a mimic grants one optional relic and kill")
	check(get_nodes_in_group("healing_vials").size() == 1, "Mimic reward includes a healing pickup")
	mimic.strike(mimic.position + Vector2(0, -30), 0, 4)
	check(level.combat.relics == 1, "A defeated mimic cannot grant its relic twice")
	mimic.set_physics_process(true)
	level.respawn()
	await ticks(2)
	check(level.combat.relics == 1, "Relics survive a checkpoint return")
	var remaining: Node2D = mimics[1]
	remaining.awakened = true
	remaining.health = 1
	level.combat.reset_after_fall()
	check(not remaining.awakened and remaining.health == 4, "Surviving mimic resets to a closed chest and full health")
	var first: Node2D = get_nodes_in_group("enemies")[0]
	var second: Node2D = get_nodes_in_group("enemies")[1]
	var old_home: Vector2 = second.position
	first.state = 1
	second.position = first.position + Vector2(100, 0)
	check(not level.combat.may_attack(second), "A nearby windup prevents a simultaneous attack")
	first.state = 3
	check(level.combat.may_attack(second), "A recovery window permits the next enemy attack")
	first.state = 1
	second.position = first.position + Vector2(800, 0)
	check(level.combat.may_attack(second), "Distant encounters do not block each other's attacks")
	first.state = 0
	second.position = old_home
	await place(Vector2(300, 598))
	level.player.hit_pause = 0.07
	Input.action_press("move_left")
	Input.action_press("dash")
	await ticks(2)
	Input.action_release("dash")
	Input.action_release("move_left")
	check(level.player.dash_buffer > 0, "Dash tap is retained during hit pause")
	await ticks(5)
	check(level.player.dash_time > 0 and level.player.velocity.x < -700, "Buffered dash retains its requested direction after releasing keys")
	await place(Vector2(300, 598))
	level.player.dash_cooldown = 0.09
	Input.action_press("dash")
	await ticks(2)
	Input.action_release("dash")
	await ticks(5)
	check(level.player.dash_time > 0, "Dash tap just before recharge is buffered")
	await place(Vector2(300, 598))
	level.player.facing = 1
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	Input.action_press("move_left")
	Input.action_press("dash")
	await ticks(2)
	Input.action_release("move_left")
	Input.action_release("dash")
	check(level.player.velocity.x < -700 and level.player.attack_time == 0, "Directional dash cancels an attack toward the held direction")
	await place(Vector2(255, 598))
	level.player.facing = 1
	level.hud.notice_time = 0
	check(level.world_details.nearest == 0, "Cartographer offers interaction when approached")
	await interact(true)
	await interact(false)
	check(level.hud.notice.contains("Cartographer:"), "E delivers the cartographer's route advice")
	check(not level.player.locked and not paused, "NPC conversation preserves movement and world time")
	await capture("refined_camp")
	await place(Vector2(6200, 598))
	check(level.world_details.nearest == -1 and level.hud.talk_prompt.is_empty(), "NPC prompt clears when leaving its range")
	var fire: Sprite2D = level.world_details.fires[0]
	var frame: Color = fire.self_modulate
	await ticks(10)
	check(fire.self_modulate != frame and not fire.region_enabled,"Upright supplied campfire flickers without top-down frame cropping")
	if screenshots:
		await place(Vector2(5140, 598))
		level.player.facing = -1
		await interact(true)
		await interact(false)
		await capture("refined_ritual_camp")
	level.completed = true
	await ticks(10)
	check(level.sky.dawn_blend > 0, "Completion begins a visible transition toward dawn")
	if not level.audio.muted:
		level.audio.toggle()
	level.restart()
	await ticks(20)
	level = current_scene
	check(level.audio.muted and level.audio.music.volume_db < -70 and level.hud.muted, "Mute preference and HUD label survive a level restart")
	check(level.combat.relics == 0 and get_nodes_in_group("enemies").size() == 13, "Restart restores optional relics and all encounters")
	print("REFINEMENT RESULT: %d/%d checks passed" % [checks - failures, checks])
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
