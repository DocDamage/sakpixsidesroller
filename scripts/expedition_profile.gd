extends RefCounted

const DARK: String = "res://Stages/Dark Fantasy/"
const FOREST: String = "res://Stages/Abandonded Forest/"
const LOOT: String = DARK + "9. Collectibles & Props/"
const GATES: String = DARK + "10. Doors, Windows & Architectural Pieces/"
const CAMP: String = FOREST + "9. Forgotten Campsites, Lost Objects & Woodland Props/"
const HAZARDS: String = FOREST + "10. Forest Hazards, Natural Obstacles & Interactive Objects/"
const BUILDERS: Array[Script] = [preload("res://scripts/ashen_builder.gd"),preload("res://scripts/cathedral_builder.gd"),preload("res://scripts/briarwood_builder.gd"),preload("res://scripts/elderroot_builder.gd")]
const TITLES: Array[String] = ["ASHEN RAMPARTS","HOLLOW CATHEDRAL","BRIARWOOD EXPANSE","ELDERROOT SANCTUARY"]
const COLORS: Array[Color] = [Color("d6a8eb"),Color("96c6ee"),Color("e3c88f"),Color("a5e3b4")]
const BOSSES: Array[String] = ["THE ASHEN SENTINEL","THE HOLLOW PRELATE","THE BRIAR MARSHAL","THE ROOTBOUND SOVEREIGN"]
const KEYS: Array[String] = ["CINDER WRIT","SANCTUM SIGIL","RANGER'S TOKEN","ELDERROOT WARD"]

