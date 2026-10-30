extends Node2D

const Assets = preload("res://scripts/level_assets.gd")
const Profile = preload("res://scripts/chapter_profile.gd")
const Campaign = preload("res://scripts/campaign_state.gd")
const Player = preload("res://scripts/seeker.gd")
const Hud = preload("res://scripts/level_hud.gd")
const NightSky = preload("res://scripts/night_sky.gd")
const Audio = preload("res://scripts/level_audio.gd")
const Atmosphere = preload("res://scripts/town_atmosphere.gd")
const Effects = preload("res://scripts/level_effects.gd")
const Lighting = preload("res://scripts/world_lighting.gd")
const Combat = preload("res://scripts/combat_director.gd")
@export_range(1, 12) var chapter: int = 1
var profile: RefCounted
var player: CharacterBody2D
var camera: Camera2D
var hud: Control
var sky: Node2D
var audio: Node
var atmosphere: Node2D
var effects: Node2D
var lighting: Node2D
var combat: Node
var world_details: Node2D
var seals: int = 0
var coins: int = 0
var deaths: int = 0
var elapsed: float = 0.0
var key_found: bool = false
var completed: bool = false
var checkpoint: Vector2 = Vector2(180, 590)
var checkpoint_index: int = -1
var items: Array[Dictionary] = []
var checkpoints: Array[Sprite2D] = []
var hazards: Array[Rect2] = []
var chest: Sprite2D
var portal: Sprite2D
var clock: float = 0.0
var respawning: bool = false
var stage_width: float = 6400
var extended: bool = false
var extension: Node2D
var weather: Node2D
var district: Node2D
var district_mode: bool = false

func _ready() -> void:
	profile = Profile.new(chapter)
	district_mode = chapter == 1 and "--original-layout" not in OS.get_cmdline_user_args() and "--classic-expanded" not in OS.get_cmdline_user_args()
	if district_mode:
		preload("res://scripts/district_layout.gd").configure(profile)
	install_inputs()
	RenderingServer.set_default_clear_color(Color("111326"))
	var backdrop: CanvasLayer = CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	sky = NightSky.new()
	backdrop.add_child(sky)
	lighting = Lighting.new()
	add_child(lighting)
	effects = Effects.new()
	add_child(effects)
	profile.builder.build(self)
	atmosphere = Atmosphere.new()
	add_child(atmosphere)
	build_objectives()
	player = Player.new()
	player.position = checkpoint
	add_child(player)
	lighting.add_glow(player.position, Color("91a0b566"), 80, player, Vector2(0, -35))
	player.sword_contact.connect(strike)
	player.sword_tail_requested.connect(effects.sword_tail)
	player.fallen.connect(respawn)
	player.hurt.connect(func(_health: int) -> void: effects.impact(5.0); effects.flash = 0.18; burst(player.position + Vector2(0, -35), Color("ed987d")))
	player.effect_requested.connect(effects.play)
	player.dash_trail_requested.connect(func() -> void: effects.ghost(player.animation, player.position))
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_right = 6400
	camera.limit_top = 0
	camera.limit_bottom = 720
	add_child(camera)
	var ui: CanvasLayer = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	hud = Hud.new()
	hud.profile = profile
	hud.region = profile.regions[0]
	hud.last_region = profile.regions[0]
	ui.add_child(hud)
	hud.total_coins = items.size() - 3
	hud.pause_requested.connect(toggle_pause)
	hud.restart_requested.connect(restart)
	hud.continue_requested.connect(func() -> void: Campaign.next(self))
	hud.first_requested.connect(func() -> void: Campaign.first(self))
	audio = Audio.new()
	audio.chapter = chapter
	add_child(audio)
	hud.muted = audio.muted
	player.sound_requested.connect(audio.play)
	combat = Combat.new()
	add_child(combat)
	combat.setup(self)
	world_details = profile.details.new()
	add_child(world_details)
	world_details.setup(self)
	if district_mode:
		preload("res://scripts/district_director.gd").install(self)
		preload("res://scripts/stage_weather.gd").install(self)
	else:
		preload("res://scripts/journey_details.gd").install(self)
		preload("res://scripts/border_details.gd").install(self)
	if not district_mode and "--original-layout" not in OS.get_cmdline_user_args():
		preload("res://scripts/stage_expansion.gd").install(self)
		preload("res://scripts/scenery_composition.gd").install(self)
		preload("res://scripts/stage_weather.gd").install(self)

func install_inputs() -> void:
	preload("res://scripts/level_controls.gd").install(self)

