extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Weather = preload("res://scripts/stage_weather.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/weather-test-controller.cfg"
	hub.defaults()
	for stage: int in range(1,12):
		check(Weather.climate_at(stage,6400).is_equal_approx(Weather.climate_at(stage+1,0)),"Border %d/%d shares rain, mist, wind and cloud values" % [stage,stage+1])
	for stage: int in range(1,13):
		level = load(Campaign.SCENES[stage-1]).instantiate()
		root.add_child(level)
		current_scene = level
		level.player.set_physics_process(false)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		await ticks(8)
		var weather: Node2D = level.weather
		check(weather != null and weather.panels.size() == 3 and weather.roof_map.get_width() == 2048,"Stage %d installs cloud, mist and rain passes with its real shelter map" % stage)
		var safe_ui: bool = true
		for panel: ColorRect in weather.panels:
			safe_ui = safe_ui and panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and panel.get_parent().layer < 20 and panel.size == root.get_visible_rect().size
		check(safe_ui,"Stage %d weather sits below the HUD and cannot consume controller/menu input" % stage)
		var ledge: Rect2 = level.profile.builder.LEDGES[0]
		check(weather.sky_at(ledge.get_center()+Vector2(0,30)) == 0,"Stage %d elevated walkways shelter the space underneath from rain" % stage)
		if level.district != null:
			check(weather.sky_at(Vector2(4380,1300)) == 0,"District prison and lower return loop remain sheltered")
			check(weather.sky_at(Vector2(4600,-620)) == 0 and weather.sky_at(Vector2(3900,-150)) == 1,"Bell tower interior stays dry while the approach across the eaves remains exposed")
		for room: Dictionary in level.extension.rooms:
			if room.lower:
				check(weather.sky_at(room.peak-Vector2(0,70)) == 0,"Stage %d lower traversal stays sheltered under its actual ceiling" % stage)
			else:
				check(weather.sky_at(room.peak-Vector2(0,70)) == (0 if stage == 9 else 1),"Stage %d upper traversal respects its open-air/underground setting" % stage)
		check(weather.wet_materials.size() > 0 and get_nodes_in_group("weather_surfaces").size() > (20 if level.district != null else 100),"Stage %d exposed terrain and ledges receive the wet-surface shader" % stage)
		var before: float = weather.clock
		var wet_clock: float = weather.wet_materials[0].get_shader_parameter("clock")
		paused = true
		await ticks(6)
		check(is_equal_approx(weather.clock,before) and is_equal_approx(float(weather.rain_material.get_shader_parameter("clock")),before) and is_equal_approx(float(weather.wet_materials[0].get_shader_parameter("clock")),wet_clock),"Stage %d pause freezes rain, clouds, fog, wet glints and storm timing" % stage)
		paused = false
		await ticks(3)
		check(weather.clock > before,"Stage %d weather resumes cleanly after pause" % stage)
		level.player.position = Vector2(6020,-700) if level.district != null else level.extension.rooms[0].peak
		preload("res://scripts/level_backdrop.gd").update(level)
		level.camera.reset_smoothing()
		level.camera.force_update_scroll()
		weather._process(0)
		var origin: Vector2 = weather.rain_material.get_shader_parameter("camera_origin")
		check(origin.is_equal_approx(level.camera.get_screen_center_position()-root.get_visible_rect().size/2),"Stage %d weather follows the real camera through vertical traversal" % stage)
		if stage == 9:
			check(weather.exposure.count(0.0) == weather.exposure.size(),"Rootbound Catacombs remain fully dry even beside a rainy stage boundary")
		if stage == 10:
			check(weather.sky_at(Vector2(2000,300)) == 0 and weather.sky_at(Vector2(12400,300)) == 1,"Prism Vault weather appears only on its exposed roof and forest-facing exit")
		if stage == 4:
			level.player.position = Vector2(100,550)
			weather.set_process(false)
			weather.next_flash = weather.clock
			weather._process(0.01)
			var scheduled: float = weather.next_flash-weather.clock
			weather._process(0.2)
			check(weather.flash > 0 and weather.flash <= 0.85 and scheduled >= 48,"Distant storm light uses a single soft pulse with at least 48 seconds between strikes")
			weather._process(0.8)
			check(is_zero_approx(weather.flash),"Storm light returns fully to normal without repeated flicker")
		level.queue_free()
		await ticks(2)
	print("WEATHER RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
