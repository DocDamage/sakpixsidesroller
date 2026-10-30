extends Node2D

const Assets = preload("res://scripts/level_assets.gd")
var level: Node2D
var spaces: Array[Dictionary] = []
var rooms: Array[Dictionary] = []
var climbs: Array[Dictionary] = []
var hooks: Array[Vector2] = []
var waters: Array[Node2D] = []
var platforms: Array[AnimatableBody2D] = []
var switches: Array[Dictionary] = []
var gates: Dictionary = {}
var upgrades: Dictionary = {}
var rewards: Array[Dictionary] = []
var visited: Dictionary = {}
var opened: Dictionary = {}
var map_overlay: Control
var lighting: Node2D
var jailer: Node2D
var hint_time: float = 0
var ambience_time: float = 0
var water_ambience_time: float = 2
var weather_room: String = ""
var map_cooldown: float = 0
var ritual_ready: bool = false
var tram: AnimatableBody2D
var jail_arena: bool = false

static func install(owner_level: Node2D) -> void:
	var director: Node2D = load("res://scripts/district_director.gd").new()
	director.name = "HauntedDistrict"
	director.level = owner_level
	owner_level.district = director
	owner_level.extension = director
	owner_level.extended = true
	owner_level.add_child(director)
	director.setup()

func setup() -> void:
	spaces = level.profile.builder.rooms
	level.player.world_width = level.stage_width
	level.player.world_bottom = 2150
	level.camera.limit_right = int(level.stage_width)
	level.camera.limit_top = -1300
	level.camera.limit_bottom = 2150
	level.hud.stage_width = level.stage_width
	level.hud.allow_exploration = true
	level.chest.position = Vector2(18260,600)
	level.portal.position = Vector2(19000,600)
	Assets.anchor_base(level.chest,600)
	Assets.anchor_base(level.portal,600)
	level.player.traversal = preload("res://scripts/district_motion.gd").new(level.player,self)
	preload("res://scripts/district_sounds.gd").install(level.audio)
	for at: Vector2 in [Vector2(620,600),Vector2(2500,600),Vector2(5390,-500),Vector2(4380,1460),Vector2(7350,1100),Vector2(10500,600),Vector2(15280,-120),Vector2(16800,600)]:
		var lantern: Sprite2D = Assets.sprite(level,Assets.PROPS+"spirit_lantern.png",at-Vector2(0,49),3,3)
		lantern.set_meta("feet",at)
		level.checkpoints.append(lantern)
		level.profile.checkpoints.append(at.x)
		level.lighting.add_glow(lantern.position,Color("7fd5d9"),125,lantern)
	level.hud.checkpoint_total = level.checkpoints.size()
	for at: Vector2 in [Vector2(810,600),Vector2(2640,120),Vector2(3950,-80),Vector2(5110,-500),Vector2(6040,600),Vector2(4150,1460),Vector2(6550,1460),Vector2(7630,1100),Vector2(9910,1420),Vector2(10820,600),Vector2(11850,80),Vector2(12700,-120),Vector2(15300,600),Vector2(16580,600),Vector2(17130,600)]:
		var urn: Node2D = preload("res://scripts/breakable_urn.gd").new()
		urn.position = at
		level.add_child(urn)
		urn.shattered.connect(level.combat.urn_shattered)
		level.profile.urns.append(at.x)
	for entry: Array in [[2440,380,600,false],[2720,120,380,false],[4180,-80,200,true],[3570,600,1460,false],[6920,600,1460,true],[7140,600,1100,false],[10000,1100,1760,false],[10250,600,1460,false],[11600,80,600,false],[12420,-120,600,true],[14740,-120,640,true],[16430,600,1460,false]]:
		add_climb(entry[0],entry[1],entry[2],entry[3])
	add_climb(7560,1100,1760,false)
	add_climb(5240,1120,1460,true)
	add_climb(4460,1120,1460,true)
	add_climb(18520,600,1460,false)
	add_gate("quarter",Rect2(4090,260,44,340))
	add_gate("trapdoor",Rect2(3460,600,220,28))
	add_gate("sluice",Rect2(9050,1260,44,500))
	add_gate("chapel",Rect2(16900,140,48,460))
	add_gate("chapel_hatch",Rect2(18400,600,240,28))
	add_gate("chapel_passage",Rect2(16600,1220,100,240))
	add_gate("jail_left",Rect2(4600,1180,36,280))
	add_gate("jail_right",Rect2(5180,1180,36,280))
	for id: String in ["jail_left","jail_right"]:
		gates[id].body.collision_layer = 0
		gates[id].visual.position.y = -280
	var bell_lift: AnimatableBody2D = add_platform(Vector2(4915,-500),Vector2(4915,600),145,true)
	bell_lift.enabled = false
	bell_lift.shuttle = true
	add_platform(Vector2(10300,600),Vector2(10300,1460),145,true)
	add_platform(Vector2(12460,600),Vector2(12460,-120),125,true)
	add_platform(Vector2(16380,600),Vector2(16380,1460),140,true)
	add_platform(Vector2(7400,600),Vector2(8200,600),115,false)
	add_platform(Vector2(13140,-120),Vector2(13860,-120),130,false)
	add_platform(Vector2(13400,400),Vector2(13900,400),105,false)
	tram = add_platform(Vector2(3780,1390),Vector2(16380,1390),720,false)
	tram.width = 240
	tram.shuttle = true
	tram.enabled = false
	add_switch("bell_winch",Vector2(6020,-700),"Release the bell cage: open the return lift and quarter gate")
	add_switch("bell_cage",Vector2(4915,-500),"Call / ride the bell cage to the court")
	add_switch("bell_cage",Vector2(4915,600),"Call / ride the bell cage")
	add_switch("prison_release",Vector2(3500,1460),"Open the trapdoor shortcut to the quarter")
	add_switch("sluice_control",Vector2(7410,1100),"Drain / fill the cistern and open the floodgate")
	add_switch("quarter_ritual",Vector2(2920,600),"Offer the three seals at the quarter ritual")
	add_switch("quarter_tram",Vector2(3780,1390),"Call / ride the lantern tram")
	add_switch("quarter_tram",Vector2(16380,1390),"Call / ride the lantern tram")
	add_water(Vector2(7660,1320),2440,1760,38)
	add_water(Vector2(13200,600),1600,1040,58)
	for at: Vector2 in [Vector2(13230,-390),Vector2(13920,-400),Vector2(14630,-410),Vector2(11220,-500),Vector2(5420,-820)]:
		hooks.append(at)
		var ring: Sprite2D = Assets.sprite(self,Assets.MAGIC+"void_crystal_gem.png",at,1.1,3)
		ring.modulate = Color("9ee2dd")
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if enemy.species == "guard" and enemy.home.distance_to(Vector2(4810,1460)) < 4:
			jailer = enemy
			jailer.health = 8
			jailer.max_health = 8
			jailer.damage_trail = 8
			var title := Label.new()
			title.text = "THE PRISON JAILER"
			title.position = Vector2(-78,jailer.ui_top-30)
			title.add_theme_font_size_override("font_size",12)
			title.add_theme_color_override("font_color",Color("dfc39c"))
			jailer.add_child(title)
			jailer.defeated.connect(jailer_fallen)
	add_reward("moon_hook",Vector2(4530,1460),"MOON HOOK: hold Up + Use below a hook ring",true)
	add_reward("lantern_wick",Vector2(11520,-240),"LANTERN WICK: wider character light",false)
	add_reward("grave_edge",Vector2(13550,1460),"GRAVE EDGE: combo finishers deal one extra damage",false)
	for x: float in [8080.0,8220.0,8360.0,8500.0,8640.0,8780.0,8920.0,9060.0]:
		level.add_item("coin",Vector2(x,1695))
	level.hud.total_coins = level.items.size()-3
	lighting = preload("res://scripts/district_lighting.gd").new()
	level.add_child(lighting)
	lighting.setup(self)
	map_overlay = preload("res://scripts/district_map.gd").new()
	map_overlay.district = self
	var map_layer := CanvasLayer.new()
	map_layer.layer = 22
	level.add_child(map_layer)
	map_layer.add_child(map_overlay)
	map_overlay.hide()
	install_route_markers()
	level.combat.guardian.defeated.connect(chapel_opened)

