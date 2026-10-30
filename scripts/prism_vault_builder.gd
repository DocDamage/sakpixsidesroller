extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0,1664),Vector2(1920,3072),Vector2(3392,4544),Vector2(4800,6400)]
const LEDGES: Array[Rect2] = [Rect2(448,496,192,30),Rect2(928,416,192,30),Rect2(1248,448,256,30),Rect2(1728,512,128,30),Rect2(2112,480,192,30),Rect2(2688,384,256,30),Rect2(3136,496,128,30),Rect2(3584,480,192,30),Rect2(4128,400,256,30),Rect2(4608,512,128,30),Rect2(5056,464,192,30),Rect2(5376,400,192,30)]
const ROUTE: Array = [[1216, false], [1376, true], [1608, false], [1976, true], [2656, false], [2816, true], [3016, false], [3448, true], [4096, false], [4256, true], [4488, false], [4856, true], [5430, false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/deep_builder.gd").build(level,FLOORS,LEDGES)
