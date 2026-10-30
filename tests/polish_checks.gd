extends SceneTree

var level: Node2D
var checks: int = 0
var failures: int = 0
var hits: Array[Vector2] = []

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
	level.player.invincible = 1000.0
	await ticks(5)

func press_attack() -> void:
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")

func run() -> void:
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	level.audio.toggle()
	for enemy: Node in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	await place(Vector2(570, 478))
	check(level.player.is_on_floor(), "Player stands on a one-way ledge")
	Input.action_press("move_down")
	Input.action_press("jump")
	await ticks(2)
	Input.action_release("jump")
	Input.action_release("move_down")
	await ticks(26)
	check(level.player.position.y > 590 and level.player.is_on_floor(), "Down + jump drops through ledge onto ground")
	Input.action_press("move_down")
	Input.action_press("jump")
	await ticks(2)
	Input.action_release("jump")
	Input.action_release("move_down")
	await ticks(20)
	check(level.player.position.y < 603 and level.player.drop_time == 0 and level.player.get_collision_mask_value(3), "Down + jump on solid ground jumps without disabling terrain")
	await place(Vector2(680, 478))
	Input.action_press("move_right")
	var waited: int = 0
	while level.player.is_on_floor() and waited < 30:
		await ticks(1)
		waited += 1
	Input.action_press("jump")
	await ticks(2)
	Input.action_release("jump")
	Input.action_release("move_right")
	check(level.player.jumps == 1 and level.player.velocity.y < 0, "Coyote time preserves first jump just beyond ledge")
	await place(Vector2(300, 598))
	level.player.position.y = 562
	level.player.velocity.y = 550
	level.player.jumps = 2
	level.player.coyote = 0
	Input.action_press("jump")
	await ticks(8)
	check(level.player.jumps == 1 and level.player.velocity.y < -400, "Jump pressed just before landing is buffered")
	Input.action_release("jump")
	await place(Vector2(300, 598))
	level.player.invincible = 0
	level.player.take_damage(Vector2(400, 600))
	Input.action_press("move_right")
	await ticks(5)
	check(level.player.velocity.x < -250, "Knockback persists against opposite movement input")
	check(level.player.animation.animation == "Hurt", "Damage plays supplied hurt animation")
	Input.action_release("move_right")
	await place(Vector2(300, 598))
	level.player.attacked.connect(func(origin: Vector2, _facing: float) -> void: hits.append(origin))
	await press_attack()
	await ticks(11)
	await press_attack()
	await ticks(12)
	check(level.player.combo_step == 1 and level.player.attack_time > 0, "Late attack input buffers the second combo strike")
	while level.player.attack_time > 0.16:
		await ticks(1)
	await press_attack()
	await ticks(25)
	check(level.player.combo_step == 2, "Third buffered strike uses Attack3")
	check(hits.size() == 3, "Combo emits exactly one hit per strike")
	await place(Vector2(300, 598))
	var enemy: Node2D = get_nodes_in_group("enemies")[0]
	enemy.position = Vector2(260, 600)
	enemy.home = enemy.position
	check(not enemy.strike(Vector2(350, 565), 1), "Melee cannot hit an enemy behind the attacker")
	enemy.position = Vector2(360, 600)
	enemy.home = enemy.position
	check(enemy.strike(Vector2(350, 565), 1), "Melee hits an enemy in front")
	enemy.hit_timer = 0
	enemy.hit_pause = 0
	enemy.knocked = 0
	enemy.state = 0
	enemy.state_time = 0
	enemy.alert_cooldown = 0
	enemy.position = Vector2(900, 600)
	enemy.home = enemy.position
	await place(Vector2(1080, 598))
	enemy.set_physics_process(true)
	await ticks(2)
	check(enemy.state == 1, "Nearby pumpkin telegraphs its attack before lunging")
	var warning_position: Vector2 = enemy.position
	await ticks(15)
	check(enemy.state == 1 and enemy.position.distance_to(warning_position) < 1, "Windup gives a stationary reaction window")
	await ticks(17)
	check(enemy.state == 2 and enemy.position.x > warning_position.x, "Lunge follows the visible windup")
	enemy.set_physics_process(false)
	enemy.hit_timer = 0
	enemy.strike(enemy.position + Vector2(0, -30))
	check(enemy.dead and not enemy.is_in_group("enemies") and is_instance_valid(enemy), "Defeated enemy stops combat while death animation plays")
	enemy.set_physics_process(true)
	await ticks(43)
	check(not is_instance_valid(enemy), "Death animation cleans up its enemy node")
	await place(Vector2(1650, 680))
	check(level.deaths == 1 and level.player.position.x < 200, "Cursed water returns player promptly to checkpoint")
	await place(Vector2(570, 478))
	var coin: Dictionary = level.items[4]
	coin["taken"] = false
	coin["visual"].show()
	coin["visual"].position = coin["position"]
	level.player.position = Vector2(coin["position"].x + 70, 478)
	await ticks(12)
	check(coin["taken"], "Nearby coins magnetize into the player")
	level.coins = 9
	level.player.health = 3
	level.player.position = Vector2(6090, 586)
	level.player.velocity = Vector2.ZERO
	await ticks(3)
	check(level.coins >= 10 and level.player.health == 4, "Ten-coin milestone restores exactly one vitality")
	await ticks(10)
	check(level.player.health == 4, "Coin milestone cannot heal repeatedly without new coins")
	var bat: Node2D
	for candidate: Node2D in get_nodes_in_group("enemies"):
		if candidate.flying:
			bat = candidate
			break
	bat.home = Vector2(800, 420)
	bat.position = bat.home
	bat.alert_cooldown = 0
	await place(Vector2(950, 598))
	bat.set_physics_process(true)
	await ticks(10)
	check(bat.state == 1, "Bat gives a windup before its dive")
	var bat_height: float = bat.position.y
	await ticks(32)
	check(bat.position.y > bat_height + 10 and bat.state == 2, "Bat dive follows its captured target")
	bat.set_physics_process(false)
	level.player.position = Vector2(5600, 600)
	level.update_compass()
	check(level.hud.goal_direction == "← BACK", "Compass points back toward a missed seal")
	check(level.effects.frames.size() == 7, "All supplied dust and impact sheets load")
	await ticks(80)
	check(level.effects.get_child_count() == 0, "Temporary effect sprites clean up after animation")
	print("POLISH RESULT: %d/%d checks passed" % [checks - failures, checks])
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