func build_objectives() -> void:
	for pos: Vector2 in profile.seals:
		add_item("seal", pos)
	for rect: Rect2 in profile.builder.LEDGES:
		for dx: float in [40.0, 100.0]:
			add_item("coin", rect.position + Vector2(dx, -43))
	for x: float in profile.ground_coins:
		add_item("coin", Vector2(x, 552))
	for x: float in profile.checkpoints:
		var lantern: Sprite2D = Assets.sprite(self, Assets.PROPS + "spirit_lantern.png", Vector2(x, 551), 3.0, 3)
		checkpoints.append(lantern)
		lighting.add_glow(lantern.position, Color("76d9c8"), 125, lantern)
	chest = Assets.sprite(self, profile.chest_texture, Vector2(5520, 557), 3.2, 3)
	portal = Assets.sprite(self, profile.exit_texture, Vector2(6190, 518), 5.5, 3)
	portal.modulate = Color("655979")
	if chapter >= 5:
		Assets.anchor_base(chest, 600)
		Assets.anchor_base(portal, 600)
	lighting.add_glow(portal.position, profile.seal_color, 170, portal)
	lighting.add_glow(chest.position, Color("aa7cdd"), 115, chest)

func add_item(kind: String, pos: Vector2) -> void:
	var path: String = profile.seal_texture if kind == "seal" else profile.coin_texture
	var visual: Sprite2D = Assets.sprite(self, path, pos, 2.4 if kind == "seal" else 1.2, 4)
	if kind == "seal":
		lighting.add_glow(pos, profile.seal_color, 110, visual)
		var marker: Node2D = preload("res://scripts/seal_marker.gd").new()
		profile.style_marker(marker)
		visual.add_child(marker)
	else:
		visual.modulate = Color("f6dba7")
	items.append({"kind": kind, "position": pos, "visual": visual, "taken": false})

func _physics_process(delta: float) -> void:
	clock += delta
	if not completed:
		elapsed += delta
	preload("res://scripts/level_backdrop.gd").update(self)
	update_items(delta)
	if not completed:
		for rect: Rect2 in hazards:
			if rect.has_point(player.position + Vector2(0, -8)):
				player.take_damage(rect.get_center())
		for gap: Vector2 in profile.gaps:
			if player.position.x > gap.x and player.position.x < gap.y and player.position.y > 668:
				respawn()
		update_checkpoints()
		update_interaction()
	portal.modulate = profile.seal_color if key_found else Color("655979")
	portal.modulate.a = 0.8 + sin(clock * 2.0) * 0.12
	portal.texture = Assets.texture(profile.open_exit_texture if key_found else profile.exit_texture)
	if chapter >= 5:
		Assets.anchor_base(portal, 600)
	hud.health = player.health
	hud.seals = seals
	hud.coins = coins
	hud.key_found = key_found
	hud.progress = player.position.x / stage_width
	hud.checkpoint_index = checkpoint_index
	hud.elapsed = elapsed
	hud.deaths = deaths
	hud.dash_ready = player.dash_cooldown <= 0.0
	hud.dash_charge = 1.0 - player.dash_cooldown / 0.85
	hud.damage_flash = effects.flash
	update_compass()
	hud.region = extension.region() if extended else profile.regions[mini(3,int(player.position.x/1600))]

func update_items(delta: float) -> void:
	for item: Dictionary in items:
		if item["taken"]:
			continue
		var visual: Sprite2D = item["visual"]
		var pos: Vector2 = item["position"]
		var center: Vector2 = player.position + Vector2(0, -34)
		if item["kind"] == "coin" and center.distance_to(visual.position) < 85:
			item["magnetized"] = true
		if item.get("magnetized", false) and center.distance_to(visual.position) < 170:
			visual.position = visual.position.move_toward(center, 540.0 * delta)
		else:
			item["magnetized"] = false
			visual.position = pos + Vector2(0, sin(clock * 2.6 + pos.x) * 7.0)
		if not completed and (player.position + Vector2(0, -34)).distance_to(visual.position) < 47.0:
			item["taken"] = true
			visual.hide()
			if item["kind"] == "seal":
				seals += 1
				effects.play("seal", pos)
				effects.impact(2.0)
				audio.play("seal")
				var next_step: String = "Follow the violet light." if chapter == 1 else "Follow the golden hearth sparks."
				if chapter >= 3:
					next_step = "Follow the remaining %ss." % profile.seal_name.to_lower()
				if seals == 3:
					next_step = profile.chest_prompt if combat.warden_cleared else profile.boss_objective.capitalize() + "."
				hud.notify_player("%s %d / 3 restored. %s" % [profile.seal_name.capitalize(), seals, next_step])
			else:
				coins += 1
				audio.play("coin")
				if coins % 10 == 0 and player.health < 5:
					player.health += 1
					hud.notify_player("Ten %s gathered. One vitality restored." % profile.coin_label.to_lower())
			burst(pos, Color("d4acfa") if item["kind"] == "seal" else Color("e8c984"))

