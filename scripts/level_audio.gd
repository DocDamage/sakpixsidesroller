extends Node

var muted: bool = false
var music: AudioStreamPlayer
var effects: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
static var remembered_mute: bool = false
static var handoff: Dictionary = {}
var chapter: int = 1
var village_music: AudioStreamPlayer
var ending_blend: float = 0.0
var ending_started: bool = false
var music_blend: float = 0.0
var sound_clock: float = 0.0
var sound_order: int = 0
var last_sound: Dictionary = {}
var variants: Dictionary = {}
var variant_index: Dictionary = {}
var music_gain_db: float = 0.0
var sfx_gain_db: float = 0.0
var acoustics: RefCounted
const SOUNDS: Array[String] = ["attack", "dash", "coin", "seal", "hurt", "jump", "hit", "land", "break", "hiss", "warden_warning", "reflect", "guard_break", "armor", "eye_warning", "mushroom_warning", "water", "finisher", "heavy_hit", "eye_fire", "enemy_notice", "guard_swing", "witch_fire", "mosquito_dive", "enemy_defeat"]
const PRIORITIES: Dictionary = {"land":0,"coin":1,"jump":1,"attack":2,"dash":2,"break":3,"water":3,"enemy_notice":4,"enemy_defeat":4,"hit":4,"armor":5,"finisher":5,"guard_swing":6,"witch_fire":6,"mosquito_dive":6,"heavy_hit":6,"hiss":6,"eye_fire":6,"eye_warning":7,"mushroom_warning":7,"warden_warning":8,"reflect":8,"hurt":9,"guard_break":9,"seal":9}

# One album supplies the entire campaign, including the final ending cue.
const SOUNDTRACK: String = "res://Soundtrack/The Haunted Manor — Creepy Horror Soundtrack Pack/"
const STAGE_TRACKS: Array[String] = ["6.","3.","5.","4.","7.","14.","6.","13.","8.","14.","6.","1."]
# Full-file RMS measurements, relative to the original Moonlight exploration cue.
# These playback gains leave the supplied MP3 files untouched.
const TRACK_GAIN_DB: Dictionary = {"1.":0.3,"3.":-1.2,"4.":-0.8,"5.":-1.4,"6.":0.0,"7.":-2.4,"8.":-1.3,"13.":-1.3,"14.":0.1,"17.":-0.9}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	muted = remembered_mute
	music = AudioStreamPlayer.new()
	add_child(music)
	music.volume_db = -80.0 if muted else -23.0
	load_song(music,STAGE_TRACKS[chapter-1])
	if handoff.get("chapter",0) == chapter and handoff.get("path","") == music.get_meta("song_path",""):
		music.play(float(handoff.get("position",0.0)))
	handoff.clear()
	for i: int in range(8):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.volume_db = -19.0
		add_child(voice)
		effects.append(voice)
	for key: String in SOUNDS:
		streams[key] = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path("res://assets/audio/" + key + ".wav"))
	var enemy_sources: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/enemies/sources.json"))
	for event: String in enemy_sources:
		var choices: Array[AudioStreamWAV] = []
		for entry: Dictionary in enemy_sources[event]:
			choices.append(AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(entry.path)))
		variants[event] = choices
		streams[event] = choices[0]
	village_music = AudioStreamPlayer.new()
	add_child(village_music)
	village_music.volume_db = -80
	load_song(village_music,STAGE_TRACKS[chapter] if chapter < STAGE_TRACKS.size() else "17.")
	_process(0.0)

func load_song(voice: AudioStreamPlayer, prefix: String) -> void:
	for file: String in DirAccess.get_files_at(SOUNDTRACK):
		if file.begins_with(prefix) and file.ends_with(".mp3"):
			var stream: AudioStreamMP3 = AudioStreamMP3.load_from_file(ProjectSettings.globalize_path(SOUNDTRACK+file))
			if stream != null:
				stream.loop = true
				voice.stream = stream
				var title: String = file.get_basename().get_slice("—",1).strip_edges()
				voice.set_meta("song_title",title.trim_prefix("_").trim_suffix("_").trim_prefix("“").trim_suffix("”"))
				voice.set_meta("song_path",SOUNDTRACK+file)
				voice.set_meta("gain_db",TRACK_GAIN_DB.get(prefix,0.0))
				voice.play()
			return
	push_error("Missing Haunted Manor soundtrack cue: "+prefix)

func now_playing() -> String:
	var voice: AudioStreamPlayer = music
	if village_music != null and music_blend > 0.5:
		voice = village_music
	return str(voice.get_meta("song_title", ""))

