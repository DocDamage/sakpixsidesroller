extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Deep = preload("res://scripts/deep_biome.gd")
const Kingdom = preload("res://scripts/kingdom_builder.gd")

# Each parallax layer has a shared ground plane. Individual image centers are
# never used as the foot of a building or tree.
static func install(level: Node2D) -> void:
	for layer_name: String in ["DistantTown","DistantForest"]:
		var layer: Node2D = level.get_node(layer_name)
		if layer_name == "DistantTown" and level.chapter in [9,10]:
			dungeon_wall(level,layer)
			continue
		var surface: float = 604 if layer_name == "DistantTown" else 642
		for child: Node in layer.get_children():
			if child is Sprite2D:
				Assets.anchor_base(child,surface+8)
				child.set_meta("surface_y",surface+8)
				child.add_to_group("grounded_scenery")
		var foundation := Polygon2D.new()
		foundation.name = "ContinuousGround"
		var points := PackedVector2Array()
		for x: int in range(-1280,16001,160):
			points.append(Vector2(x,surface+sin(x*0.003)*7))
		points.append(Vector2(16000,3200))
		points.append(Vector2(-1280,3200))
		foundation.polygon = points
		var woods: bool = level.chapter in [2,7,8,11,12]
		foundation.color = Color("223930") if woods else Color("292c38")
		if layer_name == "DistantTown":
			foundation.color = foundation.color.lightened(0.035)
		foundation.add_to_group("scenic_foundations")
		layer.add_child(foundation)
	curate_foreground(level)
	support_opening_ledges(level)

static func dungeon_wall(level: Node2D, layer: Node2D) -> void:
	# Wall, frieze and carved details share a parent and the same fade. A relief
	# cannot remain as a floating square after its backing disappears.
	for child: Node in layer.get_children():
		child.queue_free()
	var path: String = Deep.WALL+("mossy_dark_brick_wall.png" if level.chapter == 9 else "dark_grey_brick_wall.png")
	var image: Image = Assets.texture(path).get_image()
	if image.is_compressed():
		image.decompress()
	var texture: ImageTexture = ImageTexture.create_from_image(image.get_region(Rect2i(1,1,30,30)))
	for x: int in range(-512,14080,256):
		var bay := Node2D.new()
		bay.position.x = x
		if level.chapter == 10:
			bay.modulate.a = 1.0-smoothstep(2400,3400,x)
		layer.add_child(bay)
		var wall := Sprite2D.new()
		wall.texture = texture
		wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall.region_enabled = true
		wall.region_rect = Rect2(0,0,64,960)
		wall.scale = Vector2.ONE*4
		wall.position = Vector2(128,500)
		wall.modulate = Color("39434e") if level.chapter == 9 else Color("383a4d")
		bay.add_child(wall)
		bay.add_to_group("scenic_foundations")
		if (x/256)%2 == 0:
			var relief: Sprite2D = Assets.sprite(bay,Deep.WALL+("mossy_statue_relief_wall.png" if level.chapter == 9 else "glyph_carved_wall.png"),Vector2(128,350),2.0,1)
			relief.modulate = Color("66717c")

static func hide_prop(visual: Sprite2D) -> void:
	visual.hide()
	visual.set_meta("composition_removed",true)

static func curate_foreground(level: Node2D) -> void:
	var occupied: Array[Rect2] = []
	for enemy: Node2D in level.get_tree().get_nodes_in_group("enemies"):
		if not enemy.flying:
			occupied.append(Rect2(enemy.home+Vector2(-105,-130),Vector2(210,130)))
	for actor: Dictionary in level.world_details.actors:
		occupied.append(Rect2(actor.position+Vector2(-55,-130),Vector2(110,130)))
	for fire: Sprite2D in level.world_details.fires:
		occupied.append(Rect2(fire.position.x-50,510,100,90))
	for x: float in level.profile.checkpoints:
		occupied.append(Rect2(x-50,490,100,110))
	for x: float in level.profile.urns:
		occupied.append(Rect2(x-40,525,80,75))
	# Hand props belong to a few inhabited set pieces, not every empty interval.
	# Keep the lamps and purposeful roadside landmarks; remove loose clutter.
	var loose: PackedStringArray = ["grain_sacks.png","hay_cart.png","hay_bale.png","wheelbarrow.png","wooden_handcart.png","coiled_rope.png","stacked_books.png","firewood_stack.png","broken_open_crate.png","leaning_ladder.png","stacked_planks.png","bread_basket.png","wooden_table.png","blacksmith_anvil.png","weapon_rack.png","training_dummy.png","grindstone.png","coal_pile.png","cracked_clay_jug.png","broken_clay_jug.png","carved_stone_tablet.png","tilled_soil_rows.png","wheat_stage5.png","carrot_stage5.png","cabbage_stage5.png"]
	var unattached: PackedStringArray = ["hanging_vines.png","hanging_potion_rack.png","hanging_shop_sign.png"]
	for visual: Sprite2D in level.find_children("*","Sprite2D",true,false):
		if visual.texture == null or visual.region_enabled or visual.is_in_group("upright_campfires") or visual.is_in_group("mounted_scenery"):
			continue
		if visual.get_parent().name in ["DistantTown","DistantForest"]:
			continue
		var file: String = visual.texture.resource_path.get_file()
		if file in unattached or file in loose:
			hide_prop(visual)
			continue
		if not visual.is_in_group("grounded_scenery") or visual.z_index < -4:
			continue
		if file.contains("spike") or file.contains("trap") or file.contains("lantern") or file.contains("candelabra"):
			continue
		var rect: Rect2 = Assets.visible_rect(visual)
		var path: String = visual.texture.resource_path
		var architecture: bool = path.contains("Architecture") or path.contains("Market Buildings") or path.contains("Village Houses") or file.contains("tree") or file.contains("arch")
		if not architecture and rect.size.y < 130 and rect.size.x < 180 and occupied.any(func(area: Rect2) -> bool: return area.intersects(rect)):
			hide_prop(visual)
	var sets: Array = [
		[[Assets.DECOR+"pumpkin_cluster.png",1260],[Assets.HAZARDS+"cross_tombstone.png",2540]],
		[[Kingdom.LIFE+"grain_sacks.png",2540],[Kingdom.LIFE+"hay_bale.png",2660]],
		[[Kingdom.LIFE+"bread_basket.png",1280],[Kingdom.LIFE+"grain_sacks.png",2610]],
		[[Kingdom.LIFE+"weapon_rack.png",710],[Kingdom.LIFE+"grindstone.png",2780]],
		[],[],[],[],[],[],[],[]]
	for entry: Array in sets[level.chapter-1]:
		var visual: Sprite2D = Assets.grounded(level,entry[0],entry[1],1.8,-3)
		var rect: Rect2 = Assets.visible_rect(visual).grow(6)
		if occupied.any(func(area: Rect2) -> bool: return area.intersects(rect)):
			visual.queue_free()
		else:
			visual.set_meta("dense_prop",true)
			visual.set_meta("authored_set",true)
			occupied.append(rect)

