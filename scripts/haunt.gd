extends Node2D

signal defeated(at: Vector2)
signal shot_requested(at: Vector2, direction: Vector2, is_wave: bool)
signal hit_received(at: Vector2, damage: int)
signal warned(kind: String)
signal noticed(at: Vector2)
signal motion_effect(kind: String, at: Vector2, facing: float)
signal attack_started(kind: String)
signal attack_connected(at: Vector2, kind: String)
const Assets = preload("res://scripts/level_assets.gd")
const Animator = preload("res://scripts/enemy_animation.gd")
const Footing = preload("res://scripts/enemy_footing.gd")
# Orc attack row: cells 0/1 anticipate, cells 2/3 sweep, cells 4/5 recover.
const BLADE_START: float = 0.38*2.0/6.0
const BLADE_END: float = 0.38*4.0/6.0
var home: Vector2
var patrol: float = 95.0
var flying: bool = false
var health: int = 2
var phase: float = 0.0
var hit_timer: float = 0.0
var visual: Sprite2D
var dead: bool = false
enum State { PATROL, WINDUP, LUNGE, RECOVER, DYING }
var state: State = State.PATROL
var state_time: float = 0.0
var attack_direction: float = 1.0
var target: Vector2
var knocked: float = 0.0
var alert_cooldown: float = 1.2
var species: String = "pumpkin"
var max_health: int = 2
var hit_pause: float = 0.0
var volley_fired: bool = false
var recent_hit: float = 0.0
var body_scale: float = 3.0
var awakened: bool = false
var awareness: float = 0.0
var sight_time: float = 0.0
var sight_memory: float = 0.0
var last_seen := Vector2.ZERO
var sees_player: bool = false
var notice_cooldown: float = 0.0
var attack_permission: Callable
var base_color: Color = Color.WHITE
var last_hit_armored: bool = false
var last_hit_broke_guard: bool = false
var guard_broken: bool = false
var committed_windup: float = 0.48
var damage_trail: float = 2.0
var ui_top: float = -85.0
var travel_limits := Vector2(-INF,INF)
var support_limits := Vector2(-INF,INF)
var attack_fx_fired: bool = false

func _ready() -> void:
	home = position
	phase = home.x * 0.01
	if flying and species == "pumpkin":
		species = "bat"
	if species == "plant":
		health = 3
		patrol = 0
	elif species == "warden":
		health = 8
		body_scale = 4.2
		patrol = 155
	elif species == "mimic":
		health = 4
		patrol = 0
	elif species == "rat":
		health = 2
		patrol = 60
		body_scale = 2.8
	elif species == "mushroom":
		health = 2
		patrol = 75
		body_scale = 2.8
	elif species == "eye":
		health = 2
		flying = true
		body_scale = 2.3
	elif species == "witch":
		health = 3
		flying = true
		body_scale = 2.2
	elif species == "mosquito":
		health = 1
		flying = true
		body_scale = 2.8
	elif species == "guard":
		health = 3
		patrol = 70
		body_scale = 3.1
	max_health = health
	travel_limits = Vector2(home.x-patrol-70,home.x+patrol+70)
	damage_trail = health
	add_to_group("enemies")
	z_index = 4
	var path: String = "res://Enemies/GandalfHardcore Pixel Art Enemies/"
	var sheet: String = "Bat sheet.png" if flying else ("Plant sheet.png" if species == "plant" else ("Orc sheet.png" if species == "warden" else ("Mimic sheet.png" if species == "mimic" else "Pumpkin.png")))
	if species == "rat":
		sheet = "Rat sheet.png"
	elif species in ["mushroom", "eye"]:
		sheet = "Mushroom sheet.png" if species == "mushroom" else "Flying Eye sheet.png"
	elif species == "guard":
		sheet = "Orc sheet.png"
	elif species in ["witch","mosquito"]:
		sheet = "Flying Witch sheet.png" if species == "witch" else "Mosquito sheet.png"
	visual = Assets.sprite(self, path + sheet, Vector2.ZERO, body_scale)
	visual.region_enabled = true
	visual.region_rect = Rect2(0, 0, 64, 64)
	visual.position.y = -35.0 if flying else -32.0 * body_scale
	Animator.configure_ui(self)
	var flash := ShaderMaterial.new()
	flash.shader = preload("res://scripts/enemy_impact.gdshader")
	visual.material = flash
	committed_windup = windup_duration()

func windup_duration() -> float:
	if species == "warden":
		return 0.70 if health * 2 > max_health else 0.55
	return {"plant": 0.68, "guard": 0.72, "mimic": 0.75, "rat": 0.60, "mushroom": 0.68, "eye": 0.82, "witch": 0.95, "mosquito": 0.72}.get(species, 0.48)

