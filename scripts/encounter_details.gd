extends Node2D

const Assets = preload("res://scripts/level_assets.gd")
var flames: Array[Sprite2D] = []
var clock: float = 0.0

func _ready() -> void:
	for x: float in [1040.0, 2320.0, 3880.0]:
		Assets.sprite(self, Assets.CRYPT + "open_stone_coffin.png", Vector2(x, 571), 2.8, -2).modulate = Color("b9a3b7")
	for x: float in [1380.0, 2670.0, 4020.0]:
		Assets.sprite(self, Assets.DECOR + "spider_on_web.png", Vector2(x, 474), 2.4, -2).modulate = Color("a39bb4")
	for x: float in [2520.0, 2710.0, 3970.0, 4140.0]:
		Assets.sprite(self, Assets.FOREST + "toxic_green_mushrooms.png", Vector2(x, 586), 2.1, 2)
	for x: float in [900.0,1260.0,2560.0,3890.0,5390.0,5740.0]:
		Assets.roadside_lantern(self,get_parent().lighting,x)
	for x: float in [5100.0, 5860.0]:
		Assets.sprite(self, Assets.CRYPT + "chained_pillar.png", Vector2(x, 511), 5.3, -3).modulate = Color("b4a3ba")
		Assets.sprite(self, Assets.CRYPT + "jack_o_lantern_pedestal.png", Vector2(x, 568), 2.5, 2)
	for x: float in [5390.0, 5760.0]:
		Assets.sprite(self, Assets.HAZARDS + "rune_tombstone_door.png", Vector2(x, 557), 3, -3).modulate = Color("8c789e")
	for x: float in [2640.0, 4080.0, 5340.0, 5790.0]:
		var flame: Sprite2D = Assets.sprite(self, Assets.MAGIC + "green_spirit_flame.png", Vector2(x, 548), 1.3, 2)
		flames.append(flame)
	for x: float in [280.0, 1820.0, 4620.0]:
		Assets.sprite(self, Assets.DECOR + "pumpkin_sign.png", Vector2(x, 555), 2.6, -2)

func _process(delta: float) -> void:
	clock += delta
	for i: int in range(flames.size()):
		flames[i].scale = Vector2(1.3, 1.3 + sin(clock * 6 + i * 2) * 0.15)
		flames[i].modulate.a = 0.8 + sin(clock * 9 + i) * 0.15