static func support_opening_ledges(level: Node2D) -> void:
	for ledge: Rect2 in level.profile.builder.LEDGES:
		if ledge.position.x >= 4800 and ledge.position.x < 11200:
			continue
		var woods: bool = level.chapter in [7,8,11,12]
		var texture: String = Deep.TREE+"trunk_column_mossy.png" if level.chapter >= 11 else "res://Stages/Abandonded Forest/3. Ancient Trees & Twisted Roots/mossy_trunk_section.png"
		if not woods:
			texture = Kingdom.CASTLE+"marble_column.png" if level.chapter >= 3 else Assets.VILLAGE+"Village Sheet Sprites/wooden_post.png"
		var bounds: Rect2 = Assets.opaque_rect(texture)
		# Use the shaft, not the wide cap/foot of the column as its width.
		if not woods:
			bounds = Rect2(12,10,8,14) if level.chapter >= 3 else Rect2(bounds.get_center().x-3,bounds.position.y,6,bounds.size.y)
		var width: float = 34 if woods else 18
		var height: float = 1100-ledge.position.y
		for x: float in [ledge.position.x+30,ledge.end.x-30]:
			var support: Sprite2D = Assets.sprite(level,texture,Vector2(x,ledge.position.y+height/2),1,-4)
			support.region_enabled = true
			support.region_rect = bounds
			support.scale = Vector2(width/bounds.size.x,height/bounds.size.y)
			support.modulate = Color("4b6555") if woods else Color("66616b")
			support.add_to_group("traversal_supports")

static func woodland_tier(level: Node2D, platform: Rect2, floor_y: float, crown: bool) -> void:
	var magic: bool = level.chapter >= 11
	var root: String = Deep.TREE if magic else "res://Stages/Abandonded Forest/3. Ancient Trees & Twisted Roots/"
	var trunk: String = root+("trunk_column_mossy.png" if magic else "mossy_trunk_section.png")
	var bounds: Rect2 = Assets.opaque_rect(trunk)
	var image: Image = Assets.texture(trunk).get_image()
	if image.is_compressed():
		image.decompress()
	var column := Sprite2D.new()
	column.texture = ImageTexture.create_from_image(image.get_region(Rect2i(bounds)))
	column.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	column.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.region_enabled = true
	var top: float = platform.position.y-(300 if crown else -28)
	var x: float = platform.end.x-48
	column.region_rect = Rect2(0,0,bounds.size.x,(floor_y-top)/5)
	column.scale = Vector2.ONE*5
	column.position = Vector2(x,(top+floor_y)/2)
	column.modulate = Color("6b8b79") if magic else Color("607462")
	column.z_index = -6
	level.add_child(column)
	column.add_to_group("traversal_supports")
	var branch: String = root+("mossy_branch_platform.png" if magic else "mossy_trunk_ledge.png")
	var branch_bounds: Rect2 = Assets.opaque_rect(branch)
	var limb: Sprite2D = Assets.sprite(level,branch,platform.position+Vector2(platform.size.x/2,40),1,2)
	limb.region_enabled = true
	limb.region_rect = branch_bounds
	limb.scale = Vector2(platform.size.x/branch_bounds.size.x,80/branch_bounds.size.y)
	limb.modulate = Color("9cb59b")
	if crown:
		var top_path: String = root+("branching_tree_top.png" if magic else "forked_branch.png")
		var fork: Sprite2D = Assets.grounded(level,top_path,x,6,-7,top+65)
		fork.modulate = column.modulate
		var leaf: String = Deep.TREE+"leafy_canopy_block.png" if magic else root+"leafy_branch_spray.png"
		for side: float in [-1.0,1.0]:
			var canopy: Sprite2D = Assets.grounded(level,leaf,x+side*75,6,-7,top+30)
			canopy.flip_h = side < 0
			canopy.modulate = Color("5b8c71") if magic else Color("53715b")