func install_route_markers() -> void:
	# The chapel stair is an actual hole through street and crypt ceilings.
	# A recessed doorway and wall-mounted route boards make its use explicit.
	Assets.grounded(self,Assets.CRYPT+"crypt_arch_doorway.png",18520,4.2,-8,600)
	for entry: Array in [[4915,-570,"BELL CAGE",true],[2720,300,"APOTHECARY",true],[18520,492,"UNDERCROFT / TRAM",true],[17860,1360,"TRAM STATION",false],[16430,500,"RETURN GALLERY",true],[4180,100,"TOWER ENTRY",true],[6920,870,"OSSUARY",true]]:
		var sign := Label.new()
		sign.text = ("↓ " if entry[3] else "← ")+entry[2]
		sign.position = Vector2(entry[0]-100,entry[1])
		sign.size = Vector2(200,28)
		sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign.add_theme_font_size_override("font_size",13)
		sign.add_theme_color_override("font_color",Color("d7c69e"))
		sign.add_theme_color_override("font_shadow_color",Color("10141a"))
		sign.add_theme_constant_override("shadow_offset_y",2)
		add_child(sign)

func chapel_opened(_at: Vector2) -> void:
	# A clear must leave a complete route home even if the optional pump or
	# prison releases were missed on the outward journey.
	for id: String in ["chapel","chapel_hatch","chapel_passage","sluice","trapdoor","quarter"]:
		open_gate(id)
	drain_for_tram()
	level.hud.notify_player("Chapel undercroft opened. Descend the marked stair beyond the Moon Key and follow the passage left to the tram. You can return before leaving.")

