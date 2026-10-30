extends RefCounted

var audio: Node
var slots: Array[Dictionary] = []
var clock: float = 0

func setup(owner_audio: Node) -> void:
	audio = owner_audio
	for voice: AudioStreamPlayer in audio.effects:
		var name: StringName = StringName("DistrictVoice_"+str(voice.get_instance_id()))
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count-1
		AudioServer.set_bus_name(index,name)
		AudioServer.set_bus_send(index,&"Master")
		var pan := AudioEffectPanner.new()
		var filter := AudioEffectLowPassFilter.new()
		filter.cutoff_hz = 20000
		AudioServer.add_bus_effect(index,pan)
		AudioServer.add_bus_effect(index,filter)
		voice.bus = name
		slots.append({"voice":voice,"name":name,"pan":pan,"filter":filter,"source":Vector2.INF})

func configure(voice: AudioStreamPlayer, at: Vector2) -> void:
	for slot: Dictionary in slots:
		if slot.voice == voice:
			slot.source = at
			refresh(slot)
			return

func refresh(slot: Dictionary) -> void:
	var level: Node2D = audio.get_parent()
	var listener: Vector2 = level.player.global_position-Vector2(0,45)
	var local: bool = not slot.source.is_finite()
	slot.pan.pan = 0.0 if local else clampf((slot.source.x-listener.x)/700,-0.72,0.72)
	var underwater: bool = level.district.water_at(listener) != null
	var blocked: bool = false
	if not local and listener.distance_to(slot.source) > 65:
		var query := PhysicsRayQueryParameters2D.create(listener,slot.source,1)
		query.hit_from_inside = true
		blocked = not level.get_world_2d().direct_space_state.intersect_ray(query).is_empty()
	var ui_sound: bool = slot.voice.get_meta("kind","") == "map_open"
	slot.filter.cutoff_hz = 20000.0 if ui_sound else (2300.0 if blocked else (4200.0 if underwater else 20000.0))
	slot.voice.set_meta("occluded",blocked)
	slot.voice.set_meta("underwater",underwater and not ui_sound)

func update(delta: float) -> void:
	clock -= delta
	if clock > 0:
		return
	clock = 0.12
	for slot: Dictionary in slots:
		if slot.voice.playing:
			refresh(slot)

func dispose() -> void:
	for slot: Dictionary in slots:
		slot.voice.bus = &"Master"
		var index: int = AudioServer.get_bus_index(slot.name)
		if index > 0:
			AudioServer.remove_bus(index)
	slots.clear()
