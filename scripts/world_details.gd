extends Node2D

var controller: Node:
	get:
		return get_node("/root/Controller")

const Assets = preload("res://scripts/level_assets.gd")
const RUINS: String = "res://Stages/Abandonded Forest/6. Forgotten Ruins & Mossy Stone Structures/"
const GROWTH: String = "res://Stages/Abandonded Forest/8. Dead Vegetation, Fungi & Forest Overgrowth/"
const DARK: String = "res://Stages/Dark Fantasy/4. Background Decorations/"
const VILLAGE_LIFE: String = "res://Stages/Medievil Kingdom/8. Medieval Props, Furniture & Village Life/"
var level: Node2D
var clock: float = 0.0
var fires: Array[Sprite2D] = []
var actors: Array[Dictionary] = []
var nearest: int = -1

func setup(owner_level: Node2D) -> void:
	level = owner_level
	Assets.sprite(self, "res://NPCs/GandalfHardcore Pixel Art Carriage/Carriage only 2.png", Vector2(145, 537), 1.25, -2).modulate = Color("c1a8b7")
	for x: float in [420.0, 2220.0, 3790.0, 5290.0]:
		var fire: Sprite2D = preload("res://scripts/upright_campfire.gd").place(self,x)
		fires.append(fire)
		level.lighting.add_glow(fire.position+fire.get_meta("emitter_offset"),Color("ffb979"),110,fire,fire.get_meta("emitter_offset"))
	add_actor("Cartographer", "Wizard with a map.png", Vector2(320, 600), 6,
		"Violet seals lie above the path. Double-jump for ledges; dash across cursed water.")
	add_actor("Lantern Keeper", "Sitting Witch.png", Vector2(5080, 600), 5,
		"The Gravekeeper braces for light strikes. Finish your combo, then jump his flame.")
	for x: float in [1900.0, 2780.0]:
		Assets.sprite(self, DARK + "hooded_statue.png", Vector2(x, 543), 3.5, -3).modulate = Color("a99cae")
	for x: float in [2340.0, 2560.0, 5200.0, 5830.0]:
		Assets.grounded(self, "res://Stages/Medievil Kingdom/3. Medieval Castles & Royal Architecture/banner_on_pole.png", x, 3.0, -4).modulate = Color("a991ac")
	for entry: Array in [["columned_gateway.png", Vector2(3540, 493)], ["vine_temple_gate.png", Vector2(3850, 485)]]:
		Assets.sprite(self, RUINS + str(entry[0]), entry[1], 6.0, -5).modulate = Color("708b89")
	for x: float in [3210.0, 3480.0, 3740.0, 4120.0]:
		Assets.sprite(self, GROWTH + "hanging_vines.png", Vector2(x, 463), 2.8, -2).modulate = Color("7b9690")
		Assets.sprite(self, GROWTH + "stump_fungus_shelf.png", Vector2(x + 35, 578), 2.2, 2)
	for x: float in [470.0, 1400.0, 1920.0, 2640.0, 3160.0, 4040.0, 4690.0, 5910.0]:
		Assets.sprite(self, GROWTH + "fern.png", Vector2(x, 591), 1.8, 2).modulate = Color("a1a4af")
	for x: float in [2030.0, 3550.0, 4800.0]:
		Assets.sprite(self, DARK + "firewood_stack.png", Vector2(x, 582), 2.0, -2)
	for entry: Array in [["broken_open_crate.png", 1090], ["leaning_ladder.png", 1940], ["grain_sacks.png", 2270], ["stacked_planks.png", 3530], ["wooden_bench_simple.png", 5170]]:
		Assets.grounded(self, VILLAGE_LIFE + str(entry[0]), entry[1], 1.8, -2).modulate = Color("9b8b9f")
	preload("res://scripts/world_motion.gd").install(level, self)

func add_actor(actor_name: String, file: String, at: Vector2, frames: int, line: String) -> void:
	var visual: Sprite2D = Assets.sprite(self, "res://NPCs/GandalfHardcore characters pack 2/" + file, at + Vector2(0, -64), 2.0, 3)
	visual.region_enabled = true
	visual.region_rect = Rect2(0, 0, 64, 64)
	actors.append({"name": actor_name, "visual": visual, "position": at, "frames": frames, "line": line})

func _physics_process(delta: float) -> void:
	if level == null:
		return
	clock += delta
	nearest = -1
	for i: int in range(actors.size()):
		var actor: Dictionary = actors[i]
		var visual: Sprite2D = actor["visual"]
		visual.region_rect.position.x = float(int(clock * 6) % int(actor["frames"])) * 64
		if not level.completed and level.player.position.distance_to(actor["position"]) < 90:
			nearest = i
	level.hud.talk_prompt = "[E] Speak to the " + str(actors[nearest]["name"]) if nearest >= 0 else ""
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if nearest >= 0 and level != null and not level.completed and event.is_action_pressed("interact"):
		level.hud.notify_player(str(actors[nearest]["name"]) + ": " + advice(nearest))
		level.audio.play("coin")
		get_viewport().set_input_as_handled()

func advice(index: int) -> String:
	if level.key_found:
		return level.profile.exit_objective.capitalize() + ". The way is open; follow the lanterns right."
	if level.seals == 3:
		if level.combat.warden_cleared:
			return level.profile.key_objective.capitalize() + ". Your reward waits beside the guardian's arena."
		return level.profile.boss_objective.capitalize() + ". Finish your combo to break the charge; jump the spreading flame."
	return str(actors[index]["line"])

func _draw() -> void:
	if nearest >= 0:
		var at: Vector2 = actors[nearest]["position"]
		var key: String = controller.prompt("interact")
		var width: float = ThemeDB.fallback_font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_rect(Rect2(at + Vector2(-width / 2 - 6, -123), Vector2(width + 12, 20)), Color("211d32"))
		draw_string(ThemeDB.fallback_font, at + Vector2(-width / 2, -107), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e6d2ac"))
