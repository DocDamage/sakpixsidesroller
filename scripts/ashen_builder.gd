extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0,1664),Vector2(1920,3008),Vector2(3328,4544),Vector2(4800,6400)]
const LEDGES: Array[Rect2] = [Rect2(448,496,192,30),Rect2(896,416,192,30),Rect2(1216,448,256,30),Rect2(1728,512,128,30),Rect2(2112,480,192,30),Rect2(2624,384,256,30),Rect2(3072,496,128,30),Rect2(3520,480,192,30),Rect2(4096,400,256,30),Rect2(4608,512,128,30),Rect2(4992,464,192,30),Rect2(5344,400,192,30)]
const ROUTE: Array = [[1184,false],[1344,true],[1608,false],[1976,true],[2592,false],[2752,true],[2952,false],[3384,true],[4064,false],[4224,true],[4488,false],[4856,true],[5430,false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/expedition_builder.gd").build(level, FLOORS, LEDGES)
