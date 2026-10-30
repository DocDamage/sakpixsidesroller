extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0,1600),Vector2(1856,3072),Vector2(3392,4480),Vector2(4736,6400)]
const LEDGES: Array[Rect2] = [Rect2(416,496,192,30),Rect2(864,416,192,30),Rect2(1184,448,256,30),Rect2(1664,512,128,30),Rect2(2112,480,192,30),Rect2(2656,384,256,30),Rect2(3136,496,128,30),Rect2(3584,480,192,30),Rect2(4096,400,256,30),Rect2(4544,512,128,30),Rect2(4944,464,192,30),Rect2(5328,400,192,30)]
const ROUTE: Array = [[1152,false],[1312,true],[1544,false],[1912,true],[2624,false],[2784,true],[3016,false],[3448,true],[4064,false],[4224,true],[4424,false],[4792,true],[5430,false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/expedition_builder.gd").build(level, FLOORS, LEDGES)
