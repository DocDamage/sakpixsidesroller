extends Node2D

const Assets = preload("res://scripts/level_assets.gd")
const VFX: String = "res://Hero/Seeker_PRO/VFX/Bone/"
const SHEETS: Dictionary = {
	"jump": ["Dust/Seeker_VFX_Bone_Dust_Jump_32x18_6f.png", 32, 18, 6],
	"air_jump": ["Dust/Seeker_VFX_Bone_AirJump_Ring_32x16_7f.png", 32, 16, 7],
	"land": ["Dust/Seeker_VFX_Bone_Dust_Land_44x16_7f.png", 44, 16, 7],
	"dash": ["Dust/Seeker_VFX_Bone_Dust_Dash_40x20_7f.png", 40, 20, 7],
	"hit": ["Shots/Seeker_VFX_Bone_Shot_Basic_Impact_32x32_7f.png", 32, 32, 7],
	"heavy_hit": ["Shots/Seeker_VFX_Bone_Shot_Big_Impact_56x56_8f.png", 56, 56, 8],
	"seal": ["Magic/Seeker_VFX_Bone_Power_Burst_64x64_10f.png", 64, 64, 10]
}
var frames: Dictionary = {}
var shake: float = 0.0
var flash: float = 0.0
var clock: float = 0.0
var particles: Array[Dictionary] = []
var extras: RefCounted

func _ready() -> void:
	z_index = 8
	extras = preload("res://scripts/asset_effects.gd").new()
	for kind: String in SHEETS:
		var info: Array = SHEETS[kind]
		var sheet: Texture2D = Assets.texture(VFX + str(info[0]))
		var animation: SpriteFrames = SpriteFrames.new()
		animation.set_animation_loop("default", false)
		animation.set_animation_speed("default", 24.0)
		for i: int in range(int(info[3])):
			var region: AtlasTexture = AtlasTexture.new()
			region.atlas = sheet
			region.region = Rect2(i * int(info[1]), 0, int(info[1]), int(info[2]))
			animation.add_frame("default", region)
		frames[kind] = animation

func play(kind: String, at: Vector2, facing: float = 1.0, size: float = 1.0) -> AnimatedSprite2D:
	if extras.clips.has(kind):
		return extras.play(self,kind,at,facing,size)
	if not frames.has(kind):
		return null
	var effect: AnimatedSprite2D = AnimatedSprite2D.new()
	effect.sprite_frames = frames[kind]
	effect.position = at
	effect.flip_h = facing < 0.0
	effect.scale = Vector2.ONE * (2.0 if kind == "seal" else 2.4) * size
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effect.set_meta("effect_kind",kind)
	add_child(effect)
	effect.animation_finished.connect(effect.queue_free)
	effect.play()
	return effect

func follow_attack(kind: String, enemy: Node2D, offset: Vector2, size: float, color: Color, windup: bool = false) -> AnimatedSprite2D:
	var effect: AnimatedSprite2D = play(kind,enemy.position+offset,enemy.attack_direction,size)
	if effect == null:
		return null
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/enemy_attack_trail.gdshader")
	material.set_shader_parameter("tint",color)
	effect.material = material
	effect.set_meta("follow_enemy",weakref(enemy))
	effect.set_meta("follow_offset",offset)
	effect.set_meta("windup",windup)
	if windup:
		effect.sprite_frames = effect.sprite_frames.duplicate()
		effect.sprite_frames.set_animation_loop("default",true)
	return effect

func impact(strength: float = 4.0) -> void:
	shake = maxf(shake, strength)

func _process(delta: float) -> void:
	clock += delta
	shake = move_toward(shake, 0.0, delta * 25.0)
	flash = move_toward(flash, 0.0, delta * 2.0)
	for effect: Node in get_children():
		if not effect.has_meta("follow_enemy"):
			continue
		var enemy: Node2D = effect.get_meta("follow_enemy").get_ref()
		if not is_instance_valid(enemy) or enemy.dead or (enemy.state != 1 if effect.get_meta("windup",false) else enemy.state != 2):
			effect.queue_free()
		else:
			effect.position = enemy.position+Vector2(effect.get_meta("follow_offset"))
	for particle: Dictionary in particles:
		particle["position"] += particle["velocity"] * delta
		particle["life"] -= delta
	particles = particles.filter(func(p: Dictionary) -> bool: return p["life"] > 0.0)
	queue_redraw()

func camera_offset() -> Vector2:
	return Vector2(sin(clock * 83.0), cos(clock * 97.0)) * shake

func ghost(source: AnimatedSprite2D, at: Vector2) -> void:
	var image: Sprite2D = Sprite2D.new()
	image.texture = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	image.position = at + source.position
	image.scale = source.scale
	image.flip_h = source.flip_h
	image.modulate = Color("b1dfe878")
	add_child(image)
	var fade: Tween = image.create_tween()
	fade.tween_property(image, "modulate:a", 0.0, 0.22)
	fade.tween_callback(image.queue_free)

func sword_tail(source: AnimatedSprite2D, at: Vector2) -> void:
	var clip: String = source.animation
	var motion: Script = preload("res://scripts/hero_motion.gd")
	if not motion.TIMES.has(clip):
		return
	var texture: Texture2D = source.sprite_frames.get_frame_texture(clip,0)
	var size: Vector2 = texture.get_size()
	var count: int = source.sprite_frames.get_frame_count(clip)
	var path: String = "res://Hero/Seeker_PRO/Spritesheets/Bone/FX Split/Seeker_Bone_%s_FX_%dx%d_%df.png" % [clip,int(size.x),int(size.y),count]
	if not FileAccess.file_exists(path):
		return
	var frames := SpriteFrames.new()
	frames.set_animation_loop("default",false)
	frames.set_animation_speed("default",1)
	for i: int in range(source.frame,count):
		frames.add_frame("default",Assets.atlas(path,Rect2(i*size.x,0,size.x,size.y)),motion.TIMES[clip][i])
	var tail := AnimatedSprite2D.new()
	tail.sprite_frames = frames
	tail.position = at+source.position
	tail.scale = source.scale
	tail.flip_h = source.flip_h
	tail.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tail.set_meta("effect_kind","sword_tail")
	add_child(tail)
	tail.animation_finished.connect(tail.queue_free)
	tail.play()

func floating_text(value: String, at: Vector2, tint: Color) -> void:
	var label: Label = Label.new()
	label.text = value
	var font_size: int = 18 if value.length() < 4 else 13
	var width: float = ThemeDB.fallback_font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	label.position = at-Vector2(width/2,12)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color("101322"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween: Tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.1)
	tween.chain().tween_callback(label.queue_free)

func burst(at: Vector2, color: Color) -> void:
	for i: int in range(12):
		var angle: float = float(i) / 12.0 * TAU
		particles.append({"position": at, "velocity": Vector2.from_angle(angle) * 95.0, "life": 0.5, "color": color})

func _draw() -> void:
	for particle: Dictionary in particles:
		var color: Color = particle["color"]
		color.a = float(particle["life"]) * 2.0
		draw_rect(Rect2(particle["position"], Vector2(4, 4)), color)
