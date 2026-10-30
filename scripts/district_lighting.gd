extends Node2D

var district: Node2D
var lights: Array[PointLight2D] = []
var hero: PointLight2D
var radial: GradientTexture2D

func setup(owner_district: Node2D) -> void:
	district = owner_district
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.30,0.33,0.42)
	add_child(ambient)
	var gradient := Gradient.new()
	gradient.set_color(0,Color.WHITE)
	gradient.set_color(1,Color(1,1,1,0))
	gradient.add_point(0.30,Color(1,1,1,0.76))
	gradient.add_point(0.65,Color(1,1,1,0.24))
	radial = GradientTexture2D.new()
	radial.gradient = gradient
	radial.width = 512
	radial.height = 512
	radial.fill = GradientTexture2D.FILL_RADIAL
	radial.fill_from = Vector2(0.5,0.5)
	radial.fill_to = Vector2(1,0.5)
	var contours: Dictionary = {}
	for terrain: StaticBody2D in get_tree().get_nodes_in_group("contour_terrain"):
		if district.level.is_ancestor_of(terrain):
			contours[terrain.get_meta("terrain_bounds")] = true
			occluder_points(self,terrain.get_meta("terrain_contour"))
	for rect: Rect2 in district.level.profile.builder.SOLIDS:
		if not contours.has(rect):
			occluder(self,rect)
	for point: Dictionary in district.level.lighting.points:
		var follow: Node2D = point.follow
		if follow == district.level.player:
			continue
		var at: Vector2 = follow.global_position if is_instance_valid(follow) else point.visual.global_position
		var offset: Vector2 = point.get("offset",Vector2.ZERO)
		at += offset
		var fire_source: bool = follow in district.level.world_details.fires
		var light: PointLight2D = add_light(at,Color("ffbf7a") if fire_source else Color("90c9df"),330 if fire_source else 240,2.4 if fire_source else 1.55)
		if follow != null:
			light.set_meta("follow",weakref(follow))
			light.set_meta("offset",offset)
		if follow in district.level.world_details.fires:
			light.set_meta("flicker",true)
			if not follow.get_meta("hearth",false):
				exterior_source(follow,offset,330,2.4)
	for at: Vector2 in [Vector2(1280,545),Vector2(2750,65),Vector2(3300,65),Vector2(4480,-555),Vector2(6080,-755),Vector2(4020,1405),Vector2(5280,1405),Vector2(6230,1405),Vector2(7470,1045),Vector2(8730,1185),Vector2(9880,1357),Vector2(10900,545),Vector2(12000,25),Vector2(11390,-295),Vector2(13020,-175),Vector2(15180,-175),Vector2(12180,1405),Vector2(14500,1405),Vector2(16060,1405),Vector2(17250,545),Vector2(18100,545),Vector2(18800,545)]:
		fixture(Vector2(at.x,at.y+55),int(at.x) in [1280,11390,13020,15180,17250,18100,18800])
	hero = add_light(district.level.player.position-Vector2(0,42),Color("c0d4df"),195,1.1)
	for window: Sprite2D in get_tree().get_nodes_in_group("bell_window_sources"):
		if district.level.is_ancestor_of(window):
			add_light(window.global_position,Color("edc697") if window.get_meta("warm",false) else Color("a3bfdc"),370,1.25)
	hero.shadow_enabled = true
	for at: Vector2 in [Vector2(6770,975),Vector2(10140,925),Vector2(18320,985),Vector2(17450,1405),Vector2(18240,1405)]:
		fixture(Vector2(at.x,at.y+55),false)
	# This hanging lantern is explicitly attached to the loft's underside.
	var lantern: Sprite2D = preload("res://scripts/level_assets.gd").sprite(district.level,"res://Stages/GandalfHardcore Pixel Art Medieval Fantasy Assets/House Furniture Sprites/hanging_brass_lantern.png",Vector2(2980,217),3,-7)
	lantern.set_meta("mount_y",120.0)
	bind_source(lantern,Vector2(0,72),250,1.35)

func exterior_source(source: Node2D, offset: Vector2, radius: float, strength: float) -> void:
	var light: PointLight2D = add_light(source.global_position+offset,Color("ffc986"),radius,strength)
	light.range_item_cull_mask = 2
	light.shadow_enabled = false
	light.set_meta("no_shadows",true)
	light.set_meta("follow",weakref(source))
	light.set_meta("offset",offset)
	light.set_meta("flicker",true)