func recovery_duration() -> float:
	return 1.15 if guard_broken else (1.6 if species == "witch" else (1.35 if species in ["plant","eye"] else (1.05 if species == "mosquito" else 0.85)))

func can_see_player(player: Node2D) -> bool:
	var direction: float = 1.0 if player.position.x >= position.x else -1.0
	var eyes: Vector2 = global_position+Vector2(0,-35 if flying else -49)
	var mouth: Vector2 = eyes+Vector2(direction*25,0)
	var clearance := PhysicsRayQueryParameters2D.create(eyes,mouth,1)
	clearance.hit_from_inside = true
	if not get_world_2d().direct_space_state.intersect_ray(clearance).is_empty():
		return false
	var query := PhysicsRayQueryParameters2D.create(mouth, player.global_position + Vector2(0, -32), 1)
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func detection_range() -> float:
	return {"plant":530.0,"warden":400.0,"mimic":155.0,"eye":480.0,"witch":480.0}.get(species,250.0)

func perceive(player: Node2D, delta: float) -> void:
	var vertical: float = 350.0 if flying else (65.0 if species == "mimic" else 230.0)
	var in_range: bool = position.distance_to(player.position) < detection_range()+120 and absf(player.position.y-position.y) < vertical
	sees_player = in_range and can_see_player(player)
	notice_cooldown = maxf(0,notice_cooldown-delta)
	var previous: float = awareness
	if sees_player:
		sight_time = minf(0.3,sight_time+delta)
		sight_memory = 0.9
		last_seen = player.position
		awareness = move_toward(awareness,1.0,delta*6)
	else:
		sight_time = 0
		sight_memory = maxf(0,sight_memory-delta)
		awareness = move_toward(awareness,0,delta*(0.5 if sight_memory > 0 else 2.5))
	if previous < 0.25 and awareness >= 0.25 and notice_cooldown <= 0 and state == State.PATROL and species != "mimic":
		notice_cooldown = 2.5
		noticed.emit(position+Vector2(0,ui_top-18))

func _physics_process(delta: float) -> void:
	if dead:
		state_time += delta
		Animator.update(self)
		if state_time > 0.65:
			queue_free()
		return
	if hit_pause > 0:
		hit_pause = maxf(0.0, hit_pause - delta)
		return
	phase += delta
	hit_timer = maxf(0.0, hit_timer - delta)
	recent_hit = maxf(0.0, recent_hit - delta)
	if hit_timer <= 0.12:
		damage_trail = move_toward(damage_trail, health, delta * max_health * 2.0)
	alert_cooldown = maxf(0.0, alert_cooldown - delta)
	state_time += delta
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or player.locked:
		return
	perceive(player,delta)
	var before: Vector2 = position
	match state:
		State.PATROL:
			position.x = move_toward(position.x, home.x + sin(phase * 0.9) * patrol, delta * 70)
			position.y = home.y + (sin(phase * 2.5) * 30.0 if flying else 0.0)
			var detection: float = detection_range()
			var vertical_range: float = 230.0 if species == "plant" else (65.0 if species == "mimic" else 90.0)
			var permitted: bool = not attack_permission.is_valid() or attack_permission.call()
			var acquired: bool = sight_time >= 0.12 or recent_hit > 0 or position.distance_to(player.position) < 96
			if permitted and acquired and sees_player and alert_cooldown <= 0.0 and position.distance_to(player.position) < detection and (flying or absf(player.position.y - position.y) < vertical_range):
				state = State.WINDUP
				state_time = 0.0
				attack_direction = 1.0 if player.position.x >= position.x else -1.0
				target = player.position
				committed_windup = windup_duration()
				volley_fired = false
				attack_fx_fired = false
				awakened = true
				Animator.face(self,attack_direction)
				warned.emit(species)
		State.WINDUP:
			if state_time >= committed_windup:
				state = State.LUNGE
				state_time = 0.0
				if species not in ["warden","guard","plant","eye","witch"]:
					attack_started.emit(species)
					attack_fx_fired = true
		State.LUNGE:
			# Blade trails/swish begin with the damaging frames, after anticipation.
			if species in ["warden","guard"] and state_time >= BLADE_START and not attack_fx_fired:
				attack_fx_fired = true
				attack_started.emit(species)
			if species in ["plant", "eye", "witch"]:
				if not volley_fired and state_time >= (0.14 if species == "witch" else 0.12):
					volley_fired = true
					var mouth: Vector2 = position + Vector2(attack_direction * 25, -35 if flying else -49)
					shot_requested.emit(mouth, (target + Vector2(0, -32) - mouth).normalized(), false)
			elif flying:
				position = position.move_toward(target, delta * (360 if species == "mosquito" else 310))
			else:
				var speed: float = 180.0 if species == "mimic" else (230.0 if species == "warden" else 300.0)
				if species == "rat":
					speed = 460.0
				elif species == "mushroom":
					speed = 340.0
				elif species == "guard":
					speed = 230.0
				position.x = Footing.limit(self,position.x+attack_direction*speed*delta)
				if species == "warden" and not volley_fired and state_time > 0.18:
					volley_fired = true
					shot_requested.emit(position + Vector2(0, -20), Vector2(attack_direction, 0), true)
					if health * 2 <= max_health:
						shot_requested.emit(position + Vector2(0, -20), Vector2(-attack_direction, 0), true)
			if state_time >= 0.38:
				state = State.RECOVER
				state_time = 0.0
		State.RECOVER:
			position = position.move_toward(home, delta * 100)
			if state_time >= recovery_duration():
				state = State.PATROL
				guard_broken = false
				alert_cooldown = 1.5
	position.x += knocked * delta
	if not flying:
		position.x = Footing.limit(self,position.x)
	knocked = move_toward(knocked, 0.0, delta * 800)
	Animator.update(self, (position.x - before.x) / delta)
	if state == State.PATROL and awareness > 0.35 and sight_memory > 0:
		Animator.face(self,last_seen.x-position.x)
	var open_guard: bool = species == "warden" and guard_broken and state == State.RECOVER
	# An anticipating or recovering enemy cannot deal an untelegraphed body hit.
	if species not in ["guard","warden"] and state == State.LUNGE and not open_guard and hit_timer <= 0.0 and position.distance_to(player.position) < (52.0 if flying else 45.0) and can_see_player(player):
		contact_player(player)
	if species in ["warden", "guard"] and state == State.LUNGE and state_time >= BLADE_START and state_time < BLADE_END and hit_timer <= 0:
		var offset: Vector2 = player.position - position
		if offset.x * attack_direction >= -12 and offset.x * attack_direction < (110 if species == "warden" else 80) and absf(offset.y) < 75 and can_see_player(player):
			contact_player(player)
	queue_redraw()

