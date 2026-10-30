extends Node2D

const A := "res://Stages/Halloween Town/"
const GROUND := A + "1. Haunted Ground & Graveyard Terrain/"
const HOUSES := A + "3. Haunted Houses & Gothic Architecture/"
const FOREST := A + "5. Cursed Forest & Dead Trees/"
const DECOR := A + "7. Pumpkin Patch & Halloween Decorations/"
const MAGIC := A + "8. Ghostly Magic & Supernatural Effects/"
const PROPS := A + "9. Halloween Props, Treasures & Collectibles/"
const HAZARDS := A + "10. Traps, Cursed Hazards & Interactive Objects/"

var player: Sprite2D
var player_position := Vector2(265, 559)
var chest: Sprite2D
var portal: Sprite2D
var message: Label
var collected := false
var opened := false
var time := 0.0
var texture_cache: Dictionary = {}

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("090918"))
	build_sky()
	build_background()
	build_room()
	build_foreground()
	build_player()
	build_ui()

func sprite(path: String, pos: Vector2, z: int, scale_amount := 2.0, modulate_color := Color.WHITE) -> Sprite2D:
	var item := Sprite2D.new()
	item.texture = texture_from_png(path)
	item.position = pos
	item.z_index = z
	item.scale = Vector2.ONE * scale_amount
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.modulate = modulate_color
	add_child(item)
	return item

func texture_from_png(path: String) -> ImageTexture:
	if texture_cache.has(path):
		return texture_cache[path]
	# Loading source PNGs directly keeps this room portable even before Godot's
	# first editor import of the full asset library has completed.
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	var texture := ImageTexture.create_from_image(image)
	texture_cache[path] = texture
	return texture

func panel(rect: Rect2, color: Color, z: int) -> ColorRect:
	var item := ColorRect.new()
	item.position = rect.position
	item.size = rect.size
	item.color = color
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.z_index = z
	add_child(item)
	return item

func build_sky() -> void:
	panel(Rect2(0, 0, 1280, 720), Color("11122e"), -30)
	# Soft horizon bands give the room depth while preserving the pixel assets as focal points.
	panel(Rect2(0, 245, 1280, 475), Color("1d1932"), -29)
	for p in [Vector2(89, 108), Vector2(209, 174), Vector2(400, 113), Vector2(670, 143), Vector2(1016, 108), Vector2(1180, 205)]:
		panel(Rect2(p, Vector2(3, 3)), Color("928bc5"), -28)
	var moon := Polygon2D.new()
	moon.polygon = PackedVector2Array([Vector2(967, 67), Vector2(998, 78), Vector2(1012, 108), Vector2(1004, 141), Vector2(975, 158), Vector2(944, 143), Vector2(932, 111), Vector2(941, 82)])
	moon.color = Color("fff3be")
	moon.z_index = -28
	add_child(moon)

func build_background() -> void:
	# Distant crooked skyline.
	for data in [["dark_victorian_house.png", Vector2(174, 324), 4.2], ["haunted_manor.png", Vector2(426, 308), 4.8], ["crooked_spire_tower.png", Vector2(788, 283), 4.7], ["haunted_house_crooked.png", Vector2(1105, 329), 4.2]]:
		sprite(HOUSES + data[0], data[1], -20, data[2], Color("62557f"))
	for data in [["gnarled_dead_tree.png", Vector2(90, 350), 4.2], ["twisted_green_tree.png", Vector2(600, 360), 4.0], ["dark_hollow_tree.png", Vector2(1190, 348), 4.4], ["bare_branch_tree.png", Vector2(1025, 346), 3.8]]:
		sprite(FOREST + data[0], data[1], -18, data[2], Color("403650"))
	for x in range(8):
		sprite(DECOR + "wooden_picket_fence.png", Vector2(70 + x * 165, 446), -8, 2.0, Color("66516e"))

