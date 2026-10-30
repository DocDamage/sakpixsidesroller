extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Bolt = preload("res://scripts/cursed_bolt.gd")
const Urn = preload("res://scripts/breakable_urn.gd")

func barrier(x: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20,240)
	collision.shape = box
	body.position = Vector2(x,500)
	body.add_child(collision)
	level.add_child(body)
	return body

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/awareness-feedback-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	for chapter: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		level.player.set_physics_process(false)
		level.player.position = Vector2(700,600)
		level.player.invincible = 1000
		var guard := Enemy.new()
		guard.species = "guard"
		guard.position = Vector2(1000,600)
		level.add_child(guard)
		guard.set_physics_process(false)
		guard.patrol = 0
		guard.alert_cooldown = 0
		level.combat.connect_enemy(guard,false)
		var notices: Array[Vector2] = []
		guard.noticed.connect(func(at: Vector2) -> void: notices.append(at))
		guard._physics_process(0.06)
		check(guard.awareness > 0.25 and guard.state == 0 and notices.size() == 1,"Stage %d guard notices a visible approach before attack range and emits one source cue" % chapter)
		level.player.position.x = 800
		guard._physics_process(0.04)
		check(guard.state == 0 and guard.sight_time < 0.12,"Stage %d first distant sight cannot trigger an instant attack" % chapter)
		guard._physics_process(0.04)
		var captured: Vector2 = guard.target
		check(guard.state == 1 and captured == level.player.position and notices.size() == 1,"Stage %d a sustained acquisition starts the full committed warning without notice spam" % chapter)
		level.player.position.x = 600
		guard._physics_process(0.1)
		check(guard.target == captured and guard.state == 1,"Stage %d moving out of sight cannot retarget an already committed warning" % chapter)
		guard.state = 0
		guard.alert_cooldown = 5
		level.player.position.x = 1900
		guard._physics_process(0.3)
		check(guard.awareness > 0 and guard.sight_memory > 0 and guard.last_seen == captured and not guard.sees_player,"Stage %d lost sight retains only the last visible position" % chapter)
		guard._physics_process(0.95)
		check(guard.awareness == 0 and guard.sight_memory == 0 and guard.state == 0,"Stage %d suspicion fades after the target stays out of sight" % chapter)
		guard.reset_encounter()
		check(guard.awareness == 0 and guard.sight_time == 0 and not guard.sees_player,"Stage %d checkpoint encounter reset clears perception" % chapter)
		guard.queue_free()
		await ticks(2)
		if chapter == 1:
			await cover_checks()
			await sound_checks()
		for voice: AudioStreamPlayer in level.audio.effects:
			voice.stop()
		level.audio.muted = false
		level.audio.sound_clock += 1
		level.audio.play("enemy_notice")
		var active: AudioStreamPlayer
		for voice: AudioStreamPlayer in level.audio.effects:
			if voice.playing:
				active = voice
		hub.using_pad = true
		hub.feedback.clear()
		hub.rumble("hurt")
		await tap(JOY_BUTTON_START)
		check(paused and active != null and active.stream_paused and hub.last_rumble_strength == Vector2.ZERO and hub.feedback.active_kind.is_empty(),"Stage %d controller pause freezes combat SFX and clears motor feedback" % chapter)
		await tap(JOY_BUTTON_B)
		check(not paused and active != null and not active.stream_paused and level.player.jumps == 0 and level.player.dash_time == 0,"Stage %d resume restores sound without a leaked controller action" % chapter)
		level.queue_free()
		await ticks(2)
	print("AWARENESS FEEDBACK RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)

func cover_checks() -> void:
	var wall: StaticBody2D = barrier(990)
	var guard := Enemy.new()
	guard.species = "guard"
	guard.position = Vector2(1000,600)
	level.add_child(guard)
	guard.set_physics_process(false)
	guard.patrol = 0
	guard.alert_cooldown = 0
	level.player.position = Vector2(940,600)
	await ticks(3)
	guard._physics_process(0.25)
	check(not guard.sees_player and guard.state == 0 and guard.awareness == 0,"Solid cover blocks melee awareness as well as ranged casting")
	level.player.position = Vector2(960,600)
	level.player.health = 5
	level.player.invincible = 0
	guard.state = 2
	guard.attack_direction = -1
	guard.state_time = 0.1
	guard._physics_process(0.01)
	check(level.player.health == 5,"Committed contact and melee swings cannot damage through solid cover")
	guard.queue_free()
	var target := Enemy.new()
	target.species = "plant"
	target.position = Vector2(1000,600)
	level.add_child(target)
	target.set_physics_process(false)
	var spell := Bolt.new()
	spell.position = Vector2(1000,565)
	level.add_child(spell)
	spell.set_physics_process(false)
	var urn := Urn.new()
	urn.position = Vector2(1000,600)
	level.add_child(urn)
	level.player.position = Vector2(930,600)
	level.player.attack_mode = "ground"
	level.player.combo_step = 0
	level.player.invincible = 1000
	await ticks(2)
	level.combat.resolve_attack(Vector2(980,565),1)
	check(target.health == 3 and not spell.friendly and not urn.broken,"Solid cover blocks player melee, reflections and supply-breaking")
	wall.queue_free()
	await ticks(2)
	level.combat.resolve_attack(Vector2(980,565),1)
	check(target.health == 2 and spell.friendly and urn.broken,"The same attack connects with enemies, spells and supplies once cover is removed")
	target.queue_free()
	spell.queue_free()
	urn.queue_free()
	await ticks(2)

func sound_checks() -> void:
	var audio: Node = level.audio
	for kind: String in ["enemy_notice","guard_swing","witch_fire","mosquito_dive","enemy_defeat"]:
		var stream: AudioStreamWAV = audio.streams[kind]
		check(stream.mix_rate == 44100 and not stream.stereo and stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.get_length() > 0.05 and stream.get_length() < 0.5,"Supplied combat sound is short, mono PCM and playable: "+kind)
	for voice: AudioStreamPlayer in audio.effects:
		voice.stream = audio.streams.coin
		voice.play()
		voice.set_meta("priority",1)
		voice.set_meta("order",0)
		voice.set_meta("kind","coin")
	audio.muted = false
	audio.play("warden_warning")
	check(audio.effects[0].get_meta("kind") == "warden_warning","A full pickup-sound pool cannot discard the guardian warning")
	for voice: AudioStreamPlayer in audio.effects:
		voice.set_meta("priority",9)
		voice.set_meta("kind","hurt")
	var order: int = audio.sound_order
	audio.play("land")
	check(audio.sound_order == order,"A footstep cannot truncate critical combat sounds")
	audio.play("guard_break")
	check(audio.sound_order == order+1,"A fresh critical guard-break cue replaces the oldest equal-priority voice")
	for voice: AudioStreamPlayer in audio.effects:
		voice.stop()
	audio.last_sound.clear()
	audio.play("coin")
	order = audio.sound_order
	audio.play("coin")
	check(audio.sound_order == order,"Same-frame pickup cues coalesce instead of stacking")
	audio.sound_clock += 0.06
	audio.play("coin")
	check(audio.sound_order == order+1,"A later pickup still receives its own cue")
	order = audio.sound_order
	audio.play_at("enemy_notice",level.player.position+Vector2(1100,0))
	check(audio.sound_order == order,"Distant enemies cannot clutter the local warning mix")
	audio.sound_clock += 0.06
	audio.play_at("enemy_notice",level.player.position+Vector2(200,0))
	var near: float = -100
	for voice: AudioStreamPlayer in audio.effects:
		if voice.get_meta("order",-1) == audio.sound_order:
			near = voice.volume_db
	audio.sound_clock += 0.06
	audio.play_at("enemy_notice",level.player.position+Vector2(800,0))
	var far: float = 0
	for voice: AudioStreamPlayer in audio.effects:
		if voice.get_meta("order",-1) == audio.sound_order:
			far = voice.volume_db
	check(far < near-5,"Off-center enemy notices attenuate smoothly with distance")
	audio.toggle()
	order = audio.sound_order
	audio.play("hurt")
	check(audio.sound_order == order and audio.effects.all(func(voice: AudioStreamPlayer) -> bool: return not voice.playing),"Mute silences and blocks every priority tier")
	audio.toggle()
	var pending: Array[WeakRef] = []
	for kind: String in ["notice","cast_release","enemy_defeat","enemy_swing","enemy_dive"]:
		var frames: SpriteFrames = level.effects.extras.clips[kind]
		var populated: int = 0
		for i: int in frames.get_frame_count("default"):
			var pixels: Image = frames.get_frame_texture("default",i).get_image()
			if pixels.is_compressed():
				pixels.decompress()
			if pixels.get_used_rect().has_area():
				populated += 1
		check(populated >= 3,"Supplied feedback clip uses populated source frames: "+kind)
		level.effects.play(kind,Vector2(800,400))
	for node: Node in level.effects.get_children():
		if node.has_meta("effect_kind"):
			pending.append(weakref(node))
	await ticks(45)
	check(pending.all(func(reference: WeakRef) -> bool: return reference.get_ref() == null),"Notice, release and defeat effects finish without lingering nodes")
