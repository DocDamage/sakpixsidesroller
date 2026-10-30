extends RefCounted

const ROOT: String = "res://Stages/Medievil Kingdom/"
const LOOT: String = ROOT + "10. Medieval Collectibles, Interactive Objects & Royal Details/"
const GATES: String = ROOT + "6. Medieval Fortifications, Gates & Siege Structures/"

static func configure(p: RefCounted, number: int) -> void:
	p.details = preload("res://scripts/kingdom_details.gd")
	p.coin_texture = LOOT + "gold_coin.png"
	p.coin_label = "GOLD COINS"
	p.seal_name = "CREST" if number == 3 else "SIGIL"
	p.seal_texture = LOOT + ("royal_medallion.png" if number == 3 else "sapphire.png")
	p.seal_color = Color("f0ce8b") if number == 3 else Color("a0d5ff")
	p.chest_texture = LOOT + "jewel_chest.png"
	p.open_texture = LOOT + "open_gold_chest.png"
	p.exit_texture = GATES + "castle_gate_closed.png"
	p.open_exit_texture = GATES + "castle_gate_open.png"
	p.checkpoints.assign([2150.0, 3600.0, 5100.0])
	p.urns.assign([650.0, 2050.0, 3550.0, 5010.0, 5960.0])
	p.chest_goal = "WRIT" if number == 3 else "CROWN"
	p.boss_goal = "CAPTAIN" if number == 3 else "REGENT"
	p.exit_goal = "KEEP" if number == 3 else "ASHEN ROAD"
	p.key_label = "GATE WRIT" if number == 3 else "CROWN WARD"
	p.key_locked = "SEALED"
	p.key_open = "OPEN"
	p.boss_health = 10 if number == 3 else 12
	p.boss_hint = "Break his charge. Jump the spreading flame."
	p.objective = "GATHER THREE MARKET CRESTS" if number == 3 else "RESTORE THREE CROWN SIGILS"
	p.boss_objective = "DEFEAT THE GATE CAPTAIN" if number == 3 else "DEFEAT THE HOLLOW REGENT"
	p.key_objective = "CLAIM THE GATE WRIT" if number == 3 else "LIFT THE CROWN WARD"
	p.exit_objective = "ENTER CROWNWARD KEEP" if number == 3 else "OPEN THE ASHEN ROAD"
	p.chest_prompt = "[E] Claim the Gate Writ" if number == 3 else "[E] Lift the Crown Ward"
	p.blocked_prompt = "Defeat the Gate Captain to release the writ." if number == 3 else "Defeat the Hollow Regent to lift the crown ward."
	p.exit_prompt = "[E] Enter Crownward Keep" if number == 3 else "[E] Follow the Ashen Road"
	p.restored_prompt = "The writ is yours. The keep gate lies to the right." if number == 3 else "The crown is free. Follow the Ashen Road to the right."
	p.completed_objective = "MARKET ROAD CLEARED" if number == 3 else "THE KINGDOM IS FREE"
	p.destination_label = "CROWNWARD" if number == 3 else "ASHEN ROAD"
	p.destination_state = "LEVEL 4" if number == 3 else "LEVEL 5"
	if number == 3:
		p.builder = preload("res://scripts/market_builder.gd")
		p.title = "EMBERWICK MARKET"
		p.label = "03  /  THE KINGDOM ROAD"
		p.regions.assign(["THE ORCHARD GATE", "THE MARKET LANES", "THE CANAL QUARTER", "THE ROYAL APPROACH"])
		p.seals.assign([Vector2(1280, 398), Vector2(2688, 334), Vector2(4128, 350)])
		p.gaps.assign([Vector2(1600, 1856), Vector2(2944, 3264), Vector2(4480, 4736)])
		p.ground_coins.assign([390.0, 450.0, 1950.0, 2010.0, 3340.0, 3400.0, 4800.0, 4860.0, 6000.0, 6060.0])
		p.plants.assign([2810.0, 4340.0])
		p.mimics.assign([Vector2(928, 416), Vector2(5040, 464)])
		p.boss_name = "THE GATE CAPTAIN"
		p.boss_at = Vector2(5610, 600)
		p.intro_tag = "CHAPTER THREE  /  BEYOND THE VILLAGE GATE"
		p.intro_title = "The market bells are silent."
		p.intro_text = "Recover three crests. Free the road to the keep."
		p.victory = "THE ROAD IS OPEN"
		p.victory_text = "The market wakes. Crownward's banners rise ahead."
	else:
		p.builder = preload("res://scripts/keep_builder.gd")
		p.title = "CROWNWARD KEEP"
		p.label = "04  /  THE LAST CROWN WARD"
		p.regions.assign(["THE OUTER BAILEY", "THE BANNER WALL", "THE MOON COURT", "THE CROWN SANCTUM"])
		p.seals.assign([Vector2(1408, 398), Vector2(2816, 334), Vector2(4288, 350)])
		p.gaps.assign([Vector2(1728, 1984), Vector2(3072, 3392), Vector2(4544, 4800)])
		p.ground_coins.assign([390.0, 450.0, 2070.0, 2130.0, 3470.0, 3530.0, 4870.0, 4930.0, 6000.0, 6060.0])
		p.plants.assign([2950.0, 4430.0])
		p.mimics.assign([Vector2(992, 420), Vector2(5088, 464)])
		p.boss_name = "THE HOLLOW REGENT"
		p.boss_at = Vector2(5610, 600)
		p.intro_tag = "CHAPTER FOUR  /  THE HEART OF THE KINGDOM"
		p.intro_title = "Break the final ward."
		p.intro_text = "Find three crown sigils. End the Regent's vigil."
		p.victory = "THE KINGDOM AWAKES"
		p.victory_text = "Crownward is free. A shadow road leads beyond the wall."
