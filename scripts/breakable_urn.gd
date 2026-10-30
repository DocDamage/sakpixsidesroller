extends Node2D

var controller: Node:
	get:
		return get_node("/root/Controller")

signal shattered(at: Vector2)
const Assets = preload("res://scripts/level_assets.gd")
var broken: bool = false
var visual: Sprite2D
var hint_visible: bool = false
var chapter: int = 1

func _ready() -> void:
	add_to_group("breakables")
	z_index = 3
	var path: String = Assets.HAZARDS + "cracked_urn.png"
	if chapter >= 3:
		path = "res://Stages/Medievil Kingdom/8. Medieval Props, Furniture & Village Life/" + ("clay_pots.png" if chapter == 3 else "small_barrel.png")
	if chapter in [5,6]:
		path = "res://Stages/Dark Fantasy/7. Interactive Objects/wooden_barrel.png"
	elif chapter >= 7:
		path = "res://Stages/Abandonded Forest/9. Forgotten Campsites, Lost Objects & Woodland Props/wooden_crate.png"
	if chapter >= 9:
		var biome = preload("res://scripts/deep_biome.gd")
		path = biome.LOOT+"wooden_barrel.png" if chapter <= 10 else biome.LIFE+"ceramic_urn.png"
	visual = Assets.sprite(self, path, Vector2.ZERO, 2.0 if chapter >= 3 else 2.2)
	Assets.anchor_base(visual)

func strike(origin: Vector2, facing: float) -> bool:
	if broken or (position + Vector2(0, -28)).distance_to(origin) > 92:
		return false
	if facing != 0 and (position.x - (origin.x - facing * 50)) * facing < -16:
		return false
	broken = true
	remove_from_group("breakables")
	visual.texture = Assets.texture(Assets.CRYPT + "collapsed_tomb_rubble.png")
	if chapter == 4:
		visual.texture = Assets.texture("res://Stages/Medievil Kingdom/6. Medieval Fortifications, Gates & Siege Structures/wooden_debris_pile.png")
	elif chapter in [5,6]:
		visual.texture = Assets.texture("res://Stages/Dark Fantasy/1. Ground & Terrain Tiles/broken_cart_debris.png")
	elif chapter >= 7:
		visual.texture = Assets.texture("res://Stages/Abandonded Forest/4. Ruined Cabins & Forgotten Woodland Structures/broken_branch_pile.png")
	if chapter >= 9:
		var biome = preload("res://scripts/deep_biome.gd")
		visual.texture = Assets.texture(biome.LOOT+"debris_pile.png" if chapter <= 10 else biome.LIFE+"broken_pottery_shards_a.png")
	visual.scale = Vector2.ONE * 1.5
	visual.modulate = Color("827789")
	Assets.anchor_base(visual)
	shattered.emit(position + Vector2(0, -35))
	queue_redraw()
	return true

func _physics_process(_delta: float) -> void:
	if broken:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var near: bool = player != null and player.position.distance_to(position) < 130
	if near != hint_visible:
		hint_visible = near
	queue_redraw()

func _draw() -> void:
	if hint_visible and not broken:
		var key: String = controller.prompt("attack")
		var width: float = ThemeDB.fallback_font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_rect(Rect2(-width / 2 - 5, -81, width + 10, 19), Color("262236"))
		draw_string(ThemeDB.fallback_font, Vector2(-width / 2, -66), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d8c4e6"))