func contact_player(player: Node2D) -> void:
	var before: int = player.health
	player.take_damage(position)
	if player.health < before:
		attack_connected.emit(player.position-Vector2(0,40),species)

func hurt_rect() -> Rect2:
	var height: float = maxf(32,-ui_top-18)
	var width: float = 64 if species == "warden" else (48 if not flying else 44)
	return Rect2(position+Vector2(-width/2,-height),Vector2(width,height if not flying else height+10))

func strike(origin: Vector2, facing: float = 0.0, damage: int = 1, power: float = 165.0, checked: bool = false, contact: Vector2 = Vector2.INF) -> bool:
	var attacker_x: float = origin.x - facing * 50
	if dead or hit_timer > 0.0 or (not checked and (position + Vector2(0, -30)).distance_to(origin) > 105.0):
		return false
	if not checked and facing != 0.0 and (position.x - attacker_x) * facing < -16.0:
		return false
	damage_trail = maxf(damage_trail, health)
	health = maxi(0, health - damage)
	last_hit_armored = species == "warden" and state in [State.WINDUP, State.LUNGE] and damage < 2
	last_hit_broke_guard = species == "warden" and state in [State.WINDUP, State.LUNGE] and damage >= 2
	if last_hit_broke_guard:
		guard_broken = true
	awakened = true
	awareness = 1.0
	last_seen = Vector2(attacker_x,origin.y+30)
	sight_memory = 0.9
	hit_timer = 0.28
	recent_hit = 1.8
	knocked = (signf(position.x - attacker_x) if position.x != attacker_x else 1.0) * power * (0.4 if species == "warden" else 1.0)
	if species != "warden" or state not in [State.WINDUP, State.LUNGE] or damage >= 2:
		var preserve_recovery: bool = species == "warden" and state == State.RECOVER
		state = State.RECOVER
		if not preserve_recovery:
			state_time = 0.0
	hit_received.emit(contact if contact.is_finite() else position+Vector2(0,-35),damage)
	if health <= 0:
		dead = true
		remove_from_group("enemies")
		state = State.DYING
		state_time = 0.0
		defeated.emit(position + Vector2(0, -30))
	Animator.update(self)
	queue_redraw()
	return true

func reset_encounter() -> void:
	if dead:
		return
	position = home
	health = max_health
	damage_trail = health
	state = State.PATROL
	state_time = 0.0
	hit_timer = 0.0
	hit_pause = 0.0
	recent_hit = 0.0
	knocked = 0.0
	alert_cooldown = 1.2
	awakened = false
	last_hit_armored = false
	last_hit_broke_guard = false
	guard_broken = false
	awareness = 0
	sight_time = 0
	sight_memory = 0
	sees_player = false
	notice_cooldown = 0
	last_seen = home
	Animator.update(self)
	queue_redraw()

