extends RefCounted

# Feet pivots and contact frames from Seeker_PRO/Animation_Guide.txt.
const PIVOTS: Dictionary = {"Climb":Vector2(15,28),"WallSlide":Vector2(18,36),"Grapple":Vector2(20,33),"Idle":Vector2(15,28),"Run":Vector2(17,28),"JumpFall":Vector2(16,28),"DoubleJump":Vector2(26,51),"Dash":Vector2(18,26),"Hurt":Vector2(26,52),"Attack1":Vector2(16,38),"Attack2":Vector2(18,43),"Attack3":Vector2(102,43),"JumpAttack":Vector2(19,44),"DownAttack":Vector2(21,42)}
const TIMES: Dictionary = {"Attack1":[0.04,0.04,0.06,0.04,0.06,0.04,0.06,0.08],"Attack2":[0.06,0.04,0.06,0.04,0.08],"Attack3":[0.04,0.04,0.06,0.06,0.04,0.04,0.06,0.06,0.08,0.10],"JumpAttack":[0.04,0.04,0.06,0.04,0.06,0.06,0.08,0.06,0.10],"DownAttack":[0.04,0.04,0.06,0.04,0.06,0.06,0.10]}
const ACTIVE: Dictionary = {"Attack1":Vector2i(3,4),"Attack2":Vector2i(1,2),"Attack3":Vector2i(5,6),"JumpAttack":Vector2i(3,4),"DownAttack":Vector2i(3,4)}
# Blade envelopes measured from the supplied active frames, relative to feet.
const BLADES: Dictionary = {"Attack1":Rect2(8,-88,190,104),"Attack2":Rect2(8,-126,160,142),"Attack3":Rect2(8,-70,268,86),"JumpAttack":Rect2(8,-105,190,120),"DownAttack":Rect2(-63,-5,144,102)}

static func duration(clip: String) -> float:
	var total: float = 0
	for value: float in TIMES[clip]:
		total += value
	return total

static func frame(clip: String, elapsed: float) -> int:
	for i: int in TIMES[clip].size():
		if elapsed < float(TIMES[clip][i]):
			return i
		elapsed -= float(TIMES[clip][i])
	return TIMES[clip].size()-1

static func anchor(sprite: AnimatedSprite2D, facing: float) -> void:
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var pivot: Vector2 = PIVOTS.get(sprite.animation,Vector2(15,28))
	var offset: Vector2 = texture.get_size()/2-pivot
	sprite.position = Vector2(offset.x*sprite.scale.x*facing,offset.y*sprite.scale.y)
	sprite.flip_h = facing < 0
