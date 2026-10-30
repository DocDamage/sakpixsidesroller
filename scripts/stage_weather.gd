extends Node2D

const Blend = preload("res://scripts/stage_blend.gd")
const Expansion = preload("res://scripts/stage_expansion.gd")
# rain, low mist, wind, cloud cover; adjacent chapters meet at the same blend.
const CLIMATE: Array[Vector4] = [Vector4(0.40,0.29,0.33,0.55),Vector4(0.23,0.15,0.29,0.36),Vector4(0.52,0.16,0.43,0.61),Vector4(0.70,0.24,0.64,0.83),Vector4(0.82,0.34,0.73,0.90),Vector4(0.45,0.31,0.37,0.72),Vector4(0.55,0.33,0.41,0.63),Vector4(0.23,0.44,0.23,0.43),Vector4(0.0,0.27,0.06,0.0),Vector4(0.32,0.24,0.31,0.49),Vector4(0.17,0.29,0.25,0.36),Vector4(0.08,0.19,0.18,0.22)]
const STORMS: Array[float] = [0.1,0.0,0.18,0.55,0.8,0.2,0.12,0.0,0.0,0.0,0.0,0.0]
const MAP_SIZE: int = 2048
static var journey_clock: float = 0.0
var level: Node2D
var clock: float = 0.0
var climate: Vector4
var wind: float = 0.0
var precipitation: float = 0.0
var wetness: float = 0.0
var flash: float = 0.0
var flash_age: float = 100.0
var next_flash: float = 0.0
var clearing: float = 0.0
var cloud_material: ShaderMaterial
var rain_material: ShaderMaterial
var fog_material: ShaderMaterial
var wet_materials: Array[ShaderMaterial] = []
var panels: Array[ColorRect] = []
var roof_map: ImageTexture
var roof_image: Image
var ceilings := PackedFloat32Array()
var floors := PackedFloat32Array()
var exposure := PackedFloat32Array()

static func install(owner_level: Node2D) -> void:
	var weather: Node2D = load("res://scripts/stage_weather.gd").new()
	weather.name = "StageWeather"
	weather.level = owner_level
	owner_level.weather = weather
	owner_level.add_child(weather)
	weather.setup()

static func climate_at(stage: int, x: float) -> Vector4:
	var value: Vector4 = CLIMATE[stage-1]
	var entering: bool = x < Blend.WIDTH
	var neighbour: int = stage-1 if entering else stage+1
	if neighbour >= 1 and neighbour <= CLIMATE.size():
		value = value.lerp(CLIMATE[neighbour-1],Blend.weight(x,entering))
	return value

func setup() -> void:
	clock = journey_clock
	next_flash = clock+34+level.chapter%4*5
	bake_shelter()
	cloud_material = panel(preload("res://scripts/weather_clouds.gdshader"),-9)
	fog_material = panel(preload("res://scripts/weather_fog.gdshader"),7)
	rain_material = panel(preload("res://scripts/weather_rain.gdshader"),8)
	for material: ShaderMaterial in [rain_material,fog_material]:
		material.set_shader_parameter("roof_map",roof_map)
		material.set_shader_parameter("world_width",level.stage_width)
	install_wet_surfaces()
	wetness = climate_at(level.chapter,Expansion.base_x(level.player.position.x)).x
	_process(0.0)

func panel(shader: Shader, layer_index: int) -> ShaderMaterial:
	var layer := CanvasLayer.new()
	layer.layer = layer_index
	add_child(layer)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var material := ShaderMaterial.new()
	material.shader = shader
	rect.material = material
	layer.add_child(rect)
	panels.append(rect)
	return material

func column(x: float) -> int:
	return clampi(int(x/level.stage_width*MAP_SIZE),0,MAP_SIZE-1)

func cover_span(left: float, right: float, height: float) -> void:
	for i: int in range(column(left),column(right)+1):
		ceilings[i] = minf(ceilings[i],height)

static func pack_height(height: float, sky: float) -> Color:
	var value: int = clampi(roundi((height+1400)/4000*65535),0,65535)
	return Color(float(value/256)/255.0,float(value%256)/255.0,sky,1.0)

