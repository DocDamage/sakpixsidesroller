extends Node2D

var camera_left: float = 0.0
var chapter: int = 1
var journey_x: float = 180.0
var clock: float = 0.0
var swamp_blend: float = 0.0
var dawn: bool = false
var dawn_blend: float = 0.0
var road_mode: bool = false
var road_blend: float = 0.0
var fortress: bool = false
var castle_blend: float = 0.0
var expedition: int = 0

func _ready() -> void:
	z_index = -30

func _process(delta: float) -> void:
	clock += delta
	dawn_blend = move_toward(dawn_blend, 1.0 if dawn else 0.0, delta * 0.35)
	queue_redraw()

func _draw() -> void:
	var daylight: float = maxf(dawn_blend, 0.25 + road_blend * 0.55 if road_mode else 0.0)
	var palette: Array[Color] = preload("res://scripts/stage_blend.gd").sky(chapter,journey_x)
	var upper: Color = palette[0].lerp(Color("698c8a") if chapter >= 5 else Color("625574"),dawn_blend)
	var lower: Color = palette[1].lerp(Color("e6bf8f") if chapter >= 5 else Color("d79b78"),dawn_blend)
	for i: int in range(24):
		var color: Color = upper.lerp(lower, float(i) / 24.0)
		draw_rect(Rect2(0, i * 30, 1280, 31), color)
	if chapter in [9,10]:
		return # The dungeon roof covers the night sky; the vault opens toward trees.
	for i: int in range(65):
		var x: float = fposmod(float(i * 197) - camera_left * 0.06, 1280.0)
		var y: float = 90.0 + float((i * 73) % 265)
		draw_rect(Rect2(x, y, 2, 2), Color(0.7, 0.7, 0.85, (0.35 + sin(clock + i) * 0.2) * (1.0 - daylight)))
	var moon: Vector2 = Vector2(1010 - camera_left * 0.025, 183)
	draw_circle(moon, 104, Color("d0b1e108"))
	draw_circle(moon, 79, Color("d0b1e10d"))
	draw_circle(moon, 56, Color("e9dfbd"))
	draw_circle(moon + Vector2(-18, -10), 12, Color("ccc6ac"))
	draw_circle(moon + Vector2(18, 21), 8, Color("ccc6ac"))
	for layer: int in range(2):
		var points: PackedVector2Array = PackedVector2Array([Vector2(0, 720)])
		for x: int in range(0, 1340, 60):
			points.append(Vector2(x, 390 + layer * 70 + sin((x + camera_left * 0.1) * 0.006 + layer) * 48))
		points.append(Vector2(1340, 720))
		var hill: Color = Color("252238") if layer == 0 else Color("2d263d")
		var distant_color: Color = Color("657563") if road_mode else Color("5b5d57")
		if expedition >= 5:
			hill = Color("18222e") if expedition < 7 else Color("1c3430")
			distant_color = Color("526b55") if expedition >= 7 else Color("4d5262")
		draw_colored_polygon(points, hill.lerp(distant_color, daylight * 0.75))
