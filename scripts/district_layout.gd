extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Town = preload("res://scripts/town_builder.gd")
const WIDTH: float = 19200
var FLOORS: Array[Vector2] = []
var LEDGES: Array[Rect2] = []
var SOLIDS: Array[Rect2] = []
var ROUTE: Array = []
var rooms: Array[Dictionary] = []
var surfaces: Array[Dictionary] = []
var colliders: Array[StaticBody2D] = []
var level: Node2D

static func configure(profile: RefCounted) -> void:
	profile.builder = load("res://scripts/district_layout.gd").new()
	profile.details = preload("res://scripts/district_details.gd")
	profile.seals.assign([Vector2(6020,-750),Vector2(9760,1370),Vector2(15020,-170)])
	profile.checkpoints.assign([])
	profile.ground_coins.assign([])
	profile.plants.assign([])
	profile.mimics.assign([Vector2(3180,120),Vector2(11740,-240)])
	profile.urns.assign([])
	profile.gaps.assign([])
	profile.boss_at = Vector2(17660,600)
	profile.boss_health = 16
	profile.intro_title = "The bells beneath the town."
	profile.intro_text = "Explore the belfry, cistern and garden. Open routes back to the quarter."
	profile.boss_hint = "Use the balconies. Finish the combo to break his charge."
	profile.boss_objective = "RETURN THE SEALS TO THE QUARTER RITUAL"
	profile.regions.assign(["THE CROOKED QUARTER","THE BELFRY AND GRAVES","THE FLOODED UNDERCROFT","THE WITCH'S GARDEN"])

func room(title: String, rect: Rect2, style: String, sheltered: bool = false) -> void:
	rooms.append({"name":title,"rect":rect,"style":style,"sheltered":sheltered})

