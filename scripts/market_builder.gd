extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0, 1600), Vector2(1856, 2944), Vector2(3264, 4480), Vector2(4736, 6400)]
const LEDGES: Array[Rect2] = [Rect2(384, 496, 192, 30), Rect2(832, 416, 192, 30), Rect2(1152, 448, 256, 30), Rect2(1664, 512, 128, 30), Rect2(2080, 480, 192, 30), Rect2(2560, 384, 256, 30), Rect2(3040, 496, 128, 30), Rect2(3504, 480, 192, 30), Rect2(4000, 400, 256, 30), Rect2(4544, 512, 128, 30), Rect2(4944, 464, 192, 30), Rect2(5328, 400, 192, 30)]
const ROUTE: Array = [[1120, false], [1280, true], [1544, false], [1912, true], [2528, false], [2688, true], [2888, false], [3320, true], [3968, false], [4128, true], [4424, false], [4792, true], [5430, false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/kingdom_builder.gd").build(level, FLOORS, LEDGES, false)
