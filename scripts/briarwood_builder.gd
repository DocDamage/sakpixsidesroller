extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0,1728),Vector2(1984,3136),Vector2(3456,4608),Vector2(4864,6400)]
const LEDGES: Array[Rect2] = [Rect2(480,500,192,30),Rect2(928,420,192,30),Rect2(1280,448,256,30),Rect2(1792,512,128,30),Rect2(2176,480,192,30),Rect2(2752,384,256,30),Rect2(3232,496,128,30),Rect2(3650,480,192,30),Rect2(4256,400,256,30),Rect2(4672,512,128,30),Rect2(5024,464,192,30),Rect2(5392,400,192,30)]
const ROUTE: Array = [[1248,false],[1408,true],[1672,false],[2040,true],[2720,false],[2880,true],[3080,false],[3512,true],[4224,false],[4384,true],[4552,false],[4920,true],[5430,false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/expedition_builder.gd").build(level, FLOORS, LEDGES)