func build(owner_level: Node2D) -> void:
	level = owner_level
	level.stage_width = WIDTH
	level.checkpoint = Vector2(180,590)
	# Rooms overlap at their doors, not at arbitrary apexes. Upper and lower
	# branches return to hubs through separate, physically connected passages.
	room("THE LANTERN COURT",Rect2(0,160,2100,620),"street")
	room("THE CROOKED QUARTER",Rect2(2100,160,2040,620),"street")
	room("THE APOTHECARY LOFT",Rect2(2200,-200,1350,800),"wood",true)
	room("THE WATCHER'S EAVES",Rect2(3550,-430,770,460),"wood")
	room("THE BELL GANTRY",Rect2(3980,-1040,1600,1640),"crypt",true)
	room("THE SILENT BELFRY",Rect2(5540,-1060,900,460),"crypt",true)
	room("THE FORGOTTEN GRAVEYARD",Rect2(4140,160,2400,610),"grave")
	room("THE OSSUARY STAIR",Rect2(6450,180,750,1400),"crypt",true)
	room("THE OLD PRISON",Rect2(3300,850,2050,800),"crypt",true)
	room("THE SMUGGLER'S PASSAGE",Rect2(5330,900,1800,720),"crypt",true)
	room("THE PUMP HOUSE",Rect2(7000,710,830,550),"wood",true)
	room("THE DROWNED GALLERY",Rect2(7460,1120,1820,800),"crypt",true)
	room("THE FLOODGATE SHRINE",Rect2(9250,940,900,990),"crypt",true)
	room("THE BROKEN CAUSEWAY",Rect2(7050,210,3020,470),"grave")
	room("THE SERVICE SHAFT",Rect2(10000,130,600,1510),"crypt",true)
	room("THE WATCHHOUSE",Rect2(10550,-360,2180,1080),"crypt",true)
	room("THE CHIMNEY VAULT",Rect2(10820,-630,510,900),"wood",true)
	room("THE MILL WINCH",Rect2(12260,-500,650,1240),"wood")
	room("THE HIGH AQUEDUCT",Rect2(12700,-500,1850,460),"grave")
	room("THE WITCH'S FLOODGARDEN",Rect2(12800,180,2700,1020),"garden")
	room("THE GARDEN SANCTUM",Rect2(14450,-500,1200,500),"garden")
	room("THE RETURN GALLERY",Rect2(10100,1130,6620,570),"crypt",true)
	room("THE LANTERN RETURN",Rect2(15400,180,1600,630),"grave")
	room("THE MIDNIGHT CHAPEL",Rect2(16860,80,1650,740),"crypt",true)
	room("THE ROAD TO DAWN",Rect2(18500,140,700,680),"garden")
	room("THE CHAPEL UNDERCROFT",Rect2(16600,820,2120,880),"crypt",true)
	background()
	structural_backing()
	# Real earth/stone floors. The quarter's trapdoor and the ossuary shaft
	# leave deliberate holes into the lower loop.
	for rect: Rect2 in [Rect2(0,600,3460,110),Rect2(3680,600,2860,110),Rect2(3400,1460,3700,240),Rect2(7100,1760,3000,260),Rect2(10100,1460,6500,240),Rect2(10040,600,160,120),Rect2(10400,600,2960,120),Rect2(13200,640,380,450),Rect2(13580,1040,820,240),Rect2(14400,640,400,450),Rect2(14800,600,1460,200),Rect2(16500,600,1900,200),Rect2(18640,600,560,200),Rect2(16600,1460,2120,240)]:
		floor_piece(rect)
	# Continuous room floors, balconies, beams and bridge remnants. Elevations
	# alternate rooms, crossings and shafts rather than ascending/descending ramps.
	for rect: Rect2 in [Rect2(3460,600,220,20),Rect2(10200,600,200,20),Rect2(16260,600,240,20),Rect2(2260,120,1290,24),Rect2(3650,-80,560,24),Rect2(4250,-500,580,28),Rect2(5000,-500,560,28),Rect2(5560,-700,620,28),Rect2(5620,300,640,24),Rect2(6860,600,340,24),Rect2(7080,600,440,24),Rect2(8200,600,480,24),Rect2(9300,600,740,24),Rect2(7040,1100,620,24),Rect2(7880,1420,380,24),Rect2(8520,1240,400,24),Rect2(9360,1412,640,24),Rect2(9840,1100,360,24),Rect2(10580,80,1520,24),Rect2(11320,-240,650,24),Rect2(12500,-120,600,24),Rect2(13900,-120,500,24),Rect2(14700,-120,620,24),Rect2(13040,400,520,24),Rect2(13920,280,440,24),Rect2(15200,320,680,24),Rect2(16400,440,520,24),Rect2(17040,360,360,24),Rect2(18040,360,360,24)]:
		if rect.position.x < 6440 and rect.position.y <= 200:
			continue
		platform(rect)
	# Chimney walls create an optional wall-jump route to the loft cache.
	platform(Rect2(4420,1120,880,24))
	# Landings belong to the bell frame, ossuary and lift shaft. Each offers
	# a place to dismount, change direction or pause during a long climb.
	for landing: Rect2 in [Rect2(3960,200,220,24),Rect2(6660,1030,260,24),Rect2(10080,980,170,24),Rect2(18260,1040,260,24),Rect2(18400,600,240,20)]:
		if landing.position.x == 3960:
			continue
		platform(landing)
		if landing.position.y > 900:
			var bracket_path: String = "res://Stages/Medievil Kingdom/2. Castle Platforms & Defensive Walkways/stone_ledge_bracket.png"
			var crop: Rect2 = Assets.opaque_rect(bracket_path)
			for x: float in [landing.position.x+40,landing.end.x-40]:
				var bracket: Sprite2D = Assets.sprite(level,bracket_path,Vector2(x,landing.end.y+crop.size.y),2,-4)
				bracket.region_enabled = true
				bracket.region_rect = crop
				bracket.modulate = Color("8f8993")
				bracket.add_to_group("traversal_supports")
	for rail: Rect2 in [Rect2(3780,1412,780,12),Rect2(5220,1412,4140,12),Rect2(10040,1412,6340,12)]:
		platform(rail)
		for x: int in range(int(rail.position.x)+90,int(rail.end.x),760):
			panel(Assets.VILLAGE+"Village Sheet Sprites/wooden_post.png",Rect2(x-7,1424,14,(1760 if x > 7100 and x < 10100 else 1460)-1424),Rect2(3,2,6,29),-5,Color("4f515d"))
	wall(Rect2(10840,-240,48,640))
	wall(Rect2(11100,-480,48,640))
	# The underground side rooms have actual retaining walls and door openings.
	wall(Rect2(3270,750,100,950))
	wall(Rect2(6360,740,80,430))
	wall(Rect2(16600,1180,100,40))
	wall(Rect2(18720,820,60,880))
	for space: Dictionary in rooms:
		if not space.sheltered or space.rect.position.x < 6440:
			continue
		var segments: Array[Vector2] = [Vector2(space.rect.position.x,space.rect.end.x)]
		var holes: Array[Vector2] = []
		if space.name == "THE OLD PRISON":
			holes = [Vector2(3460,3680)]
		elif space.name == "THE WATCHHOUSE":
			holes = [Vector2(10840,12000)]
		elif space.name == "THE SMUGGLER'S PASSAGE":
			holes = [Vector2(6880,6960),Vector2(7100,7180)]
		elif space.name == "THE DROWNED GALLERY":
			holes = [Vector2(7520,7600)]
		elif space.name == "THE PUMP HOUSE":
			holes = [Vector2(7100,7180)]
		elif space.name == "THE RETURN GALLERY":
			holes = [Vector2(10200,10400),Vector2(16260,16500)]
		elif space.name == "THE CHAPEL UNDERCROFT":
			holes = [Vector2(18400,18640)]
		for hole: Vector2 in holes:
			var cut: Array[Vector2] = []
			for segment: Vector2 in segments:
				if hole.y <= segment.x or hole.x >= segment.y:
					cut.append(segment)
				else:
					if hole.x > segment.x:
						cut.append(Vector2(segment.x,hole.x))
					if hole.y < segment.y:
						cut.append(Vector2(hole.y,segment.y))
			segments = cut
		for segment: Vector2 in segments:
			wall(Rect2(segment.x,space.rect.position.y,segment.y-segment.x,28))
	preload("res://scripts/district_bell_route.gd").new().build(self)
	architecture()
	encounters()

