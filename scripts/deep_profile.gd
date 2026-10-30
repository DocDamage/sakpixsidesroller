extends RefCounted

const Biome = preload("res://scripts/deep_biome.gd")
const BUILDERS: Array[Script] = [preload("res://scripts/rootbound_catacombs_builder.gd"),preload("res://scripts/prism_vault_builder.gd"),preload("res://scripts/lumenwood_trail_builder.gd"),preload("res://scripts/starfall_glade_builder.gd")]
const TITLES: Array[String] = ["ROOTBOUND CATACOMBS","THE PRISM VAULT","LUMENWOOD TRAIL","STARFALL GLADE"]
const BOSSES: Array[String] = ["THE CRYPT MARSHAL","THE PRISM WARDEN","THE LUMEN SENTINEL","THE ASTRAL KEEPER"]
const KEYS: Array[String] = ["OSSUARY WRIT","PRISM SIGIL","GROVE TOKEN","STARFALL WARD"]

static func configure(p: RefCounted, chapter: int) -> void:
	var i: int = chapter-9
	var dungeon: bool = chapter <= 10
	p.builder = BUILDERS[i]
	p.details = preload("res://scripts/deep_details.gd")
	p.title = TITLES[i]
	p.label = "%02d  /  %s" % [chapter,"BENEATH THE ROOTS" if dungeon else "THE LIVING FOREST"]
	p.seal_name = ["CRYPT RUNE","VAULT KEY","RUNE SHARD","WORLD SEED"][i]
	p.seal_texture = [Biome.LOOT+"dark_crystal_relic.png",Biome.LOOT+"gold_skull_key.png",Biome.GEMS+"blue_rune_shard.png",Biome.GEMS+"green_seed.png"][i]
	p.seal_color = [Color("9ec7df"),Color("c1b2f0"),Color("8fdecf"),Color("dfb7f1")][i]
	p.coin_texture = Biome.LOOT+"gold_coin_pile.png" if dungeon else Biome.GEMS+("fairy_coin.png" if chapter == 11 else "gold_clover_coin.png")
	p.coin_label = "GOLD CACHES" if dungeon else ("FAIRY COINS" if chapter == 11 else "CLOVER COINS")
	p.chest_texture = Biome.LOOT+("iron_chest.png" if dungeon else "ornate_treasure_chest.png")
	p.open_texture = Biome.LOOT+"open_red_chest.png" if dungeon else Biome.GEMS+"treasure_chest.png"
	p.exit_texture = [Biome.DOOR+"arched_iron_gate.png",Biome.RUIN+"vine_temple_double_door.png",Biome.HOMES+"wooden_vine_gate.png",Biome.SPELL+"dark_stone_portal.png"][i]
	p.open_exit_texture = [Biome.DOOR+"iron_gate_open_pair.png",Biome.RELIC+"rune_arch_gateway.png",Biome.HOMES+"vine_tree_doorway.png",Biome.SPELL+"golden_frame_portal.png"][i]
	p.checkpoints.assign([2120.0,3640.0,5140.0])
	p.urns.assign([650.0,2020.0,3500.0,4950.0,6040.0])
	p.plants.assign([2730.0,4300.0])
	p.mimics.assign([Vector2(p.builder.LEDGES[1].get_center().x,p.builder.LEDGES[1].position.y),Vector2(p.builder.LEDGES[10].get_center().x,p.builder.LEDGES[10].position.y)])
	var gaps: Array[Vector2] = []
	for n: int in 3:
		gaps.append(Vector2(p.builder.FLOORS[n].y,p.builder.FLOORS[n+1].x))
	p.gaps.assign(gaps)
	var markers: Array[Vector2] = []
	for n: int in [2,5,8]:
		markers.append(Vector2(p.builder.LEDGES[n].get_center().x,p.builder.LEDGES[n].position.y-50))
	p.seals.assign(markers)
	p.ground_coins.assign([390.0,450.0,p.builder.FLOORS[1].x+94,p.builder.FLOORS[1].x+154,p.builder.FLOORS[2].x+84,p.builder.FLOORS[2].x+144,p.builder.FLOORS[3].x+74,p.builder.FLOORS[3].x+134,6000.0,6060.0])
	p.regions.assign([
		["THE ROOT STAIR","THE MOSS GALLERIES","THE FLOODED OSSUARY","THE CRYPT WATCH"],
		["THE IRON VESTIBULE","THE GLYPH HALL","THE CRYSTAL CISTERN","THE OPEN VAULT"],
		["THE VAULT'S EDGE","THE LANTERN GROVE","THE FAIRY CROSSING","THE LUMEN PASS"],
		["THE LIVING ARCH","THE MUSHROOM HAMLET","THE STANDING STONES","THE STARFALL HEART"]][i])
	p.boss_name = BOSSES[i]
	p.boss_health = [10,12,12,14][i]
	p.boss_at = Vector2(5610,600)
	p.boss_hint = "Break the charge with a finisher. Jump the spreading flame."
	p.key_label = KEYS[i]
	p.key_locked = "SEALED"
	p.key_open = "FOUND"
	p.chest_goal = ["WRIT","SIGIL","TOKEN","WARD"][i]
	p.boss_goal = ["MARSHAL","WARDEN","SENTINEL","KEEPER"][i]
	p.exit_goal = ["PRISM VAULT","LUMENWOOD","STARFALL","DAYBREAK"][i]
	p.objective = ["RECOVER THREE CRYPT RUNES","FIND THREE VAULT KEYS","GATHER THREE RUNE SHARDS","RESTORE THREE WORLD SEEDS"][i]
	p.boss_objective = "DEFEAT "+BOSSES[i]
	p.key_objective = "CLAIM THE "+KEYS[i]
	p.exit_objective = ["ENTER THE PRISM VAULT","EMERGE INTO LUMENWOOD","FOLLOW THE STARFALL PATH","OPEN THE STARFALL GATE"][i]
	p.chest_prompt = "[E] Claim the "+KEYS[i].capitalize()
	p.blocked_prompt = "Defeat "+BOSSES[i].capitalize()+" to release the ward."
	p.exit_prompt = ["[E] Enter the Prism Vault","[E] Emerge into Lumenwood","[E] Follow the Starfall path","[E] Welcome daybreak"][i]
	p.restored_prompt = "The ward is yours. Follow the lanterns right."
	p.completed_objective = ["THE CRYPT IS UNSEALED","THE VAULT IS OPEN","LUMENWOOD IS RESTORED","THE FOREST BREATHES"][i]
	p.destination_label = ["PRISM VAULT","LUMENWOOD","STARFALL","DAYBREAK"][i]
	p.destination_state = "LEVEL %d" % (chapter+1) if chapter < 12 else "SAFE"
	p.intro_tag = "CHAPTER %d  /  %s" % [chapter,"THE HIDDEN DESCENT" if dungeon else "THE ENCHANTED ROAD"]
	p.intro_title = ["Beneath the oldest roots.","The vault remembers light.","Step into the living green.","Let the forest breathe."][i]
	p.intro_text = "Find three markers. Defeat their keeper. Open the way."
	p.victory = ["THE OSSUARY OPENS","LIGHT BEYOND THE VAULT","THE STARFALL ROAD OPENS","DAYBREAK IS YOURS"][i]
	p.victory_text = ["The old glyphs lead deeper into the crystal vault.","Roots and light spill through the broken vault.","The last path leads to the forest's living heart.","From haunted town through hidden roots, the forest is free."][i]
