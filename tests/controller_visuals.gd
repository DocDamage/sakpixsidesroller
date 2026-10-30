extends SceneTree

var level: Node2D
var hub: Node

func _initialize() -> void:
	root.call_deferred("add_child", preload("res://tests/snapshot_input_blocker.gd").new())
	call_deferred("run")

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame

func capture(name: String) -> void:
	await ticks(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/controller-visual.cfg"
	hub.defaults()
	level = load("res://scenes/lantern_road.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await ticks(25)
	for enemy: Node2D in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	level.hud.intro_time = 0
	level.hud.region_time = 0
	hub.using_pad = true
	for entry: Array in [[3000.0, "controller_fields"], [4400.0, "controller_road"], [6100.0, "controller_village"]]:
		level.player.respawn(Vector2(entry[0], 598))
		hub.flush_gameplay()
		level.player.invincible = 0
		level.camera.position.x = clampf(entry[0], 640, 5760)
		level.camera.reset_smoothing()
		level.camera.force_update_scroll()
		await ticks(20)
		level.player.animation.modulate.a = 1
		level.hud.region_time = 0
		await capture(entry[1])
	hub.label_style = "PlayStation"
	await capture("controller_playstation_prompts")
	level.toggle_pause()
	await capture("controller_pause")
	hub.open_panel()
	await capture("controller_settings")
	hub.close_panel()
	paused = false
	level.queue_free()
	await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("CONTROLLER VISUALS: CAPTURED")
	quit()
