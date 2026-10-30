extends Node2D

# Shared landmarks straddle chapter boundaries, while props stay on solid banks.
const Assets = preload("res://scripts/level_assets.gd")
const Kingdom = preload("res://scripts/kingdom_builder.gd")
var level: Node2D
var signs: Array[Dictionary] = []
var cloth: Array[Sprite2D] = []

static func install(owner_level: Node2D) -> void:
	var details: Node2D = load("res://scripts/journey_details.gd").new()
	details.name = "JourneyDetails"
	owner_level.add_child(details)
	details.setup(owner_level)

func prop(folder: String, file: String, x: float, scale: float = 1.8, depth: int = -2) -> Sprite2D:
	return Kingdom.grounded(self, folder + file + ".png", x, scale, depth)

func signpost(x: float, text: String, scale: float = 2.5) -> void:
	prop(Kingdom.LIFE, "wooden_signpost", x, scale)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("f0d6a3"))
	var width: float = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	label.position = Vector2(x - width / 2 - 10, 450)
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("191f2be6")
	plate.content_margin_left = 10
	plate.content_margin_right = 10
	plate.content_margin_top = 5
	plate.content_margin_bottom = 5
	label.add_theme_stylebox_override("normal", plate)
	label.z_index = 8
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	signs.append({"x": x, "label": label})

func banner(x: float, _y: float, scale: float = 2.2) -> void:
	# This asset includes its pole; the similarly named crown_banner_a is only a rod.
	var flag: Sprite2D = prop(Kingdom.CASTLE, "banner_on_pole", x, scale, -4)
	flag.material = level.get_node("WorldMotion").breeze
	cloth.append(flag)

func royal_approach(x: float, flag_x: float) -> void:
	prop(Kingdom.LIFE, "covered_merchant_wagon", x, 2.1, -3)
	banner(flag_x, 445, 2.3)

func setup(owner_level: Node2D) -> void:
	level = owner_level
	if level.chapter in [2,7]:
		preload("res://scripts/stage_entrance.gd").place(level)
	if level.chapter >= 5:
		signpost(580, level.profile.destination_label + "  >", 2.0)
		bank_details()
		return
	match level.chapter:
		1:
			signpost(520, "THE LANTERN ROAD  >")
			for x: float in [660.0, 2110.0, 3940.0, 5360.0]:
				prop(Assets.DECOR, "autumn_leaf_pile", x, 1.4, 1).modulate = Color("b3a0ad")
			for x: float in [1830.0, 3400.0, 6060.0]:
				prop(Kingdom.LIFE, "broken_open_crate", x, 1.5).modulate = Color("a392ae")
		2:
			signpost(5800, "EMBERWICK MARKET  >")
			banner(6310, 468, 2.5)
		3:
			preload("res://scripts/stage_entrance.gd").place(level).modulate = Color("b5b8a3")
			banner(185, 468, 2.5)
			signpost(520, "MARKET LANES  >")
			signpost(5790, "CROWNWARD KEEP  >")
			royal_approach(5860, 5720)
			for entry: Array in [["pottery_shelf_a", 2680], ["barrel_on_side", 4070]]:
				prop(Kingdom.LIFE, entry[0], entry[1], 1.8)
			for x: float in [4830.0, 5300.0]:
				banner(x, 450)
		4:
			royal_approach(930, 860)
			var shop: Sprite2D = prop(Kingdom.HOUSES, "striped_awning_shop", 1450, 4.0, -7)
			shop.modulate = Color("9ca6a4")
			preload("res://scripts/kingdom_lighting.gd").warm_window(level, shop, 0.35)
			signpost(520, "CROWN SANCTUM  >")
			for entry: Array in [["weapon_rack", 1350], ["workbench", 5850]]:
				prop(Kingdom.LIFE, entry[0], entry[1], 2.0)
	bank_details()

func bank_details() -> void:
	for gap: Vector2 in level.profile.gaps:
		for x: float in [gap.x - 23, gap.y + 23]:
			if level.chapter >= 9:
				var biome = preload("res://scripts/deep_biome.gd")
				Assets.grounded(self,biome.CAVE+"mossy_rock_pair.png" if level.chapter <= 10 else biome.LIFE+"mossy_rock.png",x,1.2,-2)
			elif level.chapter >= 7:
				Assets.grounded(self,"res://Stages/Abandonded Forest/5. Abandoned Trails, Wooden Bridges & Forest Traversal/cairn_stones.png",x,1.2,-2)
			elif level.chapter >= 3:
				Assets.grounded(self, Kingdom.FORT + "stone_bridge_support.png", x, 2, -1, 652)
			else:
				prop(Kingdom.NATURE, "small_rocks_scattered_a", x, 1.0, -1).modulate = Color("a7a295")

func _process(_delta: float) -> void:
	if level == null:
		return
	for sign: Dictionary in signs:
		var distance: float = level.player.position.distance_to(Vector2(sign["x"], 600))
		var label: Label = sign["label"]
		label.visible = not level.completed and distance < 190
		label.modulate.a = 1.0 - smoothstep(120, 190, distance)