func floor_piece(rect: Rect2) -> void:
	SOLIDS.append(rect)
	LEDGES.append(Rect2(rect.position,Vector2(rect.size.x,20)))
	var grass: bool = rect.position.x >= 12700 and rect.position.y < 900
	colliders.append(preload("res://scripts/contour_terrain.gd").foundation(level,rect,grass))
	surfaces.append({"rect":rect,"kind":"grass" if grass else "stone"})

func platform(rect: Rect2, material_kind: String = "") -> void:
	LEDGES.append(rect)
	Town.solid(level,rect,true)
	var wood: bool = rect.position.x < 5560 or rect.position.x in range(7040,7601) or rect.position.x > 12200 and rect.position.x < 13200 or rect.position.x == 18400 and rect.position.y == 600
	if material_kind == "house":
		surfaces.append({"rect":rect,"kind":"wood"})
		# Only the horizontal timber face; exclude the source icon's feet.
		panel("res://Stages/Medievil Kingdom/7. Medieval Interiors, Halls & Underground Chambers/wooden_plank_floor.png",rect,Rect2(2,11,28,8),1,Color("b3a3a6"),3)
		return
	if not material_kind.is_empty():
		wood = material_kind == "wood"
	surfaces.append({"rect":rect,"kind":"wood" if wood else "stone"})
	panel(Assets.PLATFORMS+("wooden_plank_ledge.png" if wood else "purple_stone_platform.png"),rect,Rect2(3,14,26,8) if wood else Rect2(3,11,26,12),1,Color("9b8f84") if wood else Color("87919c"))
	# Brackets and posts connect these floors to the architecture underneath.
	if rect.position.y >= 300 and rect.position.y < 600 and rect.position.x < 6500:
		for x: float in [rect.position.x+36,rect.end.x-36]:
			panel(Assets.VILLAGE+"Village Sheet Sprites/wooden_post.png",Rect2(x-10,rect.end.y,20,600-rect.end.y),Rect2(3,2,6,29),-5,Color("484557"))

func wall(rect: Rect2, visible_skin: bool = true) -> void:
	SOLIDS.append(rect)
	Town.solid(level,rect)
	colliders.append(level.get_child(level.get_child_count()-1))
	if visible_skin:
		panel(Assets.GROUND+"grey_stone_brick.png",rect,Rect2(3,5,26,24),0,Color("737986"))

func panel(path: String, rect: Rect2, crop: Rect2, depth: int, tint: Color, pixel_scale: float = 2) -> Sprite2D:
	var image: Image = Assets.texture(path).get_image()
	if image.is_compressed():
		image.decompress()
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(image.get_region(Rect2i(crop)))
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO,rect.size/pixel_scale)
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2.ONE*pixel_scale
	sprite.position = rect.get_center()
	sprite.z_index = depth
	sprite.modulate = tint
	level.add_child(sprite)
	sprite.add_to_group("district_panels")
	sprite.set_meta("source_crop",crop)
	sprite.set_meta("source_size",image.get_size())
	if depth == -5 and rect.size.x <= 40:
		sprite.add_to_group("traversal_supports")
	if depth >= 0 and rect.size.y <= 28:
		sprite.set_meta("surface_y",rect.position.y)
		sprite.add_to_group("district_surfaces")
	return sprite

