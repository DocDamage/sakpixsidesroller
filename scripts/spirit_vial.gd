extends Node2D

signal collected(at: Vector2)
const Assets = preload("res://scripts/level_assets.gd")
var clock: float = 0.0
var visual: Sprite2D
var consumed: bool = false

func _ready() -> void:
	z_index = 5
	visual = Sprite2D.new()
	visual.texture = Assets.atlas(Assets.HEALING, Rect2(0, 0, 16, 16))
	visual.scale = Vector2.ONE * 2.0
	add_child(visual)
	add_to_group("healing_vials")

func _physics_process(delta: float) -> void:
	if consumed:
		return
	clock += delta
	(visual.texture as AtlasTexture).region.position.y = float(int(clock * 7) % 8) * 16
	visual.position.y = sin(clock * 3) * 5
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and not player.locked and player.health < 5 and (player.position + Vector2(0, -32)).distance_to(position) < 52:
		consumed = true
		player.health = mini(5, player.health + 1)
		remove_from_group("healing_vials")
		collected.emit(position)
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0, visual.position.y), 23, Color("7de5c015"))
	draw_arc(Vector2(0, visual.position.y), 23, clock, clock + 2, 12, Color("b2edc780"), 1)
