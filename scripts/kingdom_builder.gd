extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Town = preload("res://scripts/town_builder.gd")
const Enemy = preload("res://scripts/haunt.gd")
const Fixtures = preload("res://scripts/kingdom_lighting.gd")
const ROOT: String = "res://Stages/Medievil Kingdom/"
const GROUND: String = ROOT + "1. Medieval Terrain & Cobblestone Ground/"
const LEDGE: String = ROOT + "2. Castle Platforms & Defensive Walkways/"
const CASTLE: String = ROOT + "3. Medieval Castles & Royal Architecture/"
const HOUSES: String = ROOT + "4. Medieval Village Houses & Market Buildings/"
const FORT: String = ROOT + "6. Medieval Fortifications, Gates & Siege Structures/"
const LIFE: String = ROOT + "8. Medieval Props, Furniture & Village Life/"
const NATURE: String = ROOT + "9. Medieval Nature, Forest Edges & Farmland/"

static func grounded(parent: Node, path: String, x: float, scale: float, depth: int = -4) -> Sprite2D:
	return Assets.grounded(parent, path, x, scale, depth)

static func build(level: Node2D, floors: Array[Vector2], ledges: Array[Rect2], keep: bool) -> void:
	background(level, keep)
	for span: Vector2 in floors:
		Town.solid(level, Rect2(span.x, 600, span.y - span.x, 220))
		for x: int in range(int(span.x), int(span.y), 64):
			for row: int in range(4):
				var file: String = ("sandstone_cobble.png" if keep else "cracked_flagstone.png") if row == 0 else "grey_brick_wall_cracked.png"
				var tile: Sprite2D = Assets.sprite(level, GROUND + file, Vector2(x + 32, 632 + row * 64), 1, 0)
				tile.region_enabled = true
				tile.region_rect = Rect2(1, 1, 30, 30)
				tile.scale = Vector2.ONE * (64.0 / 30)
				tile.modulate = (Color("9cabb5") if keep else Color("c6c3a5")) * (Color.WHITE if row == 0 else (Color("858b8c") if row == 1 else Color("4a5057")))
				preload("res://scripts/stage_blend.gd").terrain(level,tile,row)
	for platform: Rect2 in ledges:
		Town.solid(level, platform, true)
		for x: int in range(int(platform.position.x), int(platform.end.x), 64):
			var slab: Sprite2D = Assets.sprite(level, LEDGE + "stone_slab_platform.png", Vector2(x + 32, platform.position.y + 10), 1, 1)
			slab.region_enabled = true
			# Crop the filled slab. Transparent side padding produced a row of
			# disconnected frames instead of a continuous defensive walkway.
			slab.region_rect = Rect2(3, 10, 26, 10)
			slab.scale = Vector2(64.0 / 26, 2.0)
			slab.modulate = Color("a6b5c4") if keep else Color("c8bda5")
		for dx: float in [20.0, platform.size.x - 20]:
			Assets.sprite(level, LEDGE + "stone_ledge_bracket.png", platform.position + Vector2(dx, 25), 1.4, -1).modulate = Color("8d949d")
	for gap: Vector2 in level.profile.gaps:
		var water: Node2D = preload("res://scripts/cursed_water.gd").new()
		water.position = Vector2(gap.x, 630)
		water.width = gap.y - gap.x
		water.clean = true
		water.purity = 0.9 if keep else 1.0
		level.add_child(water)
	architecture(level, floors, keep)
	var ground_roster: Array = [["rat", 1010], ["guard", 2380], ["mushroom", 3500], ["rat", 3930], ["guard", 5180]] if not keep else [["guard", 1100], ["mushroom", 2410], ["guard", 3620], ["rat", 4110], ["guard", 5170]]
	for entry: Array in ground_roster:
		spawn(level, entry[0], Vector2(entry[1], 600))
	for entry: Array in ([["bat", Vector2(1460, 430)], ["eye", Vector2(2860, 390)], ["bat", Vector2(4380, 400)]] if not keep else [["eye", Vector2(1510, 430)], ["bat", Vector2(2950, 390)], ["eye", Vector2(4450, 400)]]):
		spawn(level, "witch" if entry[1].x > 4300 else entry[0], entry[1])
	for x: float in ([740.0, 2350.0, 3840.0, 4910.0] if not keep else [800.0, 2450.0, 3980.0, 4920.0]):
		grounded(level, Assets.HAZARDS + "bone_spike_row.png", x, 2, 3).modulate = Color("ffc2bd")
		level.hazards.append(Rect2(x - 26, 570, 52, 30))
		level.lighting.add_glow(Vector2(x, 588), Color("fb7775"), 65)

static func spawn(level: Node2D, species: String, at: Vector2) -> void:
	var enemy: Node2D = Enemy.new()
	enemy.species = species
	enemy.flying = species in ["bat", "eye", "witch", "mosquito"]
	enemy.health = 1 if species == "bat" else 2
	enemy.position = at
	level.add_child(enemy)
	enemy.defeated.connect(level.enemy_defeated)