func background() -> void:
	for layer_name: String in ["DistantTown","DistantForest"]:
		var layer := Node2D.new()
		layer.name = layer_name
		layer.z_index = -20 if layer_name == "DistantTown" else -16
		level.add_child(layer)
		for i: int in 30:
			var path: String = Assets.HOUSES+["haunted_manor.png","dark_victorian_house.png","crooked_spire_tower.png"][i%3] if layer_name == "DistantTown" else Assets.FOREST+["gnarled_dead_tree.png","bare_branch_tree.png"][i%2]
			var visual: Sprite2D = Assets.grounded(layer,path,120+i*340,4.5 if layer_name == "DistantTown" else 4,-1,720)
			var material := ShaderMaterial.new()
			material.shader = preload("res://scripts/background_wash.gdshader")
			material.set_shader_parameter("haze_color",Color("26303e"))
			material.set_shader_parameter("distance_fade",0.7)
			visual.material = material
		var ground := Polygon2D.new()
		ground.polygon = PackedVector2Array([Vector2(-1000,714),Vector2(12000,714),Vector2(12000,2800),Vector2(-1000,2800)])
		ground.color = Color("1b2230")
		ground.add_to_group("scenic_foundations")
		layer.add_child(ground)
	for space: Dictionary in rooms:
		if space.sheltered and space.rect.position.x >= 6440:
			panel(Assets.GROUND+"purple_stone_brick.png",space.rect,Rect2(4,5,24,24),-12,Color("343847") if space.style == "crypt" else Color("443b40"))
			# Grounded friezes establish a ceiling and a base for each interior.
			panel(Assets.GROUND+"grey_stone_brick.png",Rect2(space.rect.position,Vector2(space.rect.size.x,40)),Rect2(3,5,26,24),-10,Color("5b6070"))

func prop(path: String, x: float, surface: float = 600, size: float = 4, depth: int = -7) -> Sprite2D:
	return Assets.grounded(level,path,x,size,depth,surface)

func structural_backing() -> void:
	# The upper rooms belong to buildings whose walls continue to street level.
	# Structural bays, door recesses and timber frames tie the floors together.
	# The chapel sits on continuous foundations. Looking down its stair must
	# reveal earth and masonry behind the rooms, rather than open night sky.
	panel(Assets.GROUND+"grey_stone_brick.png",Rect2(16260,800,2940,1600),Rect2(3,5,26,24),-14,Color("202632"))
	# Subterranean rooms need a continuous rear retaining wall. The old prison
	# skip left its wall fixtures, cells and ladders silhouetted against the sky.
	for space: Dictionary in rooms:
		if space.sheltered and (space.rect.position.y >= 700 or space.style == "crypt" and space.rect.position.x >= 6440):
			panel(Assets.GROUND+"grey_stone_brick.png",space.rect,Rect2(3,5,26,24),-14,Color("303442"))
	for rect: Rect2 in [Rect2(10580,80,1520,520),Rect2(12270,-500,360,1100)]:
		panel(Assets.GROUND+"purple_stone_brick.png",rect,Rect2(4,5,24,24),-11,Color("454554"))
		for x: float in [rect.position.x,rect.end.x-40]:
			panel(Assets.GROUND+"grey_stone_brick.png",Rect2(x,rect.position.y,40,rect.size.y),Rect2(5,6,22,22),-9,Color("686878"))
		for y: int in range(int(rect.position.y)+140,int(rect.end.y),220):
			panel(Assets.PLATFORMS+"wooden_plank_ledge.png",Rect2(rect.position.x,y,rect.size.x,18),Rect2(3,14,26,8),-8,Color("71616a"))
	for entry: Vector2 in [Vector2(11040,600),Vector2(11740,600)]:
		prop(Assets.CRYPT+"crypt_arch_doorway.png",entry.x,entry.y,5,-8).modulate = Color("77758b")
	for space: Dictionary in rooms:
		if not space.sheltered or space.rect.position.x < 6440:
			continue
		for x: int in range(int(space.rect.position.x)+110,int(space.rect.end.x)-40,460):
			panel(Assets.GROUND+"grey_stone_brick.png",Rect2(x,space.rect.position.y+40,44,space.rect.size.y-40),Rect2(4,5,24,24),-10,Color("53586b"))
	# Cells and ossuary bays have recessed doorways rather than a bare tiled wall.
	for entry: Vector2 in [Vector2(3690,1460),Vector2(5030,1460),Vector2(5760,1460),Vector2(6500,1460),Vector2(8120,1760),Vector2(8840,1760),Vector2(9610,1760),Vector2(11600,1460),Vector2(13100,1460),Vector2(14900,1460)]:
		prop(Assets.CRYPT+"barred_crypt_window.png",entry.x,entry.y-170,4.5,-9).modulate = Color("7d849b")

