extends RefCounted

# A room sequence: sheltered stair -> roof crossing -> switchback bell shaft ->
# reward gallery. The powered cage provides a different way back to the court.
const Assets = preload("res://scripts/level_assets.gd")
var layout: RefCounted
var world: Node2D

func build(builder: RefCounted) -> void:
	layout = builder
	world = builder.level
	court()
	tower()

func masonry(rect: Rect2, tint: String = "626475", depth: int = -11) -> void:
	layout.panel(Assets.GROUND+"purple_stone_brick.png",rect,Rect2(4,5,24,24),depth,Color(tint))

func timber(rect: Rect2, depth: int = -9) -> void:
	layout.panel(Assets.PLATFORMS+"wooden_plank_ledge.png",rect,Rect2(3,14,26,8),depth,Color("82716c"))

func shape(points: PackedVector2Array, color: Color, depth: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = depth
	world.add_child(polygon)
	return polygon

func recess(rect: Rect2, tint: String = "151c2a") -> void:
	shape(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),Color(tint),-10)

func fitted(path: String, rect: Rect2, depth: int, tint: String) -> Sprite2D:
	var sprite: Sprite2D = Assets.sprite(world,path,rect.get_center(),1,depth)
	sprite.region_enabled = true
	sprite.region_rect = Assets.opaque_rect(path)
	sprite.scale = rect.size/sprite.region_rect.size
	sprite.modulate = Color(tint)
	return sprite

func window(at: Vector2, size: Vector2, warm: bool = false) -> void:
	var rect := Rect2(at,size)
	recess(rect.grow(10))
	# Extend the panes at the source pixel scale; preserve the arch and sill.
	var source: Image = Assets.texture(Assets.HOUSES+"gothic_window.png").get_image()
	if source.is_compressed():
		source.decompress()
	var height: int = maxi(28,roundi(size.y/(size.x/20)))
	var glass: Image = Image.create(20,height,false,Image.FORMAT_RGBA8)
	glass.blit_rect(source,Rect2i(6,2,20,12),Vector2i.ZERO)
	for y: int in range(12,height-4):
		glass.blit_rect(source,Rect2i(6,14+(y-12)%12,20,1),Vector2i(0,y))
	glass.blit_rect(source,Rect2i(6,26,20,4),Vector2i(0,height-4))
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(glass)
	sprite.position = rect.get_center()
	sprite.scale = size/Vector2(20,height)
	sprite.z_index = -8
	sprite.modulate = Color("bea67f" if warm else "849da8")
	world.add_child(sprite)
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = material
	sprite.modulate.a = 0.62
	sprite.add_to_group("bell_window_sources")
	sprite.set_meta("warm",warm)
	# A limited, source-aligned beam fades into the room behind the action.
	var beam: Polygon2D = shape(PackedVector2Array([at+Vector2(size.x*0.25,size.y*0.7),at+size,at+size+Vector2(240,310),at+Vector2(70,size.y+310)]),Color.WHITE,-7)
	var color := Color("e6c79b" if warm else "a9c7df")
	beam.vertex_colors = PackedColorArray([Color(color,0.04),Color(color,0.05),Color(color,0),Color(color,0)])
	beam.material = material

func ledge(rect: Rect2, stone: bool = false) -> void:
	layout.platform(rect,"stone" if stone else "wood")
	# Short brackets are anchored to piers, never kilometre-long free posts.
	for x: float in [rect.position.x+35,rect.end.x-35]:
		fitted(Assets.PLATFORMS+"wooden_bracket_shelf.png",Rect2(x-30,rect.end.y,60,36),-4,"696575")

func roof(points: PackedVector2Array) -> void:
	var polygon: Polygon2D = shape(points,Color("938294"),-9)
	var source: Image = Assets.texture(Assets.HOUSES+"dark_shingle_roof.png").get_image()
	if source.is_compressed():
		source.decompress()
	polygon.texture = ImageTexture.create_from_image(source.get_region(Rect2i(5,12,22,8)))
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	polygon.texture_scale = Vector2(0.5,0.5)

