extends "res://tests/living_world_checks.gd"

const Assets = preload("res://scripts/level_assets.gd")
const Campaign = preload("res://scripts/campaign_state.gd")

func protected_areas() -> Array[Dictionary]:
	var areas: Array[Dictionary] = []
	for gate: Sprite2D in get_nodes_in_group("stage_entrances"):
		areas.append({"name":"arrival gateway","rect":Assets.visible_rect(gate).grow(8)})
	for actor: Dictionary in level.world_details.actors:
		areas.append({"name": actor["name"], "rect": Rect2(actor["position"] + Vector2(-32, -85), Vector2(64, 85))})
	for lantern: Sprite2D in level.checkpoints:
		var feet: Vector2 = lantern.get_meta("feet") if lantern.has_meta("feet") else Vector2(lantern.position.x,600)
		areas.append({"name":"checkpoint","rect":Rect2(feet+Vector2(-24,-100),Vector2(48,100))})
	for hazard: Rect2 in level.hazards:
		areas.append({"name": "spikes", "rect": hazard.grow(10)})
	for urn: Node2D in get_nodes_in_group("breakables"):
		areas.append({"name":"urn","rect":Rect2(urn.position+Vector2(-27,-66),Vector2(54,66))})
	for fire: Sprite2D in level.world_details.fires:
		areas.append({"name":"campfire","rect":Rect2(fire.position.x-22,float(fire.get_meta("surface_y"))-52,44,52),"owner":fire})
	areas.append({"name":"reward","rect":Rect2(level.chest.position.x-40,510,80,90)})
	areas.append({"name":"exit","rect":Rect2(level.portal.position.x-70,430,140,170)})
	return areas

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/placement-test-controller.cfg"
	hub.defaults()
	for chapter: int in range(1, Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter - 1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		var areas: Array[Dictionary] = protected_areas()
		var floating: Array[String] = []
		var conflicts: Array[String] = []
		var unsupported: Array[String] = []
		var furniture: Array[Sprite2D] = []
		for visual: Sprite2D in get_nodes_in_group("grounded_scenery"):
			if not visual.is_visible_in_tree():
				continue
			var rect: Rect2 = Assets.visible_rect(visual)
			var path: String = visual.texture.resource_path
			var file: String = path.get_file()
			# Surface metadata belongs to the prop's parent layer. Distant layers
			# now move vertically with the camera as well as horizontally.
			var surface: Vector2 = visual.get_parent().to_global(Vector2(visual.position.x,float(visual.get_meta("surface_y"))))
			if absf(rect.end.y - surface.y) > 0.1:
				floating.append(file + " at " + str(visual.position.x))
			var solid_prop: bool = visual.get_meta("dense_prop",false) or path.contains("8. Medieval Props") or (visual.z_index >= -3 and (file in ["cross_tombstone.png", "pumpkin_cluster.png", "stone_well.png", "witch_cauldron.png", "pumpkin_scarecrow.png", "raven_on_signpost.png", "open_stone_coffin.png"]))
			if solid_prop:
				if path.contains("8. Medieval Props") or visual.get_meta("dense_prop",false):
					furniture.append(visual)
				for area: Dictionary in areas:
					if area.get("owner") == visual:
						continue
					if rect.intersects(area["rect"]):
						conflicts.append("%s at %d overlaps %s" % [file, visual.position.x, area["name"]])
				var supported: bool = false
				for span: Vector2 in level.profile.builder.FLOORS:
					if rect.position.x >= span.x and rect.end.x <= span.y:
						supported = true
				if level.district != null:
					for floor: Rect2 in level.profile.builder.LEDGES:
						supported = supported or (absf(floor.position.y-float(visual.get_meta("surface_y"))) < 1 and rect.position.x >= floor.position.x and rect.end.x <= floor.end.x)
				if not supported:
					unsupported.append(file + " at " + str(visual.position.x))
		check(floating.is_empty(), "Stage %d props use visible pixel bases: %s" % [chapter, str(floating)])
		check(conflicts.is_empty(), "Stage %d solid props leave interactions and hazards clear: %s" % [chapter, str(conflicts)])
		check(unsupported.is_empty(), "Stage %d solid prop footprints stay entirely on land: %s" % [chapter, str(unsupported)])
		var collisions: Array[String] = []
		for i: int in furniture.size():
			for j: int in range(i + 1, furniture.size()):
				if Assets.visible_rect(furniture[i]).grow(3).intersects(Assets.visible_rect(furniture[j])):
					collisions.append("%s/%s at %d/%d" % [furniture[i].texture.resource_path.get_file(), furniture[j].texture.resource_path.get_file(), furniture[i].position.x, furniture[j].position.x])
		check(collisions.is_empty(), "Stage %d furniture silhouettes have breathing room: %s" % [chapter, str(collisions)])
		if chapter == 4:
			var mounted: Array[Node] = get_nodes_in_group("mounted_scenery")
			var supported: bool = mounted.size() == 8
			for fixture: Sprite2D in mounted:
				var structure: Sprite2D = fixture.get_meta("mount_surface").get_ref()
				if structure == null:
					supported = false
					continue
				var point: Vector2 = fixture.get_meta("mount_pixel")
				var pixels: Image = structure.texture.get_image()
				if pixels.is_compressed():
					pixels.decompress()
				var surface: Vector2 = structure.to_global(point - structure.texture.get_size() / 2.0)
				var bracket: Vector2 = fixture.global_position + Vector2(fixture.get_meta("hook_offset"))
				supported = supported and pixels.get_pixelv(Vector2i(point)).a > 0.5 and surface.distance_to(bracket) < 0.1
			check(supported, "Keep's eight torch brackets attach to opaque architecture pixels, including the arch pillars")
		level.queue_free()
		await ticks(2)
	print("PLACEMENT RESULT: %d/%d checks passed" % [checks - failures, checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
