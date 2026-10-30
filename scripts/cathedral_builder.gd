extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0,1536),Vector2(1792,2880),Vector2(3200,4416),Vector2(4672,6400)]
const LEDGES: Array[Rect2] = [Rect2(384,496,192,30),Rect2(800,416,192,30),Rect2(1088,448,256,30),Rect2(1600,512,128,30),Rect2(1984,480,192,30),Rect2(2496,384,256,30),Rect2(2944,496,128,30),Rect2(3392,480,192,30),Rect2(3968,400,256,30),Rect2(4480,512,128,30),Rect2(4864,464,192,30),Rect2(5280,400,192,30)]
const ROUTE: Array = [[1056,false],[1216,true],[1480,false],[1848,true],[2464,false],[2624,true],[2824,false],[3256,true],[3936,false],[4096,true],[4360,false],[4728,true],[5430,false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/expedition_builder.gd").build(level, FLOORS, LEDGES)
