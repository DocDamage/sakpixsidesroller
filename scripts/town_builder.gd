extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Enemy = preload("res://scripts/haunt.gd")
const FLOORS: Array[Vector2] = [Vector2(0, 1536), Vector2(1792, 2816), Vector2(3136, 4224), Vector2(4544, 6400)]
const LEDGES: Array[Rect2] = [Rect2(512, 480, 192, 30), Rect2(832, 400, 192, 30), Rect2(1152, 448, 256, 30), Rect2(1600, 512, 128, 30), Rect2(2048, 480, 192, 30), Rect2(2368, 384, 256, 30), Rect2(2912, 496, 128, 30), Rect2(3424, 480, 192, 30), Rect2(3776, 400, 256, 30), Rect2(4352, 496, 128, 30), Rect2(4800, 464, 192, 30), Rect2(5152, 400, 192, 30)]

static func build(level: Node2D) -> void:
	background(level)
	for span: Vector2 in FLOORS:
		solid(level, Rect2(span.x, 600, span.y - span.x, 220))
		for x: int in range(int(span.x), int(span.y), 64):
			for row: int in range(4):
				terrain_tile(level, x, row)
	for rect: Rect2 in LEDGES:
		solid(level, rect, true)
		for x: int in range(int(rect.position.x), int(rect.end.x), 64):
			var wooden: bool = rect.position.x < 1000 or (rect.position.x > 2800 and rect.position.x < 3700)
			var plank: Sprite2D = Assets.sprite(level, Assets.PLATFORMS + ("wooden_plank_ledge.png" if wooden else "purple_stone_platform.png"), Vector2(x + 32, rect.position.y + (8 if wooden else 17)), 1.0, 1)
			plank.region_enabled = true
			plank.region_rect = Rect2(1, 14, 30, 8) if wooden else Rect2(1, 10, 30, 17)
			plank.scale = Vector2(64.0 / 30.0, 2.0)
		# Short brackets make platforms readable without chains cutting across the sky.
		for dx: float in [20.0, rect.size.x - 20.0]:
			Assets.sprite(level, Assets.PLATFORMS + "wooden_bracket_shelf.png", Vector2(rect.position.x + dx, rect.position.y + 14), 1.3, -1).modulate = Color("8a7f9b")
	decorate(level)
	for x: float in [990.0, 2260.0, 3360.0, 4730.0]:
		var enemy: Node2D = Enemy.new()
		if x == 3360:
			enemy.species = "mushroom"
		enemy.position = Vector2(x, 600)
		level.add_child(enemy)
		enemy.defeated.connect(level.enemy_defeated)
	for pos: Vector2 in [Vector2(1450, 430), Vector2(2690, 390), Vector2(4050, 370), Vector2(5300, 380)]:
		var bat: Node2D = Enemy.new()
		bat.flying = true
		if pos.x == 4050:
			bat.species = "eye"
		elif pos.x == 2690:
			bat.species = "mosquito"
		bat.health = 1
		bat.position = pos
		level.add_child(bat)
		bat.defeated.connect(level.enemy_defeated)
	level.add_child(preload("res://scripts/encounter_details.gd").new())

static func solid(level: Node2D, rect: Rect2, one_way: bool = false) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 4 if one_way else 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = one_way
	body.add_child(shape)
	level.add_child(body)

static func background(level: Node2D) -> void:
	var distant: Node2D = Node2D.new()
	distant.name = "DistantTown"
	distant.z_index = -18
	level.add_child(distant)
	var town_material: ShaderMaterial = ShaderMaterial.new()
	town_material.shader = preload("res://scripts/background_wash.gdshader")
	town_material.set_shader_parameter("haze_color", Color("454059"))
	town_material.set_shader_parameter("distance_fade", 0.72)
	for i: int in range(10):
		var house: String = ["haunted_manor.png", "dark_victorian_house.png", "crooked_spire_tower.png", "haunted_house_crooked.png"][i % 4]
		var visual: Sprite2D = Assets.sprite(distant, Assets.HOUSES + house, Vector2(140 + i * 365, 395 - (i % 3) * 14), 5.0 + float(i % 3) * 0.5)
		visual.material = town_material
	var forest: Node2D = Node2D.new()
	forest.name = "DistantForest"
	forest.z_index = -14
	level.add_child(forest)
	var forest_material: ShaderMaterial = ShaderMaterial.new()
	forest_material.shader = town_material.shader
	forest_material.set_shader_parameter("haze_color", Color("383344"))
	forest_material.set_shader_parameter("distance_fade", 0.66)
	for i: int in range(18):
		var tree: String = ["gnarled_dead_tree.png", "dark_hollow_tree.png", "bare_branch_tree.png"][i % 3]
		var visual: Sprite2D = Assets.sprite(forest, Assets.FOREST + tree, Vector2(80 + i * 285, 442), 4.5 + float(i % 2))
		visual.material = forest_material
	for span: Vector2 in FLOORS:
		for x: int in range(int(span.x) + 55, int(span.y), 140):
			Assets.sprite(level, Assets.DECOR + "wooden_picket_fence.png", Vector2(x, 558), 3.0, -5).modulate = Color("847080")

