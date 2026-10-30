extends RefCounted

static func install(audio: Node) -> void:
	# Put contact and movement in front of the score while retaining headroom
	# for overlapping warnings, armor breaks and body layers.
	audio.music_gain_db = 3.0
	audio.sfx_gain_db = 7.0
	audio.acoustics = preload("res://scripts/district_acoustics.gd").new()
	audio.acoustics.setup(audio)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/district/sources.json"))
	for event: String in source:
		var variants: Array[AudioStreamWAV] = []
		for entry: Dictionary in source[event]:
			var stream: AudioStreamWAV = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(entry.path))
			if stream != null:
				variants.append(stream)
		if not variants.is_empty():
			audio.variants[event] = variants
			audio.streams[event] = variants[0]
