extends Node

var controller: Node:
	get:
		return get_node("/root/Controller")

const Enemy = preload("res://scripts/haunt.gd")
const Bolt = preload("res://scripts/cursed_bolt.gd")
const Urn = preload("res://scripts/breakable_urn.gd")
const Vial = preload("res://scripts/spirit_vial.gd")
var level: Node2D
var guardian: Node2D
var warden_cleared: bool = false
var kills: int = 0
var combo_hits: int = 0
var combo_timeout: float = 0.0
var warden_enraged: bool = false
var relics: int = 0
var swing_id: int = -1
var swing_hits: Dictionary = {}

func setup(owner_level: Node2D) -> void:
	level = owner_level
	level.player.evaded.connect(clean_dodge)
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		connect_enemy(enemy, false)
	for x: float in level.profile.plants:
		var spitter: Node2D = Enemy.new()
		spitter.species = "plant"
		spitter.position = Vector2(x, 600)
		level.add_child(spitter)
		connect_enemy(spitter, true)
	guardian = Enemy.new()
	guardian.species = "warden"
	guardian.position = level.profile.boss_at
	level.add_child(guardian)
	guardian.health = level.profile.boss_health
	guardian.max_health = level.profile.boss_health
	guardian.damage_trail = guardian.health
	if level.chapter == 2:
		guardian.base_color = Color("d2dfbb")
	elif level.chapter >= 3:
		guardian.base_color = Color("d8c29d") if level.chapter == 3 else Color("b0cce5")
	if level.chapter >= 5:
		guardian.base_color = level.profile.seal_color.lerp(Color.WHITE, 0.65)
	connect_enemy(guardian, true)
	guardian.defeated.connect(warden_fallen)
	for at: Vector2 in level.profile.mimics:
		var mimic: Node2D = Enemy.new()
		mimic.species = "mimic"
		mimic.position = at
		level.add_child(mimic)
		connect_enemy(mimic, true)
		mimic.defeated.connect(mimic_fallen)
	for x: float in level.profile.urns:
		var urn: Node2D = Urn.new()
		urn.chapter = level.chapter
		urn.position = Vector2(x, 600)
		level.add_child(urn)
		urn.shattered.connect(urn_shattered)

func connect_enemy(enemy: Node2D, add_defeat_effect: bool) -> void:
	preload("res://scripts/enemy_footing.gd").configure(enemy,level)
	enemy.attack_permission = may_attack.bind(enemy)
	if add_defeat_effect:
		enemy.defeated.connect(level.enemy_defeated)
	enemy.defeated.connect(func(_at: Vector2) -> void: kills += 1)
	enemy.hit_received.connect(hit_feedback.bind(enemy))
	enemy.shot_requested.connect(spawn_bolt.bind(enemy))
	enemy.warned.connect(enemy_warning.bind(enemy))
	enemy.noticed.connect(enemy_noticed)
	enemy.motion_effect.connect(enemy_motion)
	enemy.attack_started.connect(enemy_attack.bind(enemy))
	enemy.attack_connected.connect(enemy_contact)

func may_attack(requester: Node2D) -> bool:
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if enemy != requester and enemy.state in [1, 2] and absf(enemy.position.x - requester.position.x) < 600 and absf(enemy.position.y-requester.position.y) < 210:
			return false
	return true

func enemy_warning(species: String, enemy: Node2D) -> void:
	level.audio.play_at({"guard":"armor_ready","rat":"beast_ready","mimic":"beast_ready","warden":"warden_warning","eye":"eye_warning","witch":"eye_warning","mushroom":"mushroom_warning"}.get(species,"hiss"),enemy.position)
	if species in ["plant","eye","witch"]:
		level.effects.follow_attack("eye_charge",enemy,Vector2(enemy.attack_direction*25,-35 if enemy.flying else -49),1.2,Color("c7a0ff") if species == "witch" else Color("b5ed9b"),true)

func enemy_attack(species: String, enemy: Node2D) -> void:
	var facing: float = enemy.attack_direction
	if species in ["guard","warden"]:
		level.effects.follow_attack("enemy_swing",enemy,Vector2(facing*25,-85 if species == "guard" else -115),1.3 if species == "guard" else 1.7,Color("eedab1"))
		level.audio.play_at("guard_swing" if species == "guard" else "warden_swing",enemy.position)
	elif species in ["bat","mosquito"]:
		level.effects.follow_attack("enemy_dive",enemy,Vector2(facing*18,-25),1.35,Color("c0d5e0"))
		level.audio.play_at("bat_dive" if species == "bat" else "mosquito_dive",enemy.position)
	else:
		level.effects.follow_attack("mushroom_roll" if species == "mushroom" else "dash",enemy,Vector2(-facing*18,-15),0.85,Color("b7a391"))
		level.audio.play_at({"rat":"rat_lunge","mimic":"mimic_snap","mushroom":"mushroom_rush"}.get(species,"beast_ready"),enemy.position)

