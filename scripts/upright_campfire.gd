extends Sprite2D

const Assets = preload("res://scripts/level_assets.gd")
const FLAME: String = "res://Props/Campfire/Campfire Sprites/flame_orange_frame"
var clock: float = 0
var flame: AnimatedSprite2D

static func place(parent: Node2D, x: float, surface: float = 600, hearth: bool = false) -> Sprite2D:
	var fire: Sprite2D = load("res://scripts/upright_campfire.gd").new()
	# Only the side-on log bed: no elliptical stone ring or overhead perspective.
	fire.texture = Assets.atlas("res://Stages/Medievil Kingdom/8. Medieval Props, Furniture & Village Life/campfire.png",Rect2(7,24,18,6))
	fire.scale = Vector2.ONE*2.6
	fire.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fire.position = Vector2(x,surface)
	fire.z_index = -1 if hearth else 2
	parent.add_child(fire)
	Assets.anchor_base(fire,surface)
	fire.set_meta("surface_y",surface)
	fire.set_meta("emitter_offset",Vector2(0,-26))
	fire.set_meta("hearth",hearth)
	fire.add_to_group("grounded_scenery")
	fire.add_to_group("upright_campfires")
	fire.flame = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default",9)
	for i: int in range(1,5):
		frames.add_frame("default",Assets.texture(FLAME+str(i)+".png"))
	fire.flame.sprite_frames = frames
	fire.flame.position = Vector2(0,-9)
	fire.flame.scale = Vector2.ONE*0.85
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	fire.flame.material = material
	fire.add_child(fire.flame)
	fire.flame.play()
	return fire

func _process(delta: float) -> void:
	clock += delta
	flame.self_modulate = Color(1,0.96+sin(clock*8)*0.04,0.92+sin(clock*6)*0.08)
	queue_redraw()

func _draw() -> void:
	# Contact stays on the horizontal walking plane, not under the sprite pivot.
	draw_rect(Rect2(-10,2,20,1),Color(0.035,0.025,0.04,0.5))
