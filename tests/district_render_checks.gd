extends SceneTree

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, title: String) -> void:
	checks += 1
	if value:
		print("PASS: "+title)
	else:
		failures += 1
		push_error("FAIL: "+title)

func pixels(view: SubViewport) -> Image:
	for i: int in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()

func panel(parent: Node, rect: Rect2, color: Color) -> ColorRect:
	var result := ColorRect.new()
	result.position = rect.position
	result.size = rect.size
	result.color = color
	parent.add_child(result)
	return result

func run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(192,128)
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	panel(view,Rect2(0,0,192,128),Color(0.5,0.5,0.5))
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.15,0.15,0.15)
	view.add_child(ambient)
	var gradient := Gradient.new()
	gradient.set_color(0,Color.WHITE)
	gradient.set_color(1,Color(1,1,1,0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	var light := PointLight2D.new()
	light.texture = texture
	light.position = Vector2(40,64)
	light.energy = 1.4
	view.add_child(light)
	var occluder := LightOccluder2D.new()
	var polygon := OccluderPolygon2D.new()
	polygon.polygon = PackedVector2Array([Vector2(80,15),Vector2(90,15),Vector2(90,114),Vector2(80,114)])
	occluder.occluder = polygon
	view.add_child(occluder)
	var unshadowed: Image = await pixels(view)
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	var shadowed: Image = await pixels(view)
	check(unshadowed.get_pixel(115,64).r-shadowed.get_pixel(115,64).r > 0.04,"GPU point light casts a real structural shadow behind its blocker")
	check(absf(unshadowed.get_pixel(55,64).r-shadowed.get_pixel(55,64).r) < 0.02,"GPU shadow preserves the illuminated side of the room")
	shadowed.save_png("res://artifacts/district-shadow-proof.png")
	view.queue_free()
	await process_frame
	view = SubViewport.new()
	view.size = Vector2i(128,128)
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	panel(view,Rect2(0,0,128,128),Color(0.1,0.2,0.6))
	panel(view,Rect2(0,0,128,40),Color(0.9,0.15,0.1))
	var before: Image = await pixels(view)
	var water: Node2D = preload("res://scripts/district_water.gd").new()
	water.position = Vector2(0,40)
	water.target_y = 40
	water.bottom = 128
	water.width = 128
	view.add_child(water)
	var bed: Image = Image.create(2,1,false,Image.FORMAT_RGBA8)
	bed.set_pixel(0,0,preload("res://scripts/stage_weather.gd").pack_height(80,1))
	bed.set_pixel(1,0,preload("res://scripts/stage_weather.gd").pack_height(128,1))
	water.water_material.set_shader_parameter("bed_map",ImageTexture.create_from_image(bed))
	var alive: Image = await pixels(view)
	check(absf(alive.get_pixel(24,110).b-before.get_pixel(24,110).b) < 0.01,"GPU water stops at a shallow bank instead of painting over solid terrain")
	check(absf(alive.get_pixel(98,110).b-before.get_pixel(98,110).b) > 0.03,"GPU deeper water refracts and absorbs the scene behind it")
	var reflected_red: float = 0
	for x: int in range(10,118):
		reflected_red += alive.get_pixel(x,52).r
	check(reflected_red/108 > 0.14,"GPU surface reflects the visible scene above the waterline")
	for i: int in 30:
		await physics_frame
	var animated: Image = await pixels(view)
	var changes: int = 0
	for x: int in 128:
		for y: int in range(35,100):
			if absf(animated.get_pixel(x,y).r-alive.get_pixel(x,y).r) > 0.015:
				changes += 1
	check(changes > 100,"GPU flow, surface waves and caustics animate rather than remaining a flat color")
	animated.save_png("res://artifacts/district-water-proof.png")
	view.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(120)
	for i: int in 6:
		await process_frame
	print("DISTRICT RENDER RESULT: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)
