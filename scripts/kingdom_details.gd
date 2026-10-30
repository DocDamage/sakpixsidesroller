extends "res://scripts/world_details.gd"

const Kingdom = preload("res://scripts/kingdom_builder.gd")
var banners: Array[Sprite2D] = []

func setup(owner_level: Node2D) -> void:
	level = owner_level
	var keep: bool = level.chapter == 4
	var camps: Array = [420.0, 2670.0, 3760.0, 4830.0] if keep else [420.0, 2480.0, 4020.0, 4830.0]
	for x: float in camps:
		var fire: Sprite2D = preload("res://scripts/upright_campfire.gd").place(self,x)
		fires.append(fire)
		level.lighting.add_glow(fire.position, Color("ffc78b"), 130, fire)
	if not keep:
		add_actor("Seamstress", "Seemstress.png", Vector2(320, 600), 6, "The market crests lie above the lanes. Carry three to the Captain's strongbox.")
		add_actor("Cook", "Knight Cooking.png", Vector2(2200, 600), 12, "Guards commit to their swings. Dodge behind them, then finish your combo.")
		add_actor("Gate Knight", "Kneeling knight.png", Vector2(5980, 600), 8, "The Captain's writ opens Crownward. The final ward still waits inside.")
		for entry: Array in [["bread_basket.png", 1290], ["wooden_table.png", 2260], ["grain_sacks.png", 2610], ["stone_well.png", 3720], ["blacksmith_anvil.png", 4140], ["weapon_rack.png", 5310]]:
			Kingdom.grounded(self, Kingdom.LIFE + str(entry[0]), entry[1], 2.0, -2)
		for x: float in [1330.0, 1930.0, 3430.0, 4240.0, 4900.0, 6350.0]:
			Kingdom.grounded(self, Kingdom.NATURE + "flowering_bush.png", x, 2.0, -3)
		for x: float in [1370.0, 3760.0]:
			banners.append(Kingdom.grounded(self, Kingdom.NATURE + "golden_birch_tree.png", x, 4.0, -7))
	else:
		add_actor("Knight", "Kneeling knight.png", Vector2(320, 600), 8, "Three crown sigils hold the sanctum closed. The Hollow Regent guards the last ward.")
		add_actor("Quartermaster", "Heavy Knight.png", Vector2(2200, 600), 16, "Light strikes stop the guards. A heavy finisher breaks the Regent's charge armor.")
		add_actor("Bishop", "Bishop.png", Vector2(5980, 600), 5, "The crown ward opens the royal gate. The Ashen Road leads to the cathedral.")
		for entry: Array in [["weapon_rack.png", 710], ["training_dummy.png", 2330], ["grindstone.png", 2780], ["iron_banded_chest.png", 4330], ["coal_pile.png", 5310]]:
			Kingdom.grounded(self, Kingdom.LIFE + str(entry[0]), entry[1], 2.0, -2)
		for x: float in [1300.0, 2050.0, 2890.0, 3470.0, 4280.0, 5270.0, 6330.0]:
			var banner: Sprite2D = Kingdom.grounded(self, Kingdom.CASTLE + "banner_on_pole.png", x, 3.5, -4)
			banners.append(banner)
		preload("res://scripts/kingdom_lighting.gd").mount_torches(level, self)
	preload("res://scripts/world_motion.gd").install(level, self)
	for banner: Sprite2D in banners:
		banner.material = level.get_node("WorldMotion").breeze
