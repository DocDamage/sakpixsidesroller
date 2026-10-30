extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
var chapter: int = 1
var builder: Variant = preload("res://scripts/town_builder.gd")
var details: Script = preload("res://scripts/world_details.gd")
var title: String = "WITCHING HOUR"
var label: String = "01  /  HALLOWEEN TOWN"
var regions: Array[String] = ["THE CROOKED QUARTER", "THE FORGOTTEN GRAVEYARD", "THE WITCH'S SWAMP", "THE MIDNIGHT RITUAL"]
var seals: Array[Vector2] = [Vector2(1280, 398), Vector2(2496, 334), Vector2(3904, 350)]
var checkpoints: Array[float] = [2150.0, 3650.0, 5000.0]
var ground_coins: Array[float] = [390.0, 450.0, 1880.0, 1940.0, 3200.0, 3260.0, 4600.0, 4660.0, 6030.0, 6090.0]
var plants: Array[float] = [2630.0, 4080.0]
var mimics: Array[Vector2] = [Vector2(930, 400), Vector2(4900, 464)]
var urns: Array[float] = [650.0, 2050.0, 3460.0, 4860.0, 5980.0]
var boss_name: String = "THE GRAVEKEEPER"
var boss_at: Vector2 = Vector2(5590, 600)
var boss_hint: String = "Jump the flame. Finish your combo to break the charge."
var seal_name: String = "SEAL"
var seal_texture: String = Assets.MAGIC + "void_crystal_gem.png"
var seal_color: Color = Color("ce97f4")
var objective: String = "BREAK THE THREE SEALS"
var boss_objective: String = "DEFEAT THE GRAVEKEEPER"
var key_objective: String = "TAKE THE MOON KEY"
var exit_objective: String = "REACH THE PORTAL"
var key_label: String = "MOON KEY"
var key_locked: String = "LOCKED"
var key_open: String = "FOUND"
var chest_texture: String = Assets.PROPS + "chained_chest.png"
var open_texture: String = Assets.HAZARDS + "open_chest.png"
var exit_texture: String = Assets.MAGIC + "purple_swirl_portal.png"
var open_exit_texture: String = Assets.MAGIC + "purple_swirl_portal.png"
var chest_prompt: String = "[E] Take the Moon Key"
var blocked_prompt: String = "Defeat the Gravekeeper to release the Moon Key."
var exit_prompt: String = "[E] Step into the dawn"
var intro_tag: String = "THE LAST LIGHT BEFORE MIDNIGHT"
var intro_title: String = "Three seals. One way home."
var intro_text: String = "Find the seals. Defeat their keeper. Take the Moon Key."
var victory: String = "DAWN IS YOURS"
var victory_text: String = "The curse is broken. The lantern road lies ahead."
var gaps: Array[Vector2] = [Vector2(1536, 1792), Vector2(2816, 3136), Vector2(4224, 4544)]
var chest_goal: String = "CHEST"
var boss_goal: String = "WARDEN"
var exit_goal: String = "PORTAL"
var completed_objective: String = "CURSE LIFTED"
var destination_label: String = "ROAD AHEAD"
var destination_state: String = "LEVEL 2"
var restored_prompt: String = "The portal is awake. Follow the light to the right."
var coin_texture: String = Assets.PROPS + "bat_coin.png"
var coin_label: String = "BAT COINS"
var boss_health: int = 8

func _init(number: int = 1) -> void:
	chapter = number
	if number >= 9:
		preload("res://scripts/deep_profile.gd").configure(self,number)
		return
	if number >= 5:
		preload("res://scripts/expedition_profile.gd").configure(self, number)
		return
	if number >= 3:
		preload("res://scripts/kingdom_profile.gd").configure(self, number)
		return
	if number != 2:
		return
	builder = preload("res://scripts/village_builder.gd")
	details = preload("res://scripts/village_details.gd")
	title = "THE LANTERN ROAD"
	label = "02  /  ROAD TO EMBERWICK"
	regions = ["ASHEN OUTSKIRTS", "THE PUMPKIN FIELDS", "THE LANTERN ROAD", "EMBERWICK APPROACH"]
	seals = [Vector2(1280, 398), Vector2(2880, 334), Vector2(4384, 350)]
	checkpoints = [2200.0, 3700.0, 5100.0]
	gaps = [Vector2(1664, 1920), Vector2(3136, 3456), Vector2(4608, 4864)]
	ground_coins = [390.0, 450.0, 2010.0, 2070.0, 3510.0, 3570.0, 4900.0, 4960.0, 6000.0, 6060.0]
	plants = [2940.0, 4460.0]
	mimics = [Vector2(864, 420), Vector2(5080, 464)]
	urns = [650.0, 2100.0, 3550.0, 5010.0, 5960.0]
	boss_name = "THE THORN MARSHAL"
	boss_at = Vector2(5610, 600)
	boss_hint = "Break the charge with your finisher. Jump the spreading flame."
	seal_name = "SPARK"
	seal_texture = Assets.MAGIC + "orange_flame.png"
	seal_color = Color("ffe0a5")
	objective = "GATHER THE HEARTH SPARKS"
	boss_objective = "DEFEAT THE THORN MARSHAL"
	key_objective = "OPEN THE VILLAGE WARD"
	exit_objective = "ENTER EMBERWICK"
	key_label = "VILLAGE WARD"
	key_locked = "SEALED"
	key_open = "OPEN"
	chest_texture = Assets.HAZARDS + "gothic_shrine.png"
	open_texture = Assets.MAGIC + "orange_flame.png"
	exit_texture = "res://Stages/Medievil Kingdom/6. Medieval Fortifications, Gates & Siege Structures/castle_gate_closed.png"
	open_exit_texture = "res://Stages/Medievil Kingdom/6. Medieval Fortifications, Gates & Siege Structures/castle_gate_open.png"
	chest_prompt = "[E] Lift the village ward"
	blocked_prompt = "Defeat the Thorn Marshal to lift the village ward."
	exit_prompt = "[E] Enter Emberwick"
	intro_tag = "CHAPTER TWO  /  THE ROAD HOME"
	intro_title = "Carry the dawn onward."
	intro_text = "Gather three hearth sparks. Clear the road to Emberwick."
	victory = "EMBERWICK REACHED"
	victory_text = "Emberwick's lanterns are lit. Follow the market road."
	chest_goal = "SHRINE"
	boss_goal = "MARSHAL"
	exit_goal = "GATE"
	completed_objective = "EMBERWICK IS SAFE"
	destination_label = "MARKET"
	destination_state = "LEVEL 3"
	restored_prompt = "The village ward is lifted. Follow the lanterns right."

func style_marker(marker: Node2D) -> void:
	marker.caption = seal_name
	marker.tint = seal_color
	marker.tint.a = 0.65
