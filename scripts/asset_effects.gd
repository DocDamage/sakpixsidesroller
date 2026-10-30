extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
var clips: Dictionary = {}
var settings: Dictionary = {}

func _init() -> void:
	settings = JSON.parse_string(FileAccess.get_file_as_string("res://assets/effects_manifest.json"))
	for kind: String in settings:
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		frames.add_animation("default")
		frames.set_animation_loop("default", false)
		frames.set_animation_speed("default", settings[kind]["fps"])
		for path: String in settings[kind]["frames"]:
			frames.add_frame("default", Assets.texture(path))
		clips[kind] = frames

func play(parent: Node2D, kind: String, at: Vector2, facing: float = 1, size: float = 1) -> AnimatedSprite2D:
	if not clips.has(kind):
		return null
	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = clips[kind]
	effect.position = at
	effect.scale = Vector2.ONE * settings[kind]["scale"] * size
	effect.flip_h = facing < 0
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.set_meta("effect_kind",kind)
	parent.add_child(effect)
	effect.animation_finished.connect(effect.queue_free)
	effect.play()
	return effect
