extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0,1728),Vector2(1984,3008),Vector2(3328,4480),Vector2(4736,6400)]
const LEDGES: Array[Rect2] = [Rect2(480,500,192,30),Rect2(960,416,192,30),Rect2(1312,448,256,30),Rect2(1792,512,128,30),Rect2(2176,480,192,30),Rect2(2624,384,256,30),Rect2(3072,496,128,30),Rect2(3520,480,192,30),Rect2(4032,400,256,30),Rect2(4544,512,128,30),Rect2(4992,464,192,30),Rect2(5344,400,192,30)]
const ROUTE: Array = [[1280, false], [1440, true], [1672, false], [2040, true], [2592, false], [2752, true], [2952, false], [3384, true], [4000, false], [4160, true], [4424, false], [4792, true], [5430, false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/deep_builder.gd").build(level,FLOORS,LEDGES)
