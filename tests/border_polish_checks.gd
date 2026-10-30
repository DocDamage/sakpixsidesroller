extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Blend = preload("res://scripts/stage_blend.gd")
const Footing = preload("res://scripts/enemy_footing.gd")
const Audio = preload("res://scripts/level_audio.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/border-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	for chapter: int in range(1,Campaign.STAGES):
		var exit: Array[Color] = Blend.sky(chapter,6400)
		var entrance: Array[Color] = Blend.sky(chapter+1,0)
		check(exit[0].is_equal_approx(entrance[0]) and exit[1].is_equal_approx(entrance[1]),"Boundary %d/%d shares its sky palette at the handoff" % [chapter,chapter+1])
		var gradual: bool = true
		for x: int in range(4928,6401,64):
			var before: Array[Color] = Blend.sky(chapter,x-64)
			var after: Array[Color] = Blend.sky(chapter,x)
			for i: int in 2:
				gradual = gradual and Vector3(before[i].r,before[i].g,before[i].b).distance_to(Vector3(after[i].r,after[i].g,after[i].b)) < 0.06
		check(gradual,"Boundary %d/%d changes gradually across the last region" % [chapter,chapter+1])
	var expected_handoff: Dictionary = {}
	for chapter: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		if not expected_handoff.is_empty():
			check(level.audio.music.get_meta("song_path") == expected_handoff.path and level.audio.music.get_playback_position() > 22,"Stage %d continues the destination song at its previous playback position" % chapter)
			expected_handoff.clear()
		var overlays_valid: bool = true
		var sides: Dictionary = {}
		for tile: Sprite2D in get_nodes_in_group("transition_ground"):
			var supported: bool = false
			for span: Vector2 in level.profile.builder.FLOORS:
				supported = supported or (tile.position.x-32 >= span.x and tile.position.x+32 <= span.y)
			overlays_valid = overlays_valid and supported and tile.modulate.a > 0 and tile.modulate.a <= 0.5
			sides[tile.get_meta("neighbour")] = true
		check(overlays_valid and sides.size() == (1 if chapter in [1,Campaign.STAGES] else 2),"Stage %d blends supplied neighbour terrain on solid land at the appropriate entrances/exits" % chapter)
		var grounded: bool = true
		for enemy: Node2D in get_nodes_in_group("enemies"):
			if not enemy.flying:
				grounded = grounded and is_finite(enemy.support_limits.x) and is_finite(enemy.support_limits.y) and enemy.travel_limits.x >= enemy.support_limits.x and enemy.travel_limits.y <= enemy.support_limits.y
		check(grounded,"Stage %d every ground enemy and mimic is constrained to its actual supporting surface" % chapter)
		var bank: Vector2 = level.profile.builder.FLOORS[0]
		var sample: Node2D = Enemy.new()
		sample.species = "mushroom"
		sample.position = Vector2(bank.y-38,600)
		level.add_child(sample)
		sample.set_physics_process(false)
		Footing.configure(sample,level)
		sample.state = 2
		sample.attack_direction = 1
		sample.knocked = 1000
		level.player.position = Vector2(bank.y-200,600)
		level.player.invincible = 1000
		sample._physics_process(0.15)
		check(sample.position.x <= bank.y-24 and sample.position.y == 600,"Stage %d a charging enemy cannot roll or be knocked beyond a water bank" % chapter)
		sample.queue_free()
		var guardian: Node2D = level.combat.guardian
		guardian.reset_encounter()
		guardian.state = 1
		guardian.state_time = 0.2
		guardian.strike(guardian.position+Vector2(0,-30),0,2,0)
		check(guardian.guard_broken and guardian.state == 3 and is_equal_approx(guardian.recovery_duration(),1.15),"Stage %d a finisher opens a longer, explicit guardian punish window" % chapter)
		guardian.hit_pause = 0
		guardian.hit_timer = 0
		guardian.state_time = 0.7
		guardian.strike(guardian.position+Vector2(0,-30),0,1,0)
		check(is_equal_approx(guardian.state_time,0.7),"Stage %d follow-up attacks cannot reset the guardian recovery clock forever" % chapter)
		level.player.position = guardian.home+Vector2(-200,0)
		level.combat._physics_process(0)
		check(level.hud.boss_staggered,"Stage %d guardian UI calls out the guard-break opening" % chapter)
		guardian.hit_pause = 0
		guardian._physics_process(0.5)
		check(guardian.state == 0 and not guardian.guard_broken,"Stage %d guardian visibly recovers after the advertised opening" % chapter)
		guardian.reset_encounter()
		Pad.release()
		level.player.respawn(Vector2(450,598))
		await ticks(8)
		level.player.hit_pause = 0.12
		Pad.axis(JOY_AXIS_LEFT_X,1)
		Pad.button(JOY_BUTTON_B,true)
		await ticks(2)
		Pad.button(JOY_BUTTON_B,false)
		Pad.axis(JOY_AXIS_LEFT_X,-1)
		await ticks(8)
		check(level.player.dash_time > 0 and level.player.facing > 0 and level.player.velocity.x > 700,"Stage %d buffered pad dodge keeps its pressed direction through a later stick reversal" % chapter)
		Pad.release()
		level.player.respawn(Vector2(450,598))
		await ticks(8)
		level.player.facing = -1
		level.player.hit_pause = 0.12
		Pad.axis(JOY_AXIS_TRIGGER_RIGHT,1)
		await ticks(2)
		Pad.axis(JOY_AXIS_TRIGGER_RIGHT,0)
		Pad.axis(JOY_AXIS_LEFT_X,1)
		await ticks(8)
		check(level.player.dash_time > 0 and level.player.facing < 0 and level.player.velocity.x < -700,"Stage %d neutral trigger dodge captures facing before the stick changes" % chapter)
		Pad.release()
		await tap(JOY_BUTTON_START)
		check(level.player.buffered_dash_direction == 0 and level.player.dash_buffer == 0,"Stage %d opening menus clears queued dodge direction" % chapter)
		await tap(JOY_BUTTON_B)
		for style: String in ["Xbox","PlayStation","Nintendo"]:
			hub.label_style = style
			check(hub.alternate_dodge_label() == {"Xbox":"RB / RT","PlayStation":"R1 / R2","Nintendo":"R / ZR"}[style] and hub.special_footer().contains(hub.alternate_dodge_label()),"Stage %d %s footer shows the real alternate dodge controls" % [chapter,style])
		hub.rebind("jump",JOY_BUTTON_RIGHT_SHOULDER)
		check(hub.alternate_dodge_label() == "ZR","Stage %d remapped shoulder is removed from alternate dodge guidance" % chapter)
		hub.rebind("dash",JOY_BUTTON_LEFT_SHOULDER)
		check(hub.alternate_dodge_label().is_empty(),"Stage %d custom dodge binding removes unavailable trigger guidance" % chapter)
		hub.defaults()
		if chapter >= 6:
			var breeze: ShaderMaterial = level.get_node("WorldMotion").breeze
			var before_wind: float = float(breeze.get_shader_parameter("clock"))
			await ticks(3)
			var running_wind: float = float(breeze.get_shader_parameter("clock"))
			paused = true
			await ticks(3)
			check(running_wind > before_wind and is_equal_approx(float(breeze.get_shader_parameter("clock")),running_wind),"Stage %d woodland branch motion advances in play and freezes in controller menus" % chapter)
			paused = false
		if chapter >= 5 and chapter < Campaign.STAGES:
			level.player.position.x = 6300
			level.audio.village_music.play(23)
			level.audio._process(0)
			var title: String = level.audio.now_playing()
			level.audio.toggle()
			level.audio._process(0)
			check(level.audio.music_blend > 0.99 and level.audio.now_playing() == title,"Stage %d destination music and its title remain selected while muted" % chapter)
			level.audio.prepare_handoff(chapter+1)
			expected_handoff = Audio.handoff.duplicate()
			check(expected_handoff.path == level.audio.village_music.get_meta("song_path") and float(expected_handoff.position) >= 23,"Stage %d carries the correct destination stream and playback position into the next stage" % chapter)
			level.audio.toggle()
			check(level.audio.music.volume_db < -60 and is_equal_approx(level.audio.village_music.volume_db,-23+float(level.audio.village_music.get_meta("gain_db",0.0))),"Stage %d unmute immediately restores its balanced crossfade without a burst from the old track" % chapter)
		level.completed = true
		preload("res://scripts/level_backdrop.gd").update(level)
		check(level.sky.dawn == (chapter in [1,Campaign.STAGES]),"Stage %d completion preserves the next border lighting or its intended dawn celebration" % chapter)
		level.queue_free()
		await ticks(2)
	print("BORDER POLISH RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
