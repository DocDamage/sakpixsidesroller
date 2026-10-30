extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Town = preload("res://scripts/town_builder.gd")
const Enemy = preload("res://scripts/haunt.gd")
const Biome = preload("res://scripts/road_biome.gd")
const VILLAGE: String = "res://Stages/Village/GandalfHardcore Pixel Art Village Houses tiles/"
const FLOORS: Array[Vector2] = [Vector2(0, 1664), Vector2(1920, 3136), Vector2(3456, 4608), Vector2(4864, 6400)]
const LEDGES: Array[Rect2] = [Rect2(384, 500, 192, 30), Rect2(768, 420, 192, 30), Rect2(1152, 448, 256, 30), Rect2(1728, 512, 128, 30), Rect2(2112, 480, 192, 30), Rect2(2752, 384, 256, 30), Rect2(3264, 496, 128, 30), Rect2(3712, 480, 192, 30), Rect2(4256, 400, 256, 30), Rect2(4672, 512, 128, 30), Rect2(4992, 464, 192, 30), Rect2(5344, 400, 192, 30)]

static func build(level: Node2D) -> void:
	background(level)
	for span: Vector2 in FLOORS:
		Town.solid(level, Rect2(span.x, 600, span.y - span.x, 220))
		for x: int in range(int(span.x), int(span.y), 64):
			for row: int in range(4):
				terrain(level, x, row)
	for ledge: Rect2 in LEDGES:
		Town.solid(level, ledge, true)
		for x: int in range(int(ledge.position.x), int(ledge.end.x), 64):
			var wooden: bool = x > 1600 or x < 1100
			var texture: String = Assets.PLATFORMS + ("wooden_plank_ledge.png" if wooden else "purple_stone_platform.png")
			var crop: Rect2 = Rect2(1, 14, 30, 8) if wooden else Rect2(1, 10, 30, 17)
			var plank: Sprite2D = Assets.sprite(level, texture, Vector2(x + 32, ledge.position.y + crop.size.y), 1, 1)
			plank.region_enabled = true
			plank.region_rect = crop
			plank.scale = Vector2(64.0 / 30.0, 2)
		for dx: float in [20.0, ledge.size.x - 20.0]:
			Assets.sprite(level, Assets.PLATFORMS + "wooden_bracket_shelf.png", ledge.position + Vector2(dx, 14), 1.3, -1).modulate = Color("b3a297")
	for entry: Array in [["pumpkin", 1000.0], ["pumpkin", 2430.0], ["mushroom", 3670.0], ["rat", 4120.0], ["rat", 5170.0]]:
		var enemy: Node2D = Enemy.new()
		enemy.species = entry[0]
		enemy.position = Vector2(entry[1], 600)
		level.add_child(enemy)
		enemy.defeated.connect(level.enemy_defeated)
	for at: Vector2 in [Vector2(1460, 430), Vector2(3030, 390), Vector2(4540, 400)]:
		var bat: Node2D = Enemy.new()
		bat.flying = true
		if at.x == 1460:
			bat.species = "mosquito"
		if at.x == 3030:
			bat.species = "eye"
		bat.health = 1
		bat.position = at
		level.add_child(bat)
		bat.defeated.connect(level.enemy_defeated)
	decorate(level)

static func terrain(level: Node2D, x: int, row: int) -> void:
	var blend: float = clampf((x - 800.0) / 4400.0, 0, 1)
	var path: String = Assets.GROUND + "orange_ground_top.png"
	var crop: Rect2 = Rect2(1, 10, 30, 22)
	if row > 0:
		path = Assets.GROUND + "mossy_stone_wall.png"
		crop = Rect2(1, 1, 30, 31)
	var tile: Sprite2D = Assets.sprite(level, path, Vector2(x + 32, 632 + row * 64), 1, 0)
	tile.region_enabled = true
	tile.region_rect = crop
	tile.scale = Vector2(64.0 / crop.size.x, 64.0 / crop.size.y)
	tile.modulate = Color("c3a2cc").lerp(Color("dbd5aa"), blend)
	if row == 0:
		var grass: Sprite2D = Assets.sprite(level, Assets.GROUND + "grass_ground_top.png", tile.position, 1, 0)
		grass.region_enabled = true
		grass.region_rect = Rect2(1, 11, 30, 21)
		grass.scale = Vector2(64.0 / 30.0, 64.0 / 21.0)
		grass.modulate = tile.modulate
		grass.modulate.a = Biome.grass_blend(x)
	if row > 0:
		tile.modulate *= Color("6f647e") if row == 1 else Color("484050")
		var foundation: Sprite2D = Assets.sprite(level, Biome.TERRAIN + "grey_brick_wall_cracked.png", tile.position, 1, 0)
		foundation.region_enabled = true
		foundation.region_rect = Rect2(1, 1, 30, 30)
		foundation.scale = Vector2.ONE * (64.0 / 30.0)
		foundation.modulate = Color("858b83") if row == 1 else Color("494c4c")
		foundation.modulate.a = smoothstep(3400.0, 6100.0, x)
	preload("res://scripts/stage_blend.gd").terrain(level,tile,row)

