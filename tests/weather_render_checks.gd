extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)

func render(view: SubViewport) -> Image:
	for i: int in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256,256)
	viewport.transparent_bg = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var pixels: Image = Image.create(2,2,false,Image.FORMAT_RGBA8)
	var packed: Color = preload("res://scripts/stage_weather.gd").pack_height(128,1)
	pixels.fill(packed)
	var map: ImageTexture = ImageTexture.create_from_image(pixels)
	var rect := ColorRect.new()
	rect.size = viewport.size
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/weather_rain.gdshader")
	material.set_shader_parameter("roof_map",map)
	material.set_shader_parameter("world_width",256.0)
	material.set_shader_parameter("viewport_size",Vector2(256,256))
	material.set_shader_parameter("rain",1.0)
	material.set_shader_parameter("clock",2.7)
	rect.material = material
	viewport.add_child(rect)
	var rain: Image = await render(viewport)
	var above: int = 0
	var below: float = 0
	for x: int in 256:
		for y: int in 256:
			var alpha: float = rain.get_pixel(x,y).a
			if y < 120 and alpha > 0.01:
				above += 1
			elif y > 144:
				below = maxf(below,alpha)
	check(above > 30,"GPU rain produces visible layered falling streaks")
	check(below < 0.005,"GPU shelter clipping leaves the area below the roof dry")
	rain.save_png("res://artifacts/weather-rain-mask.png")
	material.set_shader_parameter("rain",0.0)
	material.set_shader_parameter("clock",0.0)
	var clear_sky: Image = await render(viewport)
	var clear_alpha: float = 0
	for x: int in 256:
		for y: int in 256:
			clear_alpha = maxf(clear_alpha,clear_sky.get_pixel(x,y).a)
	check(clear_alpha < 0.005,"GPU zero-rain weather leaves no stray seeded streaks or ground splashes")
	material.set_shader_parameter("rain",1.0)
	material.set_shader_parameter("clock",2.7)
	pixels.fill(Color(packed.r,packed.g,0,1))
	map.update(pixels)
	var interior: Image = await render(viewport)
	var interior_alpha: float = 0
	for x: int in 256:
		for y: int in 256:
			interior_alpha = maxf(interior_alpha,interior.get_pixel(x,y).a)
	check(interior_alpha < 0.005,"GPU dungeon exposure mask removes both rain and impact splashes")
	pixels.fill(packed)
	map.update(pixels)
	material.shader = preload("res://scripts/weather_fog.gdshader")
	material.set_shader_parameter("fog",1.0)
	var mist: Image = await render(viewport)
	var maximum: float = 0
	var minimum: float = 1
	for x: int in 256:
		for y: int in 256:
			var alpha: float = mist.get_pixel(x,y).a
			maximum = maxf(maximum,alpha)
			minimum = minf(minimum,alpha)
	check(maximum > 0.05 and maximum <= 0.235 and maximum-minimum > 0.02,"GPU mist forms varied low wisps while keeping opacity below 24 percent")
	mist.save_png("res://artifacts/weather-mist-mask.png")
	material.shader = preload("res://scripts/weather_clouds.gdshader")
	material.set_shader_parameter("cover",0.9)
	var clouds: Image = await render(viewport)
	check(clouds.get_pixel(128,250).a < 0.02,"GPU cloud coverage fades away before the foreground ground plane")
	clouds.save_png("res://artifacts/weather-cloud-mask.png")
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 20
	viewport.add_child(ui_layer)
	var ui_patch := ColorRect.new()
	ui_patch.size = Vector2(32,32)
	ui_patch.color = Color(0.9,0.15,0.35,1)
	ui_layer.add_child(ui_patch)
	var with_ui: Image = await render(viewport)
	var ui_color: Color = with_ui.get_pixel(16,16)
	check(absf(ui_color.r-0.9) < 0.01 and absf(ui_color.g-0.15) < 0.01 and absf(ui_color.b-0.35) < 0.01,"GPU weather composition preserves the HUD layer's colors exactly")
	ui_layer.queue_free()
	rect.hide()
	var source_path: String = "res://Stages/Medievil Kingdom/1. Medieval Terrain & Cobblestone Ground/cracked_flagstone.png"
	var original: Sprite2D = preload("res://scripts/level_assets.gd").sprite(viewport,source_path,Vector2(16,16),1)
	var wet: Sprite2D = preload("res://scripts/level_assets.gd").sprite(viewport,source_path,Vector2(48,16),1)
	original.modulate = Color("c6c3a5")
	wet.modulate = original.modulate
	var wet_material := ShaderMaterial.new()
	wet_material.shader = preload("res://scripts/wet_terrain.gdshader")
	wet_material.set_shader_parameter("roof_map",map)
	wet_material.set_shader_parameter("world_width",256.0)
	wet_material.set_shader_parameter("surface_y",0.0)
	wet_material.set_shader_parameter("wetness",1.0)
	wet.material = wet_material
	var zero_height: Color = preload("res://scripts/stage_weather.gd").pack_height(0,1)
	pixels.fill(zero_height)
	map.update(pixels)
	var damp: Image = await render(viewport)
	var alpha_error: float = 0
	var changed: int = 0
	for x: int in 32:
		for y: int in 32:
			var a: Color = damp.get_pixel(x,y)
			var b: Color = damp.get_pixel(x+32,y)
			alpha_error = maxf(alpha_error,absf(a.a-b.a))
			if absf(a.r-b.r) > 0.01:
				changed += 1
	check(alpha_error < 0.005 and changed > 100,"GPU wet terrain changes exposed stone lighting while preserving the source silhouette")
	pixels.fill(Color(zero_height.r,zero_height.g,0,1))
	map.update(pixels)
	var dry: Image = await render(viewport)
	var sheltered_error: float = 0
	for x: int in 32:
		for y: int in 32:
			var a: Color = dry.get_pixel(x,y)
			var b: Color = dry.get_pixel(x+32,y)
			sheltered_error = maxf(sheltered_error,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
	check(sheltered_error < 0.01,"GPU sheltered terrain retains the original source colors")
	viewport.queue_free()
	await process_frame
	await process_frame
	print("WEATHER RENDER RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	for i: int in 6:
		await process_frame
	quit(1 if failures else 0)