func drain_for_tram() -> void:
	waters[0].target_y = 1720
	waters[0].current = -45
	waters[0].water_material.set_shader_parameter("current",-45.0)

func add_climb(x: float, top: float, bottom: float, rope: bool) -> void:
	climbs.append({"x":x,"top":top,"bottom":bottom,"rope":rope})
	# The scaffold icon contains a whole worktable/platform, not a ladder tile.
	# These rails repeat at a uniform 3x source scale: 48px wide, 18px rungs.
	var path: String = "res://Stages/Dark Fantasy/7. Interactive Objects/"+("wooden_rope_ladder.png" if rope else "wooden_ladder.png")
	for y: int in range(int(top),int(bottom),72):
		var height: float = minf(72,bottom-y)
		var rung: Sprite2D = Assets.sprite(self,path,Vector2(x,y+height/2),1,-2)
		rung.region_enabled = true
		rung.region_rect = Rect2(8,4,16,height/3)
		rung.scale = Vector2.ONE*3
		rung.modulate = Color("c0ae99")
		rung.add_to_group("district_ladder_sections")
		rung.set_meta("climb_span",Vector2(top,bottom))

func add_gate(id: String, rect: Rect2) -> void:
	preload("res://scripts/town_builder.gd").solid(level,rect)
	var body: StaticBody2D = level.get_child(level.get_child_count()-1)
	var visual: Sprite2D = Assets.sprite(body,Assets.CRYPT+"barred_cell_door.png",Vector2.ZERO,1,2)
	var bounds: Rect2 = Assets.opaque_rect(visual.texture.resource_path)
	visual.region_enabled = true
	visual.region_rect = bounds
	visual.scale = rect.size/bounds.size
	gates[id] = {"body":body,"visual":visual,"rect":rect}

func open_gate(id: String) -> void:
	if opened.has(id):
		return
	opened[id] = true
	var gate: Dictionary = gates[id]
	gate.body.set_deferred("collision_layer",0)
	var tween: Tween = create_tween()
	tween.tween_property(gate.visual,"position:y",-gate.rect.size.y,0.8)
	# The gate retracts into its housing; its raised sprite must not hang
	# across a different balcony or climbing route after collision is removed.
	tween.tween_callback(gate.visual.hide)
	level.audio.play_at("gate",gate.rect.get_center())
	level.hud.notify_player("Shortcut opened. The route remains open after a fall.")