func architecture() -> void:
	# Each cluster describes a place; props are not distributed at fixed intervals.
	for x: float in [900.0,1750.0]:
		preload("res://scripts/district_house.gd").install(self,Vector2(x-240,75),1,288,false)
	for x: float in [4710.0,5420.0,6190.0]:
		prop(Assets.CRYPT+"small_mausoleum.png",x,600,5.2).modulate = Color("8b8d9f")
	for entry: Vector2 in [Vector2(3610,1460),Vector2(5050,1460),Vector2(6160,1460),Vector2(7980,1760),Vector2(9600,1760),Vector2(10900,1460),Vector2(13200,1460),Vector2(15600,1460)]:
		prop(Assets.CRYPT+"crypt_arch_doorway.png",entry.x,entry.y,6,-8).modulate = Color("677484")
	for x: float in [10820.0,11980.0,12680.0]:
		prop(Assets.CRYPT+"mausoleum_entrance.png",x,600,8,-8).modulate = Color("7e8394")
	for x: float in [13080.0,14600.0,15540.0]:
		prop(Assets.SWAMP+"dead_swamp_tree.png",x,640 if x < 14800 else 600,7,-8).modulate = Color("617a78")
	prop(Assets.CRYPT+"mausoleum_entrance.png",17640,600,11,-9).modulate = Color("8a829e")
	for x: float in [17010.0,18280.0]:
		prop(Assets.HAZARDS+"gargoyle_statue.png",x,600,3.4,-5)
	for x: float in [18770.0]:
		prop(Assets.VILLAGE+"House3.png",x,600,1.1,-7).modulate = Color("a2a2a0")
	# Only graveyard plots receive headstones; the alleys and combat courts stay open.
	for x: float in [4490.0,5180.0,5990.0,16280.0]:
		prop(Assets.HAZARDS+"cross_tombstone.png",x,600,2,-3)
	for x: float in [940.0,3110.0,6280.0]:
		prop(Assets.DECOR+"pumpkin_cluster.png",x,600,1.5,-3)
	var circle: Sprite2D = Assets.sprite(level,Assets.MAGIC+"purple_summoning_circle.png",Vector2(2920,597),1,2)
	circle.scale = Vector2(4,0.48)
	circle.modulate = Color("afa2d5")

func encounters() -> void:
	var roster: Array = [["rat",1120,600],["guard",2060,600],["guard",3100,120],["bat",3800,-240],["bat",4600,-340],["guard",5220,-500],["witch",5730,-840],["rat",4480,600],["guard",5330,600],["plant",5680,600],["guard",6170,300],["bat",6590,260],["guard",3880,1460],["guard",4810,1460],["rat",5480,1460],["mushroom",6100,1460],["guard",8320,600],["eye",8180,1180],["mushroom",8740,1240],["guard",9660,1420],["mosquito",8980,430],["guard",11030,600],["plant",11430,600],["guard",11380,80],["bat",12160,-80],["guard",12830,-120],["mosquito",13640,-310],["eye",14370,-320],["guard",14900,-120],["mushroom",13100,600],["witch",14320,180],["plant",15120,600],["guard",15930,600],["rat",16100,600],["guard",11950,1460],["mushroom",14300,1460],["rat",15830,1460]]
	for entry: Array in roster:
		var enemy: Node2D = preload("res://scripts/haunt.gd").new()
		enemy.species = entry[0]
		enemy.flying = entry[0] in ["bat","eye","witch","mosquito"]
		if entry[0] == "bat":
			enemy.health = 1
		enemy.position = Vector2(entry[1],entry[2])
		level.add_child(enemy)
		enemy.defeated.connect(level.enemy_defeated)