func enemy_contact(at: Vector2, species: String) -> void:
	var effect: AnimatedSprite2D = level.effects.play("heavy_hit" if species == "warden" else "hit",at,1,0.65)
	if effect != null:
		effect.set_meta("enemy_contact",species)
	level.audio.play_at("enemy_contact",at)

func enemy_noticed(at: Vector2) -> void:
	level.effects.play("notice",at)
	level.audio.play_at("enemy_notice",at)

func enemy_motion(kind: String, at: Vector2, facing: float) -> void:
	level.effects.play(kind,at,facing)
	if kind in ["enemy_swing","enemy_dive"]:
		level.audio.play_at("guard_swing" if kind == "enemy_swing" else "mosquito_dive",at)

func clean_dodge(at: Vector2) -> void:
	level.effects.play("clean_dodge", at)
	level.effects.floating_text("CLEAN DODGE", at + Vector2(0, -35), Color("b8e8d1"))
	controller.rumble("evade")

func spawn_bolt(at: Vector2, direction: Vector2, is_wave: bool, shooter: Node2D) -> void:
	if level.completed or shooter.dead:
		return
	var bolt: Node2D = Bolt.new()
	bolt.position = at
	bolt.eye_orb = shooter.species == "eye"
	bolt.witch_orb = shooter.species == "witch"
	bolt.velocity = direction * (210.0 if bolt.witch_orb else (230.0 if bolt.eye_orb else (270.0 if is_wave else 260.0)))
	bolt.shooter = shooter
	bolt.wave = is_wave
	bolt.ember = level.chapter >= 2
	bolt.lifetime = 1.25 if is_wave else 3.0
	level.add_child(bolt)
	bolt.collided.connect(projectile_collided)
	if not is_wave:
		level.effects.follow_attack("cast_release",shooter,at-shooter.position,1.1,Color("d2a0ff") if bolt.witch_orb or bolt.eye_orb else Color("9eda79"))
	else:
		level.effects.play("land",at,1,1)
	if bolt.eye_orb or bolt.witch_orb:
		level.audio.play_at("witch_fire" if bolt.witch_orb else "eye_fire",at)
	elif not is_wave:
		level.audio.play_at("spit",at)
	if is_wave:
		level.effects.impact(3.0)

func projectile_collided(at: Vector2, kind: String) -> void:
	if kind == "terrain":
		var splash: AnimatedSprite2D = level.effects.play("cast_release",at,1,0.8)
		if splash != null:
			splash.modulate = Color("b9d4b1")
		level.audio.play_at("spell_impact",at)
	elif kind == "player":
		level.effects.play("heavy_hit",at,1,0.55)
		level.audio.play_at("spell_impact",at)
	elif kind == "returned":
		controller.rumble("hit")
		level.effects.floating_text("RETURN HIT",at+Vector2(0,-22),Color("b6eeff"))

func resolve_attack(origin: Vector2, facing: float) -> void:
	var finisher: bool = level.player.combo_step == 2
	var plunge: bool = level.player.attack_mode == "plunge"
	var damage: int = 2 if finisher or plunge else 1
	if finisher:
		damage += level.player.sword_bonus
	var power: float = 310.0 if damage == 2 else 165.0
	var connected: bool = false
	var source: Vector2 = origin-Vector2(facing*50,0) if not plunge else origin+Vector2(0,-55)
	if swing_id != level.player.swing_id:
		swing_id = level.player.swing_id
		swing_hits.clear()
	var blade: Rect2 = preload("res://scripts/hero_motion.gd").BLADES[level.player.attack_clip()]
	if facing < 0 and not plunge:
		blade.position.x = -blade.end.x
	var shape := Rect2(source+Vector2(0,32 if plunge else 35)+blade.position,blade.size)
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if swing_hits.has(enemy.get_instance_id()) or not shape.intersects(enemy.hurt_rect()):
			continue
		var contact: Vector2 = shape.intersection(enemy.hurt_rect()).get_center()
		if clear_strike(source,contact) and enemy.strike(origin,0.0 if plunge else facing,damage,power,true,contact):
			swing_hits[enemy.get_instance_id()] = true
			connected = true
	for bolt: Node2D in get_tree().get_nodes_in_group("enemy_projectiles"):
		if clear_strike(source,bolt.position) and bolt.deflect(origin,0.0 if plunge else facing):
			level.effects.play("reflect", bolt.position)
			level.effects.floating_text("REFLECT", bolt.position, Color("b6eeff"))
			level.audio.play("reflect")
			connected = true
	for urn: Node2D in get_tree().get_nodes_in_group("breakables"):
		if clear_strike(source,urn.position+Vector2(0,-30)) and urn.strike(origin, 0.0 if plunge else facing):
			connected = true
	if connected:
		controller.rumble("heavy_hit" if damage > 1 else "hit")
		level.player.hit_pause = 0.045 if damage == 1 else 0.065
		if plunge:
			level.player.rebound()

