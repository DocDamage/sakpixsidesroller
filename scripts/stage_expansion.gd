extends Node2D

const Assets = preload("res://scripts/level_assets.gd")
const Town = preload("res://scripts/town_builder.gd")
const Styles = preload("res://scripts/stage_blend.gd")
const Footing = preload("res://scripts/enemy_footing.gd")
const CUT: float = 4800
const EXTRA: float = 6400
const WIDTH: float = 12800
static var wall_tiles: Dictionary = {}
const ROOM_NAMES: Array = [["THE BELFRY ROOFS","THE BURIED CRYPT"],["THE OLD MILL RISE","THE MILLRACE"],["THE MARKET ROOFTOPS","THE CANAL UNDERCROFT"],["THE BANNER ASCENT","THE ROYAL CISTERNS"],["THE CRUMBLED WATCH","THE ASHEN GALLERY"],["THE BELL CLOISTER","THE FLOODED NAVE"],["THE UPPER BRIARS","THE ROOTED RAVINE"],["THE ELDER BRANCHES","THE ROOT VAULT"],["THE OSSUARY DESCENT","THE CRYPT UPPER RUN"],["THE CRYSTAL DEPTHS","THE PRISM CROWN"],["THE LANTERN CANOPY","THE FAIRY WETLANDS"],["THE STARFALL CANOPY","THE WORLD ROOTS"]]
var level: Node2D
var rooms: Array[Dictionary] = []
var route: Array[Vector2] = []

class Layout extends RefCounted:
	var FLOORS: Array[Vector2] = []
	var LEDGES: Array[Rect2] = []
	var ROUTE: Array = []

static func map_x(x: float) -> float:
	return x+EXTRA if x >= CUT else x

static func base_x(x: float) -> float:
	return x if x < CUT else (CUT if x < CUT+EXTRA else x-EXTRA)

static func mapped(at: Vector2) -> Vector2:
	return Vector2(map_x(at.x),at.y)

