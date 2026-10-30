extends Node2D

var clock: float = 0.0
var caption: String = "SEAL"
var tint: Color = Color("e5c3ffa0")

func _ready() -> void:
	# This marker inherits the seal sprite's scale; keep the rune fine and quiet.
	scale = Vector2.ONE / 2.4

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var color: Color = tint
	draw_arc(Vector2.ZERO, 38, clock * 0.4, clock * 0.4 + 4.4, 28, Color("b18bd940"), 1.0)
	for i: int in range(4):
		var at: Vector2 = Vector2.from_angle(i * PI / 2 + clock * 0.4) * 38
		draw_rect(Rect2(at - Vector2.ONE * 2, Vector2.ONE * 4), color)
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	draw_string(font, Vector2(-width / 2, -54), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