func add_platform(from: Vector2, to: Vector2, speed: float, lift: bool) -> AnimatableBody2D:
	var platform: AnimatableBody2D = preload("res://scripts/district_platform.gd").new()
	platform.start = from
	platform.finish = to
	platform.speed = speed
	platform.lift = lift
	if absf(to.x-from.x) > 4000:
		platform.width = 240
	platform.district = self
	level.add_child(platform)
	platforms.append(platform)
	if lift and platforms.size() == 1:
		# Repeat the actual chain links at their native scale along both cage rails.
		var path: String = Assets.CRYPT+"hanging_chains_a.png"
		var bounds: Rect2 = Assets.opaque_rect(path)
		for x: float in [from.x-68,from.x+68]:
			for y: int in range(-980,600,60):
				var chain: Sprite2D = Assets.sprite(self,path,Vector2(x,y+30),1,-5)
				chain.region_enabled = true
				chain.region_rect = bounds
				chain.scale = Vector2(12/bounds.size.x,60/bounds.size.y)
				chain.modulate = Color("9892a4")
		return platform
	if lift:
		var chain_path: String = "res://Stages/Medievil Kingdom/5. Drawbridges, Stairs & Traversal Structures/hanging_ropes_a.png"
		var chain: Sprite2D = Assets.sprite(self,chain_path,Vector2(from.x,(from.y+to.y)/2),1,-5)
		chain.region_enabled = true
		chain.region_rect = Assets.opaque_rect(chain_path)
		chain.scale = Vector2(40/chain.region_rect.size.x,absf(from.y-to.y)/chain.region_rect.size.y)
	return platform

func add_switch(id: String, at: Vector2, text: String) -> void:
	var lever: Sprite2D = Assets.grounded(self,"res://Stages/Medievil Kingdom/10. Medieval Collectibles, Interactive Objects & Royal Details/pump_lever.png",at.x,2.2,3,at.y)
	switches.append({"id":id,"position":at,"text":text,"visual":lever})

func add_water(at: Vector2, span: float, bottom: float, flow: float) -> void:
	var water: Node2D = preload("res://scripts/district_water.gd").new()
	water.position = at
	water.target_y = at.y
	water.width = span
	water.bottom = bottom
	water.current = flow
	water.level = level
	level.add_child(water)
	waters.append(water)

func add_reward(id: String, at: Vector2, text: String, locked: bool) -> void:
	var chest: Sprite2D = Assets.grounded(self,Assets.PROPS+"ghost_chest.png",at.x,2.3,3,at.y)
	rewards.append({"id":id,"position":at,"text":text,"locked":locked,"visual":chest})
	level.lighting.add_glow(chest.position,Color("8aacc866"),80,chest)

func water_at(at: Vector2) -> Node2D:
	for water: Node2D in waters:
		if water.contains(at):
			return water
	return null

func surface_kind(at: Vector2) -> String:
	if water_at(at-Vector2(0,5)) != null:
		return "wet"
	for platform: AnimatableBody2D in platforms:
		if absf(at.y-platform.position.y) < 6 and absf(at.x-platform.position.x) < platform.width/2+8:
			return "wood"
	for surface: Dictionary in level.profile.builder.surfaces:
		var rect: Rect2 = surface.rect
		if absf(at.y-rect.position.y) < 12 and at.x >= rect.position.x and at.x <= rect.end.x:
			return surface.kind
	return "stone"

func find_hook(from: Vector2) -> Vector2:
	var nearest: float = 460
	var result: Vector2 = Vector2.INF
	for hook: Vector2 in hooks:
		if hook.y > from.y-50 or hook.distance_to(from) >= nearest:
			continue
		var ray := PhysicsRayQueryParameters2D.create(from,hook,1)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			result = hook
			nearest = hook.distance_to(from)
	return result

func update_checkpoints() -> void:
	for i: int in level.checkpoints.size():
		var lantern: Sprite2D = level.checkpoints[i]
		var feet: Vector2 = lantern.get_meta("feet")
		if level.player.position.distance_to(feet) < 60 and level.player.is_on_floor() and (i != level.checkpoint_index or Input.is_action_just_pressed("interact")):
			level.checkpoint_index = i
			level.checkpoint = feet-Vector2(0,8)
			level.player.health = 5
			lantern.modulate = Color("a5ffe8")
			level.audio.play("rest")
			level.hud.notify_player("Lantern sanctuary. Vitality restored; return point saved.")

func region() -> String:
	for i: int in range(spaces.size()-1,-1,-1):
		if spaces[i].rect.has_point(level.player.position-Vector2(0,35)):
			return spaces[i].name
	return "THE HAUNTED DISTRICT"

func story_x() -> float:
	return clampf(level.player.position.x/level.stage_width*6400,0,6400)