func build_room() -> void:
	# Walkable town square, assembled as a tiled graveyard path.
	for x in range(0, 21):
		for y in range(0, 4):
			var variation := "fallen_leaf_ground.png" if (x + y * 2) % 5 == 0 else "dark_grass_fill.png"
			sprite(GROUND + variation, Vector2(32 + x * 64, 500 + y * 58), -2, 2.0)
	for x in range(2, 18):
		sprite(GROUND + "graveyard_stone_slabs.png", Vector2(90 + x * 60, 590 + (x % 2) * 4), 0, 1.8)
	# Main focal point: witch ritual and protected treasure.
	sprite(MAGIC + "purple_summoning_circle.png", Vector2(914, 566), 1, 3.0)
	sprite(DECOR + "witch_cauldron.png", Vector2(912, 525), 5, 2.5)
	sprite(MAGIC + "green_spirit_flame.png", Vector2(890, 463), 6, 2.0)
	sprite(MAGIC + "green_spirit_flame.png", Vector2(934, 456), 6, 1.5)
	portal = sprite(MAGIC + "purple_swirl_portal.png", Vector2(1114, 493), 4, 3.0, Color("8a70ad"))
	# Village dressing.
	for data in [["pumpkin_cluster.png", Vector2(183, 560), 2.2], ["hay_bale_stack.png", Vector2(132, 510), 2.3], ["raven_on_signpost.png", Vector2(330, 489), 2.5], ["stone_well.png", Vector2(560, 546), 2.6], ["pumpkin_scarecrow.png", Vector2(704, 500), 2.7], ["stacked_crates.png", Vector2(1010, 559), 2.2], ["black_cat_arched.png", Vector2(486, 575), 1.8], ["skull_pile.png", Vector2(823, 584), 2.0]]:
		sprite(DECOR + data[0], data[1], 3, data[2])
	for data in [["cross_tombstone.png", Vector2(388, 534), 2.25], ["gargoyle_statue.png", Vector2(1057, 516), 2.1], ["hanging_lantern.png", Vector2(748, 416), 2.0], ["spider_web.png", Vector2(1194, 452), 2.0]]:
		sprite(HAZARDS + data[0], data[1], 3, data[2])
	chest = sprite(PROPS + "chained_chest.png", Vector2(813, 557), 4, 2.3)
	sprite(PROPS + "bat_coin.png", Vector2(777, 572), 5, 2.2)
	sprite(PROPS + "bat_coin.png", Vector2(850, 572), 5, 2.2)
	# Framing walls and high-detail foreground objects.
	for data in [["crooked_dead_trunk.png", Vector2(42, 545), 4.5], ["rooted_dark_trunk.png", Vector2(1235, 544), 4.7], ["tangled_branch_arch.png", Vector2(1144, 402), 3.5]]:
		sprite(FOREST + data[0], data[1], 8, data[2])

func build_foreground() -> void:
	for data in [["autumn_leaf_pile.png", Vector2(235, 645)], ["pumpkin_vine.png", Vector2(670, 652)], ["blue_mushrooms.png", Vector2(439, 646)], ["orange_mushroom_cluster.png", Vector2(1080, 648)], ["bone_spike_row.png", Vector2(1169, 644)]]:
		var folder := FOREST if data[0].contains("mushroom") else (HAZARDS if data[0] == "bone_spike_row.png" else DECOR)
		sprite(folder + data[0], data[1], 10, 2.0)

func build_player() -> void:
	player = sprite("res://Hero/Seeker_PRO/Frames/Bone/Idle/Seeker_Bone_Idle_00.png", player_position, 9, 2.2)
	# A subtle cyan halo keeps the explorer readable in the dark room.
	player.modulate = Color("d9f6ff")

func build_ui() -> void:
	var title := Label.new()
	title.text = "WITCHING HOUR  •  HALLOWEEN TOWN"
	title.position = Vector2(36, 28)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("ffe0a0"))
	title.z_index = 30
	add_child(title)
	message = Label.new()
	message.text = "Arrow keys / WASD to explore  •  E near the chained chest"
	message.position = Vector2(36, 62)
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", Color("c8bad9"))
	message.z_index = 30
	add_child(message)

func _process(delta: float) -> void:
	time += delta
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	player_position += direction.normalized() * 185.0 * delta
	player_position.x = clampf(player_position.x, 70.0, 1210.0)
	player_position.y = clampf(player_position.y, 448.0, 633.0)
	player.position = player_position + Vector2(0, sin(time * 3.0) * 1.5)
	portal.modulate.a = 0.68 + sin(time * 2.2) * 0.18
	if player_position.distance_to(chest.position) < 65.0 and not opened:
		message.text = "The chained chest hums with violet light.  [E] Open it"
		if Input.is_action_just_pressed("interact"):
			opened = true
			chest.texture = texture_from_png(HAZARDS + "open_chest.png")
			message.text = "Moon Key found! The portal to the Crooked Quarter is awake."
	elif opened and player_position.distance_to(portal.position) < 85.0:
		message.text = "The Crooked Quarter portal shivers in the moonlight. Room complete!"
	elif not opened:
		message.text = "Arrow keys / WASD to explore  •  Find and open the chained chest"
