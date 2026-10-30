extends Node2D

var camera_left: float = 0.0
var clock: float = 0.0
var warmth: float = 0.0
var chapter: int = 1
var journey_x: float = 180.0
const Blend = preload("res://scripts/stage_blend.gd")
const COLORS: Array[Color] = [Color("b9a5df"),Color("e6cb91"),Color("ebd399"),Color("b2c8e0"),Color("c5accb"),Color("a0c5d2"),Color("afc6a2"),Color("b6d5a9"),Color("93b6d1"),Color("b7afe0"),Color("9edaca"),Color("e0ceaa")]

static func tint(stage: int, x: float) -> Color:
	var color: Color = COLORS[stage-1]
	var incoming: bool = x < Blend.WIDTH
	var neighbour: int = stage-1 if incoming else stage+1
	if neighbour >= 1 and neighbour <= COLORS.size():
		color = color.lerp(COLORS[neighbour-1],Blend.weight(x,incoming))
	return color

func _ready() -> void:
	z_index = -3

func _process(delta: float) -> void:
	clock += delta
	position.x = camera_left
	queue_redraw()

func _draw() -> void:
	var swamp: float = clampf(1.0 - absf(camera_left + 640 - 3800) / 1100.0, 0, 1) * (1.0 - warmth)
	for i: int in range(16):
		var x: float = fposmod(i * 109.0 + clock * 9.0 - camera_left * 0.17, 1420.0) - 70
		var y: float = 510 + sin(clock * 0.35 + i * 4.2) * 48.0
		draw_circle(Vector2(x, y), 50 + float(i % 4) * 16, Color(0.43, 0.63, 0.63, 0.012 + swamp * 0.012))
	for i: int in range(25):
		var x: float = fposmod(i * 137.0 + clock * 12 - camera_left * 0.65, 1280.0)
		var y: float = 340 + fposmod(i * 43.0 + sin(clock + i) * 16, 242)
		var alpha: float = 0.16 + (sin(clock * 1.5 + i * 2.7) + 1) * 0.18
		var color: Color = tint(chapter,journey_x)
		color.a = alpha
		draw_rect(Rect2(x, y, 3, 3),color)