func _physics_process(delta: float) -> void:
	hint_time = maxf(0,hint_time-delta)
	map_cooldown = maxf(0,map_cooldown-delta)
	if not jail_arena and not opened.has("jailer") and level.player.position.x > 4640 and level.player.position.x < 5140 and absf(level.player.position.y-1460) < 28:
		jail_arena = true
		for id: String in ["jail_left","jail_right"]:
			gates[id].body.set_deferred("collision_layer",1)
			gates[id].visual.position.y = 0
		level.audio.play("gate")
		level.hud.notify_player("The prison jailer seals the cell. Break his swing, or use the upper passage on a later visit.")
	var current_room: String = region()
	if current_room != weather_room and level.weather != null:
		weather_room = current_room
		level.weather.bake_shelter()
	for i: int in spaces.size():
		if spaces[i].rect.has_point(level.player.position-Vector2(0,30)):
			visited[i] = true
	if absf(level.player.position.x-18520) < 125:
		if absf(level.player.position.y-600) < 65:
			level.hud.prompt = "Hold Down to descend to the return tram." if opened.has("chapel_hatch") else "Defeat the Gravekeeper to open this return stair."
		elif absf(level.player.position.y-1460) < 65:
			level.hud.prompt = "Hold Up to return to the chapel; follow the passage left for the tram."
	for switch: Dictionary in switches:
		if level.player.position.distance_to(switch.position) < 85:
			var caption: String = switch.text
			if switch.id == "bell_cage":
				if not opened.has("bell_winch"):
					caption = "Release the winch in the belfry above"
				elif platforms[0].enabled:
					caption = "Bell cage moving. Wait at the landing."
				elif platforms[0].position.distance_to(switch.position) > 6:
					caption = "Call the bell cage to this landing"
				else:
					caption = "Ride the bell cage to the court" if switch.position.y < 0 else "Ride the bell cage to the tower"
			if switch.id == "quarter_tram":
				if tram.enabled:
					caption = "Tram moving. Wait at the station."
				elif tram.position.distance_to(switch.position) < 6:
					caption = "Depart on the tram" if absf(level.player.position.y-tram.position.y) < 12 else "Jump onto the tram before departing"
				else:
					caption = "Call the tram to this station"
			level.hud.prompt = "[%s] %s" % [level.get_node("/root/Controller").prompt("interact"),caption]
			if Input.is_action_just_pressed("interact"):
				activate_switch(switch.id)
	for reward: Dictionary in rewards:
		if upgrades.has(reward.id) or level.player.position.distance_to(reward.position) > 85:
			continue
		level.hud.prompt = "Defeat the prison jailer first." if reward.locked and not opened.has("jailer") else "[%s] Inspect the relic cache" % level.get_node("/root/Controller").prompt("interact")
		if Input.is_action_just_pressed("interact") and (not reward.locked or opened.has("jailer")):
			upgrades[reward.id] = true
			reward.visual.texture = Assets.texture(Assets.HAZARDS+"open_chest.png")
			Assets.anchor_base(reward.visual,reward.position.y)
			if reward.id == "grave_edge":
				level.player.sword_bonus = 1
			level.audio.play("equipment")
			level.hud.notify_player(reward.text)
	if Input.is_action_just_pressed("district_map") and not level.completed and map_cooldown <= 0:
		map_overlay.open_map()
	var controller: Node = level.get_node("/root/Controller")
	if JOY_BUTTON_LEFT_SHOULDER in controller.mapping.values() and controller.down_pressed() and Input.is_action_just_pressed("interact") and map_cooldown <= 0:
		var context: bool = false
		for switch: Dictionary in switches:
			context = context or level.player.position.distance_to(switch.position) < 90
		for reward: Dictionary in rewards:
			context = context or level.player.position.distance_to(reward.position) < 90
		for actor: Dictionary in level.world_details.actors:
			context = context or level.player.position.distance_to(actor.position) < 90
		if not context:
			map_overlay.open_map()
	ambience_time -= delta
	water_ambience_time -= delta
	if water_ambience_time <= 0:
		water_ambience_time = randf_range(3.8,6.4)
		var cistern: Node2D = waters[0]
		var drip_x: float = clampf(level.player.position.x+randf_range(-180,180),cistern.position.x+30,cistern.position.x+cistern.width-30)
		var drip_at := Vector2(drip_x,cistern.position.y-4)
		if level.player.position.distance_to(drip_at) < 600:
			level.audio.play_at("water_drip",drip_at)
			cistern.ripple(drip_x,1.7)
	if ambience_time <= 0:
		ambience_time = 2.5
		for fire: Sprite2D in level.world_details.fires:
			if fire.position.distance_to(level.player.position) < 250:
				level.audio.play_at("fire_detail",fire.position)
				break