func arch(rect: Rect2) -> void:
	var x: float = rect.position.x
	var y: float = rect.position.y
	var w: float = rect.size.x
	var h: float = rect.size.y
	var outer := PackedVector2Array([Vector2(x,y+h),Vector2(x,y+h*0.35),Vector2(x+w*0.18,y+h*0.13),Vector2(x+w*0.5,y),Vector2(x+w*0.82,y+h*0.13),Vector2(x+w,y+h*0.35),Vector2(x+w,y+h)])
	var frame: Polygon2D = shape(outer,Color("8d8299"),-8)
	var brick: Image = Assets.texture(Assets.GROUND+"grey_stone_brick.png").get_image()
	if brick.is_compressed():
		brick.decompress()
	frame.texture = ImageTexture.create_from_image(brick.get_region(Rect2i(3,5,26,24)))
	frame.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	frame.texture_scale = Vector2(0.5,0.5)
	var inner := PackedVector2Array([Vector2(x+18,y+h),Vector2(x+18,y+h*0.38),Vector2(x+w*0.23,y+h*0.20),Vector2(x+w*0.5,y+20),Vector2(x+w*0.77,y+h*0.20),Vector2(x+w-18,y+h*0.38),Vector2(x+w-18,y+h)])
	shape(inner,Color("101724"),-7)
	# Frame footing is grounded; restrained masonry keeps source pixel scale.
	for foot_x: float in [x-7,x+w-25]:
		masonry(Rect2(foot_x,y+h-25,32,25),"8f8198",-6)

func court() -> void:
	# Complete buildings share one kit and source scale. The cutaway follows the
	# playable rooms; roof, cornice and foundation remain one coherent structure.
	preload("res://scripts/district_house.gd").install(layout,Vector2(2144,-437),3,800,true)
	preload("res://scripts/district_house.gd").install(layout,Vector2(3620,-80),1,680,false,true)
	for rect: Rect2 in [Rect2(2280,380,470,24),Rect2(2620,120,930,24),Rect2(3650,-80,560,24)]:
		layout.platform(rect,"house")
	# Collision remains at the actual cutaway edges and open side entrances.
	for rect: Rect2 in [Rect2(2200,-200,60,480),Rect2(2200,-200,1350,32),Rect2(3410,-200,140,160),Rect2(2270,180,250,40)]:
		layout.wall(rect,false)

func tower() -> void:
	# Thick tower piers and separate voids establish the whole cross-section.
	masonry(Rect2(3980,-980,1540,1580),"454655",-13)
	for rect: Rect2 in [Rect2(4080,-910,570,1390),Rect2(4800,-910,570,1390)]:
		recess(rect,"1b2330")
	for at: Vector2 in [Vector2(4220,-800),Vector2(4930,-780)]:
		window(at,Vector2(100,310))
	# Openings through the piers line up with the approach and top gallery.
	for rect: Rect2 in [Rect2(3960,-1040,120,730),Rect2(3960,260,120,120),Rect2(5480,-1080,100,240),Rect2(5480,-470,100,370)]:
		layout.wall(rect)
	layout.wall(Rect2(4080,-1040,1400,60))
	ledge(Rect2(3960,200,220,24),true)
	ledge(Rect2(4380,-240,300,24),true)
	ledge(Rect2(4040,-400,280,24),true)
	ledge(Rect2(4250,-500,580,28),true)
	ledge(Rect2(5000,-500,480,28),true)
	# A low overhead break changes the upper crossing's silhouette.
	layout.wall(Rect2(4800,-980,130,260))
	fitted(Assets.CRYPT+"hanging_chains_a.png",Rect2(4670,-980,16,305),-6,"9e93a4")
	fitted("res://Stages/Medievil Kingdom/10. Medieval Collectibles, Interactive Objects & Royal Details/rope_winch.png",Rect2(4640,-690,90,110),-5,"b7a78e")
	# The last leap passes through a broken wall into a quieter reward chapel.
	masonry(Rect2(5580,-1060,660,660),"555366")
	recess(Rect2(5620,-1010,580,290),"242536")
	window(Vector2(5810,-1000),Vector2(100,235),true)
	ledge(Rect2(5560,-700,620,28),true)
	layout.wall(Rect2(5580,-1060,660,40))
	layout.wall(Rect2(6240,-1060,60,260))
	roof(PackedVector2Array([Vector2(5540,-1060),Vector2(5930,-1260),Vector2(6320,-1060)]))
	# Grounded bases continue to the graveyard; broad street passages stay open.
	for x: float in [3990,5500,6220]:
		masonry(Rect2(x,260,90,340),"454655",-12)
