extends CharacterBody2D

var controller: Node:
	get:
		return get_node("/root/Controller")

signal attacked(origin: Vector2, facing: float)
signal sword_contact(origin: Vector2, facing: float)
signal sword_tail_requested(source: AnimatedSprite2D, at: Vector2)
signal hurt(health: int)
signal fallen
signal sound_requested(kind: String)
signal effect_requested(kind: String, at: Vector2, facing: float)
signal dash_trail_requested
signal evaded(at: Vector2)

const Assets = preload("res://scripts/level_assets.gd")
const Motion = preload("res://scripts/hero_motion.gd")
const SPEED: float = 310.0
const JUMP: float = -650.0
const GRAVITY: float = 1700.0
var health: int = 5
var facing: float = 1.0
var jumps: int = 0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var invincible: float = 0.0
var attack_time: float = 0.0
var dash_time: float = 0.0
var dash_cooldown: float = 0.0
var attack_pending: bool = false
var locked: bool = false
var animation: AnimatedSprite2D
var hurt_time: float = 0.0
var attack_buffer: float = 0.0
var combo_window: float = 0.0
var combo_step: int = 0
var trail_time: float = 0.0
var drop_time: float = 0.0
var squash: Vector2 = Vector2.ONE
var attack_mode: String = "ground"
var hit_pause: float = 0.0
var cut_jump_requested: bool = false
var dash_buffer: float = 0.0
var buffered_dash_direction: float = 0.0
var dodge_rewarded: bool = false
var jump_wants_drop: bool = false
var buffered_attack_direction: float = 0.0
var attack_wants_plunge: bool = false
var swing_id: int = 0
var attack_notified: bool = false
var world_width: float = 6400
var world_bottom: float = 900
var traversal: RefCounted
var sword_bonus: int = 0

