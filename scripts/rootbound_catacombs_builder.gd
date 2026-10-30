extends RefCounted

const FLOORS: Array[Vector2] = [Vector2(0,1600),Vector2(1856,2944),Vector2(3264,4480),Vector2(4736,6400)]
const LEDGES: Array[Rect2] = [Rect2(320,496,192,30),Rect2(800,416,192,30),Rect2(1184,432,256,30),Rect2(1664,512,128,30),Rect2(1984,480,192,30),Rect2(2528,384,256,30),Rect2(3008,496,128,30),Rect2(3456,480,192,30),Rect2(4032,400,256,30),Rect2(4544,512,128,30),Rect2(4992,448,192,30),Rect2(5344,400,192,30)]
const ROUTE: Array = [[1152, false], [1312, true], [1544, false], [1912, true], [2496, false], [2656, true], [2888, false], [3320, true], [4000, false], [4160, true], [4424, false], [4792, true], [5430, false]]

static func build(level: Node2D) -> void:
	preload("res://scripts/deep_builder.gd").build(level,FLOORS,LEDGES)
