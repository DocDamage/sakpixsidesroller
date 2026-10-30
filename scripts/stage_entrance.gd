extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Biome = preload("res://scripts/deep_biome.gd")
const ROYAL: String = "res://Stages/Medievil Kingdom/6. Medieval Fortifications, Gates & Siege Structures/castle_gate_open.png"
const IRON: String = "res://Stages/Dark Fantasy/10. Doors, Windows & Architectural Pieces/iron_gate_open.png"
const VINE: String = "res://Stages/Abandonded Forest/10. Forest Hazards, Natural Obstacles & Interactive Objects/vine_cave_entrance.png"

static func path(chapter: int) -> String:
	return {2:Assets.MAGIC+"purple_swirl_portal.png",3:ROYAL,4:ROYAL,5:ROYAL,6:IRON,7:IRON,8:VINE,9:VINE,10:Biome.DOOR+"iron_gate_open_pair.png",11:Biome.RELIC+"rune_arch_gateway.png",12:Biome.HOMES+"vine_tree_doorway.png"}.get(chapter,"")

static func place(level: Node2D, depth: int = -8) -> Sprite2D:
	var gate: Sprite2D = Assets.grounded(level,path(level.chapter),90,5.5,depth)
	gate.modulate = Color("a7abb1") if level.chapter < 7 else Color("9baa9b")
	if level.chapter == 2:
		gate.modulate = Color("d0b3eb")
		gate.z_index = -3
		level.lighting.add_glow(gate.position,Color("bf94dc70"),95,gate)
	gate.add_to_group("stage_entrances")
	gate.set_meta("from_chapter",level.chapter-1)
	return gate
