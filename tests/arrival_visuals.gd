extends "res://tests/controller_visuals.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Bolt = preload("res://scripts/cursed_bolt.gd")

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/arrival-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	for chapter: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		level.player.set_physics_process(false)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.player.position = Vector2(180,600)
		level.player.animation.play("Idle")
		level.hud.intro_time = 0
		level.hud.region_time = 0
		level.hud.arrival_time = 0.22
		# Freeze the fade at a representative intermediate frame.
		level.hud.set_process(false)
		level.hud.queue_redraw()
		await capture("arrival_%d_fade" % chapter)
		level.hud.set_process(true)
		level.hud.arrival_time = 0
		var plant: Node2D
		for enemy: Node2D in get_nodes_in_group("enemies"):
			if enemy.species == "plant":
				plant = enemy
				break
		level.player.position = plant.position+Vector2(-150,0)
		level.player.invincible = 1000
		level.camera.position.x = clampf(level.player.position.x,640,5760)
		level.camera.reset_smoothing()
		level.camera.force_update_scroll()
		await ticks(4)
		level.hud.region_time = 0
		level.hud.notice_time = 0
		var returned := Bolt.new()
		returned.position = level.player.position+Vector2(40,-35)
		returned.velocity = Vector2.LEFT*260
		returned.shooter = plant
		level.add_child(returned)
		returned.collided.connect(level.combat.projectile_collided)
		returned.deflect(level.player.position+Vector2(50,-35),1)
		await capture("arrival_%d_return_flight" % chapter)
		await ticks(8)
		await capture("arrival_%d_return_hit" % chapter)
		level.combat.spawn_bolt(plant.position+Vector2(-80,-70),Vector2.DOWN,false,plant)
		await ticks(17)
		await capture("arrival_%d_stone_impact" % chapter)
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("ARRIVAL VISUALS: CAPTURED ARRIVAL FADES, RETURN FLIGHTS/HITS AND STONE IMPACTS IN ALL TWELVE STAGES")
	quit()