func _ready() -> void:
	name = "Seeker"
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 8.0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 15.0
	capsule.height = 62.0
	shape.shape = capsule
	shape.position.y = -32.0
	add_child(shape)
	animation = AnimatedSprite2D.new()
	animation.sprite_frames = Assets.hero_frames()
	animation.scale = Vector2.ONE * 3.0
	animation.position = Vector2(0, -42)
	animation.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(animation)
	animation.play("Idle")
	Motion.anchor(animation,facing)
	z_index = 5
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var input_ready: bool = not controller.suppress_until_release
	if not input_ready:
		jump_buffer = 0
		attack_buffer = 0
		dash_buffer = 0
	if hit_pause > 0.0:
		hit_pause = maxf(0.0, hit_pause - delta)
		if input_ready and Input.is_action_just_pressed("attack"):
			queue_attack()
		if input_ready and Input.is_action_just_pressed("jump"):
			queue_jump()
		if Input.is_action_just_released("jump"):
			cut_jump_requested = true
		if input_ready and Input.is_action_just_pressed("dash"):
			queue_dash()
		animation.pause()
		return
	invincible = maxf(0.0, invincible - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	attack_time = maxf(0.0, attack_time - delta)
	dash_time = maxf(0.0, dash_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	attack_buffer = maxf(0.0, attack_buffer - delta)
	dash_buffer = maxf(0.0, dash_buffer - delta)
	combo_window = maxf(0.0, combo_window - delta)
	drop_time = maxf(0.0, drop_time - delta)
	if drop_time <= 0.0:
		set_collision_mask_value(3, true)
	squash = squash.lerp(Vector2.ONE, minf(1.0, delta * 14.0))
	animation.scale = Vector2(3, 3) * squash
	if locked:
		attack_time = 0.0
		dash_time = 0.0
		animation.modulate = Color.WHITE
		animation.play("Idle")
		Motion.anchor(animation,facing)
		queue_redraw()
		return
	if is_on_floor():
		coyote = 0.12
		jumps = 0
	else:
		coyote = maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if input_ready and Input.is_action_just_pressed("jump"):
		queue_jump()
	if traversal != null:
		traversal.prepare(delta,input_ready)
		if traversal.override_motion(delta,input_ready):
			queue_redraw()
			return
	if jump_buffer > 0.0 and hurt_time <= 0.0 and dash_time <= 0.0 and (coyote > 0.0 or jumps < 2):
		if jump_wants_drop and standing_on_ledge():
			drop_time = 0.16 if traversal != null else 0.22
			set_collision_mask_value(3, false)
			position.y += 4.0
			velocity.y = 90.0
			jumps = 1
		else:
			if coyote <= 0.0 and jumps == 0:
				jumps = 1
			velocity.y = JUMP
			jumps += 1
			squash = Vector2(0.88, 1.12)
			sound_requested.emit("jump")
			effect_requested.emit("air_jump" if jumps == 2 else "jump", position + Vector2(0, -8), facing)
		coyote = 0.0
		jump_buffer = 0.0
		jump_wants_drop = false
	if (Input.is_action_just_released("jump") or cut_jump_requested) and velocity.y < -270.0 and (traversal == null or traversal.wall_lock <= 0):
		velocity.y = -270.0
	cut_jump_requested = false
	var direction: float = controller.horizontal_direction() if input_ready else 0.0
	var aim: float = controller.aim_direction() if input_ready else 0.0
	if aim != 0.0 and attack_time <= 0.0 and dash_time <= 0.0 and hurt_time <= 0.0:
		facing = signf(aim)
	if input_ready and Input.is_action_just_pressed("attack"):
		queue_attack()
	var recover_frame: int = [5,4,7][combo_step]
	var chain_ready: bool = attack_time > 0 and attack_mode == "ground" and Motion.frame(attack_clip(),Motion.duration(attack_clip())-attack_time) >= recover_frame
	if attack_buffer > 0.0 and (attack_time <= 0.0 or chain_ready) and dash_time <= 0.0 and hurt_time <= 0.0:
		start_attack()
	var clip: String = attack_clip()
	var contact_frame: int = Motion.frame(clip,Motion.duration(clip)-attack_time)
	var active: Vector2i = Motion.ACTIVE[clip]
	if attack_pending and attack_time > 0 and contact_frame >= active.x and contact_frame <= active.y:
		var origin: Vector2 = position + (Vector2(0, 23) if attack_mode == "plunge" else Vector2(facing * 50.0, -35))
		if not attack_notified:
			attack_notified = true
			sound_requested.emit("attack")
			attacked.emit(origin,facing)
		sword_contact.emit(origin,facing)
	if input_ready and Input.is_action_just_pressed("dash"):
		queue_dash()
	if dash_buffer > 0.0 and dash_cooldown <= 0.0 and hurt_time <= 0.0:
		dash_buffer = 0.0
		var requested_direction: float = buffered_dash_direction
		if requested_direction != 0.0:
			facing = signf(requested_direction)
		buffered_dash_direction = 0.0
		dash_time = 0.17
		dodge_rewarded = false
		dash_cooldown = 0.85
		invincible = maxf(invincible, 0.20)
		if attack_time > 0:
			sword_tail_requested.emit(animation,position)
		attack_pending = false
		attack_time = 0.0
		sound_requested.emit("dash")
		effect_requested.emit("dash", position + Vector2(-facing * 24, -14), facing)
	if dash_time > 0.0:
		velocity = Vector2(facing * 820.0, 0.0)
		trail_time -= delta
		if trail_time <= 0.0:
			trail_time = 0.035
			dash_trail_requested.emit()
	else:
		if hurt_time > 0.0:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		else:
			var control: float = 0.65 if attack_time > 0.0 and is_on_floor() else 1.0
			velocity.x = move_toward(velocity.x, direction * SPEED * control, 2300.0 * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, 1100.0)
		if attack_mode == "plunge" and attack_time > 0.10:
			velocity.y = maxf(velocity.y, 670.0)
	var was_grounded: bool = is_on_floor()
	if traversal != null:
		traversal.modify_velocity(delta)
	var fall_speed: float = velocity.y
	move_and_slide()
	if traversal != null:
		traversal.after_motion(delta)
	if is_on_floor() and not was_grounded and fall_speed > 220.0:
		squash = Vector2(1.14, 0.86)
		effect_requested.emit("land", position + Vector2(0, -9), facing)
		sound_requested.emit("land")
	position.x = clampf(position.x,35.0,world_width-40)
	if position.y > world_bottom:
		fallen.emit()
	update_animation()
	queue_redraw()

func queue_jump() -> void:
	jump_buffer = 0.14
	jump_wants_drop = controller.down_pressed()

func queue_dash() -> void:
	dash_buffer = 0.16
	buffered_dash_direction = controller.aim_direction()
	if buffered_dash_direction == 0.0:
		buffered_dash_direction = facing

func queue_attack() -> void:
	attack_buffer = 0.24
	buffered_attack_direction = controller.aim_direction()
	attack_wants_plunge = controller.down_pressed()

func standing_on_ledge() -> bool:
	if not is_on_floor():
		return false
	for i: int in get_slide_collision_count():
		var contact: KinematicCollision2D = get_slide_collision(i)
		var body: CollisionObject2D = contact.get_collider() as CollisionObject2D
		if body != null and body.get_collision_layer_value(3) and contact.get_normal().y < -0.5:
			return true
	return false

func start_attack() -> void:
	if attack_time > 0:
		sword_tail_requested.emit(animation,position)
	if buffered_attack_direction != 0.0:
		facing = signf(buffered_attack_direction)
	attack_mode = "ground" if is_on_floor() else ("plunge" if attack_wants_plunge or controller.down_pressed() else "air")
	buffered_attack_direction = 0.0
	attack_wants_plunge = false
	combo_step = (combo_step + 1) % 3 if combo_window > 0.0 else 0
	attack_time = Motion.duration(attack_clip())
	combo_window = attack_time + 0.32
	attack_buffer = 0.0
	attack_pending = true
	attack_notified = false
	swing_id += 1
	animation.stop()

func attack_clip() -> String:
	return "DownAttack" if attack_mode == "plunge" else ("JumpAttack" if attack_mode == "air" else "Attack%d" % (combo_step + 1))

func rebound() -> void:
	velocity.y = -460.0
	attack_time = 0.0
	attack_pending = false
	jumps = 1
	attack_mode = "ground"
	effect_requested.emit("air_jump", position, facing)

func update_animation() -> void:
	animation.flip_h = facing < 0.0
	animation.modulate.a = 0.45 if invincible > 0.0 and fmod(invincible, 0.16) < 0.08 else 1.0
	if hurt_time > 0.0:
		animation.play("Hurt")
	elif dash_time > 0.0:
		animation.play("Dash")
	elif attack_time > 0.0:
		animation.play(attack_clip())
		animation.pause()
		animation.frame = Motion.frame(attack_clip(),Motion.duration(attack_clip())-attack_time)
	elif traversal != null and is_on_wall_only() and velocity.y > 20:
		animation.play("WallSlide")
		facing = get_wall_normal().x
	elif not is_on_floor():
		animation.play("DoubleJump" if jumps == 2 and velocity.y < 0.0 else "JumpFall")
	elif absf(velocity.x) > 10.0:
		animation.play("Run")
	else:
		animation.play("Idle")
	Motion.anchor(animation,facing)

func take_damage(source: Vector2) -> void:
	if not locked and invincible > 0.0 and dash_time > 0.0 and not dodge_rewarded:
		dodge_rewarded = true
		dash_cooldown = maxf(0.0, dash_cooldown - 0.18)
		evaded.emit(position + Vector2(0, -40))
	if invincible > 0.0 or locked:
		return
	health -= 1
	invincible = 1.3
	hurt_time = 0.22
	attack_time = 0.0
	attack_pending = false
	attack_buffer = 0.0
	dash_time = 0.0
	buffered_attack_direction = 0.0
	attack_wants_plunge = false
	var away: float = signf(position.x - source.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * 360.0, -310.0)
	sound_requested.emit("hurt")
	hurt.emit(health)
	if health <= 0:
		fallen.emit()

func respawn(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	health = 5
	invincible = 1.6
	dash_time = 0.0
	attack_time = 0.0
	attack_pending = false
	jumps = 0
	jump_buffer = 0.0
	jump_wants_drop = false
	hurt_time = 0.0
	combo_window = 0.0
	attack_buffer = 0.0
	dash_cooldown = 0.0
	buffered_attack_direction = 0.0
	attack_wants_plunge = false
	dash_buffer = 0.0
	buffered_dash_direction = 0.0
	dodge_rewarded = false
	hit_pause = 0.0
	cut_jump_requested = false
	attack_mode = "ground"
	drop_time = 0.0
	set_collision_mask_value(3, true)

func _draw() -> void:
	if traversal != null:
		if traversal.grapple != Vector2.INF:
			draw_line(Vector2(0,-42),traversal.grapple-position,Color("c5bacb"),2)
		if traversal.swimming and traversal.breath < 13.5:
			draw_rect(Rect2(-23,-88,46,4),Color("101b2b"))
			draw_rect(Rect2(-23,-88,46*traversal.breath/14,4),Color("97d9de"))
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, 23.0 if is_on_floor() else 16.0, Color("080c1866"))
	draw_set_transform(Vector2.ZERO)
	if dash_time > 0.0:
		draw_line(Vector2(-facing * 20.0, -28), Vector2(-facing * 95.0, -28), Color("7774c880"), 15.0)
