extends RefCounted

# Godot adaptation of Ferr2D's path -> directional edge bodies -> fill model.
# Read Ferr2D_Path.GetDirection and the material segment descriptors in the
# supplied package. Unity meshes/editor scripts are not runtime dependencies.
const Assets = preload("res://scripts/level_assets.gd")

static func direction(a: Vector2, b: Vector2) -> String:
	# Clockwise screen-space contour; the perpendicular points into the fill.
	var normal := Vector2(-(b-a).y,(b-a).x)
	if absf(normal.x) > absf(normal.y):
		return "left" if normal.x > 0 else "right"
	return "top" if normal.y > 0 else "bottom"

static func region(path: String, crop: Rect2i) -> Texture2D:
	var pixels: Image = Assets.texture(path).get_image()
	if pixels.is_compressed():
		pixels.decompress()
	return ImageTexture.create_from_image(pixels.get_region(crop))

static func build(parent: Node2D, contour: PackedVector2Array, grass: bool = false) -> StaticBody2D:
	assert(contour.size() >= 3 and not Geometry2D.triangulate_polygon(contour).is_empty())
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var collider := CollisionPolygon2D.new()
	collider.polygon = contour
	body.add_child(collider)
	var fill := Polygon2D.new()
	fill.polygon = contour
	fill.texture = Assets.texture("res://assets/terrain/ferr2d/RockyFill.png")
	fill.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	fill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fill.color = Color("77818d")
	fill.z_index = 0
	body.add_child(fill)
	var stone: Texture2D = region(Assets.GROUND+"grey_stone_brick.png",Rect2i(3,5,26,24))
	var top: Texture2D = region(Assets.GROUND+("grass_ground_top.png" if grass else "graveyard_stone_slabs.png"),Rect2i(2,11,28,10) if grass else Rect2i(3,12,26,12))
	for i: int in contour.size():
		var a: Vector2 = contour[i]
		var b: Vector2 = contour[(i+1)%contour.size()]
		var tangent: Vector2 = (b-a).normalized()
		var inward := Vector2(-tangent.y,tangent.x)
		var side: String = direction(a,b)
		var depth: float = 28 if side == "top" else 18
		# A retaining-stone course sits directly beneath the walking edge. Its
		# end follows the contour, so caps never become a floating square tile.
		if side == "top":
			var course := Polygon2D.new()
			course.polygon = PackedVector2Array([a,b,b+inward*78,a+inward*78])
			course.texture = stone
			course.texture_scale = Vector2.ONE*0.5
			course.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			course.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			course.color = Color("5b626d")
			course.z_index = 0
			body.add_child(course)
		var edge := Polygon2D.new()
		edge.polygon = PackedVector2Array([a,b,b+inward*depth,a+inward*depth])
		edge.texture = top if side == "top" else stone
		edge.uv = PackedVector2Array([Vector2.ZERO,Vector2(a.distance_to(b)/2,0),Vector2(a.distance_to(b)/2,depth/2),Vector2(0,depth/2)])
		edge.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		edge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		edge.color = Color("9aa3a4") if side == "top" else Color("59616b")
		edge.z_index = 1
		body.add_child(edge)
	body.set_meta("terrain_contour",contour)
	body.add_to_group("contour_terrain")
	return body

static func foundation(parent: Node2D, rect: Rect2, grass: bool) -> StaticBody2D:
	var bevel: float = minf(24,rect.size.x/6)
	var bottom: float = rect.end.y
	var contour := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),Vector2(rect.end.x,bottom-bevel),Vector2(rect.end.x-bevel,bottom),Vector2(rect.position.x+bevel,bottom),Vector2(rect.position.x,bottom-bevel)])
	var body: StaticBody2D = build(parent,contour,grass)
	body.set_meta("terrain_bounds",rect)
	return body
