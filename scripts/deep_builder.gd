extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Town = preload("res://scripts/town_builder.gd")
const Biome = preload("res://scripts/deep_biome.gd")
const Expedition = preload("res://scripts/expedition_builder.gd")

static func build(level: Node2D, floors: Array[Vector2], ledges: Array[Rect2]) -> void:
	preload("res://scripts/deep_scenery.gd").build(level)
	var dungeon: bool = level.chapter <= 10
	for span: Vector2 in floors:
		Town.solid(level,Rect2(span.x,600,span.y-span.x,220))
		for x: int in range(int(span.x),int(span.y),64):
			for row: int in 4:
				var style: Dictionary = Biome.terrain_style(level.chapter,row)
				var tile: Sprite2D = Assets.sprite(level,style.path,Vector2(x+32,632+row*64),1,0)
				tile.region_enabled = true
				tile.region_rect = style.crop
				tile.scale = Vector2(64.0/style.crop.size.x,64.0/style.crop.size.y)
				tile.modulate = style.tint
				preload("res://scripts/stage_blend.gd").terrain(level,tile,row)
	for ledge: Rect2 in ledges:
		Town.solid(level,ledge,true)
		for x: int in range(int(ledge.position.x),int(ledge.end.x),64):
			var path: String = Biome.LEDGE+("cracked_stone_platform.png" if level.chapter == 9 else "gold_trim_platform.png") if dungeon else Biome.SOIL+("grass_ground_top.png" if level.chapter == 11 else "mossy_cobble_ground.png")
			var crop: Rect2 = Rect2(6,8,20,10) if level.chapter == 9 else (Rect2(6,6,20,10) if level.chapter == 10 else (Rect2(1,14,30,10) if level.chapter == 11 else Rect2(2,1,28,10)))
			var platform: Sprite2D = Assets.sprite(level,path,Vector2(x+32,ledge.position.y+10),1,1)
			platform.region_enabled = true
			platform.region_rect = crop
			platform.scale = Vector2(64.0/crop.size.x,20.0/crop.size.y)
			platform.modulate = Color("b4b9cf") if dungeon else Color("bdd8cf")
	for gap: Vector2 in level.profile.gaps:
		var water: Node2D = preload("res://scripts/cursed_water.gd").new()
		water.position = Vector2(gap.x,630)
		water.width = gap.y-gap.x
		water.purity = {9:0.35,10:0.65,11:0.85,12:1.0}[level.chapter]
		level.add_child(water)
	var rosters: Dictionary = {
		9:[["rat",1010],["guard",2310],["guard",3540],["mushroom",4070],["guard",5250]],
		10:[["guard",1060],["mushroom",2370],["guard",3620],["rat",4100],["guard",5230]],
		11:[["mushroom",1080],["rat",2390],["mushroom",3560],["guard",4090],["guard",5220]],
		12:[["mushroom",990],["guard",2330],["mushroom",3500],["rat",4050],["guard",5190]]}
	for entry: Array in rosters[level.chapter]:
		Expedition.spawn(level,entry[0],Vector2(entry[1],600))
	for entry: Array in [["eye" if level.chapter == 9 else ("witch" if level.chapter == 10 else "mosquito"),Vector2(1430,430)],["mosquito" if level.chapter == 9 else ("bat" if level.chapter == 11 else "eye"),Vector2(2810,380)],["witch" if level.chapter in [9,12] else "eye",Vector2(4350,390)]]:
		Expedition.spawn(level,entry[0],entry[1])
	for x: float in [780.0,2420.0,3980.0,5080.0]:
		var path: String = Biome.TRAP+"floor_spike_trap.png" if dungeon else Biome.THORN+("red_thorn_spike.png" if level.chapter == 11 else "amethyst_spikes.png")
		Assets.grounded(level,path,x,1.7,3).modulate = Color("ecc0bb")
		level.hazards.append(Rect2(x-26,570,52,30))
		level.lighting.add_glow(Vector2(x,588),Color("ca919b"),50)
