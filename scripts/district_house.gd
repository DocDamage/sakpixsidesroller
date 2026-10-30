extends Node2D

# One architectural family, one source-pixel scale, continuous wall/roof/base.
# Room infills fade when entered; the building's silhouette and frame remain.
const Assets = preload("res://scripts/level_assets.gd")
const KIT: String = "res://Stages/GandalfHardcore Pixel Art Medieval Fantasy Assets/"
const PIXEL: int = 3
var level: Node2D
var facade: Sprite2D
var interior: Rect2
var cutaway: bool = false
var native_floor: int
var canvas_width: int
var base: Image
var front: Image
var outside: Image
var inside: Image
var roofline: PackedVector2Array = []
var furnishings: Array[Dictionary] = []

static func install(builder: RefCounted, at: Vector2, columns: int, wall_height: int, enterable: bool, flat: bool = false) -> Node2D:
	var house: Node2D = load("res://scripts/district_house.gd").new()
	house.level = builder.level
	house.position = at
	house.cutaway = enterable
	builder.level.add_child(house)
	house.compose(columns,wall_height,flat)
	return house

func source(path: String) -> Image:
	var result: Image = Assets.texture(KIT+path).get_image()
	if result.is_compressed():
		result.decompress()
	return result

func tile(target: Image, sheet: Image, crop: Rect2i, area: Rect2i) -> void:
	assert(sheet.get_region(crop).get_used_rect().has_area(),"Empty architectural source crop: "+str(crop))
	for y: int in range(area.position.y,area.end.y,crop.size.y):
		for x: int in range(area.position.x,area.end.x,crop.size.x):
			var part := Rect2i(crop.position,Vector2i(mini(crop.size.x,area.end.x-x),mini(crop.size.y,area.end.y-y)))
			target.blend_rect(sheet,part,Vector2i(x,y))

func image_at(target: Image, path: String, at: Vector2i) -> void:
	var art: Image = source(path)
	target.blend_rect(art,Rect2i(Vector2i.ZERO,art.get_size()),at)

func world_at(at: Vector2) -> Vector2i:
	return Vector2i(((at-position)/PIXEL).round())

func foot(target: Image, path: String, at: Vector2) -> void:
	var art: Image = source(path)
	var point: Vector2i = world_at(at)
	var opaque: Rect2i = art.get_used_rect()
	var origin: Vector2i = point-Vector2i(opaque.get_center().x,opaque.end.y)
	target.blend_rect(art,Rect2i(Vector2i.ZERO,art.get_size()),origin)
	if path.begins_with("House Furniture"):
		furnishings.append({"path":path,"feet":at,"bounds":Rect2(position+Vector2(origin+opaque.position)*PIXEL,Vector2(opaque.size)*PIXEL)})

func shadow(target: Image, rect: Rect2i, opacity: float) -> void:
	var shade := Image.create(rect.size.x,rect.size.y,false,Image.FORMAT_RGBA8)
	shade.fill(Color(0.04,0.03,0.07,opacity))
	target.blend_rect(shade,Rect2i(Vector2i.ZERO,rect.size),rect.position)

func sprite(art: Image, depth: int) -> Sprite2D:
	var visual := Sprite2D.new()
	visual.texture = ImageTexture.create_from_image(art)
	visual.centered = false
	visual.scale = Vector2.ONE*PIXEL
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.z_index = depth
	add_child(visual)
	return visual

