extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Biome = preload("res://scripts/deep_biome.gd")

static func build(level: Node2D) -> void:
	var dungeon: bool = level.chapter <= 10
	var distant := Node2D.new()
	distant.name = "DistantTown"
	distant.z_index = -18
	level.add_child(distant)
	var middle := Node2D.new()
	middle.name = "DistantForest"
	middle.z_index = -14
	level.add_child(middle)
	var wash := ShaderMaterial.new()
	wash.shader = preload("res://scripts/background_wash.gdshader")
	wash.set_shader_parameter("haze_color",Color("293d4e") if dungeon else Color("4b706f"))
	wash.set_shader_parameter("distance_fade",0.66)
	if dungeon:
		for column: int in 35:
			for row: int in 4:
				var path: String = Biome.WALL+("mossy_dark_brick_wall.png" if level.chapter == 9 else "dark_grey_brick_wall.png")
				var wall: Sprite2D = Assets.sprite(distant,path,Vector2(column*128+64,192+row*128),1)
				wall.region_enabled = true
				wall.region_rect = Rect2(1,1,30,30)
				wall.scale = Vector2.ONE*(128.0/30)
				wall.modulate = Color("303c48") if level.chapter == 9 else Color("303248")
				if level.chapter == 10:
					wall.modulate.a = 1.0-smoothstep(2400,3400,column*128)
		for i: int in 16:
			var path: String = Biome.WALL+("stone_arch_doorway.png" if level.chapter == 9 else "gothic_arch_frame.png")
			if level.chapter == 9 and i < 4:
				path = "res://Stages/Abandonded Forest/6. Forgotten Ruins & Mossy Stone Structures/vine_temple_gate.png"
			if level.chapter == 10 and i >= 9:
				path = Biome.TREE+["willow_canopy_tree.png","windswept_oak_tree.png"][i%2]
			var visual: Sprite2D = Assets.grounded(middle,path,80+i*285,6.0,-1)
			visual.material = wash
		for column: int in 35:
			var band: Sprite2D = Assets.sprite(distant,Biome.WALL+("mossy_frieze_band.png" if level.chapter == 9 else "ornate_frieze_band.png"),Vector2(column*128+64,192),4,1)
			band.modulate = Color("55626a")
			if level.chapter == 10:
				band.modulate.a = 1.0-smoothstep(2400,3400,column*128)
		for i: int in 8:
			var relief: Sprite2D = Assets.sprite(distant,Biome.WALL+("mossy_statue_relief_wall.png" if level.chapter == 9 else "glyph_carved_wall.png"),Vector2(260+i*480,350),3.0,2)
			relief.modulate = Color("65747f")
	else:
		for i: int in 16:
			var path: String = Biome.TREE+["willow_canopy_tree.png","leafy_oak_tree.png","windswept_oak_tree.png"][i%3]
			if level.chapter == 11 and i < 4:
				path = Biome.RUIN+"glyph_stone_archway.png"
			var visual: Sprite2D = Assets.sprite(distant,path,Vector2(80+i*260,410),6.0)
			visual.material = wash
		for i: int in 18:
			var visual: Sprite2D = Assets.grounded(middle,Biome.RELIC+["rune_arch_gateway.png","mossy_cave_entrance.png","standing_stone.png"][i%3],80+i*285,4.8,-1)
			visual.material = wash
	preload("res://scripts/stage_entrance.gd").place(level)
	if dungeon:
		for i: int in 7:
			var x: float = [1160.0,2110.0,2790.0,3430.0,4160.0,4980.0,5800.0][i]
			var path: String = Biome.TOMB+"stone_arch.png" if level.chapter == 9 else Biome.RUIN+"glyph_stone_archway.png"
			if level.chapter == 10 and i >= 5:
				path = Biome.RELIC+"rune_arch_gateway.png"
			Assets.grounded(level,path,x,6.8,-8).modulate = Color("8a9ca9") if level.chapter == 9 else Color("a4aac0")
		for x: float in [1440.0,2790.0,4240.0,5380.0]:
			var crystal: Sprite2D = Assets.grounded(level,Biome.CAVE+"green_crystal_cluster.png" if level.chapter == 9 else Biome.CAVE+"blue_crystal_formation.png",x,2.6,-6)
			crystal.modulate = Color("9aa8c0")
			crystal.set_meta("dense_prop",true)
			level.lighting.add_glow(crystal.position,Color("82d5b54d") if level.chapter == 9 else Color("8bbfed4d"),90,crystal)
	else:
		for x: float in [810.0,2580.0,3910.0,5800.0]:
			var tree: Sprite2D = Assets.grounded(level,Biome.TREE+("windswept_oak_tree.png" if level.chapter == 11 else "willow_canopy_tree_glow.png"),x,5.2 if level.chapter == 11 else 5.8,-8)
			tree.modulate = Color("8caea4")
			tree.add_to_group("wind_foliage")
		for i: int in 4:
			var path: String = Biome.HOMES+(["log_cabin_green_roof.png","spotted_mushroom_cottage.png","leaf_roof_hut.png","treehouse_round.png"] if level.chapter == 11 else ["treehouse_round.png","spotted_mushroom_cottage.png","green_mushroom_house.png","treehouse_tall.png"])[i]
			Assets.grounded(level,path,[260.0,2250.0,3650.0,5050.0][i],4.7,-7).modulate = Color("b8c5b8")
		Assets.grounded(level,Biome.RELIC+"rune_arch_gateway.png",5760,6.5,-9).modulate = Color("97c3bb")