func bake_shelter() -> void:
	ceilings.resize(MAP_SIZE)
	floors.resize(MAP_SIZE)
	exposure.resize(MAP_SIZE)
	ceilings.fill(2500)
	floors.fill(630)
	exposure.fill(1)
	for span: Vector2 in level.profile.builder.FLOORS:
		cover_span(span.x,span.y,600)
		for i: int in range(column(span.x),column(span.y)+1):
			floors[i] = 600
	for ledge: Rect2 in level.profile.builder.LEDGES:
		cover_span(ledge.position.x,ledge.end.x,ledge.position.y)
	for water: Node2D in get_tree().get_nodes_in_group("water_surfaces"):
		if not level.is_ancestor_of(water) or water.is_queued_for_deletion():
			continue
		cover_span(water.position.x,water.position.x+water.width,water.position.y)
		for i: int in range(column(water.position.x),column(water.position.x+water.width)+1):
			floors[i] = water.position.y
	if level.district != null:
		floors.fill(2500)
		for surface: Dictionary in level.profile.builder.surfaces:
			var rect: Rect2 = surface.rect
			if rect.position.y < level.player.position.y-90:
				continue
			for i: int in range(column(rect.position.x),column(rect.end.x)+1):
				floors[i] = minf(floors[i],rect.position.y)
		for space: Dictionary in level.district.spaces:
			if space.sheltered:
				cover_span(space.rect.position.x,space.rect.end.x,space.rect.position.y)
		for building: Node2D in get_tree().get_nodes_in_group("district_buildings"):
			if not level.is_ancestor_of(building):
				continue
			for point: Vector2 in building.roofline:
				cover_span(point.x,point.x+12,point.y)
	for room: Dictionary in level.extension.rooms:
		for i: int in range(column(room.start+350),column(room.start+2850)+1):
			floors[i] = 1590 if room.lower else 1010
		if room.lower:
			cover_span(room.start+350,room.start+2850,600)
	for i: int in MAP_SIZE:
		var x: float = (i+0.5)/MAP_SIZE*level.stage_width
		if level.chapter == 9:
			exposure[i] = 0
		elif level.chapter == 10:
			exposure[i] = smoothstep(11200,12000,x)
			for room: Dictionary in level.extension.rooms:
				if not room.lower and x >= room.start and x <= room.start+3200:
					exposure[i] = 1
		elif level.chapter == 6:
			# The roofed nave stays dry; open cloister crossings and the exit
			# toward Briarwood receive rain. The elevated belfry is outside.
			exposure[i] = 1 if x >= 11200 or (x > 1536 and x < 1792) or (x > 2880 and x < 3200) or (x > 4416 and x < 4672) else 0
			for room: Dictionary in level.extension.rooms:
				if not room.lower and x >= room.start and x <= room.start+3200:
					exposure[i] = 1
	roof_image = Image.create(MAP_SIZE,2,false,Image.FORMAT_RGBA8)
	for i: int in MAP_SIZE:
		roof_image.set_pixel(i,0,pack_height(ceilings[i],exposure[i]))
		roof_image.set_pixel(i,1,pack_height(floors[i],exposure[i]))
	if roof_map == null:
		roof_map = ImageTexture.create_from_image(roof_image)
	else:
		roof_map.update(roof_image)

func sky_at(at: Vector2) -> float:
	var i: int = column(at.x)
	return exposure[i] if at.y < ceilings[i]+2 else 0.0

func install_wet_surfaces() -> void:
	var materials: Dictionary = {}
	for tile: Sprite2D in level.get_children().filter(func(node: Node) -> bool: return node is Sprite2D):
		if not tile.region_enabled or tile.z_index < 0 or tile.z_index > 1 or tile.material != null:
			continue
		var surface_y: float = INF
		if tile.is_in_group("district_surfaces"):
			surface_y = tile.get_meta("surface_y")
		elif absf(tile.position.y-632) < 0.1:
			surface_y = 600
		else:
			for ledge: Rect2 in level.profile.builder.LEDGES:
				if tile.position.x >= ledge.position.x and tile.position.x <= ledge.end.x and tile.position.y >= ledge.position.y and tile.position.y <= ledge.position.y+22:
					surface_y = ledge.position.y
					break
		if not is_finite(surface_y):
			continue
		if not materials.has(surface_y):
			var material := ShaderMaterial.new()
			material.shader = preload("res://scripts/wet_terrain.gdshader")
			material.set_shader_parameter("roof_map",roof_map)
			material.set_shader_parameter("world_width",level.stage_width)
			material.set_shader_parameter("surface_y",surface_y)
			materials[surface_y] = material
			wet_materials.append(material)
		tile.material = materials[surface_y]
		tile.add_to_group("weather_surfaces")

func _process(delta: float) -> void:
	if level == null or rain_material == null:
		return
	clock += delta
	journey_clock = clock
	var story_x: float = Expansion.base_x(level.player.position.x)
	if level.district != null:
		story_x = level.district.story_x()
	climate = climate_at(level.chapter,story_x)
	clearing = move_toward(clearing,1.0 if level.completed and level.chapter in [1,12] else 0.0,delta*0.065)
	var gust: float = 0.80+sin(clock*0.17)*0.13+sin(clock*0.071+1.4)*0.07
	wind = climate.z*gust
	precipitation = climate.x*(0.91+sin(clock*0.047)*0.09)*(1-clearing)
	wetness = move_toward(wetness,precipitation,delta*0.018)
	flash_age += delta
	if clock >= next_flash and STORMS[level.chapter-1] >= 0.5 and sky_at(level.player.position-Vector2(0,60)) > 0.7 and not level.completed:
		flash_age = 0
		next_flash = clock+48+level.chapter%3*7
	flash = sin(clampf(flash_age/0.65,0,1)*PI)*0.85 if flash_age < 0.65 else 0.0
	var size: Vector2 = get_viewport_rect().size
	var origin: Vector2 = level.camera.get_screen_center_position()-size/2
	for rect: ColorRect in panels:
		rect.size = size
	for material: ShaderMaterial in [cloud_material,rain_material,fog_material]:
		material.set_shader_parameter("clock",clock)
		material.set_shader_parameter("camera_origin",origin)
		material.set_shader_parameter("viewport_size",size)
		material.set_shader_parameter("wind",wind)
	cloud_material.set_shader_parameter("cover",climate.w*(1-clearing*0.8))
	cloud_material.set_shader_parameter("flash",flash)
	rain_material.set_shader_parameter("rain",precipitation)
	fog_material.set_shader_parameter("fog",climate.y*(1-clearing*0.5))
	fog_material.set_shader_parameter("flash",flash)
	for material: ShaderMaterial in wet_materials:
		material.set_shader_parameter("wetness",wetness)
		material.set_shader_parameter("clock",clock)
	var motion: Node = level.get_node("WorldMotion")
	motion.breeze.set_shader_parameter("wind_force",0.65+wind*2.0)
	for water: Node2D in get_tree().get_nodes_in_group("water_surfaces"):
		if level.is_ancestor_of(water) and not water.is_queued_for_deletion():
			var exposed: float = sky_at(water.position+Vector2(water.width/2,-2))
			water.water_material.set_shader_parameter("weather_rain",precipitation*exposed)
			water.water_material.set_shader_parameter("weather_wind",wind*exposed)
