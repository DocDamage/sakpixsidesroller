extends Node2D

const Assets = preload("res://scripts/level_assets.gd")
const Biome = preload("res://scripts/road_biome.gd")
const SMOKE: String = "res://Props/Campfire/Campfire Sprites/smoke_light_frame"
const HOMES: String = "res://Stages/Medievil Kingdom/4. Medieval Village Houses & Market Buildings/"
var level: Node2D
var clock: float = 0.0
var smoke: Array[Dictionary] = []
var butterflies: Array[Dictionary] = []
var hamlet: Node2D
var breeze: ShaderMaterial
var windows: Array[ShaderMaterial] = []

static func install(owner_level: Node2D, details: Node2D) -> void:
	var motion: Node2D = load("res://scripts/world_motion.gd").new()
	motion.name = "WorldMotion"
	owner_level.add_child(motion)
	motion.setup(owner_level, details)

func setup(owner_level: Node2D, details: Node2D) -> void:
	level = owner_level
	breeze = ShaderMaterial.new()
	breeze.shader = preload("res://scripts/foliage_sway.gdshader")
	for foliage: Sprite2D in get_tree().get_nodes_in_group("wind_foliage"):
		if level.is_ancestor_of(foliage):
			foliage.material = breeze
	for building: Sprite2D in get_tree().get_nodes_in_group("warm_windows"):
		if level.is_ancestor_of(building):
			windows.append(building.material)
	for fire: Sprite2D in details.fires:
		if not fire.get_meta("hearth",false):
			add_smoke(self,fire.position+fire.get_meta("emitter_offset",Vector2(0,-24)),1.0,0.15)
	if level.chapter == 1:
		haunted_details()
	elif level.chapter == 2:
		village_life()
		for visual: Node in level.get_node("RoadsideLife").get_children():
			if visual is Sprite2D and (str(visual.texture.resource_path).contains("tree") or str(visual.texture.resource_path).contains("stage5") or str(visual.texture.resource_path).contains("wildflowers")):
				visual.material = breeze

func add_smoke(parent: Node2D, chimney: Vector2, scale: float, opacity: float) -> void:
	var visual: Sprite2D = Assets.sprite(parent, SMOKE + "1.png", chimney - Vector2(0, 24 * scale), scale, -3)
	visual.modulate = Color(0.80, 0.83, 0.82, opacity)
	smoke.append({"visual": visual, "home": visual.position, "phase": chimney.x * 0.013})

func haunted_details() -> void:
	for entry: Array in [[Vector2(620, 500), 3.0], [Vector2(2140, 500), 2.5], [Vector2(4880, 484), 2.5]]:
		var flag: Sprite2D = Assets.sprite(self, Assets.DECOR + "halloween_bunting_a.png", entry[0], entry[1], -4)
		flag.modulate = Color("9985a4")
		flag.material = breeze
		var top: float = entry[0].y - 5.5 * float(entry[1])
		for side: float in [-1.0, 1.0]:
			var post: Sprite2D = Assets.sprite(self, Assets.VILLAGE + "Village Sheet Sprites/wooden_post.png", Vector2(entry[0].x + side * 15 * float(entry[1]), (600 + top) / 2), (600 - top) / 64, -4)
			post.modulate = Color("84748b")
	for x: float in [590.0, 1990.0, 4900.0]:
		Assets.sprite(self, Assets.DECOR + "raven_on_signpost.png", Vector2(x, 568), 2.0, -2).modulate = Color("b2a7b5")
	for x: float in [350.0, 2160.0, 3650.0]:
		Assets.sprite(self, Assets.DECOR + "metal_bucket.png", Vector2(x, 582), 1.4, -2).modulate = Color("9b92a8")

func village_life() -> void:
	hamlet = Node2D.new()
	hamlet.name = "RoadsideHamlet"
	hamlet.z_index = -8
	add_child(hamlet)
	var ruin: Sprite2D = Biome.prop(hamlet, "res://Stages/Abandonded Forest/4. Ruined Cabins & Forgotten Woodland Structures/collapsed_shelter.png", Vector2(1460, 542), 3.8)
	ruin.modulate = Color("80788c")
	for entry: Array in [["timber_cottage_chimney.png", 2200.0, -10.0], ["stone_cottage_chimney.png", 3020.0, 9.0], ["moss_roof_chimney_house.png", 3800.0, 5.0], ["red_roof_house_chimney.png", 5040.0, 8.0], ["stone_cottage_chimney.png", 5740.0, 9.0]]:
		var scale: float = 3.8
		var x: float = entry[1]
		var home: Sprite2D = Biome.prop(hamlet, HOMES + str(entry[0]), Vector2(x, 542), scale)
		var panes: Dictionary = {"timber_cottage_chimney.png": Vector4(22, 22, 2, 3), "stone_cottage_chimney.png": Vector4(19, 21, 4, 4), "moss_roof_chimney_house.png": Vector4(21, 23, 3, 2), "red_roof_house_chimney.png": Vector4(24, 20, 2, 5)}
		var pane: Vector4 = panes[entry[0]]
		var warmth: float = smoothstep(2100, 5700, x)
		var window := ShaderMaterial.new()
		window.shader = preload("res://scripts/hearth_windows.gdshader")
		window.set_shader_parameter("pane_rect", pane)
		window.set_shader_parameter("warmth", warmth)
		home.material = window
		windows.append(window)
		level.lighting.add_glow(home.position, Color(1.0, 0.72, 0.35, warmth * 0.6), 48, home, (Vector2(pane.x + pane.z / 2, pane.y + pane.w / 2) - Vector2(16, 16)) * scale)
		add_smoke(hamlet, home.position + Vector2(entry[2] * scale, -53), 1.3, 0.22 + Biome.greenery(x) * 0.12)
	for x: float in [3540.0, 4280.0, 6040.0]:
		var visual: Sprite2D = Assets.sprite(self, "res://Stages/Magic Forest/8. Forest Wildlife & Ambient Props/blue_butterfly.png", Vector2(x, 542), 0.55, -1)
		visual.modulate = Color("b6c8b8")
		butterflies.append({"visual": visual, "home": visual.position, "phase": x * 0.01})
	for x: float in [5180.0, 6080.0]:
		Assets.sprite(self, Assets.DECOR + "black_cat.png", Vector2(x, 581), 1.2, -2)
	for x: float in [3560.0, 5910.0]:
		Assets.sprite(self, Biome.LIFE + "well_bucket_rope.png", Vector2(x, 584), 1.4, -2)

func _process(delta: float) -> void:
	clock += delta
	breeze.set_shader_parameter("clock", clock)
	for window: ShaderMaterial in windows:
		window.set_shader_parameter("clock", clock)
	for entry: Dictionary in smoke:
		var visual: Sprite2D = entry["visual"]
		var phase: float = entry["phase"]
		visual.texture = Assets.texture(SMOKE + str(1 + int(clock * 7 + phase) % 4) + ".png")
		visual.position = entry["home"] + Vector2(sin(clock * 0.9 + phase) * 3.0, sin(clock * 0.5 + phase) * 1.5)
	for entry: Dictionary in butterflies:
		var visual: Sprite2D = entry["visual"]
		var phase: float = entry["phase"]
		visual.position = entry["home"] + Vector2(sin(clock * 0.65 + phase) * 31, sin(clock * 1.3 + phase) * 12)
		visual.scale.x = 0.55 * (0.25 + absf(sin(clock * 8 + phase)) * 0.75)
