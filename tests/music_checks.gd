extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Audio = preload("res://scripts/level_audio.gd")
const TITLES: Array[String] = ["Moonlight Through Broken Glass","Behind the Iron Gates","Footsteps Upstairs","Whispers Between Pages","The Locked Chamber","Beneath the Manor","Moonlight Through Broken Glass","The Forgotten Attic","Behind the Walls","Beneath the Manor","Moonlight Through Broken Glass","The Haunted Manor"]

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/music-test-controller.cfg"
	hub.defaults()
	Audio.remembered_mute = false
	Audio.handoff.clear()
	var previous_path: String = ""
	for stage: int in range(1,13):
		level = load(Campaign.SCENES[stage-1]).instantiate()
		root.add_child(level)
		current_scene = level
		level.player.set_physics_process(false)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		await ticks(5)
		var audio: Node = level.audio
		var track: AudioStreamPlayer = audio.music
		var destination: AudioStreamPlayer = audio.village_music
		check(track.get_meta("song_path","").begins_with(Audio.SOUNDTRACK) and destination.get_meta("song_path","").begins_with(Audio.SOUNDTRACK),"Stage %d both music streams come exclusively from Haunted Manor" % stage)
		check(track.playing and destination.playing and track.stream.loop and destination.stream.loop,"Stage %d supplied MP3 streams load, play and loop" % stage)
		check(audio.now_playing() == TITLES[stage-1],"Stage %d starts with the selected horror exploration cue" % stage)
		if not previous_path.is_empty():
			check(track.get_meta("song_path","") == previous_path and track.get_playback_position() > 22 and track.get_playback_position() < 26,"Stage %d resumes the actual destination stream without restarting it" % stage)
		level.player.position.x = level.portal.position.x
		await ticks(3)
		if stage < 12:
			check(audio.music_blend > 0.99 and audio.now_playing() == TITLES[stage],"Stage %d approach crossfades to the next stage's Haunted Manor cue" % stage)
		else:
			check(is_zero_approx(audio.music_blend) and not audio.ending_started,"Final ending music cannot start before completion")
			level.completed = true
			await ticks(220)
			check(audio.ending_started and audio.music_blend > 0.99 and audio.now_playing() == "The Morning After","Final victory fades into Haunted Manor's true ending cue")
		var playing_title: String = audio.now_playing()
		var level_db: float = destination.volume_db
		paused = true
		await ticks(3)
		check(is_equal_approx(destination.volume_db,level_db-5),"Stage %d pause ducks music by five dB while preserving track balancing" % stage)
		paused = false
		await ticks(2)
		audio.toggle()
		await ticks(2)
		check(track.volume_db <= -80 and destination.volume_db <= -80 and audio.now_playing() == playing_title,"Stage %d mute silences both tracks and preserves the selected cue" % stage)
		audio.toggle()
		await ticks(2)
		check(is_equal_approx(destination.volume_db,level_db) and audio.now_playing() == playing_title,"Stage %d unmute restores the balanced crossfade without switching music" % stage)
		if stage < 12:
			destination.play(23)
			audio.prepare_handoff(stage+1)
			previous_path = destination.get_meta("song_path","")
		level.queue_free()
		await ticks(2)
	print("MUSIC RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