static func background(level: Node2D, keep: bool) -> void:
	var wash := ShaderMaterial.new()
	wash.shader = preload("res://scripts/background_wash.gdshader")
	wash.set_shader_parameter("haze_color", Color("647783") if keep else Color("777a78"))
	wash.set_shader_parameter("distance_fade", 0.73)
	var distant := Node2D.new()
	distant.name = "DistantTown"
	distant.z_index = -18
	level.add_child(distant)
	for i: int in range(16):
		# At this parallax speed, the royal skyline enters the market's final third.
		# The keep retains town roofs behind its first gate before the towers take over.
		var royal: bool = (i >= 3 if keep else i >= 8)
		var file: String = CASTLE + ["gold_trim_crown_tower.png", "mossy_round_tower.png", "gatehouse_portcullis.png"][i % 3] if royal else HOUSES + ["tall_timber_house.png", "red_roof_gable_house.png", "blue_roof_townhouse.png"][i % 3]
		if keep and i >= 8:
			file = "res://Stages/Dark Fantasy/10. Doors, Windows & Architectural Pieces/"+["gothic_chapel_tower.png","stone_archway_ruined.png","portcullis_arch.png"][i%3]
		var visual: Sprite2D = Assets.sprite(distant, file, Vector2(100 + i * 250, 410), 7.5 if royal else 5.5)
		visual.material = wash
	var middle := Node2D.new()
	middle.name = "DistantForest"
	middle.z_index = -14
	level.add_child(middle)
	for i: int in range(18):
		var file: String = FORT + "crenellated_wall.png" if keep or i >= 11 else NATURE + ["oak_tree.png", "golden_birch_tree.png"][i % 2]
		var visual: Sprite2D = Assets.sprite(middle, file, Vector2(80 + i * 285, 458), 5)
		visual.material = wash

static func architecture(level: Node2D, floors: Array[Vector2], keep: bool) -> void:
	if not keep:
		for x: float in [260.0, 1070.0]:
			Assets.sprite(level, Assets.VILLAGE + "House3.png", Vector2(x, 504), 1.5, -5).modulate = Color("d1c4ac")
		for entry: Array in [["striped_awning_shop.png", 2040], ["bakery_shop_front.png", 2550], ["stone_house_chimney.png", 3490], ["tavern_shop_front.png", 3970], ["blue_roof_shop.png", 5080]]:
			var shop: Sprite2D = grounded(level, HOUSES + str(entry[0]), entry[1], 6.2)
			shop.modulate = Color("c5bda9")
			Fixtures.warm_window(level, shop, 0.70 - smoothstep(4000, 5400, entry[1]) * 0.25)
		for x: float in [1180.0, 2550.0, 3930.0]:
			grounded(level, HOUSES + "produce_market_stall.png", x, 2.7, -2)
		grounded(level, CASTLE + "gatehouse_portcullis.png", 5740, 7.5, -7).modulate = Color("aeb1ac")
		for x: float in [4900.0, 5320.0, 6030.0]:
			grounded(level, FORT + "mossy_rampart_wall.png", x, 5.2, -8).modulate = Color("aeb4ae")
	else:
		for entry: Array in [["gatehouse_portcullis.png", 260], ["mossy_round_tower.png", 1050], ["royal_banner_wall.png", 2150], ["gold_trim_crown_tower.png", 2720], ["stone_archway.png", 3500], ["royal_banner_wall.png", 4060], ["ornate_palace_entrance.png", 5620], ["gold_trim_crown_tower.png", 6070]]:
			var structure: Sprite2D = preload("res://scripts/stage_entrance.gd").place(level,-6) if entry[1] == 260 else grounded(level, CASTLE + str(entry[0]), entry[1], 8.0, -6)
			structure.modulate = Color("a2afba")
			Fixtures.mark_structure(structure)
		for x: float in [2020.0, 2910.0, 3450.0, 4350.0, 5000.0, 5850.0]:
			grounded(level, CASTLE + "marble_column.png", x, 4.6, -4).modulate = Color("a2b0bc")
	for span: Vector2 in floors:
		for x: int in range(int(span.x) + 50, int(span.y), 160):
			grounded(level, FORT + "iron_fence.png" if keep or x >= 4800 else NATURE + "rail_fence.png", x, 2.6, -5).modulate = Color("929c99")
	var lamps: Array = [220.0, 1200.0, 2570.0, 3670.0, 4220.0, 5390.0, 6070.0, 6350.0] if keep else [220.0, 1200.0, 1920.0, 2760.0, 3460.0, 4220.0, 5390.0, 6070.0, 6350.0]
	for x: float in lamps:
		grounded(level, LIFE + "lantern_post.png", x, 3.3, -2)
		level.lighting.add_glow(Vector2(x, 520), Color("ffd399"), 115)