func _process(delta: float) -> void:
	sound_clock += delta
	if acoustics != null:
		acoustics.update(delta)
	for voice: AudioStreamPlayer in effects:
		voice.stream_paused = get_tree().paused and voice.get_meta("kind","") != "map_open"
	var volume: float = (-28.0 if get_tree().paused else -23.0)+music_gain_db
	if village_music == null:
		music.volume_db = -80.0 if muted else volume+float(music.get_meta("gain_db",0.0))
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var x: float = preload("res://scripts/stage_expansion.gd").base_x(player.position.x) if get_parent().get("extended") == true else player.position.x
	if get_parent().get("district") != null:
		x = get_parent().district.story_x()
	var blend: float = smoothstep(1700,5800,x)
	if chapter == 3:
		blend = smoothstep(4200,6200,x)
	if chapter in [1,4,5,6,7,8,9,10,11]:
		blend = smoothstep(4700,6200,x)
	if chapter == 12:
		var scene: Node = get_tree().current_scene
		if scene != null and scene.get("completed") == true and not ending_started:
			village_music.play(0)
			ending_started = true
		ending_blend = move_toward(ending_blend, 1.0 if scene != null and scene.get("completed") == true else 0.0, delta * 0.3)
		blend = ending_blend
	music_blend = blend
	music.volume_db = -80.0 if muted else volume+float(music.get_meta("gain_db",0.0))+linear_to_db(maxf(0.001,1.0-blend))
	village_music.volume_db = -80.0 if muted else volume+float(village_music.get_meta("gain_db",0.0))+linear_to_db(maxf(0.001,blend))

func prepare_handoff(next_chapter: int) -> void:
	var voice: AudioStreamPlayer = village_music if village_music != null and music_blend > 0.5 else music
	handoff = {"chapter":next_chapter,"path":voice.get_meta("song_path",""),"position":voice.get_playback_position()}

func play_at(kind: String, at: Vector2) -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var distance: float = (player.global_position-at).length()
	if distance > 900 or absf(player.global_position.y-at.y) > 650:
		return
	play(kind,-12.0*smoothstep(180,900,distance),at)

func play(kind: String, gain_db: float = 0.0, at: Vector2 = Vector2.INF) -> void:
	if kind == "attack":
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player != null and player.combo_step == 2:
			kind = "finisher"
	if muted or not streams.has(kind):
		return
	if kind in ["coin","hit","hiss","land","enemy_notice","guard_swing","enemy_defeat"] and sound_clock-float(last_sound.get(kind,-100.0)) < 0.055:
		return
	var priority: int = PRIORITIES.get(kind,3)
	if kind in ["warden_swing","rat_lunge","bat_dive","mimic_snap","mushroom_rush","spit","spell_impact"]:
		priority = 6
	if kind.begins_with("foot_") or kind in ["climb","swim","fire_detail","map_open","water_drip"]:
		priority = 0
	if kind == "map_open":
		priority = 9
	var selected: AudioStreamPlayer
	for voice: AudioStreamPlayer in effects:
		if not voice.playing:
			selected = voice
			break
	if selected == null:
		for voice: AudioStreamPlayer in effects:
			if int(voice.get_meta("priority",0)) > priority or (int(voice.get_meta("priority",0)) == priority and priority < 8):
				continue
			if selected == null or int(voice.get_meta("priority",0)) < int(selected.get_meta("priority",0)) or (voice.get_meta("priority",0) == selected.get_meta("priority",0) and int(voice.get_meta("order",0)) < int(selected.get_meta("order",0))):
				selected = voice
	if selected == null:
		return
	selected.stop()
	selected.stream_paused = false
	selected.stream = streams[kind]
	if variants.has(kind):
		var index: int = int(variant_index.get(kind,0))
		selected.stream = variants[kind][index%variants[kind].size()]
		variant_index[kind] = index+1
	selected.pitch_scale = randf_range(0.94,1.06) if kind in ["hit","land","attack"] else 1.0
	var volume: float = -25.0 if kind in ["land","jump"] else -19.0
	if kind.begins_with("foot_") or kind in ["climb","swim"]:
		volume = -27
	elif kind in ["lift_stop","water_entry","water_exit","water_gate"]:
		volume = -25
	elif kind in ["fire_detail","map_open"]:
		volume = -35 if kind == "fire_detail" else -29
	elif kind == "flesh_layer":
		volume = -29
	elif kind == "water_drip":
		volume = -32
	elif kind in ["armor_ready","beast_ready"]:
		volume = -31
	elif kind in ["warden_swing","rat_lunge","bat_dive","mimic_snap","mushroom_rush","spit","spell_impact","enemy_contact"]:
		volume = -25
	if kind in ["hiss","enemy_notice"]:
		volume = -28.0 if kind == "hiss" else -32.0
	elif kind == "warden_warning":
		volume = -22.0
	elif kind in ["eye_warning","mushroom_warning","eye_fire","water","witch_fire","mosquito_dive","enemy_defeat"]:
		volume = -27.0
	elif kind in ["armor","finisher","heavy_hit","guard_swing"]:
		volume = -22.0 if kind != "guard_swing" else -27.0
	selected.volume_db = volume+gain_db+sfx_gain_db
	sound_order += 1
	selected.set_meta("priority",priority)
	selected.set_meta("order",sound_order)
	selected.set_meta("kind",kind)
	if acoustics != null:
		acoustics.configure(selected,at)
	last_sound[kind] = sound_clock
	selected.play()

func toggle() -> void:
	muted = not muted
	remembered_mute = muted
	_process(0.0)
	if muted:
		for voice: AudioStreamPlayer in effects:
			voice.stop()

func _exit_tree() -> void:
	music.stop()
	music.stream = null
	if village_music != null:
		village_music.stop()
		village_music.stream = null
	for voice: AudioStreamPlayer in effects:
		voice.stop()
		voice.stream = null
	if acoustics != null:
		acoustics.dispose()
