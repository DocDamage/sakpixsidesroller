extends SceneTree

const Bolt = preload("res://scripts/cursed_bolt.gd")
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

func capture(filename: String) -> void:
	if not screenshots:
		return
	level.hud.intro_time = 0
	level.camera.position.x = clampf(level.player.position.x, 640, 5760)
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	level.player.animation.modulate.a = 1
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + filename + ".png")

func run() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 720)
	level = load("res://scenes/halloween_town.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	level.audio.toggle()
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var pumpkin: Node2D = get_nodes_in_group("enemies")[0]
	check(pumpkin.max_health == 2 and level.combat.guardian.max_health == 8, "Basic enemies and guardian have separate health profiles")
	await place(Vector2(950, 510))
	pumpkin.position = Vector2(950, 600)
	Input.action_press("move_down")
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	Input.action_release("move_down")
	check(level.player.attack_mode == "plunge", "Airborne down + attack selects the supplied plunge animation")
	await ticks(12)
	check(pumpkin.dead, "Plunge deals two damage to a basic enemy")
	check(level.player.velocity.y < 0 and level.player.jumps == 1, "Connected plunge rebounds and restores an air jump")
	var boss: Node2D = level.combat.guardian
	boss.position = boss.home
	boss.state = 2
	boss.state_time = 0.1
	boss.hit_timer = 0
	boss.strike(boss.position + Vector2(0, -35), 0, 1)
	check(boss.health == 7 and boss.state == 2, "Guardian takes light damage while retaining charge armor")
	boss.hit_timer = 0
	boss.hit_pause = 0
	boss.strike(boss.position + Vector2(0, -35), 0, 2, 310)
	check(boss.health == 5 and boss.state == 3, "Two-damage combo finisher interrupts guardian charge")
	check(level.combat.combo_hits >= 2, "Connected hits update the combat chain")
	await place(boss.home+Vector2(-170,-2))
	boss.hit_pause = 0
	boss.hit_timer = 0
	boss.knocked = 0
	boss.health = 4
	# Enter naturally so the committed warning captures the enraged duration.
	boss.state = 0
	boss.alert_cooldown = 0
	boss.set_physics_process(true)
	await ticks(2)
	boss.state_time = 0.54
	await ticks(18)
	var waves: Array[Node] = get_nodes_in_group("enemy_projectiles")
	check(waves.size() == 2, "Enraged guardian releases flames in both directions")
	if waves.size() == 2:
		check(waves[0].velocity.x * waves[1].velocity.x < 0, "Ground flames travel away from one another")
		check(not waves[0].deflect(waves[0].position, 1), "Ground flames must be jumped or dashed through")
	await capture("combat_gravekeeper")
	boss.set_physics_process(false)
	level.combat.clear_projectiles()
	await ticks(2)
	var plant: Node2D
	for enemy: Node2D in get_nodes_in_group("enemies"):
		if enemy.species == "plant":
			plant = enemy
			break
	await place(Vector2(2350, 598))
	plant.alert_cooldown = 0
	plant.state = 0
	plant.set_physics_process(true)
	await ticks(30)
	check(get_nodes_in_group("enemy_projectiles").is_empty() and plant.state == 1, "Thorn spitter gives a warning before firing")
	await ticks(24)
	check(not get_nodes_in_group("enemy_projectiles").is_empty(), "Thorn spitter creates a visible projectile")
	await capture("combat_spitter")
	plant.set_physics_process(false)
	level.combat.clear_projectiles()
	await ticks(2)
	await place(Vector2(2300, 598))
	var spore: Node2D = Bolt.new()
	spore.position = Vector2(2375, 565)
	spore.velocity = Vector2(-260, 0)
	spore.shooter = plant
	level.add_child(spore)
	level.player.facing = 1
	Input.action_press("attack")
	await ticks(10)
	Input.action_release("attack")
	check(is_instance_valid(spore) and spore.friendly, "Timed melee attack reflects a spore")
	if is_instance_valid(spore):
		check(spore.velocity.x > 0, "Reflected projectile returns toward the spitter")
	var plant_health: int = plant.health
	await ticks(50)
	check(plant.health == plant_health - 1 and not is_instance_valid(spore), "Returned projectile damages its target once and cleans up")
	await place(Vector2(300, 598))
	level.player.invincible = 0
	var hostile: Node2D = Bolt.new()
	hostile.position = Vector2(320, 565)
	hostile.velocity = Vector2(-200, 0)
	level.add_child(hostile)
	await ticks(2)
	check(level.player.health == 4, "Hostile projectile contact removes one vitality")
	await ticks(3)
	check(level.player.health == 4 and not is_instance_valid(hostile), "Projectile cannot deal repeated contact damage")
	await place(Vector2(300, 598))
	level.player.invincible = 0
	var avoid: Node2D = Bolt.new()
	avoid.position = Vector2(320, 565)
	avoid.velocity = Vector2(-200, 0)
	level.add_child(avoid)
	Input.action_press("dash")
	await ticks(3)
	Input.action_release("dash")
	check(level.player.health == 5, "Dash invulnerability avoids projectile damage")
	var blocked: Node2D = Bolt.new()
	blocked.position = Vector2(300, 590)
	blocked.velocity = Vector2(0, 300)
	level.add_child(blocked)
	await ticks(5)
	check(not is_instance_valid(blocked), "Projectile ray collision stops shots at solid terrain")
	await place(Vector2(590, 598))
	level.player.facing = 1
	Input.action_press("attack")
	await ticks(10)
	Input.action_release("attack")
	var urn: Node2D
	for child: Node in level.get_children():
		if child.get_script() == preload("res://scripts/breakable_urn.gd") and child.position.x == 650:
			urn = child
	check(urn.broken and get_nodes_in_group("healing_vials").size() == 1, "Attack shatters urn and drops one healing vial")
	check(not urn.strike(Vector2(650, 565), 1), "Broken urn cannot drop more vials")
	await ticks(10)
	check(get_nodes_in_group("healing_vials").size() == 1, "Full vitality leaves the vial available")
	level.player.health = 3
	level.player.position = Vector2(650, 600)
	var vial: Node2D = get_nodes_in_group("healing_vials")[0]
	vial._physics_process(1.0 / 60.0)
	vial._physics_process(1.0 / 60.0)
	await ticks(3)
	check(level.player.health == 4 and get_nodes_in_group("healing_vials").is_empty(), "Vial heals exactly once even across repeated physics updates")
	level.player.hit_pause = 0.05
	Input.action_press("attack")
	await ticks(2)
	Input.action_release("attack")
	check(level.player.attack_buffer > 0, "Attack input remains buffered during hit pause")
	level.respawn()
	await ticks(3)
	check(boss.health == 8 and boss.position.distance_to(boss.home) < 1, "Respawn restores a living guardian to its arena and full health")
	check(get_nodes_in_group("enemy_projectiles").is_empty(), "Respawn removes all hostile projectiles")
	print("COMBAT RESULT: %d/%d checks passed" % [checks - failures, checks])
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