static func decorate(level: Node2D) -> void:
	for x: float in [80.0, 1410.0, 1880.0, 2710.0, 3240.0, 4140.0, 4610.0, 5920.0, 6320.0]:
		Assets.grounded(level, Assets.DECOR + "pumpkin_cluster.png", x, 2.2, -2)
	for x: float in [590.0, 1840.0, 2320.0, 3290.0, 3970.0, 5370.0, 5820.0]:
		Assets.grounded(level, Assets.HAZARDS + "cross_tombstone.png", x, 2.5, -3)
	for x: float in [50.0, 1510.0, 2800.0, 4200.0, 4570.0, 6020.0]:
		Assets.sprite(level, Assets.FOREST + "gnarled_dead_tree.png", Vector2(x, 495), 6.5, -4).modulate = Color("8b8094")
	Assets.grounded(level, Assets.DECOR + "stone_well.png", 1950, 2.4, -2)
	Assets.grounded(level, Assets.DECOR + "pumpkin_scarecrow.png", 4650, 2.8, -2)
	Assets.sprite(level, Assets.CRYPT + "mausoleum_entrance.png", Vector2(2390, 470), 7.0, -6).modulate = Color("a18da8")
	Assets.sprite(level, Assets.CRYPT + "small_mausoleum.png", Vector2(2720, 498), 6.0, -6).modulate = Color("a18da8")
	for x: float in [3220.0, 3550.0, 4020.0]:
		Assets.sprite(level, Assets.SWAMP + "dead_swamp_tree.png", Vector2(x, 480), 7.5, -6).modulate = Color("8ca29c")
	for x: float in [3160.0, 3310.0, 3480.0, 3710.0, 4000.0, 4170.0]:
		Assets.sprite(level, Assets.SWAMP + "cattail_reeds.png", Vector2(x, 567), 3.0, -2).modulate = Color("afbec0")
	Assets.sprite(level, Assets.SWAMP + "hanging_potion_rack.png", Vector2(4110, 549), 3.0, 2)
	for x: float in [5470.0, 5620.0]:
		Assets.grounded(level, Assets.HAZARDS + "gargoyle_statue.png", x, 2.5, -5)
	var rune: Sprite2D = Assets.sprite(level, Assets.MAGIC + "purple_summoning_circle.png", Vector2(5590, 597), 1.0, 1)
	rune.scale = Vector2(3.2, 0.55)
	rune.modulate.a = 0.65
	Assets.grounded(level, Assets.DECOR + "witch_cauldron.png", 5830, 2.4, -2)
	for x: float in [5800.0, 5840.0]:
		Assets.sprite(level, Assets.MAGIC + "green_spirit_flame.png", Vector2(x, 491), 2.0, 3)
	for x: float in [1536.0, 2816.0, 4224.0]:
		var pool: Node2D = preload("res://scripts/cursed_water.gd").new()
		pool.position = Vector2(x, 630)
		pool.width = 256.0 if x == 1536 else 320.0
		level.add_child(pool)
	for x: float in [790.0, 2460.0, 3590.0, 4920.0]:
		Assets.sprite(level, Assets.HAZARDS + "bone_spike_row.png", Vector2(x, 583), 2.0, 3).modulate = Color("ffc2bd")
		level.lighting.add_glow(Vector2(x, 588), Color("fb7775"), 65)
		level.hazards.append(Rect2(x - 26, 570, 52, 30))
	for x: float in [430.0, 1320.0, 1900.0, 2740.0, 3260.0, 4100.0, 4700.0, 5940.0]:
		Assets.sprite(level, Assets.VILLAGE + "Village Sheet Sprites/wooden_post.png", Vector2(x + 11, 542), 1.8, -2).modulate = Color("97839b")
		Assets.sprite(level, Assets.VILLAGE + "Village Sheet Sprites/wooden_beam_horizontal.png", Vector2(x + 1, 487), 0.5, -2).modulate = Color("97839b")
		Assets.sprite(level, Assets.HAZARDS + "hanging_lantern.png", Vector2(x, 505), 2.5, 2)
		level.lighting.add_glow(Vector2(x, 505), Color("ffc47c"), 145)
	for x: float in [110.0, 1440.0, 2060.0, 2670.0, 3180.0, 4000.0, 4780.0, 5680.0, 6340.0]:
		Assets.grounded(level, Assets.DECOR + "autumn_leaf_pile.png", x, 1.5, -1).modulate = Color("9a8398")

static func terrain_tile(level: Node2D, x: int, row: int) -> void:
	var region: int = mini(3, x / 1600)
	var path: String = Assets.GROUND + ("orange_ground_top.png" if row == 0 else "mossy_stone_wall.png")
	var crop: Rect2 = Rect2(1, 10, 30, 22) if row == 0 else Rect2(1, 1, 30, 31)
	var tint: Color = Color.WHITE
	if region == 1:
		path = Assets.GROUND + ("grass_ground_top.png" if row == 0 else "purple_stone_brick.png")
		crop = Rect2(1, 11, 30, 21) if row == 0 else Rect2(1, 1, 30, 31)
		tint = Color("b7adc8")
	elif region == 2:
		path = Assets.SWAMP + ("mossy_mud_ground.png" if row == 0 else "mossy_mud_block.png")
		crop = Rect2(0, 7, 32, 25) if row == 0 else Rect2(0, 12, 32, 20)
		tint = Color("8a9d8f")
	elif region == 3:
		path = Assets.GROUND + ("orange_ground_top.png" if row == 0 else "purple_stone_brick.png")
		tint = Color("c3a2cc") if row == 0 else Color("c3adc9")
	var tile: Sprite2D = Assets.sprite(level, path, Vector2(x + 32, 632 + row * 64), 1.0, 0)
	tile.region_enabled = true
	tile.region_rect = crop
	tile.scale = Vector2(64.0 / crop.size.x, 64.0 / crop.size.y)
	if row > 0:
		tint *= Color("706681") if row == 1 else Color("4b415c")
	tile.modulate = tint
	preload("res://scripts/stage_blend.gd").terrain(level,tile,row)