func update_compass() -> void:
	var target: Vector2 = chest.position if not key_found else portal.position
	hud.goal_name = profile.chest_goal if not key_found else profile.exit_goal
	if seals == 3 and not combat.warden_cleared and is_instance_valid(combat.guardian):
		target = combat.guardian.position
		hud.goal_name = profile.boss_goal
	if seals < 3:
		var closest: float = INF
		for item: Dictionary in items:
			if item["kind"] == "seal" and not item["taken"]:
				var distance: float = player.position.distance_to(item["position"])
				if distance < closest:
					closest = distance
					target = item["position"]
					hud.goal_name = profile.seal_name
	var offset: Vector2 = target - player.position
	if district != null and seals == 3 and not district.ritual_ready:
		offset = Vector2(2920,600)-player.position
		hud.goal_name = "QUARTER RITUAL"
	if absf(offset.x) < 300 and absf(offset.y) > 96:
		hud.goal_direction = "↑ ABOVE" if offset.y < 0 else "↓ BELOW"
	else:
		hud.goal_direction = "← BACK" if offset.x < -95 else ("→ AHEAD" if offset.x > 95 else ("↑ ABOVE" if offset.y < -80 else ("↓ BELOW" if offset.y > 80 else "HERE")))

func update_checkpoints() -> void:
	if district != null:
		district.update_checkpoints()
		return
	for i: int in range(checkpoints.size()):
		if i > checkpoint_index and absf(player.position.x - checkpoints[i].position.x) < 56.0 and absf(player.position.y - 600.0) < 36.0 and player.is_on_floor():
			checkpoint_index = i
			checkpoint = Vector2(checkpoints[i].position.x, 590)
			checkpoints[i].modulate = Color("a5ffe8")
			player.health = 5
			audio.play("seal")
			hud.notify_player("Spirit lantern lit. Checkpoint saved; vitality restored.")
			burst(checkpoints[i].position, Color("a5ffe8"))

func update_interaction() -> void:
	hud.prompt = ""
	if player.position.distance_to(chest.position) < 100.0:
		if district != null and not district.ritual_ready:
			hud.prompt = "Return the three seals to the quarter's ritual circle."
			return
		hud.prompt = profile.chest_prompt if seals == 3 else "Three %ss are needed (%d / 3)." % [profile.seal_name.to_lower(), seals]
		if seals == 3 and not combat.warden_cleared:
			hud.prompt = profile.blocked_prompt
		if key_found:
			hud.prompt = profile.restored_prompt
		elif seals == 3 and combat.warden_cleared and Input.is_action_just_pressed("interact"):
			key_found = true
			chest.texture = Assets.texture(profile.open_texture)
			if chapter >= 5 or district != null:
				Assets.anchor_base(chest, 600)
			audio.play("seal")
			burst(chest.position, Color("ffe1a3"))
			hud.notify_player("The way home is open. " + profile.exit_objective.capitalize() + ".")
	if player.position.distance_to(portal.position) < 110.0:
		hud.prompt = profile.exit_prompt if key_found else "Gather three " + profile.seal_name.to_lower() + "s and lift the ward first."
		if key_found and Input.is_action_just_pressed("interact"):
			completed = true
			player.locked = true
			player.velocity = Vector2.ZERO
			hud.complete = true
			Campaign.record(self)
			audio.play("seal")

func strike(origin: Vector2, facing: float) -> void:
	combat.resolve_attack(origin, facing)

func enemy_defeated(at: Vector2) -> void:
	burst(at, Color("c9b3ea"))
	effects.play("enemy_defeat", at)
	audio.play_at("enemy_defeat",at)

func respawn() -> void:
	if respawning or completed:
		return
	respawning = true
	deaths += 1
	player.respawn(checkpoint)
	combat.reset_after_fall()
	camera.position.x = clampf(checkpoint.x,640,stage_width-640)
	if player.traversal != null:
		player.traversal.reset()
	camera.reset_smoothing()
	hud.notify_player("The lantern calls you back. Objectives and coins kept.")
	respawning = false

func toggle_pause() -> void:
	if district != null and district.map_overlay.visible:
		district.map_overlay.close_map()
		return
	if completed:
		if district != null:
			resume_exploration()
		return
	get_tree().paused = not get_tree().paused
	hud.paused = get_tree().paused
	if hud.paused:
		get_node("/root/Controller").quiet_feedback()
		hud.resume_button.grab_focus()

func resume_exploration() -> void:
	if district == null or not completed:
		return
	completed = false
	player.locked = false
	player.attack_buffer = 0
	player.jump_buffer = 0
	player.dash_buffer = 0
	hud.complete = false
	hud.paused = false
	get_tree().paused = false
	var controller: Node = get_node("/root/Controller")
	controller.flush_gameplay()
	controller.suppress_until_release = true
	hud.notify_player("The district is still open. The chapel stair leads back to the tram; use the dawn portal again when you are ready to leave.")

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func burst(at: Vector2, color: Color) -> void:
	effects.burst(at, color)
