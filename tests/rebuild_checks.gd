extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Motion = preload("res://scripts/hero_motion.gd")
const Assets = preload("res://scripts/level_assets.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/rebuild-check-controller.cfg"
	hub.defaults()
	for stage: int in range(1,13):
		level = load(Campaign.SCENES[stage-1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(25)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		check((level.stage_width == 19200 and level.portal.position.x == 19000 and level.chest.position.x == 18260) if level.district != null else (level.stage_width == 12800 and level.portal.position.x == 12590 and level.chest.position.x == 11920),"Stage %d uses its current authored extent and final encounter/reward/gateway" % stage)
		check((level.district.spaces.size() == 26 and level.profile.builder.LEDGES.size() > 35) if level.district != null else (level.extension.rooms.size() == 2 and level.profile.builder.LEDGES.size() >= 26),"Stage %d loads its authored district or expanded traversal rooms" % stage)
		var ordered: Array = level.profile.checkpoints.duplicate()
		ordered.sort()
		check((level.checkpoints.size() == 8 and level.hud.checkpoint_total == 8) if level.district != null else (level.checkpoints.size() == 5 and level.hud.checkpoint_total == 5 and level.profile.checkpoints == ordered),"Stage %d exposes the correct sanctuary count to the HUD" % stage)
		check(get_nodes_in_group("enemies").size() == (43 if level.district != null else 19),"Stage %d populates its current route with the intended encounter roster" % stage)
		check(level.profile.seals[2].x > 8000 and absf(level.profile.seals[2].y-550) > 500,"Stage %d puts the final objective on a required upper/lower route" % stage)
		var fires: Array[Node] = get_nodes_in_group("upright_campfires")
		var upright: bool = fires.size() == level.world_details.fires.size()
		for fire: Sprite2D in fires:
			upright = upright and not fire.region_enabled and fire.rotation == 0 and fire.scale.x == fire.scale.y and fire.texture.resource_path.ends_with("/campfire.png") and absf(Assets.visible_rect(fire).end.y-float(fire.get_meta("surface_y"))) < 0.1
		check(upright,"Stage %d uses complete upright side-view campfires with a fixed floor contact" % stage)
		var supported: bool = true
		for enemy: Node2D in get_nodes_in_group("enemies"):
			if not enemy.flying:
				if not is_finite(enemy.support_limits.x):
					print("UNSUPPORTED ENEMY ",enemy.species," at ",enemy.home)
				supported = supported and is_finite(enemy.support_limits.x) and enemy.travel_limits.x >= enemy.support_limits.x and enemy.travel_limits.y <= enemy.support_limits.y
		check(supported,"Stage %d elevated enemies patrol only their actual supporting tier" % stage)
		level.player.set_physics_process(false)
		if level.district != null:
			for at: Vector2 in [Vector2(6020,-700),Vector2(8530,1760)]:
				level.player.position = at
				preload("res://scripts/level_backdrop.gd").update(level)
				check(level.camera.position.y < -700 if at.y < 0 else level.camera.position.y > 1400,"District camera frames the actual belfry and submerged gallery")
		for room: Dictionary in level.extension.rooms:
			level.player.position = room.peak
			preload("res://scripts/level_backdrop.gd").update(level)
			check(level.camera.position.y > 700 if room.lower else level.camera.position.y < 100,"Stage %d camera follows the %s route vertically" % [stage,"lower" if room.lower else "upper"])
		if stage == 1:
			for clip: String in Motion.PIVOTS:
				var stable: bool = true
				for facing: float in [-1.0,1.0]:
					level.player.animation.play(clip)
					level.player.animation.pause()
					for frame: int in level.player.animation.sprite_frames.get_frame_count(clip):
						level.player.animation.frame = frame
						Motion.anchor(level.player.animation,facing)
						var texture: Texture2D = level.player.animation.sprite_frames.get_frame_texture(clip,frame)
						var pivot: Vector2 = Motion.PIVOTS[clip]-texture.get_size()/2
						var world: Vector2 = level.player.animation.position+Vector2(pivot.x*3*facing,pivot.y*3)
						stable = stable and world.length() < 0.01
				check(stable,"Documented feet pivot stays fixed in every frame and direction: "+clip)
			await contact_window()
		level.queue_free()
		await ticks(2)
	OS.delay_msec(120)
	await ticks(6)
	print("REBUILD RESULT: %d/%d checks passed" % [checks-failures,checks])
	quit(1 if failures else 0)

func contact_window() -> void:
	# Nearby breakable props have their own hit pause. Isolate the blade
	# window fixture so elapsed test ticks describe the sword itself.
	var props: Array[Node] = []
	for urn: Node2D in get_nodes_in_group("breakables"):
		if urn.position.distance_to(Vector2(700,600)) < 300:
			urn.remove_from_group("breakables")
			props.append(urn)
	level.player.respawn(Vector2(700,598))
	level.player.facing = 1
	level.player.set_physics_process(true)
	await ticks(5)
	var target := Enemy.new()
	target.species = "plant"
	target.position = Vector2(1100,600)
	level.add_child(target)
	target.set_physics_process(false)
	level.combat.connect_enemy(target,false)
	var cues: Array[String] = []
	level.player.sound_requested.connect(func(kind: String) -> void: cues.append(kind))
	Pad.button(JOY_BUTTON_X,true)
	await ticks(5)
	Pad.button(JOY_BUTTON_X,false)
	check(target.health == 3 and not cues.has("attack"),"Sword windup cannot damage or play its swing sound before the source blade frames")
	await ticks(5)
	target.position.x = 870
	await ticks(3)
	check(target.health == 2,"A monster entering the visible blade late in the active window is hit")
	await ticks(22)
	check(target.health == 2,"One sword swing cannot damage the same monster repeatedly")
	check(cues.count("attack") == 1,"Each visible sword swing emits its swish exactly once on contact frames")
	check(absf(level.player.position.x-700) < 1,"A stationary sword attack never moves the character's physics body")
	target.queue_free()
	for urn: Node in props:
		urn.add_to_group("breakables")
