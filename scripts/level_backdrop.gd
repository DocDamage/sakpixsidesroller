extends RefCounted

static func update(level: Node2D) -> void:
	var story_x: float = preload("res://scripts/stage_expansion.gd").base_x(level.player.position.x) if level.extended else level.player.position.x
	if level.district != null:
		story_x = level.district.story_x()
	level.camera.position.x = clampf(level.player.position.x+level.player.velocity.x*0.22,640,level.stage_width-640)
	var vertical: float = clampf(absf(level.player.position.y-600)/160,0,1) if level.extended else 0.0
	level.camera.position.y = clampf(level.player.position.y-lerpf(240,80,vertical),-540,1440) if level.extended else 360.0
	if level.district != null:
		level.camera.position.y = clampf(level.player.position.y-lerpf(240,80,vertical),-1050,1900)
	level.camera.offset = level.effects.camera_offset()
	var left: float = level.camera.get_screen_center_position().x - 640
	level.sky.camera_left = left
	level.sky.chapter = level.chapter
	level.sky.journey_x = story_x
	level.atmosphere.camera_left = left
	level.atmosphere.chapter = level.chapter
	level.atmosphere.journey_x = story_x
	var top: float = level.camera.get_screen_center_position().y-360
	level.atmosphere.position.y = top
	level.get_node("DistantTown").position.y = top*(1.0 if level.chapter in [9,10] else 0.7)
	level.get_node("DistantForest").position.y = top*0.45
	level.get_node("DistantTown").position.x = left * 0.62
	level.get_node("DistantForest").position.x = left * 0.25
	var swamp: float = clampf(1.0-absf(story_x-3750)/1000.0,0,1) if level.chapter == 1 else 0.0
	level.get_node("DistantTown").modulate.a = 1.0 - swamp * 0.65
	if level.chapter == 10:
		# The whole roof recedes during the final region. A per-tile fade alone
		# stayed mostly hidden because the wall moves with distant parallax.
		level.get_node("DistantTown").modulate.a *= 1.0-smoothstep(4400,6200,story_x)*0.94
	level.sky.swamp_blend = swamp
	# The first curse and the final Daybreak Gate celebrate dawn. Intermediate
	# results preserve the border palette instead of flashing day before night.
	level.sky.dawn = level.completed and level.chapter in [1,12]
	level.sky.road_mode = level.chapter >= 2
	level.sky.fortress = level.chapter == 4
	level.sky.castle_blend = smoothstep(4000,6400,story_x) if level.chapter == 3 else 0.0
	level.sky.road_blend = clampf((story_x-500)/5900.0,0,1) if level.chapter == 2 else (0.82 if level.chapter >= 3 else 0.0)
	level.sky.expedition = level.chapter if level.chapter >= 5 else 0
	if level.chapter >= 5:
		level.sky.road_mode = false
		level.sky.road_blend = 0.15 if level.chapter >= 7 else 0.0
		if level.chapter in [9,10]:
			level.sky.road_blend = 0.0
	level.atmosphere.warmth = level.sky.road_blend
	level.get_node("DistantForest").modulate.a = 1.0 - level.sky.road_blend * 0.55