func bind_source(source: Node2D, offset: Vector2, radius: float, strength: float, exterior: bool = false) -> void:
	source.set_meta("emitter_offset",offset)
	source.add_to_group("district_light_fixtures")
	var light: PointLight2D = add_light(source.global_position+offset,Color("ffc986"),radius,strength)
	light.set_meta("follow",weakref(source))
	light.set_meta("offset",offset)
	light.set_meta("flicker",true)
	district.level.lighting.add_glow(source.global_position+offset,Color("ffbd773f"),65,source,offset)
	if exterior:
		exterior_source(source,offset,radius,strength)

func fixture(floor_at: Vector2, street: bool) -> void:
	var assets: Script = preload("res://scripts/level_assets.gd")
	if street:
		var post: Sprite2D = assets.grounded(district.level,"res://Stages/Medievil Kingdom/8. Medieval Props, Furniture & Village Life/lantern_post.png",floor_at.x,4,-3,floor_at.y)
		post.set_meta("district_lamp",true)
		bind_source(post,Vector2(20,-8),315,1.65,true)
	else:
		# Bracketed torches belong to the rear wall, above the walking plane.
		var torch := AnimatedSprite2D.new()
		var frames := SpriteFrames.new()
		frames.set_animation_speed("default",9)
		for i: int in range(1,5):
			frames.add_frame("default",assets.texture("res://Props/Campfire/Campfire Sprites/torch_orange_frame"+str(i)+".png"))
		torch.sprite_frames = frames
		torch.position = floor_at-Vector2(0,105)
		torch.scale = Vector2.ONE*3
		torch.z_index = -3
		torch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		district.level.add_child(torch)
		var bracket: Sprite2D = assets.sprite(torch,"res://Stages/Medievil Kingdom/8. Medieval Props, Furniture & Village Life/wall_torch_bracket.png",Vector2(0,3),0.45,-1)
		bracket.modulate = Color("827582")
		var material := CanvasItemMaterial.new()
		material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		torch.material = material
		torch.play()
		torch.set_meta("mount_y",floor_at.y-105)
		bind_source(torch,Vector2(0,-12),290,1.5)

func occluder(parent: Node, rect: Rect2) -> void:
	occluder_points(parent,PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))

func occluder_points(parent: Node, points: PackedVector2Array) -> void:
	var node := LightOccluder2D.new()
	var polygon := OccluderPolygon2D.new()
	polygon.polygon = points
	polygon.cull_mode = OccluderPolygon2D.CULL_DISABLED
	node.occluder = polygon
	parent.add_child(node)
	node.add_to_group("district_shadows")

func add_light(at: Vector2, color: Color, radius: float, strength: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = radial
	light.texture_scale = radius/256
	light.position = at
	light.color = color
	light.energy = strength*0.38
	light.range_item_cull_mask = 1
	light.set_meta("base_energy",light.energy)
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = 1.5
	add_child(light)
	lights.append(light)
	return light

func _process(_delta: float) -> void:
	if hero == null:
		return
	var player: Node2D = district.level.player
	hero.position = player.position-Vector2(0,42)
	hero.texture_scale = (235.0 if district.upgrades.has("lantern_wick") else 195.0)/256
	for light: PointLight2D in lights:
		if light == hero:
			continue
		var follow: WeakRef = light.get_meta("follow") if light.has_meta("follow") else null
		if follow != null and is_instance_valid(follow.get_ref()):
			light.position = follow.get_ref().global_position+Vector2(light.get_meta("offset",Vector2.ZERO))
		light.visible = absf(light.position.x-player.position.x) < 1250 and absf(light.position.y-player.position.y) < 950
		light.shadow_enabled = not light.get_meta("no_shadows",false) and light.visible and light.position.distance_to(player.position) < 850
		if light.visible and light.get_meta("flicker",false):
			var phase: float = district.level.clock+light.position.x*0.037
			light.energy = float(light.get_meta("base_energy"))*(1.0+sin(phase*9.3)*0.025+sin(phase*17.1)*0.015)
