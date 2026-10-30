extends RefCounted

# Counts measured from the populated 64px cells in the supplied sheets.
const IDLE: Dictionary = {"pumpkin": 10, "bat": 4, "plant": 5, "warden": 5, "mimic": 1, "rat": 5, "mushroom": 5, "eye": 5, "guard": 5, "witch": 5, "mosquito": 4}
const ATTACK: Dictionary = {"pumpkin": 9, "bat": 6, "plant": 6, "warden": 6, "mimic": 6, "rat": 6, "mushroom": 6, "eye": 5, "guard": 6, "witch": 8, "mosquito": 4}
const DEATH: Dictionary = {"pumpkin": 7, "bat": 6, "plant": 5, "warden": 7, "mimic": 7, "rat": 5, "mushroom": 6, "eye": 6, "guard": 7, "witch": 7, "mosquito": 6}
# These sheets face left in their original pixels; the rat faces right.
const LEFT_FACING: Array[String] = ["warden","guard","plant","eye","witch"]

static func face(enemy: Node2D, direction: float) -> void:
	enemy.visual.flip_h = (direction < 0) != (enemy.species in LEFT_FACING)

static func configure_ui(enemy: Node2D) -> void:
	var pixels: Image = enemy.visual.texture.get_image()
	if pixels.is_compressed():
		pixels.decompress()
	var strip: Image = pixels.get_region(Rect2i(0, 0, int(IDLE[enemy.species]) * 64, 64))
	var top: float = strip.get_used_rect().position.y
	# A stable anchor clears all idle frames, including the hit-reaction stretch.
	enemy.ui_top = enemy.visual.position.y + (top - 32) * enemy.body_scale - 18

static func update(enemy: Node2D, speed: float = 0.0) -> void:
	var species: String = enemy.species
	var row: int = 0
	var count: int = IDLE[species]
	var frame: int = int(enemy.phase * 10) % count
	if enemy.dead:
		row = 1 if species in ["eye","mosquito"] else (2 if species in ["pumpkin", "bat","witch"] else 3)
		frame = mini(DEATH[species] - 1, int(enemy.state_time / 0.65 * DEATH[species]))
	elif enemy.state in [1, 2]:
		row = 0 if species in ["eye","mosquito"] else (1 if species in ["pumpkin", "bat","witch"] else 2)
		frame = 0 if enemy.state == 1 else mini(ATTACK[species] - 1, int(enemy.state_time / 0.38 * ATTACK[species]))
	elif species == "mimic" and enemy.awakened:
		row = 1
		frame = int(enemy.phase * 10) % 8
	elif species in ["plant", "warden", "rat", "guard"] and absf(speed) > 5:
		row = 1
		frame = int(enemy.phase * 12) % 8
	elif species == "mushroom" and absf(speed) > 5:
		row = 1
		frame = int(enemy.phase * 12) % 5
	if enemy.state == 0 and absf(speed) > 5:
		face(enemy,speed)
	elif enemy.state in [1,2]:
		face(enemy,enemy.attack_direction)
	enemy.visual.region_rect.position = Vector2(frame * 64, row * 64)
	var stretch := Vector2.ONE
	var tint: Color = enemy.base_color
	if not enemy.dead:
		if enemy.state == 3 and enemy.awakened:
			stretch = Vector2(1.04, 0.96)
		if enemy.state == 1:
			stretch = Vector2(1.08, 0.92)
			tint = Color("ffca7c")
		if enemy.hit_timer > 0:
			stretch = Vector2(0.92, 1.06)
			tint = Color.WHITE if enemy.hit_timer > 0.22 else Color("ffacb5")
	enemy.visual.scale = stretch * enemy.body_scale
	if not enemy.flying:
		enemy.visual.position.y = -32.0 * enemy.visual.scale.y
	enemy.visual.modulate = tint
	# Mix the texture itself toward white so dark sprites visibly react to a hit.
	enemy.visual.material.set_shader_parameter("impact", clampf((enemy.hit_timer - 0.18) / 0.10, 0, 1) if not enemy.dead else 0.0)
	if enemy.dead:
		enemy.visual.modulate.a = clampf((0.65 - enemy.state_time) * 5, 0, 1)
