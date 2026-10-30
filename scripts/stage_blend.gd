extends RefCounted

# Border strips borrow the neighbouring pack. The two sides meet at a 50/50 mix;
# authored terrain, collision and dressing stay intact through the stage interior.
const Assets = preload("res://scripts/level_assets.gd")
const Campaign = preload("res://scripts/campaign_state.gd")
const Deep = preload("res://scripts/deep_biome.gd")
const KINGDOM: String = "res://Stages/Medievil Kingdom/1. Medieval Terrain & Cobblestone Ground/"
const DARK: String = "res://Stages/Dark Fantasy/1. Ground & Terrain Tiles/"
const WOODS: String = "res://Stages/Abandonded Forest/1. Overgrown Forest Ground & Terrain/"
const WIDTH: float = 1536.0

static func weight(x: float, entering: bool) -> float:
	return 0.5*(1.0-smoothstep(0,WIDTH,x)) if entering else 0.5*smoothstep(6400-WIDTH,6400,x)

static func terrain_style(chapter: int, row: int, entering: bool = false) -> Dictionary:
	if chapter >= 9:
		return Deep.terrain_style(chapter,row)
	var path: String
	var crop := Rect2(1,1,30,30)
	var tint := Color.WHITE
	if chapter <= 2:
		path = Assets.GROUND+("orange_ground_top.png" if row == 0 else "purple_stone_brick.png")
		crop = Rect2(1,10,30,22) if row == 0 else Rect2(1,1,30,31)
		tint = Color("c3a2cc") if row == 0 else Color("c3adc9")
		if chapter == 2:
			path = Assets.GROUND+("orange_ground_top.png" if row == 0 else "mossy_stone_wall.png") if entering else (Assets.GROUND+"grass_ground_top.png" if row == 0 else KINGDOM+"grey_brick_wall_cracked.png")
			crop = Rect2(1,10,30,22) if entering and row == 0 else (Rect2(1,11,30,21) if row == 0 else Rect2(1,1,30,30))
			tint = Color("c3a2cc") if entering else Color("dbd5aa")
		if row > 0:
			tint *= Color("706681") if row == 1 else Color("4b415c")
			if chapter == 2:
				tint = Color("c3a2cc")*(Color("6f647e") if row == 1 else Color("484050")) if entering else (Color("858b83") if row == 1 else Color("494c4c"))
	elif chapter <= 4:
		path = KINGDOM+(("cracked_flagstone.png" if chapter == 3 else "sandstone_cobble.png") if row == 0 else "grey_brick_wall_cracked.png")
		tint = Color("c6c3a5") if chapter == 3 else Color("9cabb5")
		if row > 0:
			tint *= Color("858b8c") if row == 1 else Color("4a5057")
	else:
		if chapter <= 6:
			path = DARK+(("cracked_flagstone.png" if chapter == 5 else "mossy_stone_floor.png") if row == 0 else "large_stone_brick.png")
			crop = Rect2(1,1,30,29)
		else:
			path = WOODS+(("grass_ground_overgrown.png" if chapter == 7 else "mossy_cobble_lichen.png") if row == 0 else "dark_soil.png")
			crop = Rect2(1,1,30,31) if chapter == 7 and row == 0 else (Rect2(1,5,30,26) if row == 0 else Rect2(1,1,30,29))
		tint = Color("a8b69c") if chapter >= 7 else Color("9692ac")
		if row > 0:
			tint *= Color("777d79") if row == 1 else Color("41494d")
	return {"path":path,"crop":crop,"tint":tint}

static func terrain(level: Node2D, tile: Sprite2D, row: int) -> void:
	var x: float = tile.position.x-32
	var entering: bool = x < WIDTH
	var neighbour: int = level.chapter-1 if entering else level.chapter+1
	if neighbour < 1 or neighbour > Campaign.STAGES or (not entering and x < 6400-WIDTH):
		return
	var amount: float = weight(x,entering)
	if amount <= 0:
		return
	var style: Dictionary = terrain_style(neighbour,row,not entering)
	var overlay: Sprite2D = Assets.sprite(level,style.path,tile.position,1,tile.z_index)
	overlay.region_enabled = true
	overlay.region_rect = style.crop
	overlay.scale = Vector2(64.0/style.crop.size.x,64.0/style.crop.size.y)
	overlay.modulate = style.tint
	overlay.modulate.a = amount
	overlay.add_to_group("transition_ground")
	overlay.set_meta("neighbour",neighbour)
	overlay.set_meta("terrain_row",row)

static func native_sky(chapter: int, x: float) -> Array[Color]:
	if chapter >= 9:
		return Deep.sky(chapter)
	if chapter >= 5:
		var palette: Array[Color] = []
		palette.assign([[Color("181b2b"),Color("6c4c63")],[Color("0f202d"),Color("314c5e")],[Color("192a29"),Color("5d6655")],[Color("263c38"),Color("879c79")]][chapter-5])
		return palette
	var upper := Color("101326")
	var lower := Color("40304c")
	if chapter == 1:
		var swamp: float = clampf(1.0-absf(x-3750)/1000.0,0,1)
		return [upper.lerp(Color("10252d"),swamp),lower.lerp(Color("324d4a"),swamp)]
	var road: float = clampf((x-500)/5900.0,0,1) if chapter == 2 else 0.82
	var daylight: float = 0.25+road*0.55
	upper = upper.lerp(Color("625574"),daylight).lerp(Color("637887"),road*0.8)
	lower = lower.lerp(Color("d79b78"),daylight).lerp(Color("e7c897"),road*0.8)
	var castle: float = 1.0 if chapter == 4 else (smoothstep(4000,6400,x) if chapter == 3 else 0.0)
	return [upper.lerp(Color("283850"),castle*0.7),lower.lerp(Color("819ca8"),castle*0.7)]

static func sky(chapter: int, x: float) -> Array[Color]:
	var colors: Array[Color] = native_sky(chapter,x)
	var entering: bool = x < WIDTH
	var neighbour: int = chapter-1 if entering else chapter+1
	if neighbour >= 1 and neighbour <= Campaign.STAGES:
		var other: Array[Color] = native_sky(neighbour,6400 if entering else 0)
		for i: int in 2:
			colors[i] = colors[i].lerp(other[i],weight(x,entering))
	return colors