func activate_switch(id: String) -> void:
	var source: Vector2 = level.player.position
	var nearest: float = INF
	for switch: Dictionary in switches:
		if switch.id == id and switch.position.distance_to(level.player.position) < nearest:
			source = switch.position
			nearest = source.distance_to(level.player.position)
	level.audio.play_at("lever",source)
	if id == "bell_winch":
		opened["bell_winch"] = true
		open_gate("quarter")
		level.hud.notify_player("Bell cage released. Return to its upper landing or descend to the graveyard.")
	elif id == "bell_cage":
		if not opened.has("bell_winch"):
			level.hud.notify_player("The bell cage is held above. Release the winch in the belfry.")
			return
		var cage: AnimatableBody2D = platforms[0]
		var station: Vector2 = cage.start if level.player.position.y < 0 else cage.finish
		var aboard: bool = absf(level.player.position.x-cage.position.x) < cage.width/2+8 and absf(level.player.position.y-cage.position.y) < 12 and level.player.is_on_floor()
		if aboard or cage.position.distance_to(station) > 6:
			cage.direction = (1 if station == cage.start else -1) if aboard else (1 if station == cage.finish else -1)
			cage.enabled = true
			level.audio.play_at("lift_stop",cage.position)
	elif id == "prison_release":
		open_gate("trapdoor")
	elif id == "sluice_control":
		waters[0].target_y = 1720 if waters[0].target_y < 1500 else 1320
		waters[0].current = -45 if waters[0].target_y > 1500 else 38
		waters[0].water_material.set_shader_parameter("current",waters[0].current)
		open_gate("sluice")
		level.audio.play("water_gate")
		level.hud.notify_player("Cistern draining: the submerged gallery becomes a lower walkway." if waters[0].target_y > 1500 else "Cistern filling: swim or use the service ladder to climb out.")
	elif id == "quarter_ritual":
		if level.seals < 3:
			level.hud.notify_player("The ritual needs the belfry, cistern and garden seals. All three branches are marked on the map.")
			return
		ritual_ready = true
		level.profile.boss_objective = "DEFEAT THE GRAVEKEEPER"
		open_gate("chapel")
		level.audio.play("secret")
		level.effects.play("seal",Vector2(2920,570))
		level.hud.notify_player("The chapel ward falls. The tram below the prison is ready for the return journey.")
	elif id == "quarter_tram":
		if not level.combat.warden_cleared and (not ritual_ready or not opened.has("sluice")):
			level.hud.notify_player("Restore the quarter ritual and open the pump floodgate before running the tram.")
			return
		# The tram runs above the drained channel. Calling it also opens its
		# drain so refilling the cistern cannot strand the returning passenger.
		drain_for_tram()
		var station: Vector2 = tram.start if level.player.position.distance_to(tram.start) < level.player.position.distance_to(tram.finish) else tram.finish
		var aboard: bool = absf(level.player.position.x-tram.position.x) < tram.width/2+8 and absf(level.player.position.y-tram.position.y) < 12 and level.player.is_on_floor()
		if aboard:
			tram.direction = 1 if station == tram.start else -1
			tram.enabled = true
			level.audio.play("lift_stop")
		elif tram.position.distance_to(station) > 6:
			tram.direction = 1 if station == tram.finish else -1
			tram.enabled = true
			level.hud.notify_player("Tram called. Wait at the station, jump aboard, then use the control to depart.")
		else:
			level.hud.notify_player("Tram docked. Jump onto its wooden platform, then use the control to depart.")

func jailer_fallen(_at: Vector2) -> void:
	opened["jailer"] = true
	open_gate("jail_left")
	open_gate("jail_right")
	level.audio.play("secret")
	level.hud.notify_player("The jailer falls. His moon hook is in the cache beside the cell.")
