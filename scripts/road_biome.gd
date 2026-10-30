extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const NATURE: String = "res://Stages/Medievil Kingdom/9. Medieval Nature, Forest Edges & Farmland/"
const LIFE: String = "res://Stages/Medievil Kingdom/8. Medieval Props, Furniture & Village Life/"
const FARM: String = "res://Stages/Farming/GandalfHardcore Farming Tiles and Crops 32x32/Farming Sprites/"
const TERRAIN: String = "res://Stages/Medievil Kingdom/1. Medieval Terrain & Cobblestone Ground/"

static func greenery(x: float) -> float:
	return smoothstep(1050.0, 4100.0, x)

static func grass_blend(x: float) -> float:
	# Broad organic patches fade between packs without a visible tile boundary.
	var weight: float = greenery(x)
	return clampf(weight + sin(x * 0.009) * 0.14 * 4.0 * weight * (1.0 - weight), 0, 1)

static func prop(parent: Node, path: String, at: Vector2, scale: float, depth: int = -2) -> Sprite2D:
	var visual: Sprite2D = Assets.grounded(parent, path, at.x, scale, depth)
	visual.modulate = Color("8c8197").lerp(Color("e0d8b4"), smoothstep(1000.0, 6100.0, at.x))
	return visual

static func setup(level: Node2D) -> void:
	var roadside := Node2D.new()
	roadside.name = "RoadsideLife"
	level.add_child(roadside)
	for entry: Array in [["autumn_birch_tree", 1180.0, 4.3], ["golden_birch_tree", 2050.0, 5.3], ["autumn_birch_tree", 2990.0, 4.0], ["oak_tree", 3510.0, 5.4], ["golden_birch_tree", 3820.0, 4.6], ["leafy_tree", 4520.0, 4.8], ["oak_tree", 5060.0, 5.6], ["leafy_tree", 6260.0, 5.0]]:
		var scale: float = entry[2]
		prop(roadside, NATURE + str(entry[0]) + ".png", Vector2(entry[1], 600 - scale * 15), scale, -5)
	for x: float in [2380.0, 2740.0, 3680.0, 4010.0, 4320.0, 5960.0]:
		prop(roadside, FARM + "apple_tree.png", Vector2(x, 531), 4.6, -5)
	for span: Vector2 in [Vector2(2100, 2370), Vector2(2640, 2770), Vector2(3570, 3840), Vector2(4180, 4370)]:
		for x: int in range(int(span.x), int(span.y), 42):
			prop(roadside, NATURE + "tilled_soil_rows.png", Vector2(x, 594), 1.6, -3)
			var crop: String = "wheat_stage5.png" if span.x < 3000 else ("carrot_stage5.png" if x % 3 == 0 else "cabbage_stage5.png")
			prop(roadside, FARM + crop, Vector2(x, 577), 1.45, -2)
	for entry: Array in [["scarecrow", Vector2(2300, 557), 2.8], ["hay_cart", Vector2(2700, 562), 2.5], ["hay_bale", Vector2(2780, 582), 1.7], ["grain_sacks", Vector2(3490, 573), 2.0], ["wheelbarrow", Vector2(4140, 574), 2.1], ["wooden_handcart", Vector2(5290, 566), 2.0], ["wooden_bench_backrest", Vector2(6335, 575), 1.8]]:
		prop(roadside, LIFE + str(entry[0]) + ".png", entry[1], entry[2])
	for entry: Array in [["apple_basket", 6040.0]]:
		prop(roadside, FARM + str(entry[0]) + ".png", Vector2(entry[1], 580), 1.65)
	for x: float in [1480.0, 2010.0, 2450.0, 2870.0, 3060.0, 3560.0, 4100.0, 4490.0, 5040.0, 6060.0, 6310.0]:
		prop(roadside, NATURE + ("grass_tufts_a.png" if x < 3000 else "wildflowers.png"), Vector2(x, 589), 1.6, 1)
	for x: float in [3660.0, 4090.0, 4380.0, 6350.0]:
		prop(roadside, NATURE + "flowering_bush.png", Vector2(x, 579), 1.8, -3)
	for entry: Array in [["House.png", Vector2(2680, 504)], ["House3.png", Vector2(4070, 504)], ["shop.png", Vector2(5280, 486)], ["Tavern green roof.png", Vector2(5910, 512)]]:
		var x: float = entry[1].x
		if x > 5000:
			prop(roadside, LIFE + "hanging_shop_sign.png", Vector2(x + (180 if x > 5800 else 80), 504), 1.6, -2)
	# A thin, broken-to-maintained paving strip sits below the walkable surface.
	for x: int in range(3520, 6400, 32):
		if x >= 4608 and x < 4864 or x % 96 == 0 and x < 4700:
			continue
		var stone: Sprite2D = Assets.sprite(roadside, TERRAIN + "cracked_flagstone.png", Vector2(x + 16, 606), 1, 1)
		stone.region_enabled = true
		stone.region_rect = Rect2(1, 1, 30, 9)
		stone.scale = Vector2(32.0 / 30.0, 1.3)
		stone.modulate.a = smoothstep(3400.0, 5800.0, x)