static func spans(span: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if span.y <= CUT:
		result.append(span)
	elif span.x >= CUT:
		result.append(span+Vector2.ONE*EXTRA)
	else:
		result.append(Vector2(span.x,CUT))
		result.append(Vector2(CUT+EXTRA,span.y+EXTRA))
	return result

static func install(owner_level: Node2D) -> void:
	var expansion: Node2D = load("res://scripts/stage_expansion.gd").new()
	expansion.name = "StageExpansion"
	expansion.level = owner_level
	owner_level.add_child(expansion)
	expansion.build()

func move_world(node: Node) -> void:
	if node in [level.player,level.camera,level.effects,self] or node is CanvasLayer or node.name in ["DistantTown","DistantForest"]:
		return
	if node.is_in_group("water_surfaces"):
		return
	if node is StaticBody2D:
		var collision: CollisionShape2D = node.get_child(0)
		var box: RectangleShape2D = collision.shape
		var rect := Rect2(node.position-box.size/2,box.size)
		for span: Vector2 in spans(Vector2(rect.position.x,rect.end.x)):
			Town.solid(level,Rect2(span.x,rect.position.y,span.y-span.x,rect.size.y),collision.one_way_collision)
		node.queue_free()
		return
	if node is Node2D and node.global_position.x >= CUT:
		node.global_position.x += EXTRA
		return
	if node is Control and node.global_position.x >= CUT:
		node.global_position.x += EXTRA
	for child: Node in node.get_children():
		move_world(child)

func move_data(node: Node) -> void:
	for property: String in ["smoke","butterflies","drifting","wisps","actors","signs"]:
		var value: Variant = node.get(property)
		if value is Array:
			for entry: Variant in value:
				if entry is Dictionary:
					if entry.get("x") is float or entry.get("x") is int:
						entry.x = map_x(entry.x)
					for key: String in ["home","position"]:
						if entry.get(key) is Vector2:
							entry[key] = mapped(entry[key])
	for child: Node in node.get_children():
		move_data(child)

func build() -> void:
	var layout := Layout.new()
	for span: Vector2 in level.profile.builder.FLOORS:
		layout.FLOORS.append_array(spans(span))
	for rect: Rect2 in level.profile.builder.LEDGES:
		for span: Vector2 in spans(Vector2(rect.position.x,rect.end.x)):
			layout.LEDGES.append(Rect2(span.x,rect.position.y,span.y-span.x,rect.size.y))
	for node: Node in level.get_children():
		move_world(node)
	move_data(level.world_details)
	move_data(level.get_node("WorldMotion"))
	move_data(level.get_node("JourneyDetails"))
	var gaps: Array[Vector2] = []
	for gap: Vector2 in level.profile.gaps:
		gaps.append_array(spans(gap))
	level.profile.gaps.assign(gaps)
	for water: Node2D in get_tree().get_nodes_in_group("water_surfaces"):
		if not level.is_ancestor_of(water):
			continue
		for span: Vector2 in spans(Vector2(water.position.x,water.position.x+water.width)):
			add_water(span,630,water.purity)
		water.queue_free()
	for property: String in ["checkpoints","urns","plants","ground_coins"]:
		var values: Array = level.profile.get(property)
		for i: int in values.size():
			values[i] = map_x(values[i])
	for property: String in ["seals","mimics"]:
		var values: Array = level.profile.get(property)
		for i: int in values.size():
			values[i] = mapped(values[i])
	level.profile.boss_at = mapped(level.profile.boss_at)
	for item: Dictionary in level.items:
		item.position = mapped(item.position)
	for i: int in level.hazards.size():
		level.hazards[i].position = mapped(level.hazards[i].position)
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		enemy.home = mapped(enemy.home)
		enemy.last_seen = enemy.home
	level.profile.builder = layout
	var first_lower: bool = level.chapter in [9,10]
	chamber(CUT,first_lower,4 if level.chapter in [1,2,7,9] else 5,layout)
	chamber(CUT+3200,not first_lower,4,layout)
	var objective: Vector2 = rooms[1].peak+Vector2(0,-50)
	level.profile.seals[2] = objective
	var index: int = 0
	for item: Dictionary in level.items:
		if item.kind == "seal":
			if index == 2:
				item.position = objective
				item.visual.position = objective
			index += 1
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		Footing.configure(enemy,level)
	level.checkpoints.sort_custom(func(a: Sprite2D,b: Sprite2D) -> bool: return a.position.x < b.position.x)
	level.profile.checkpoints.sort()
	level.stage_width = WIDTH
	level.extended = true
	level.extension = self
	level.player.world_width = WIDTH
	level.player.world_bottom = 1850
	level.camera.limit_right = int(WIDTH)
	level.camera.limit_top = -900
	level.camera.limit_bottom = 1800
	level.hud.stage_width = WIDTH
	level.hud.checkpoint_total = level.checkpoints.size()
	level.hud.total_coins = level.items.size()-3
	for name: String in ["DistantTown","DistantForest"]:
		var layer: Node2D = level.get_node(name)
		var max_x: float = 0
		for child: Node2D in layer.get_children():
			max_x = maxf(max_x,child.position.x)
		var source: Array[Node] = layer.get_children()
		for repeat: int in range(1,4):
			for child: Node2D in source:
				if child.position.x <= max_x-2200:
					continue
				var copy: Node2D = child.duplicate()
				copy.position.x += 2200*repeat
				if level.chapter == 10 and name == "DistantTown":
					copy.modulate.a *= 1.0-smoothstep(2400,3400,copy.position.x)
				layer.add_child(copy)

func add_water(span: Vector2, y: float, purity: float) -> void:
	if span.y-span.x < 1:
		return
	var water: Node2D = preload("res://scripts/cursed_water.gd").new()
	water.position = Vector2(span.x,y)
	water.width = span.y-span.x
	water.purity = purity
	level.add_child(water)

func surface(rect: Rect2, ground: bool, layout: RefCounted) -> void:
	Town.solid(level,rect,not ground)
	if ground:
		layout.FLOORS.append(Vector2(rect.position.x,rect.end.x))
	else:
		layout.LEDGES.append(rect)
	for x: int in range(int(rect.position.x),int(rect.end.x),64):
		var width: float = minf(64,rect.end.x-x)
		for row: int in (4 if ground else 1):
			var style: Dictionary = Styles.terrain_style(level.chapter,row)
			var tile: Sprite2D = Assets.sprite(level,style.path,Vector2(x+width/2,rect.position.y+10+row*64),1,0 if ground else 1)
			tile.region_enabled = true
			tile.region_rect = style.crop
			tile.scale = Vector2(width/style.crop.size.x,(64 if ground else 20.0)/style.crop.size.y)
			if ground:
				tile.position.y = rect.position.y+32+row*64
			tile.modulate = style.tint

func backdrop_panel(rect: Rect2, depth: int, tint: Color) -> void:
	var style: Dictionary = Styles.terrain_style(level.chapter,1)
	if level.chapter in [7,8,11,12]:
		# Border/grass tiles are unsuitable as a repeating underground fill.
		# Crop only opaque soil, leaving no transparent seams or grassy grid.
		style.path = preload("res://scripts/deep_biome.gd").SOIL+"dark_soil_fill.png" if level.chapter >= 11 else "res://Stages/Abandonded Forest/1. Overgrown Forest Ground & Terrain/dark_soil.png"
		style.crop = Rect2(4,8,24,18)
	var panel: Sprite2D = Assets.sprite(level,style.path,rect.get_center(),2,depth)
	var key: String = style.path+str(style.crop)
	if not wall_tiles.has(key):
		var pixels: Image = Assets.texture(style.path).get_image()
		if pixels.is_compressed():
			pixels.decompress()
		wall_tiles[key] = ImageTexture.create_from_image(pixels.get_region(Rect2i(style.crop)))
	panel.texture = wall_tiles[key]
	panel.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	panel.region_enabled = true
	panel.region_rect = Rect2(Vector2.ZERO,rect.size/2)
	panel.modulate = tint
	panel.add_to_group("scenic_fill")

func chamber(start: float, lower: bool, steps: int, layout: RefCounted) -> void:
	surface(Rect2(start,600,480,220),true,layout)
	surface(Rect2(start+2800,600,400,220),true,layout)
	var platforms: Array[Rect2] = []
	for i: int in range(2*steps-1):
		var elevation: float = minf(i+1,2*steps-1-i)*160*(1 if lower else -1)
		var rect := Rect2(start+400+i*(2000.0/(2*steps-2)),600+elevation,320,20)
		platforms.append(rect)
		surface(rect,false,layout)
		route.append(Vector2(rect.end.x-64,rect.position.y))
		for dx: float in [72.0,184.0]:
			level.add_item("coin",rect.position+Vector2(dx,-44))
	var peak: Vector2 = platforms[steps-1].get_center()-Vector2(0,10)
	var woods: bool = level.chapter in [7,8,11,12]
	if lower:
		var shade := Polygon2D.new()
		shade.polygon = PackedVector2Array([Vector2(start+350,600),Vector2(start+2850,600),Vector2(start+2850,1700),Vector2(start+350,1700)])
		shade.color = Color("121825")
		shade.z_index = -16
		level.add_child(shade)
		backdrop_panel(Rect2(start+350,600,2500,1100),-13,Color("303f3c") if woods else Color("46515c"))
	if woods:
		for index: int in platforms.size():
			preload("res://scripts/scenery_composition.gd").woodland_tier(level,platforms[index],1640 if lower else 1060,not lower and index == steps-1)
	elif not lower:
		for index: int in platforms.size():
			var footing: Rect2 = platforms[index]
			var width: float = 180 if index == steps-1 else 96
			backdrop_panel(Rect2(footing.get_center().x-width/2,footing.position.y,width,1010-footing.position.y),-10,Color("58616c"))
	rooms.append({"start":start,"lower":lower,"platforms":platforms,"peak":peak,"death_y":1680.0 if lower else 1100.0})
	add_water(Vector2(start+480,start+2800),1590 if lower else 1010,0.55 if level.chapter < 7 else 0.9)
	var lantern: Sprite2D = Assets.sprite(level,Assets.PROPS+"spirit_lantern.png",Vector2(start+192,551),3,3)
	level.checkpoints.append(lantern)
	level.profile.checkpoints.append(start+192)
	level.lighting.add_glow(lantern.position,Color("76d9c8"),125,lantern)
	var urn: Node2D = preload("res://scripts/breakable_urn.gd").new()
	urn.chapter = level.chapter
	urn.position = Vector2(start+368,600)
	level.add_child(urn)
	urn.shattered.connect(level.combat.urn_shattered)
	level.profile.urns.append(start+368)
	var fire: Sprite2D = preload("res://scripts/upright_campfire.gd").place(level.world_details,start+80)
	level.world_details.fires.append(fire)
	level.lighting.add_glow(fire.position,Color("ffc784"),100,fire)
	var arch: String = Assets.CRYPT+"stone_archway.png"
	if level.chapter in [3,4]:
		arch = "res://Stages/Medievil Kingdom/3. Medieval Castles & Royal Architecture/stone_archway.png"
	elif level.chapter in [5,6]:
		arch = "res://Stages/Dark Fantasy/10. Doors, Windows & Architectural Pieces/vaulted_stone_arch.png"
	elif level.chapter in [7,8]:
		arch = "res://Stages/Abandonded Forest/6. Forgotten Ruins & Mossy Stone Structures/stone_arch.png"
	elif level.chapter in [9,10]:
		arch = preload("res://scripts/deep_biome.gd").TOMB+"stone_arch.png"
	elif level.chapter >= 11:
		arch = preload("res://scripts/deep_biome.gd").RELIC+"rune_arch_gateway.png"
	if not woods:
		Assets.grounded(level,arch,peak.x,5,-7,peak.y).modulate = Color("8b9fa4")
	for i: int in [1,steps-1]:
		var enemy: Node2D = preload("res://scripts/haunt.gd").new()
		enemy.species = "guard" if i == 1 else "mushroom"
		enemy.position = Vector2(platforms[i].get_center().x,platforms[i].position.y)
		level.add_child(enemy)
		level.combat.connect_enemy(enemy,true)
	var caster: Node2D = preload("res://scripts/haunt.gd").new()
	caster.species = "witch" if level.chapter in [3,4,5,6,9,10,12] else "mosquito"
	caster.position = peak+Vector2(240,-130)
	level.add_child(caster)
	level.combat.connect_enemy(caster,true)

func region() -> String:
	for i: int in rooms.size():
		var room: Dictionary = rooms[i]
		if level.player.position.x >= room.start and level.player.position.x < room.start+3200:
			return ROOM_NAMES[level.chapter-1][i]
	return level.profile.regions[mini(3,int(base_x(level.player.position.x)/1600))]

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(level.player) or level.completed:
		return
	for room: Dictionary in rooms:
		if level.player.position.x > room.start+480 and level.player.position.x < room.start+2800 and level.player.position.y > room.death_y:
			level.respawn()
