extends AnimatableBody2D

var start: Vector2
var finish: Vector2
var speed: float = 110
var clock: float = 0
var enabled: bool = true
var width: float = 180
var pause_time: float = 0
var direction: float = 1
var district: Node2D
var lift: bool = false
var shuttle: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	sync_to_physics = false
	position = start
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(width,20)
	shape.shape = box
	shape.position = Vector2(0,10)
	shape.one_way_collision = true
	add_child(shape)
	var plank: Sprite2D = preload("res://scripts/level_assets.gd").sprite(self,preload("res://scripts/level_assets.gd").PLATFORMS+"chain_hung_planks.png",Vector2(0,10),1,2)
	plank.region_enabled = true
	plank.region_rect = Rect2(3,14,26,10)
	plank.scale = Vector2(width/26,2)
	add_to_group("district_platforms")

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	clock += delta
	if pause_time > 0:
		pause_time -= delta
		return
	var target: Vector2 = finish if direction > 0 else start
	position = position.move_toward(target,speed*delta)
	if position.distance_to(target) < 1:
		direction *= -1
		pause_time = 1.0
		if shuttle:
			enabled = false
		if district != null:
			district.level.audio.play_at("lift_stop",global_position)
