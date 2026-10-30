extends "res://scripts/world_details.gd"

func setup(owner_level: Node2D) -> void:
	level = owner_level
	preload("res://scripts/road_biome.gd").setup(level)
	for x: float in [420.0, 2465.0, 3890.0, 5420.0]:
		var fire: Sprite2D = preload("res://scripts/upright_campfire.gd").place(self,x)
		fires.append(fire)
		level.lighting.add_glow(fire.position, Color("ffd494"), 140, fire)
	add_actor("Cartographer", "Wizard with a map.png", Vector2(320, 600), 6,
		"The same path, a different dawn. Bring three hearth sparks to the village ward.")
	add_actor("Lantern Keeper", "Sitting Witch.png", Vector2(5210, 600), 5,
		"The Thorn Marshal bars Emberwick. Break his charge; then lift the ward at the shrine.")
	add_actor("Beekeeper", "Beekeeper .png", Vector2(3800, 600), 5,
		"The orchard is growing again. Follow the high lanterns for the last hearth spark.")
	add_actor("Bard", "Bard.png", Vector2(5970, 600), 5,
		"Beyond this gate is the market road. Three royal crests will lead you to Crownward.")
	for x: float in [120.0, 1530.0, 2030.0]:
		Assets.sprite(self, Assets.DECOR + "autumn_leaf_pile.png", Vector2(x, 598), 2, 7)
	for x: float in [2050.0, 3020.0, 3500.0, 4010.0, 4500.0, 4960.0, 6010.0]:
		Assets.sprite(self, GROWTH + "fern.png", Vector2(x, 591), 2, 2).modulate = Color("adb594")
	for x: float in [1980.0, 3540.0, 4990.0]:
		Assets.sprite(self, DARK + "firewood_stack.png", Vector2(x, 582), 2, -2)
	for x: float in [560.0, 1340.0, 2820.0]:
		Assets.sprite(self, Assets.CRYPT + "open_stone_coffin.png", Vector2(x, 571), 2.3, -2).modulate = Color("a597ae")
	for x: float in [2670.0, 3000.0]:
		Assets.sprite(self, Assets.FOREST + "toxic_green_mushrooms.png", Vector2(x, 586), 1.8, 2)
	for x: float in [2380.0, 3690.0, 5000.0, 6130.0]:
		Assets.sprite(self, Assets.DECOR + "pumpkin_sign.png", Vector2(x, 555), 2.6, -2)
	for x: float in [5410.0, 5780.0]:
		Assets.sprite(self, Assets.HAZARDS + "gargoyle_statue.png", Vector2(x, 548), 3.3, -2).modulate = Color("b3ad9f")
	for x: float in [500.0,1250.0,2400.0,4350.0,5700.0]:
		Assets.roadside_lantern(self,level.lighting,x)
	preload("res://scripts/world_motion.gd").install(level, self)