static func background(level: Node2D) -> void:
	var distant: Node2D = Node2D.new()
	distant.name = "DistantTown"
	distant.z_index = -18
	level.add_child(distant)
	var wash: ShaderMaterial = ShaderMaterial.new()
	wash.shader = preload("res://scripts/background_wash.gdshader")
	wash.set_shader_parameter("haze_color", Color("555169"))
	wash.set_shader_parameter("distance_fade", 0.70)
	for i: int in range(11):
		var path: String = Assets.HOUSES + ["haunted_manor.png", "dark_victorian_house.png", "crooked_spire_tower.png"][i % 3]
		var size: float = 5.5
		if i >= 4:
			path = VILLAGE + ["House.png", "House2.png", "House3.png", "Tavern green roof.png"][i % 4]
			size = 0.9 if i % 4 < 3 else 0.65
		var building: Sprite2D = Assets.sprite(distant, path, Vector2(130 + i * 365, 405), size)
		building.material = wash
	var trees: Node2D = Node2D.new()
	trees.name = "DistantForest"
	trees.z_index = -14
	level.add_child(trees)
	for i: int in range(18):
		var path: String = Assets.FOREST + "bare_branch_tree.png"
		if i >= 5:
			path = Biome.NATURE + (["bare_tree.png", "autumn_birch_tree.png", "golden_birch_tree.png"][i % 3] if i < 10 else ["oak_tree.png", "golden_birch_tree.png", "leafy_tree.png"][i % 3])
		var tree: Sprite2D = Assets.sprite(trees, path, Vector2(70 + i * 290, 442), 4.5)
		tree.material = wash

static func decorate(level: Node2D) -> void:
	for span: Vector2 in FLOORS:
		for x: int in range(int(span.x) + 55, int(span.y), 150):
			var path: String = Assets.DECOR + "wooden_picket_fence.png"
			if x > 1500:
				path = Biome.NATURE + ("broken_fence.png" if x < 2400 or x < 3500 and x % 3 == 0 else "fence_post_rail.png")
			if x > 5000:
				path = "res://Stages/Medievil Kingdom/6. Medieval Fortifications, Gates & Siege Structures/stone_bridge_railing.png"
			Assets.sprite(level, path, Vector2(x, 558), 3, -5).modulate = Color("8a7789").lerp(Color("c9ba98"), x / 6400.0)
	for x: float in [-40.0, 1500.0, 1980.0]:
		Assets.sprite(level, Assets.FOREST + "gnarled_dead_tree.png", Vector2(x, 495), 6.5, -4).modulate = Color("8b8094")
	for x: float in [560.0, 1450.0, 2030.0, 3020.0, 4070.0]:
		Assets.grounded(level, Assets.DECOR + "pumpkin_cluster.png", x, 2.0, -2)
	for x: float in [700.0, 2350.0, 3080.0]:
		Assets.grounded(level, Assets.HAZARDS + "cross_tombstone.png", x, 2.3, -3)
	for entry: Array in [["House.png", Vector2(2680, 504), 1.5], ["Stable or Storage.png", Vector2(3600, 523), 1.2], ["House3.png", Vector2(4070, 504), 1.5], ["shop.png", Vector2(5280, 486), 1.1], ["Tavern green roof.png", Vector2(5910, 512), 1.1]]:
		var house: Sprite2D = Assets.sprite(level, VILLAGE + str(entry[0]), entry[1], entry[2], -4)
		house.modulate = Color("a497a4").lerp(Color("e2d2b0"), (house.position.x - 2600) / 3400)
	for x: float in [5770.0]:
		Assets.grounded(level, VILLAGE + "market stall1.png", x, 1.0, -4).modulate = Color("b4a394")
	for x: float in [420.0, 1320.0, 2070.0, 2880.0, 3600.0, 4480.0, 4990.0, 5880.0, 6230.0]:
		Assets.sprite(level, VILLAGE + "Village Sheet Sprites/wooden_post.png", Vector2(x + 11, 542), 1.8, -2).modulate = Color("b9a38a")
		Assets.sprite(level, VILLAGE + "Village Sheet Sprites/wooden_beam_horizontal.png", Vector2(x + 1, 487), 0.5, -2).modulate = Color("b9a38a")
		Assets.sprite(level, Assets.HAZARDS + "hanging_lantern.png", Vector2(x, 505), 2.5, 2)
		level.lighting.add_glow(Vector2(x, 505), Color("ffd494"), 145)
	for x: float in [1664.0, 3136.0, 4608.0]:
		var pool: Node2D = preload("res://scripts/cursed_water.gd").new()
		pool.position = Vector2(x, 630)
		pool.width = 320 if x == 3136 else 256
		pool.clean = x > 2000
		pool.purity = Biome.greenery(x)
		level.add_child(pool)
	for x: float in [790.0, 2570.0, 3960.0, 4930.0]:
		Assets.sprite(level, Assets.HAZARDS + "bone_spike_row.png", Vector2(x, 583), 2, 3).modulate = Color("ffc2bd")
		level.hazards.append(Rect2(x - 26, 570, 52, 30))
		level.lighting.add_glow(Vector2(x, 588), Color("fb7775"), 65)