func clear_strike(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from,to,1)
	query.hit_from_inside = true
	return level.get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func hit_feedback(at: Vector2, damage: int, enemy: Node2D) -> void:
	level.effects.play("heavy_hit" if damage > 1 else "hit", at,1,0.65 if damage > 1 else 0.75)
	level.effects.impact(5.0 if damage > 1 else 2.5)
	level.effects.floating_text(str(damage), at + Vector2(0, -30), Color("ffe1a4") if damage > 1 else Color("e4d9f0"))
	# An armored strike has its own contact sound; layering an ordinary flesh
	# impact beneath it made protected hits sound indistinguishable from clean ones.
	if not enemy.last_hit_armored:
		level.audio.play_at("heavy_hit" if damage > 1 else "hit",at)
	if level.district != null and not enemy.last_hit_armored:
		level.audio.play_at("flesh_layer",at)
	if enemy.last_hit_armored:
		level.effects.play("armor", at)
		level.audio.play_at("armor",at)
		level.effects.floating_text("ARMOR", enemy.position + Vector2(0, -155), Color("d8bf95"))
	elif enemy.last_hit_broke_guard:
		level.effects.play("guard_break", enemy.position + Vector2(0, -100))
		level.audio.play_at("guard_break",at)
		level.effects.floating_text("GUARD BREAK", enemy.position + Vector2(0, -175), Color("b8e8d1"))
	enemy.hit_pause = 0.070 if damage > 1 else 0.045
	if enemy.species == "warden" and enemy.health * 2 <= enemy.max_health and enemy.health > 0 and not warden_enraged:
		warden_enraged = true
		level.effects.floating_text("ENRAGED", enemy.position + Vector2(0, -215), Color("ffd39a"))
		level.audio.play("warden_warning")
	combo_hits += 1
	combo_timeout = 2.0

func urn_shattered(at: Vector2) -> void:
	level.effects.burst(at, Color("c2a58d"))
	level.audio.play("break")
	var vial: Node2D = Vial.new()
	vial.position = at
	level.add_child(vial)
	vial.collected.connect(func(pos: Vector2) -> void:
		level.effects.play("air_jump", pos)
		level.effects.floating_text("+1 VITALITY", pos, Color("a6f0cb"))
		level.audio.play("seal"))

func mimic_fallen(at: Vector2) -> void:
	relics += 1
	level.effects.floating_text("LOST RELIC %d / 2" % relics, at + Vector2(0, -50), Color("f5d292"))
	level.effects.play("seal", at)
	level.hud.notify_player("A lost relic recovered. The mimic left a healing heart.")
	urn_shattered(at)

func warden_fallen(at: Vector2) -> void:
	controller.rumble("success")
	warden_cleared = true
	clear_projectiles()
	level.effects.play("seal", at)
	level.effects.floating_text("CURSE BROKEN", at + Vector2(0, -80), Color("e9c7ff"))
	level.hud.notify_player(level.profile.boss_name.capitalize() + " falls. " + level.profile.key_objective.capitalize() + ".")
	level.audio.play("seal")

func reset_after_fall() -> void:
	clear_projectiles()
	combo_hits = 0
	combo_timeout = 0.0
	if not warden_cleared:
		warden_enraged = false
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		enemy.reset_encounter()

func clear_projectiles() -> void:
	for bolt: Node in get_tree().get_nodes_in_group("enemy_projectiles"):
		bolt.spent = true
		bolt.queue_free()

func _physics_process(delta: float) -> void:
	if level == null:
		return
	combo_timeout = maxf(0.0, combo_timeout - delta)
	if combo_timeout <= 0.0:
		combo_hits = 0
	level.hud.combo_hits = combo_hits
	level.hud.kills = kills
	level.hud.relics = relics
	level.hud.warden_alive = not warden_cleared
	var active: bool = is_instance_valid(guardian) and not guardian.dead and absf(level.player.position.x - guardian.home.x) < 620
	level.hud.boss_visible = active and not level.completed
	if active:
		level.hud.boss_health = guardian.health
		level.hud.boss_max_health = guardian.max_health
		level.hud.boss_damage_trail = maxf(guardian.health,guardian.damage_trail)
		level.hud.boss_enraged = guardian.health * 2 <= guardian.max_health
		level.hud.boss_staggered = guardian.guard_broken and guardian.state == 3