func _draw() -> void:
	if dead:
		return
	if not flying:
		draw_set_transform(Vector2(0, -2), 0.0, Vector2(1, 0.2))
		draw_circle(Vector2.ZERO, 28, Color("10132570"))
		draw_set_transform(Vector2.ZERO)
	if species == "mimic" and not awakened and awareness > 0.3:
		for x: float in [-8.0, 8.0]:
			draw_rect(Rect2(x, -41, 3, 2), Color("c5a4e390"))
	if state == State.PATROL and awareness > 0.25 and species != "mimic":
		var at := Vector2(0,ui_top-18)
		draw_circle(at,10,Color("192333c0"))
		draw_arc(at,9,-PI/2,-PI/2+TAU*awareness,16,Color(0.72,0.85,0.85,awareness*0.65),1)
		draw_string(ThemeDB.fallback_font,at+Vector2(-3,4),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b8d9d8"))
	if state == State.WINDUP:
		var warning_y: float = -219.0 if species == "warden" else (-68.0 if species == "rat" else (-92.0 if not flying else -70.0))
		if species in ["eye","witch"]:
			warning_y = -105
		elif species == "guard":
			warning_y = -165
		warning_y = minf(warning_y, ui_top - 23)
		draw_circle(Vector2(0, warning_y), 13, Color("392c31"))
		draw_string(ThemeDB.fallback_font, Vector2(-3, warning_y + 6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("ffd597"))
		draw_arc(Vector2(0, warning_y), 17, -PI / 2, -PI / 2 + TAU * clampf(state_time / committed_windup, 0, 1), 24, Color("ffd597a0"), 2)
		if not flying:
			var travel: float = (460.0 if species == "rat" else (340.0 if species == "mushroom" else (230.0 if species in ["warden", "guard"] else (180.0 if species == "mimic" else 300.0)))) * 0.38
			var end_x: float = Footing.limit(self,position.x+attack_direction*travel)
			var reach: float = absf(end_x - position.x) + (110.0 if species == "warden" else (80.0 if species == "guard" else 25.0))
			if species == "plant":
				var muzzle: Vector2 = Vector2(attack_direction * 25, -49)
				var aim: Vector2 = (target + Vector2(0, -32) - position - muzzle).normalized()
				for i: int in range(1, 5):
					draw_circle(muzzle + aim * i * 22, 2, Color("e9ac7ca0"))
			else:
				draw_line(Vector2(attack_direction * 20, -3), Vector2(attack_direction * reach, -3), Color("e9ac7c80"), 2)
				for distance: float in [reach * 0.35, reach * 0.65, reach]:
					var point: Vector2 = Vector2(attack_direction * distance, -4)
					draw_line(point + Vector2(-attack_direction * 7, -5), point, Color("ffd597a0"), 2)
					draw_line(point + Vector2(-attack_direction * 7, 5), point, Color("ffd597a0"), 2)
		elif species in ["eye","witch"]:
			var muzzle := Vector2(attack_direction * 25, -35)
			var aim: Vector2 = (target + Vector2(0, -32) - position - muzzle).normalized()
			for i: int in range(1, 5):
				draw_circle(muzzle + aim * i * 25, 2, Color("dfb7fca0"))
		elif target.distance_to(position) < 350:
			draw_arc(target - position, 20, 0, TAU, 16, Color("e9ac7c60"), 1)
	elif state == State.RECOVER and hit_timer <= 0 and awakened:
		draw_arc(Vector2(0, -40), 32, -0.4, 0.4, 6, Color("90dfc880"), 2)
	if recent_hit > 0.0 and species != "warden":
		var bar_y: float = ui_top
		var opacity: float = smoothstep(0.0, 0.35, recent_hit)
		draw_rect(Rect2(-24, bar_y - 1, 48, 6), Color(0.18, 0.12, 0.19, opacity))
		draw_rect(Rect2(-23, bar_y, 46.0 * damage_trail / max_health, 4), Color(0.95, 0.78, 0.42, opacity * 0.75))
		draw_rect(Rect2(-23, bar_y, 46.0 * health / max_health, 4), Color(1.0, 0.77, 0.63, opacity))
	if species == "warden" and state == State.LUNGE:
		var start: float = -1.25 if attack_direction > 0 else 1.9
		draw_arc(Vector2(attack_direction * 24, -55), 84, start, start + 2.5, 24, Color("f1c2aa"), 5)
