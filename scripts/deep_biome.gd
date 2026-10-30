extends RefCounted

const DUNGEON: String = "res://Stages/Dungeon/"
const MAGIC: String = "res://Stages/Magic Forest/"
const FLOOR: String = DUNGEON+"1. Dungeon Stone Floors & Terrain/"
const LEDGE: String = DUNGEON+"2. Dungeon Platforms & Traversal Structures/"
const WALL: String = DUNGEON+"3. Dungeon Walls & Architectural Modules/"
const TOMB: String = DUNGEON+"4. Catacombs & Burial Chambers/"
const CAVE: String = DUNGEON+"5. Underground Caverns & Natural Formations/"
const RUIN: String = DUNGEON+"7. Ancient Ruins & Forgotten Temples/"
const DOOR: String = DUNGEON+"8. Dungeon Doors, Gates & Mechanisms/"
const LOOT: String = DUNGEON+"9. Dungeon Props, Loot & Ancient Relics/"
const TRAP: String = DUNGEON+"10. Traps, Hazards & Dungeon Gameplay Objects/"
const SOIL: String = MAGIC+"1. Enchanted Ground & Forest Floor/"
const TREE: String = MAGIC+"2. Giant Trees & Root Systems/"
const FLORA: String = MAGIC+"3. Magical Flora & Mushrooms/"
const HOMES: String = MAGIC+"5. Fairy Village & Woodland Architecture/"
const RELIC: String = MAGIC+"6. Ancient Ruins & Stone Relics/"
const SPELL: String = MAGIC+"7. Magical Energy & Spell Effects/"
const LIFE: String = MAGIC+"8. Forest Wildlife & Ambient Props/"
const GEMS: String = MAGIC+"9. Enchanted Treasures & Collectibles/"
const THORN: String = MAGIC+"10. Cursed Forest Obstacles & Natural Hazards/"

static func terrain_style(chapter: int, row: int) -> Dictionary:
	var dungeon: bool = chapter <= 10
	var path: String
	var crop := Rect2(1,1,30,30)
	if dungeon:
		path = FLOOR+("mossy_stone_floor.png" if chapter == 9 else "rune_floor_tile.png") if row == 0 else WALL+("mossy_dark_brick_wall.png" if chapter == 9 else "dark_grey_brick_wall.png")
		if chapter == 10 and row == 0:
			crop = Rect2(2,2,28,27)
	else:
		path = SOIL+("grass_ground_top.png" if chapter == 11 else "mossy_cobble_ground.png") if row == 0 else SOIL+("dark_soil_fill.png" if chapter == 11 else "mossy_ground_block.png")
		if chapter == 11 and row == 0:
			crop = Rect2(1,14,30,18)
	if chapter == 12 and row == 0:
		crop = Rect2(2,1,28,30)
	var tint := Color("8e9fa8") if dungeon else Color("abcac0")
	if row > 0:
		tint *= Color("75898c") if row == 1 else Color("3e5057")
	return {"path":path,"crop":crop,"tint":tint}

static func sky(chapter: int) -> Array[Color]:
	var palette: Array[Color] = []
	palette.assign([[Color("0d1721"),Color("253947")],[Color("121827"),Color("284256")],[Color("1c3040"),Color("568a83")],[Color("2a294b"),Color("9695b8")]][chapter-9])
	return palette
