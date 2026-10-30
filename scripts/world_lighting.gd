extends Node2D

var points: Array[Dictionary] = []
var gradient_texture: GradientTexture2D
var additive: CanvasItemMaterial
var clock: float = 0.0

func _ready() -> void:
	z_index = 6
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.35))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.25, Color(1, 1, 1, 0.13))
	gradient.add_point(0.6, Color(1, 1, 1, 0.025))
	gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 128
	gradient_texture.height = 128
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(1, 0.5)
	additive = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

func add_glow(at: Vector2, color: Color, radius: float = 100.0, follow: Node2D = null, offset: Vector2 = Vector2.ZERO) -> Sprite2D:
	if follow != null and follow.has_meta("emitter_offset") and offset == Vector2.ZERO:
		offset = follow.get_meta("emitter_offset")
		at = follow.global_position+offset
	var halo: Sprite2D = Sprite2D.new()
	halo.texture = gradient_texture
	halo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	halo.material = additive
	halo.position = at
	halo.modulate = color
	halo.scale = Vector2.ONE * radius / 64.0
	add_child(halo)
	points.append({"visual": halo, "follow": follow, "radius": radius, "offset": offset})
	return halo

func _process(delta: float) -> void:
	clock += delta
	for i: int in range(points.size()):
		var point: Dictionary = points[i]
		var halo: Sprite2D = point["visual"]
		var follow: Node2D = point["follow"]
		if follow != null:
			halo.position = follow.global_position + Vector2(point["offset"])
			halo.visible = follow.visible
		halo.scale = Vector2.ONE * float(point["radius"]) / 64.0 * (1.0 + sin(clock * 2.4 + i) * 0.055)
