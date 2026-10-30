extends Node2D

var width: float = 1200
var bottom: float = 1760
var target_y: float = 1320
var current: float = 30
var clock: float = 0
var water_material: ShaderMaterial
var surface: ColorRect
var level: Node2D
var ripples: PackedVector4Array = PackedVector4Array([Vector4(-1000,10,0,0),Vector4(-1000,10,0,0),Vector4(-1000,10,0,0),Vector4(-1000,10,0,0)])
var ripple_index: int = 0

func _ready() -> void:
	z_index = 6
	add_to_group("water_surfaces")
	add_to_group("district_water")
	var copy := BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://scripts/living_water.gdshader")
	water_material.set_shader_parameter("width",width)
	water_material.set_shader_parameter("current",current)
	var bed: Image = Image.create(256,1,false,Image.FORMAT_RGBA8)
	for i: int in 256:
		bed.set_pixel(i,0,preload("res://scripts/stage_weather.gd").pack_height(bed_at(position.x+(i+0.5)/256*width),1))
	water_material.set_shader_parameter("bed_map",ImageTexture.create_from_image(bed))
	surface = ColorRect.new()
	surface.position = Vector2(0,-12)
	surface.size = Vector2(width,bottom-position.y+12)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.material = water_material
	add_child(surface)

func depth() -> float:
	return bottom-position.y

func contains(at: Vector2) -> bool:
	return at.x >= position.x and at.x <= position.x+width and at.y > position.y and at.y < bed_at(at.x)+4

func bed_at(x: float) -> float:
	var height: float = bottom
	if level != null:
		for rect: Rect2 in level.profile.builder.SOLIDS:
			if x >= rect.position.x and x <= rect.end.x and rect.position.y > target_y-8:
				height = minf(height,rect.position.y)
	return height

func splash(world_x: float, strength: float) -> void:
	ripple(world_x,strength)
	if level != null:
		level.effects.play("water_splash",Vector2(world_x,position.y),1,clampf(strength/10,0.3,0.9))

func ripple(world_x: float, strength: float) -> void:
	ripples[ripple_index] = Vector4(clampf(world_x-position.x,0,width),0,strength,0)
	ripple_index = (ripple_index+1)%ripples.size()

func _physics_process(delta: float) -> void:
	clock += delta
	for i: int in ripples.size():
		ripples[i].y += delta
	position.y = move_toward(position.y,target_y,delta*48)
	surface.size.y = maxf(20,bottom-position.y+12)
	water_material.set_shader_parameter("game_time",clock)
	water_material.set_shader_parameter("depth",depth())
	water_material.set_shader_parameter("world_surface_y",position.y)
	water_material.set_shader_parameter("ripples",ripples)
