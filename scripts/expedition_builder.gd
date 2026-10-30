extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Town = preload("res://scripts/town_builder.gd")
const Enemy = preload("res://scripts/haunt.gd")
const DARK: String = "res://Stages/Dark Fantasy/"
const FOREST: String = "res://Stages/Abandonded Forest/"

static func build(level: Node2D, floors: Array[Vector2], ledges: Array[Rect2]) -> void:
	preload("res://scripts/expedition_scenery.gd").build(level, floors)
	var woods: bool = level.chapter >= 7
	for span: Vector2 in floors:
		Town.solid(level, Rect2(span.x,600,span.y-span.x,220))
		for x: int in range(int(span.x),int(span.y),64):
			for row: int in range(4):
				var path: String = FOREST+"1. Overgrown Forest Ground & Terrain/"+("grass_ground_overgrown.png" if row == 0 and level.chapter == 7 else ("mossy_cobble_lichen.png" if row == 0 else "dark_soil.png")) if woods else DARK+"1. Ground & Terrain Tiles/"+(("cracked_flagstone.png" if level.chapter == 5 else "mossy_stone_floor.png") if row == 0 else "large_stone_brick.png")
				var tile: Sprite2D = Assets.sprite(level,path,Vector2(x+32,632+row*64),1,0)
				tile.region_enabled = true
				tile.region_rect = Rect2(1,1,30,31) if woods and level.chapter == 7 and row == 0 else (Rect2(1,5,30,26) if woods and row == 0 else Rect2(1,1,30,29))
				tile.scale = Vector2(64.0/tile.region_rect.size.x,64.0/tile.region_rect.size.y)
				tile.modulate = (Color("a8b69c") if woods else Color("9692ac")) * (Color.WHITE if row == 0 else (Color("777d79") if row == 1 else Color("41494d")))
				preload("res://scripts/stage_blend.gd").terrain(level,tile,row)
	for ledge: Rect2 in ledges:
		Town.solid(level,ledge,true)
		for x: int in range(int(ledge.position.x),int(ledge.end.x),64):
			var path: String = FOREST+"2. Overgrown Platforms & Broken Walkways/mossy_platform_long.png" if woods else DARK+"2. Platform Tiles/stone_slab_platform.png"
			var slab: Sprite2D = Assets.sprite(level,path,Vector2(x+32,ledge.position.y+10),1,1)
			slab.region_enabled = true
			# The slab's tapered outer edges are omitted between tiles so a solid
			# walkway cannot appear to have holes through its collision surface.
			slab.region_rect = Rect2(1,6,62,20) if woods else Rect2(6,10,18,15)
			slab.scale = Vector2(64.0/slab.region_rect.size.x,20.0/slab.region_rect.size.y)
			slab.modulate = Color("b5c2a0") if woods else Color("b7acc4")
	for gap: Vector2 in level.profile.gaps:
		var water: Node2D = preload("res://scripts/cursed_water.gd").new()
		water.position = Vector2(gap.x,630)
		water.width = gap.y-gap.x
		water.purity = {5:0.25,6:0.40,7:0.55,8:0.85}[level.chapter]
		level.add_child(water)
	var rosters: Dictionary = {
		5:[["guard",1040],["rat",2350],["guard",3650],["mushroom",4070],["guard",5250]],
		6:[["mushroom",980],["guard",2260],["rat",3500],["guard",3950],["guard",5180]],
		7:[["rat",1100],["mushroom",2450],["mushroom",3650],["rat",4160],["guard",5270]],
		8:[["mushroom",1070],["rat",2390],["guard",3670],["mushroom",4100],["guard",5200]]}
	for entry: Array in rosters[level.chapter]:
		spawn(level,entry[0],Vector2(entry[1],600))
	for entry: Array in [["witch" if level.chapter in [5,6] else ("mosquito" if level.chapter == 7 else "eye"),Vector2(1440,430)],["bat" if level.chapter in [6,7] else ("witch" if level.chapter == 8 else "eye"),Vector2(2830,380)],["eye" if level.chapter == 6 else ("mosquito" if level.chapter == 8 else "bat"),Vector2(4360,390)]]:
		spawn(level,entry[0],entry[1])
	for x: float in [780.0,2420.0,3980.0,5080.0]:
		var path: String = FOREST+"10. Forest Hazards, Natural Obstacles & Interactive Objects/"+("dry_spikes.png" if level.chapter == 7 else "thorn_spikes.png") if woods else DARK+"8. Hazards Pack/iron_floor_spikes.png"
		var spikes: Sprite2D = Assets.grounded(level,path,x,1.7 if woods else 1.6,3)
		spikes.modulate = Color("e3b69c")
		level.hazards.append(Rect2(x-26,570,52,30))
		level.lighting.add_glow(Vector2(x,588),Color("dc846c"),55)

static func spawn(level: Node2D, species: String, at: Vector2) -> void:
	var enemy: Node2D = Enemy.new()
	enemy.species = species
	enemy.flying = species in ["eye","bat","witch","mosquito"]
	enemy.health = 1 if species == "bat" else 2
	enemy.position = at
	level.add_child(enemy)
	enemy.defeated.connect(level.enemy_defeated)
