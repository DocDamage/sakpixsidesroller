extends RefCounted

var player: CharacterBody2D
var district: Node2D
var climbing: int = -1
var grapple: Vector2 = Vector2.INF
var grapple_time: float = 0
var detach: float = 0
var wall_lock: float = 0
var wall_direction: float = 0
var swimming: bool = false
var water: Node2D
var breath: float = 14
var stroke: float = 0
var sound_step: float = 0
var previous_position: Vector2
var wake_cooldown: float = 0

func _init(body: CharacterBody2D, world: Node2D) -> void:
	player = body
	district = world
	previous_position = player.position

func reset() -> void:
	climbing = -1
	grapple = Vector2.INF
	detach = 0.3
	wall_lock = 0
	swimming = false
	breath = 14
	previous_position = player.position

func vertical() -> float:
	return Input.get_axis("move_up","move_down")

func prepare(delta: float, ready: bool) -> void:
	detach = maxf(0,detach-delta)
	wall_lock = maxf(0,wall_lock-delta)
	stroke = maxf(0,stroke-delta)
	var next_water: Node2D = district.water_at(player.position-Vector2(0,28))
	var next_swim: bool = next_water != null and next_water.bed_at(player.position.x)-next_water.position.y > 85 and player.position.y > next_water.position.y+38
	if next_swim and not swimming:
		next_water.splash(player.position.x,clampf(absf(player.velocity.y)*0.018,3,14))
		district.level.audio.play("water_entry")
	if swimming and not next_swim and is_instance_valid(water):
		water.splash(player.position.x,4)
		district.level.audio.play("water_exit")
	water = next_water
	swimming = next_swim
	if swimming:
		player.jump_buffer = 0
		if ready and Input.is_action_just_pressed("jump"):
			stroke = 0.22
			district.level.audio.play("swim")
		if player.position.y-58 > water.position.y:
			breath = maxf(0,breath-delta)
			if breath == 0:
				player.take_damage(player.position+Vector2(0,40))
		else:
			breath = minf(14,breath+delta*6)
	else:
		breath = minf(14,breath+delta*6)
	if ready and player.jump_buffer > 0 and player.is_on_wall_only():
		wall_direction = player.get_wall_normal().x
		player.velocity = Vector2(wall_direction*390,-670)
		player.facing = wall_direction
		player.jumps = 1
		player.jump_buffer = 0
		wall_lock = 0.20
		district.level.audio.play("wall_jump")
		player.effect_requested.emit("jump",player.position,wall_direction)

func override_motion(delta: float, ready: bool) -> bool:
	if player.hurt_time > 0:
		climbing = -1
		grapple = Vector2.INF
		return false
	var v: float = vertical() if ready else 0
	if ready and detach <= 0 and climbing < 0 and grapple == Vector2.INF and absf(v) > 0.3:
		for i: int in district.climbs.size():
			var climb: Dictionary = district.climbs[i]
			if v < 0 and player.position.y <= climb.top+8 or v > 0 and player.position.y >= climb.bottom-8:
				continue
			if absf(player.position.x-climb.x) < 32 and player.position.y >= climb.top-12 and player.position.y <= climb.bottom+8:
				climbing = i
				player.attack_time = 0
				player.attack_pending = false
				break
	if ready and district.upgrades.has("moon_hook") and climbing < 0 and grapple == Vector2.INF and v < -0.4 and Input.is_action_just_pressed("interact"):
		var candidate: Vector2 = district.find_hook(player.position-Vector2(0,40))
		if candidate != Vector2.INF:
			grapple = candidate
			grapple_time = 0
			player.attack_time = 0
			player.attack_pending = false
			district.level.audio.play("grapple")
	if climbing >= 0:
		var climb: Dictionary = district.climbs[climbing]
		if v >= 0 and player.position.y >= climb.bottom-8:
			climbing = -1
			detach = 0.25
			player.drop_time = 0
			player.set_collision_mask_value(3,true)
			player.velocity.y = 25
			return false
		if ready and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("dash")):
			climbing = -1
			detach = 0.3
			player.velocity = Vector2(player.controller.horizontal_direction()*280,-570)
			player.jumps = 1
			player.jump_buffer = 0
			return false
		player.velocity = Vector2((climb.x-player.position.x)*12,v*190)
		player.drop_time = 0.1
		player.set_collision_mask_value(3,false)
		player.move_and_slide()
		player.animation.play("Climb")
		if absf(v) < 0.2:
			player.animation.pause()
			player.animation.frame = 0
		preload("res://scripts/hero_motion.gd").anchor(player.animation,player.facing)
		sound_step += absf(v)*delta
		if sound_step > 0.36:
			sound_step = 0
			district.level.audio.play("climb")
		if player.position.y < climb.top-4 or player.position.y > climb.bottom+12 or v > 0 and player.is_on_floor() and player.position.y >= climb.bottom-8:
			climbing = -1
			detach = 0.25
		return true
	if grapple != Vector2.INF:
		grapple_time += delta
		var target: Vector2 = grapple+Vector2(0,64)
		var offset: Vector2 = target-player.position
		player.velocity = offset.normalized()*760
		player.move_and_slide()
		player.animation.play("Grapple")
		player.animation.frame = mini(5,int(grapple_time*12))
		player.animation.pause()
		preload("res://scripts/hero_motion.gd").anchor(player.animation,player.facing)
		if offset.length() < 42 or grapple_time > 1.2 or ready and Input.is_action_just_pressed("jump"):
			grapple = Vector2.INF
			player.velocity.y = -430
			player.jumps = 1
			detach = 0.2
		return true
	return false

func modify_velocity(delta: float) -> void:
	if wall_lock > 0:
		player.velocity.x = wall_direction*390
	elif player.is_on_wall_only() and player.velocity.y > 130 and absf(player.controller.horizontal_direction()) > 0.2:
		player.velocity.y = 130
	if swimming:
		player.velocity.x = move_toward(player.velocity.x,player.controller.horizontal_direction()*185+water.current,delta*900)
		player.velocity.y = move_toward(player.velocity.y-player.GRAVITY*delta,-255 if stroke > 0 else vertical()*155-8,delta*760)
		player.jumps = 1
		player.dash_time = 0

func after_motion(delta: float) -> void:
	wake_cooldown = maxf(0,wake_cooldown-delta)
	var travelled: float = player.position.distance_to(previous_position)
	previous_position = player.position
	if travelled > 60 or player.hurt_time > 0:
		return
	var surface_water: Node2D = district.water_at(player.position-Vector2(0,5))
	if surface_water != null and absf(player.position.y-surface_water.position.y) < 95 and absf(player.velocity.x) > 70 and wake_cooldown <= 0:
		wake_cooldown = 0.22
		surface_water.ripple(player.position.x,2.6 if swimming else 1.7)
	if player.is_on_floor() and absf(player.velocity.x) > 60:
		sound_step += travelled
		if sound_step > 86:
			sound_step = 0
			district.level.audio.play("foot_"+district.surface_kind(player.position))
	elif swimming:
		sound_step += delta
		if sound_step > 0.7 and player.velocity.length() > 70:
			sound_step = 0
			district.level.audio.play("swim")
