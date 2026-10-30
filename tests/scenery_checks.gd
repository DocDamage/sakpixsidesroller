extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Assets = preload("res://scripts/level_assets.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/scenery-check-controller.cfg"
	hub.defaults()
	for stage: int in range(1,13):
		level = load(Campaign.SCENES[stage-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for layer_name: String in ["DistantTown","DistantForest"]:
			var layer: Node2D = level.get_node(layer_name)
			var anchored: bool = true
			for child: Node in layer.get_children():
				if child is Sprite2D:
					var foot: Vector2 = layer.to_local(Assets.visible_rect(child).end)
					anchored = anchored and absf(foot.y-float(child.get_meta("surface_y",-9999))) < 0.1
			check(anchored,"Stage %d %s silhouettes share an actual ground plane" % [stage,layer_name])
		check(get_nodes_in_group("scenic_foundations").size() >= 2,"Stage %d supplies continuous earth or wall behind its background structures" % stage)
		check(get_nodes_in_group("traversal_supports").size() >= 24,"Stage %d original traversal platforms have supports below their walkable tops" % stage)
		var removed_visible: bool = false
		for visual: Sprite2D in level.find_children("*","Sprite2D",true,false):
			removed_visible = removed_visible or (visual.get_meta("composition_removed",false) and visual.is_visible_in_tree())
		check(not removed_visible,"Stage %d ambient animation does not restore removed clutter" % stage)
		if stage in [7,8,11,12]:
			var opaque: bool = true
			for fill: Sprite2D in get_nodes_in_group("scenic_fill"):
				var pixels: Image = fill.texture.get_image()
				for x: int in pixels.get_width():
					for y: int in pixels.get_height():
						opaque = opaque and pixels.get_pixel(x,y).a > 0.99
			check(opaque,"Stage %d underground fill contains no transparent seams or grass-border grid" % stage)
		if stage in [9,10]:
			var attached: bool = true
			for bay: Node in level.get_node("DistantTown").get_children():
				attached = attached and bay is Node2D and bay.get_child_count() > 0 and bay.get_child(0) is Sprite2D
				if bay.get_child_count() > 1:
					attached = attached and bay.get_child(0).texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED
			check(attached,"Stage %d reliefs fade with their supporting wall instead of floating independently" % stage)
		level.queue_free()
		await ticks(2)
	print("SCENERY RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
