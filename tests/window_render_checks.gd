extends SceneTree

const Assets = preload("res://scripts/level_assets.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(64, 32)
	viewport.transparent_bg = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var path: String = "res://Stages/Medievil Kingdom/4. Medieval Village Houses & Market Buildings/striped_awning_shop.png"
	var original: Sprite2D = Assets.sprite(viewport, path, Vector2(16, 16), 1)
	var illuminated: Sprite2D = Assets.sprite(viewport, path, Vector2(48, 16), 1)
	original.modulate = Color("c5bda9")
	illuminated.modulate = original.modulate
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/hearth_windows.gdshader")
	material.set_shader_parameter("pane_rect", Vector4(14, 10, 4, 4))
	material.set_shader_parameter("warmth", 0.7)
	illuminated.material = material
	for i: int in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var pixels: Image = viewport.get_texture().get_image()
	var outside_error: float = 0.0
	var lit: int = 0
	for y: int in range(32):
		for x: int in range(32):
			var before: Color = pixels.get_pixel(x, y)
			var after: Color = pixels.get_pixel(x + 32, y)
			if Rect2i(14, 10, 4, 4).has_point(Vector2i(x, y)):
				if after.r > before.r + 0.15 and after.a > 0.5:
					lit += 1
			else:
				outside_error = maxf(outside_error, maxf(absf(before.r - after.r), maxf(absf(before.g - after.g), absf(before.b - after.b))))
	if outside_error > 0.015:
		failures += 1
		push_error("FAIL: Window shader changes source pixels outside the pane: " + str(outside_error))
	else:
		print("PASS: Window shader preserves original roof, walls, tint and transparency")
	if lit == 0:
		failures += 1
		push_error("FAIL: Selected window pane does not illuminate")
	else:
		print("PASS: Only the measured window receives warm interior light")
	pixels.resize(512, 256, Image.INTERPOLATE_NEAREST)
	pixels.save_png("res://artifacts/window-render-comparison.png")
	viewport.queue_free()
	await process_frame
	print("WINDOW RENDER RESULT: %d/2 checks passed" % (2 - failures))
	quit(1 if failures else 0)
