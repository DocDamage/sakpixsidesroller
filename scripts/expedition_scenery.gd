extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const DARK: String = "res://Stages/Dark Fantasy/"
const FOREST: String = "res://Stages/Abandonded Forest/"
const ARCH: String = DARK+"10. Doors, Windows & Architectural Pieces/"
const TREES: String = FOREST+"3. Ancient Trees & Twisted Roots/"
const RUINS: String = FOREST+"6. Forgotten Ruins & Mossy Stone Structures/"

static func tree(parent: Node2D, x: float, scale: float, leafy: bool) -> void:
	var trunk: Sprite2D = Assets.grounded(parent,TREES+"mossy_trunk_base.png",x,scale,-8)
	trunk.modulate = Color("6d877b")
	var top: float = 600-32*scale
	var section: Sprite2D = Assets.sprite(parent,TREES+"mossy_trunk_section.png",Vector2(x,top-12*scale),scale,-8)
	section.modulate = trunk.modulate
	for side: float in [-1.0,1.0]:
		var branch: Sprite2D = Assets.sprite(parent,TREES+("leafy_branch.png" if leafy else "twisted_branch_mossy.png"),Vector2(x+side*7*scale,top-24*scale),scale*1.2,-8)
		branch.flip_h = side < 0
		branch.modulate = trunk.modulate
		branch.add_to_group("wind_foliage")

static func build(level: Node2D, floors: Array[Vector2]) -> void:
	var chapter: int = level.chapter
	var woods: bool = chapter >= 7
	var wash := ShaderMaterial.new()
	wash.shader = preload("res://scripts/background_wash.gdshader")
	wash.set_shader_parameter("haze_color",Color("45594f") if woods else (Color("485471") if chapter == 6 else Color("66556b")))
	wash.set_shader_parameter("distance_fade",0.72)
	var distant := Node2D.new()
	distant.name = "DistantTown"
	distant.z_index = -18
	level.add_child(distant)
	for i: int in range(16):
		var path: String = RUINS+["columned_gateway.png","vine_temple_gate.png","stone_arch.png"][i%3] if woods else ARCH+["gothic_chapel_tower.png","vaulted_stone_arch.png","skull_crypt_entrance.png"][i%3]
		if chapter == 5 and i < 4:
			path = "res://Stages/Medievil Kingdom/3. Medieval Castles & Royal Architecture/"+["mossy_round_tower.png","gatehouse_portcullis.png"][i%2]
		if chapter == 5 and i >= 8 or chapter == 7 and i < 4:
			path = ARCH+"vaulted_stone_arch.png"
		if chapter == 6 and i >= 8:
			path = RUINS+["stone_arch.png","vine_temple_gate.png"][i%2]
		if chapter == 8 and i >= 8:
			path = "res://Stages/Dungeon/7. Ancient Ruins & Forgotten Temples/vine_temple_doorway.png"
		var visual: Sprite2D = Assets.sprite(distant,path,Vector2(90+i*260,395),5.0 if woods else 6.2)
		visual.material = wash
	var middle := Node2D.new()
	middle.name = "DistantForest"
	middle.z_index = -14
	level.add_child(middle)
	for i: int in range(18):
		var path: String = TREES+["twisted_trunk_base.png","hollow_trunk_doorway.png","mossy_trunk_base.png"][i%3] if woods else DARK+"3. Walls & Cliffs/"+("gothic_window_wall.png" if chapter == 6 else "ruined_wall_frame.png")
		if chapter == 6 and i >= 12:
			path = TREES+"mossy_trunk_base.png"
		var visual: Sprite2D = Assets.sprite(middle,path,Vector2(80+i*285,455),5.5)
		visual.material = wash
	if chapter == 5:
		for entry: Array in [["portcullis_arch.png",270],["gothic_chapel_tower.png",1190],["stone_archway_ruined.png",2130],["gothic_chapel_tower.png",2750],["portcullis_arch.png",3530],["skull_crypt_entrance.png",4200],["gothic_chapel_tower.png",5050],["vaulted_stone_arch.png",5790]]:
			if entry[1] == 270:
				preload("res://scripts/stage_entrance.gd").place(level,-7)
			else:
				Assets.grounded(level,ARCH+str(entry[0]),entry[1],6.5,-7).modulate = Color("a49aac")
	elif chapter == 6:
		for x: float in [280.0,1140.0,2110.0,2680.0,3440.0,4130.0,4930.0,5780.0]:
			if x == 280:
				preload("res://scripts/stage_entrance.gd").place(level)
			else:
				Assets.grounded(level,ARCH+"vaulted_stone_arch.png",x,8.0,-8).modulate = Color("8b9cab")
		for x: float in [1260.0,1980.0,2810.0,3310.0,4260.0,4800.0,5910.0]:
			Assets.grounded(level,ARCH+"stone_pillar.png",x,4.2,-6).modulate = Color("9da8b0")
		Assets.grounded(level,FOREST+"4. Ruined Cabins & Forgotten Woodland Structures/collapsed_shelter.png",6010,3.3,-7)
		tree(level,6030,4.3,false)
	else:
		for x: float in [820.0,2580.0,3910.0,5800.0]:
			tree(level,x,4.8 if chapter == 7 else 5.6,(chapter == 8 and x > 1500) or (chapter == 7 and x > 5200))
		var files: Array = ["wooden_cabin.png","watchtower.png","small_shack.png","collapsed_shelter.png"]
		for i: int in range(4):
			var x: float = [260.0,2250.0,3650.0,5050.0][i]
			var path: String = FOREST+"4. Ruined Cabins & Forgotten Woodland Structures/"+str(files[i]) if chapter == 7 else RUINS+["columned_gateway.png","double_arch.png","vine_temple_gate.png","vine_ruin_doorway.png"][i]
			if chapter == 8 and i == 0:
				preload("res://scripts/stage_entrance.gd").place(level,-7)
			else:
				Assets.grounded(level,path,x,5.5 if chapter == 7 else 7.0,-7).modulate = Color("98ad95")
		Assets.grounded(level,RUINS+"vine_temple_gate.png",5750,7.0,-9).modulate = Color("8fa38c")
	for span: Vector2 in floors:
		for x: int in range(int(span.x)+55,int(span.y)-25,170):
			var path: String = FOREST+"5. Abandoned Trails, Wooden Bridges & Forest Traversal/rope_fence.png" if woods else ARCH+"iron_spiked_fence.png"
			Assets.grounded(level,path,x,2.2,-5).modulate = Color("748176") if woods else Color("797182")
