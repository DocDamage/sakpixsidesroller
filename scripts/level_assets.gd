extends RefCounted

const ROOT: String = "res://Stages/Halloween Town/"
const GROUND: String = ROOT + "1. Haunted Ground & Graveyard Terrain/"
const PLATFORMS: String = ROOT + "2. Haunted Platforms & Suspended Walkways/"
const HOUSES: String = ROOT + "3. Haunted Houses & Gothic Architecture/"
const CRYPT: String = ROOT + "4. Crypts, Tombs & Underground Passages/"
const FOREST: String = ROOT + "5. Cursed Forest & Dead Trees/"
const SWAMP: String = ROOT + "6. Witch's Swamp & Poisoned Waters/"
const DECOR: String = ROOT + "7. Pumpkin Patch & Halloween Decorations/"
const MAGIC: String = ROOT + "8. Ghostly Magic & Supernatural Effects/"
const PROPS: String = ROOT + "9. Halloween Props, Treasures & Collectibles/"
const HAZARDS: String = ROOT + "10. Traps, Cursed Hazards & Interactive Objects/"
const HEALING: String = "res://Props/Healing Items/GandalfHardcore healing Items/Healing Sheet.png"
const VILLAGE: String = "res://Stages/Village/GandalfHardcore Pixel Art Village Houses tiles/"
static var textures: Dictionary = {}
static var opaque_bounds: Dictionary = {}

static func opaque_rect(path: String) -> Rect2:
	if not opaque_bounds.has(path):
		var pixels: Image = texture(path).get_image()
		if pixels.is_compressed():
			pixels.decompress()
		opaque_bounds[path] = Rect2(pixels.get_used_rect())
	return opaque_bounds[path]

static func grounded(parent: Node, path: String, x: float, size: float = 2.0, depth: int = -2, surface: float = 600.0) -> Sprite2D:
	var visual: Sprite2D = sprite(parent, path, Vector2(x, surface), size, depth)
	anchor_base(visual, surface)
	visual.set_meta("surface_y", surface)
	visual.add_to_group("grounded_scenery")
	return visual

static func roadside_lantern(parent: Node2D, lighting: Node2D, x: float) -> Sprite2D:
	var post: Sprite2D = grounded(parent,"res://Stages/Medievil Kingdom/8. Medieval Props, Furniture & Village Life/lantern_post.png",x,4,-3)
	post.set_meta("emitter_offset",Vector2(20,-8))
	lighting.add_glow(post.global_position+Vector2(20,-8),Color("ffd094"),90,post,Vector2(20,-8))
	return post

static func anchor_base(visual: Sprite2D, surface: float = 0.0) -> void:
	var bounds: Rect2 = sprite_bounds(visual)
	visual.position.y = surface - (bounds.end.y - visual.texture.get_height() / 2.0) * visual.scale.y

static func visible_rect(visual: Sprite2D) -> Rect2:
	var bounds: Rect2 = sprite_bounds(visual)
	return visual.global_transform * Rect2(bounds.position - visual.texture.get_size() / 2.0, bounds.size)

static func sprite_bounds(visual: Sprite2D) -> Rect2:
	if not visual.texture.resource_path.is_empty():
		return opaque_rect(visual.texture.resource_path)
	var pixels: Image = visual.texture.get_image()
	if pixels.is_compressed():
		pixels.decompress()
	return Rect2(pixels.get_used_rect())

static func texture(path: String) -> Texture2D:
	if textures.has(path):
		return textures[path]
	var result: Texture2D
	if ResourceLoader.exists(path):
		result = load(path) as Texture2D
	else:
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null:
			push_error("Missing level asset: " + path)
			return null
		result = ImageTexture.create_from_image(image)
	textures[path] = result
	return result

static func sprite(parent: Node, path: String, pos: Vector2, size: float = 2.0, depth: int = 0) -> Sprite2D:
	var node: Sprite2D = Sprite2D.new()
	node.texture = texture(path)
	node.position = pos
	node.scale = Vector2.ONE * size
	node.z_index = depth
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(node)
	return node

static func atlas(path: String, rect: Rect2) -> AtlasTexture:
	var region: AtlasTexture = AtlasTexture.new()
	region.atlas = texture(path)
	region.region = rect
	return region

static func hero_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	for animation: String in ["Idle", "Run", "JumpFall", "DoubleJump", "Attack1", "Attack2", "Attack3", "JumpAttack", "DownAttack", "Dash", "Hurt","Climb","WallSlide","Grapple"]:
		frames.add_animation(animation)
		frames.set_animation_speed(animation,{"Idle":12.0,"Climb":12.5,"WallSlide":10.0,"Grapple":12.5}.get(animation,18.0))
		frames.set_animation_loop(animation, animation in ["Idle", "Run", "JumpFall","Climb","WallSlide"])
		var folder: String = "res://Hero/Seeker_PRO/Frames/Bone/" + animation + "/"
		var files: PackedStringArray = DirAccess.get_files_at(folder)
		files.sort()
		for file: String in files:
			if file.ends_with(".png"):
				frames.add_frame(animation, texture(folder + file))
	return frames
