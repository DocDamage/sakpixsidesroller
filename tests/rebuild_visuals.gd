extends "res://tests/controller_visuals.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Motion = preload("res://scripts/hero_motion.gd")

func look(at: Vector2, name: String) -> void:
	if absf(at.y-600) < 2:
		for offset: float in [0.0,-144.0,144.0,-288.0,288.0]:
			var candidate: Vector2 = at+Vector2(offset,0)
			var supported: bool = false
			for span: Vector2 in level.profile.builder.FLOORS:
				supported = supported or (candidate.x > span.x+30 and candidate.x < span.y-30)
			if level.district != null:
				for floor: Rect2 in level.profile.builder.LEDGES:
					supported = supported or (absf(floor.position.y-candidate.y) < 2 and candidate.x > floor.position.x+30 and candidate.x < floor.end.x-30)
			var clear: bool = supported
			for enemy: Node2D in get_nodes_in_group("enemies"):
				clear = clear and (enemy.flying or absf(enemy.home.x-candidate.x) > 120)
			for hazard: Rect2 in level.hazards:
				clear = clear and not hazard.grow(48).has_point(candidate-Vector2(0,10))
			if clear:
				at = candidate
				break
	else:
		at.x -= 96
	level.player.respawn(at)
	level.player.invincible = 0
	level.player.update_animation()
	preload("res://scripts/level_backdrop.gd").update(level)
	level.camera.reset_smoothing()
	level.camera.force_update_scroll()
	await ticks(4)
	level.hud.intro_time = 0
	level.hud.region_time = 0
	level.hud.notice_time = 0
	await capture(name)

func run() -> void:
	root.size = Vector2i(1280,720)
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/rebuild-visual-controller.cfg"
	hub.defaults()
	hub.using_pad = true
	for stage: int in range(1,13):
		var requested: int = 0
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--stage="):
				requested = int(argument.trim_prefix("--stage="))
		if requested > 0 and requested != stage:
			continue
		level = load(Campaign.SCENES[stage-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.player.set_physics_process(false)
		await look(Vector2(640,600),"rebuilt_%d_start" % stage)
		await look(Vector2(level.world_details.fires[1].position.x+100,600),"rebuilt_%d_camp" % stage)
		await look(Vector2(2890 if level.district != null else 2400,600),"rebuilt_%d_middle_a" % stage)
		await look(Vector2(5340 if level.district != null else 3800,600),"rebuilt_%d_middle_b" % stage)
		for i: int in 2:
			var at: Vector2 = [Vector2(5900,-700),Vector2(8280,1460)][i] if level.district != null else level.extension.rooms[i].peak
			await look(at,"rebuilt_%d_vertical_%d" % [stage,i])
		await look(Vector2(7340,1100) if level.district != null else Vector2(8192,600),"rebuilt_%d_rest" % stage)
		await look(Vector2(17300 if level.district != null else 11500,600),"rebuilt_%d_handoff" % stage)
		await look(Vector2(18700 if level.district != null else 12160,600),"rebuilt_%d_exit" % stage)
		if stage == 1:
			await look(Vector2(700,600),"sword_idle")
			level.set_physics_process(false)
			for combo: int in 3:
				level.player.combo_step = combo
				level.player.attack_mode = "ground"
				var clip: String = level.player.attack_clip()
				var elapsed: float = 0
				for frame: int in Motion.TIMES[clip].size():
					level.player.attack_time = Motion.duration(clip)-elapsed-0.001
					level.player.update_animation()
					await capture("sword_%d_%02d" % [combo,frame])
					elapsed += Motion.TIMES[clip][frame]
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("REBUILD VISUALS: CAPTURED REQUESTED STAGES, CAMPS, MIDDLE SECTIONS, HANDOFFS, VERTICAL ROOMS AND SWORD FRAMES")
	quit()