func compose(columns: int, wall_height: int, flat: bool) -> void:
	canvas_width = columns*160 if not flat else 192
	var roof_height: int = 0 if flat else 79
	var rows: int = ceili(float(wall_height)/PIXEL)
	native_floor = roof_height+rows
	base = Image.create(canvas_width,native_floor+14,false,Image.FORMAT_RGBA8)
	front = Image.create(canvas_width,native_floor+14,false,Image.FORMAT_RGBA8)
	outside = source("House Outside Tiles.png")
	inside = source("House Inside Tiles.png")
	var body := Rect2i(12,roof_height,canvas_width-24,rows)
	tile(base,inside,Rect2i(32,40,32,24),body)
	tile(front,outside,Rect2i(64,64,32,24),body)
	# Foundation runs below the terrain seam, with a shared stone sill.
	tile(base,outside,Rect2i(16,384,32,8),Rect2i(12,native_floor-4,canvas_width-24,12))
	tile(base,inside,Rect2i(32,240,32,16),Rect2i(12,native_floor-32,canvas_width-24,28))
	if not flat:
		for bay: int in columns:
			var gable: String = "plaster_gable_roof.png" if not cutaway and position.x > 1000 else "wooden_gable_roof.png"
			image_at(base,"House Outside Sprites/"+gable,Vector2i(bay*160,0))
	# The cornice and end caps are from the same wall set as the infill.
	tile(base,outside,Rect2i(16,96,32,16),Rect2i(4,roof_height,canvas_width-8,12))
	for x: int in [12,canvas_width-28]:
		var bottom: int = native_floor if not cutaway else world_at(Vector2(0,280 if x == 12 else -40)).y
		tile(base,outside,Rect2i(0,112,16,48),Rect2i(x,roof_height+12,16,maxi(1,bottom-roof_height-12)))
	if cutaway:
		compose_rooms()
	else:
		var feet: Vector2 = position+Vector2(canvas_width*PIXEL/2,native_floor*PIXEL)
		foot(front,"House Outside Sprites/arched_wooden_door.png",feet)
		for dx: float in [-140,140]:
			foot(front,"House Outside Sprites/lattice_window_red.png",feet+Vector2(dx,-108))
		if wall_height > 450:
			for dx: float in [-140,140]:
				foot(front,"House Outside Sprites/lattice_window_red.png",feet+Vector2(dx,-375))
	for x: int in range(156,canvas_width-28,160):
		tile(base,outside,Rect2i(0,112,8,48),Rect2i(x,roof_height+12,8,rows-12))
	# Copy the structural frame into the exterior skin, preserving matching joins.
	front.blend_rect(base,Rect2i(4,roof_height,canvas_width-8,12),Vector2i(4,roof_height))
	for x: int in [12,canvas_width-28]:
		front.blend_rect(base,Rect2i(x,roof_height+12,16,rows-12),Vector2i(x,roof_height+12))
	for x: int in range(156,canvas_width-28,160):
		front.blend_rect(base,Rect2i(x,roof_height+12,8,rows-12),Vector2i(x,roof_height+12))
	# Contact shading is confined to actual joins, never a haze over the house.
	for i: int in 8:
		shadow(base,Rect2i(28,roof_height+12+i,canvas_width-56,1),0.22*(1.0-i/8.0))
		shadow(base,Rect2i(28,native_floor-1-i,canvas_width-56,1),0.12*(1.0-i/8.0))
	var backing: Sprite2D = sprite(base,-11)
	backing.modulate = Color("b8afba")
	if cutaway or flat:
		for x: int in range(0,canvas_width,4):
			for y: int in native_floor:
				if base.get_pixel(x,y).a > 0.5:
					roofline.append(position+Vector2(x,y)*PIXEL)
					break
	if cutaway:
		var frame := Image.create(canvas_width,native_floor+14,false,Image.FORMAT_RGBA8)
		for rect: Rect2 in [Rect2(2200,-200,60,480),Rect2(2200,-200,1350,32),Rect2(3410,-200,140,160),Rect2(2270,180,250,40)]:
			var region := Rect2i(world_at(rect.position),Vector2i((rect.size/PIXEL).ceil()))
			tile(frame,inside,Rect2i(32,40,32,24),region)
			tile(frame,inside,Rect2i(32,24,32,8),Rect2i(region.position,Vector2i(region.size.x,mini(8,region.size.y))))
			shadow(frame,Rect2i(region.position+Vector2i(0,region.size.y-3),Vector2i(region.size.x,3)),0.35)
		var frame_visual: Sprite2D = sprite(frame,0)
		var frame_material := CanvasItemMaterial.new()
		frame_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		frame_visual.material = frame_material
		frame_visual.modulate = Color("3c3546")
	facade = sprite(front,-10 if not cutaway else 6)
	# Exterior fixtures illuminate the closed facade on their own light mask.
	# Interior lamps cannot project cutaway floors across the exterior plaster.
	facade.light_mask = 2
	facade.modulate = Color("b8afba")
	interior = Rect2(position+Vector2(30,roof_height*PIXEL),Vector2(canvas_width*PIXEL-60,rows*PIXEL))
	set_meta("building_bounds",Rect2(position,Vector2(canvas_width,native_floor+8)*PIXEL))
	add_to_group("district_buildings")
	if cutaway:
		facade.modulate.a = 0
	set_process(cutaway)

func compose_rooms() -> void:
	for entry: Vector3 in [Vector3(2620,3550,120),Vector3(2280,2750,380)]:
		var at: Vector2i = world_at(Vector2(entry.x,entry.z))
		var span: int = roundi((entry.y-entry.x)/PIXEL)
		# The collidable floor supplies the timber skin. Only its contact shadow
		# is baked into the room; no second ornate platform behind the ladder.
		for i: int in 8:
			shadow(base,Rect2i(at.x,at.y+8+i,span,1),0.24*(1.0-i/8.0))
	# A tall ritual room and a working loft, sharing the same plaster and joinery.
	for at: Vector2 in [Vector2(2390,60),Vector2(2860,60),Vector2(3260,60),Vector2(3020,465)]:
		# View from inside: bare leaded panes, no exterior shutters.
		var glass: Image = source("House Inside Sprites/red_shuttered_lattice_window.png").get_region(Rect2i(14,0,30,64))
		base.blend_rect(glass,Rect2i(Vector2i.ZERO,glass.get_size()),world_at(at)-Vector2i(15,64))
		foot(front,"House Outside Sprites/lattice_window_red.png",at)
		var light := Sprite2D.new()
		light.position = at-position-Vector2(0,96)
		light.set_meta("warm",true)
		light.add_to_group("bell_window_sources")
		add_child(light)
	foot(base,"House Inside Sprites/dark_doorway.png",Vector2(2920,600))
	foot(base,"House Furniture Sprites/glass_display_cabinet.png",Vector2(3000,120))
	foot(base,"House Furniture Sprites/small_bookshelf.png",Vector2(2770,120))
	foot(base,"House Furniture Sprites/wooden_cabinet.png",Vector2(2520,380))
	# This extracted source also contains a textile below the mantel. Keep only
	# the complete mantel/opening and put its stone foot at the actual floor.
	var hearth: Image = source("House Furniture Sprites/fireplace.png").get_region(Rect2i(0,0,46,34))
	base.blend_rect(hearth,Rect2i(Vector2i.ZERO,hearth.get_size()),world_at(Vector2(3300,600))-Vector2i(23,34))
	furnishings.append({"path":"hearth","feet":Vector2(3300,600),"bounds":Rect2(3231,498,138,102)})
	for at: Vector2 in [Vector2(2420,600),Vector2(3320,600)]:
		foot(front,"House Outside Sprites/arched_wooden_door.png",at)

func _process(delta: float) -> void:
	if not is_instance_valid(level.player):
		return
	var within: bool = interior.grow(80).has_point(level.player.position-Vector2(0,32))
	facade.modulate.a = move_toward(facade.modulate.a,0 if within else 1,delta*5)
