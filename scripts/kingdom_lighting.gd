extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const TORCH: String = "res://Stages/Medievil Kingdom/8. Medieval Props, Furniture & Village Life/wall_torch.png"
const PANES: Dictionary = {
	"striped_awning_shop.png": Vector4(14, 10, 4, 4),
	"bakery_shop_front.png": Vector4(14, 10, 4, 4),
	"stone_house_chimney.png": Vector4(21, 22, 4, 4),
	"tavern_shop_front.png": Vector4(6, 20, 5, 5),
	"blue_roof_shop.png": Vector4(6, 22, 7, 4)
}
# These points lie on opaque masonry, rather than in arch/gate openings.
const BRACKETS: Dictionary = {
	"castle_gate_open.png": Vector2(4,20),
	"gatehouse_portcullis.png": Vector2(3, 20),
	"mossy_round_tower.png": Vector2(6, 20),
	"royal_banner_wall.png": Vector2(4, 20),
	"gold_trim_crown_tower.png": Vector2(6, 22),
	"stone_archway.png": Vector2(3, 21),
	"ornate_palace_entrance.png": Vector2(4, 20)
}

static func warm_window(level: Node2D, building: Sprite2D, warmth: float = 0.6) -> void:
	var file: String = building.texture.resource_path.get_file()
	if not PANES.has(file):
		return
	var glass := ShaderMaterial.new()
	glass.shader = preload("res://scripts/hearth_windows.gdshader")
	glass.set_shader_parameter("pane_rect", PANES[file])
	glass.set_shader_parameter("warmth", warmth)
	building.material = glass
	building.add_to_group("warm_windows")
	if level.has_node("WorldMotion"):
		level.get_node("WorldMotion").windows.append(glass)

static func mark_structure(structure: Sprite2D) -> void:
	var file: String = structure.texture.resource_path.get_file()
	if BRACKETS.has(file):
		structure.set_meta("bracket_pixel", BRACKETS[file])
		structure.add_to_group("torch_surfaces")

static func mount_torches(level: Node2D, details: Node2D) -> void:
	for structure: Sprite2D in level.get_tree().get_nodes_in_group("torch_surfaces"):
		if not level.is_ancestor_of(structure):
			continue
		var pixel: Vector2 = structure.get_meta("bracket_pixel")
		var attachment: Vector2 = structure.to_global(pixel - structure.texture.get_size() / 2.0)
		# The left bracket of the source torch is at pixel (9, 21).
		var hook_offset := Vector2(-14, 10)
		var torch: Sprite2D = Assets.sprite(details, TORCH, details.to_local(attachment) - hook_offset, 2, -4)
		torch.set_meta("mount_surface", weakref(structure))
		torch.set_meta("mount_pixel", pixel)
		torch.set_meta("hook_offset", hook_offset)
		torch.add_to_group("mounted_scenery")
		level.lighting.add_glow(torch.position, Color("ffca8f"), 90, torch)
