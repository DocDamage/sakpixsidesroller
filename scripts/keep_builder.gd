extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0, 1728), Vector2(1984, 3072), Vector2(3392, 4544), Vector2(4800, 6400)]
const LEDGES: Array[Rect2] = [Rect2(448, 500, 192, 30), Rect2(896, 420, 192, 30), Rect2(1280, 448, 256, 30), Rect2(1792, 512, 128, 30), Rect2(2176, 480, 192, 30), Rect2(2688, 384, 256, 30), Rect2(3168, 496, 128, 30), Rect2(3616, 480, 192, 30), Rect2(4160, 400, 256, 30), Rect2(4608, 512, 128, 30), Rect2(4992, 464, 192, 30), Rect2(5344, 400, 192, 30)]
const ROUTE: Array = [[1248, false], [1408, true], [1672, false], [2040, true], [2656, false], [2816, true], [3016, false], [3448, true], [4128, false], [4288, true], [4488, false], [4856, true], [5430, false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/kingdom_builder.gd").build(level, FLOORS, LEDGES, true)
