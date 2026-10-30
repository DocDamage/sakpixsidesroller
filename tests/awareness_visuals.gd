extends "res://tests/controller_visuals.gd"

const Enemy = preload("res://scripts/haunt.gd")
const Animator = preload("res://scripts/enemy_animation.gd")

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/awareness-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	level = load("res://scenes/emberwick_market.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(20)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.hide()
	level.player.respawn(Vector2(800,600))
	level.player.set_physics_process(false)
	level.hud.intro_time = 0
	level.hud.region_time = 0
	level.hud.notice_time = 0
	var guard := Enemy.new()
	guard.species = "guard"
	guard.position = Vector2(1100,600)
	level.add_child(guard)
	guard.set_physics_process(false)
	guard.patrol = 0
	guard.alert_cooldown = 0
	level.combat.connect_enemy(guard,true)
	guard._physics_process(0.06)
	await capture("awareness_notice")
	level.player.position.x = 600
	guard._physics_process(0.25)
	await capture("awareness_memory")
	await ticks(16)
	level.player.position.x = 900
	guard._physics_process(0.14)
	guard.state_time = 0.45
	Animator.update(guard)
	guard.queue_redraw()
	await capture("awareness_warning")
	guard._physics_process(0.3)
	guard._physics_process(0.12)
	await capture("awareness_release")
	guard.hit_timer = 0
	guard.strike(guard.position+Vector2(0,-30),0,1,0)
	await capture("awareness_light_impact")
	await ticks(15)
	guard.hit_timer = 0
	guard.strike(guard.position+Vector2(0,-30),0,2,0)
	Animator.update(guard)
	await capture("awareness_defeat")
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("AWARENESS VISUALS: CAPTURED NOTICE, MEMORY, WARNING, RELEASE, IMPACT AND DEFEAT")
	quit()