static func configure(p: RefCounted, chapter: int) -> void:
	var i: int = chapter - 5
	p.builder = BUILDERS[i]
	p.details = preload("res://scripts/expedition_details.gd")
	p.title = TITLES[i]
	p.label = "%02d  /  %s" % [chapter,"THE SHADOW ROAD" if chapter < 7 else "THE FORGOTTEN WOODS"]
	p.seal_name = ["RUNE","SOUL","FRAGMENT","ROOT KEY"][i]
	p.seal_texture = [LOOT+"soul_crystal.png",LOOT+"moonstone_pendant.png",CAMP+"map_scroll.png",CAMP+"old_key.png"][i]
	p.seal_color = COLORS[i]
	p.coin_texture = LOOT + ("dark_rune_coin.png" if chapter == 5 else ("silver_coin.png" if chapter == 6 else "copper_face_coin.png"))
	p.coin_label = "RUNE COINS" if chapter < 7 else "TRAIL COINS"
	p.chest_texture = DARK+"7. Interactive Objects/"+("arcane_chest.png" if chapter == 5 else "skull_chest.png") if chapter < 7 else CAMP+"locked_strongbox.png"
	p.open_texture = DARK+"7. Interactive Objects/open_treasure_chest.png"
	p.exit_texture = GATES+"iron_gate_arched.png" if chapter < 7 else HAZARDS+"vine_cage_door.png"
	p.open_exit_texture = GATES+"iron_gate_open.png" if chapter < 7 else HAZARDS+"vine_cave_entrance.png"
	p.checkpoints.assign([2120.0,3640.0,5140.0])
	p.urns.assign([650.0,2020.0,3500.0,4950.0,6040.0])
	p.plants.assign([2730.0,4300.0])
	p.mimics.assign([Vector2(p.builder.LEDGES[1].get_center().x,p.builder.LEDGES[1].position.y),Vector2(p.builder.LEDGES[10].get_center().x,p.builder.LEDGES[10].position.y)])
	var gaps: Array[Vector2] = []
	for n: int in range(3):
		gaps.append(Vector2(p.builder.FLOORS[n].y,p.builder.FLOORS[n+1].x))
	p.gaps.assign(gaps)
	var seals: Array[Vector2] = []
	for n: int in [2,5,8]:
		seals.append(Vector2(p.builder.LEDGES[n].get_center().x,p.builder.LEDGES[n].position.y-50))
	p.seals.assign(seals)
	p.ground_coins.assign([390.0,450.0,p.builder.FLOORS[1].x+94,p.builder.FLOORS[1].x+154,p.builder.FLOORS[2].x+84,p.builder.FLOORS[2].x+144,p.builder.FLOORS[3].x+74,p.builder.FLOORS[3].x+134,6000.0,6060.0])
	p.regions.assign([
		["THE ASHEN ROAD","BROKEN BATTLEMENTS","THE CINDER CANAL","THE BLACK GATE"],
		["THE WEST NARTHEX","THE SILENT NAVE","THE SUNKEN CLOISTER","THE HOLLOW SANCTUM"],
		["THE OLD BORDER","THE LOST TRAIL","THE FORGOTTEN CAMP","THE BRIAR PASS"],
		["THE ROOTED PATH","THE ANCIENT GROVE","THE MOSS COURT","THE ELDER SANCTUARY"]][i])
	p.boss_name = BOSSES[i]
	p.boss_health = [10,12,10,14][i]
	p.boss_at = Vector2(5610,600)
	p.boss_hint = "Break the charge with a finisher. Jump the spreading flame."
	p.key_label = KEYS[i]
	p.key_locked = "SEALED"
	p.key_open = "FOUND"
	p.chest_goal = ["WRIT","SIGIL","TOKEN","WARD"][i]
	p.boss_goal = ["SENTINEL","PRELATE","MARSHAL","SOVEREIGN"][i]
	p.exit_goal = ["CATHEDRAL","WOODLAND","BRIAR PASS","DAYBREAK"][i]
	p.objective = ["RECOVER THREE ASHEN RUNES","GATHER THREE LOST SOULS","FIND THREE TRAIL FRAGMENTS","RESTORE THREE ROOT KEYS"][i]
	p.boss_objective = "DEFEAT " + BOSSES[i]
	p.key_objective = "CLAIM THE " + KEYS[i]
	p.exit_objective = ["ENTER THE HOLLOW CATHEDRAL","REACH THE FORGOTTEN WOODS","CROSS THE BRIAR PASS","OPEN THE DAYBREAK GATE"][i]
	p.chest_prompt = "[E] Claim the " + KEYS[i].capitalize()
	p.blocked_prompt = "Defeat " + BOSSES[i].capitalize() + " to release the ward."
	p.exit_prompt = ["[E] Enter the Hollow Cathedral","[E] Follow the woodland trail","[E] Cross the Briar Pass","[E] Welcome daybreak"][i]
	p.restored_prompt = "The ward is yours. Follow the lanterns right."
	p.completed_objective = ["RAMPARTS CLEARED","THE SANCTUM IS FREE","THE LOST TRAIL RESTORED","THE WOODS AWAKEN"][i]
	p.destination_label = ["CATHEDRAL","BRIARWOOD","ELDERROOT","DAYBREAK"][i]
	p.destination_state = "LEVEL %d" % (chapter+1) if chapter < 8 else "SAFE"
	p.intro_tag = "CHAPTER %d  /  %s" % [chapter,"BEYOND CROWNWARD" if chapter < 7 else "THE FORGOTTEN TRAIL"]
	p.intro_title = ["The ashes remember.","Hear the silent bells.","The trail has vanished.","Wake the oldest roots."][i]
	p.intro_text = "Find three markers. Defeat their keeper. Open the way."
	p.victory = ["THE BLACK GATE OPENS","THE BELLS RETURN","THE BRIAR PATH IS OPEN","THE WOODS AWAKEN"][i]
	p.victory_text = ["The cathedral rises beyond the cinder canal.","Beyond the cloister, the forgotten forest waits.","The last trail leads beneath the ancient roots.","From haunted town to elder grove, daybreak is yours."][i]
	if chapter == 8:
		p.exit_goal = "CATACOMBS"
		p.exit_objective = "DESCEND THE ROOTBOUND STAIR"
		p.exit_prompt = "[E] Descend beneath Elderroot"
		p.completed_objective = "THE ELDER WARD IS FREE"
		p.destination_label = "CATACOMBS"
		p.destination_state = "LEVEL 9"
		p.victory = "THE ROOT WAY OPENS"
		p.victory_text = "Under Elderroot, the ancient stair descends."
