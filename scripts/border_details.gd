extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Campaign = preload("res://scripts/campaign_state.gd")
const Biome = preload("res://scripts/deep_biome.gd")
const KINGDOM: String = "res://Stages/Medievil Kingdom/9. Medieval Nature, Forest Edges & Farmland/"
const DARK: String = "res://Stages/Dark Fantasy/"
const WOODS: String = "res://Stages/Abandonded Forest/8. Dead Vegetation, Fungi & Forest Overgrowth/"
const SOURCES: Array[String] = [KINGDOM+"grass_tufts_a.png",KINGDOM+"small_rocks_scattered_a.png",KINGDOM+"rock_pile.png",DARK+"5. Trees & Nature/dry_grass_tuft.png",DARK+"4. Background Decorations/bone_alt.png",WOODS+"fern.png",WOODS+"brown_mushroom_cluster.png",Biome.CAVE+"mossy_rock_pair.png",Biome.CAVE+"blue_crystal_formation.png",Biome.FLORA+"blue_flower_bush.png",Biome.FLORA+"pink_mushroom_cluster.png"]

static func install(level: Node2D) -> void:
	var protected: Array[Rect2] = []
	for actor: Dictionary in level.world_details.actors:
		protected.append(Rect2(actor.position+Vector2(-32,-85),Vector2(64,85)).grow(8))
	for x: float in level.profile.checkpoints:
		protected.append(Rect2(x-32,492,64,108))
	for x: float in level.profile.urns:
		protected.append(Rect2(x-35,526,70,74))
	for hazard: Rect2 in level.hazards:
		protected.append(hazard.grow(18))
	for fire: Sprite2D in level.world_details.fires:
		protected.append(Rect2(fire.position.x-30,540,60,60))
	for gate: Sprite2D in level.get_tree().get_nodes_in_group("stage_entrances"):
		protected.append(Assets.visible_rect(gate).grow(16))
	# Leave the guardian, reward and exit approaches easy to read.
	protected.append(Rect2(5340,350,570,250))
	protected.append(Rect2(6104,414,172,186))
	for incoming: bool in [true,false]:
		var border: int = level.chapter-2 if incoming else level.chapter-1
		if border < 0 or border >= Campaign.STAGES-1:
			continue
		var path: String = SOURCES[border]
		var bounds: Rect2 = Assets.opaque_rect(path)
		var texture: Texture2D = Assets.texture(path)
		var occupied: Array[Rect2] = protected.duplicate()
		for visual: Sprite2D in level.get_tree().get_nodes_in_group("grounded_scenery"):
			if visual.get_meta("dense_prop",false) or visual.texture.resource_path.contains("8. Medieval Props") or visual.texture.resource_path.get_file() == "apple_basket.png":
				occupied.append(Assets.visible_rect(visual).grow(7))
		var offsets: Array[float] = [0.0]
		for step: int in range(16,257,16):
			offsets.append(-float(step))
			offsets.append(float(step))
		var placed: int = 0
		for preferred: float in ([260.0,820.0,1260.0] if incoming else [4940.0,5260.0,6060.0,6330.0]):
			if placed >= 3:
				break
			for offset: float in offsets:
				var x: float = preferred+offset
				var rect := Rect2(Vector2(x+bounds.position.x-texture.get_width()/2.0,600-bounds.size.y),bounds.size)
				var supported: bool = false
				for floor: Vector2 in level.profile.builder.FLOORS:
					supported = supported or (rect.position.x >= floor.x+10 and rect.end.x <= floor.y-10)
				if not supported or occupied.any(func(area: Rect2) -> bool: return rect.intersects(area)):
					continue
				var detail: Sprite2D = Assets.grounded(level,path,x,1.0,-3)
				detail.modulate.a = lerpf(0.35,0.9,1.0-x/1536.0 if incoming else (x-4864.0)/1536.0)
				detail.set_meta("dense_prop",true)
				detail.set_meta("border",border+1)
				detail.add_to_group("border_details")
				occupied.append(rect.grow(7))
				placed += 1
				break
