extends RefCounted

const SCENES: Array[String] = ["res://scenes/halloween_town.tscn", "res://scenes/lantern_road.tscn", "res://scenes/emberwick_market.tscn", "res://scenes/crownward_keep.tscn", "res://scenes/ashen_ramparts.tscn", "res://scenes/hollow_cathedral.tscn", "res://scenes/briarwood_expanse.tscn", "res://scenes/elderroot_sanctuary.tscn", "res://scenes/rootbound_catacombs.tscn", "res://scenes/prism_vault.tscn", "res://scenes/lumenwood_trail.tscn", "res://scenes/starfall_glade.tscn"]
const STAGES: int = 12
static var unlocked_chapter: int = 1
static var results: Dictionary = {}

static func record(level: Node2D) -> void:
	results[level.chapter] = {"coins": level.coins, "relics": level.combat.relics,
		"kills": level.combat.kills, "deaths": level.deaths, "elapsed": level.elapsed}
	unlocked_chapter = maxi(unlocked_chapter, mini(STAGES, level.chapter + 1))

static func totals() -> Dictionary:
	var combined: Dictionary = {"coins": 0, "relics": 0, "kills": 0, "deaths": 0, "elapsed": 0.0}
	for result: Dictionary in results.values():
		for key: String in combined:
			combined[key] += result[key]
	return combined

static func next(level: Node2D) -> void:
	if not level.completed or level.chapter >= STAGES or unlocked_chapter < level.chapter + 1:
		return
	level.get_tree().paused = false
	level.audio.prepare_handoff(level.chapter+1)
	level.get_tree().change_scene_to_file(SCENES[level.chapter])

static func first(level: Node2D) -> void:
	if not level.completed:
		return
	level.get_tree().paused = false
	level.get_tree().change_scene_to_file("res://scenes/halloween_town.tscn")
