extends Node2D

signal collided(at: Vector2, kind: String)

const Assets = preload("res://scripts/level_assets.gd")
var velocity: Vector2 = Vector2(-270, 0)
var shooter: Node2D
var friendly: bool = false
var wave: bool = false
var ember: bool = false
var lifetime: float = 3.0
var clock: float = 0.0
var visual: Sprite2D
var spent: bool = false
var eye_orb: bool = false
var witch_orb: bool = false

func _ready() -> void:
	z_index = 6
	add_to_group("enemy_projectiles")
	visual = Assets.sprite(self, "res://Enemies/GandalfHardcore Pixel Art Enemies/Projectile sheet.png", Vector2.ZERO, 2.0)
	visual.region_enabled = true
	visual.region_rect = Rect2(0, 0, 48, 16)
	visual.modulate = Color("a5f5ab")
	if eye_orb:
		visual.modulate = Color("d4b0fa")
	if witch_orb:
		visual.texture = Assets.texture(preload("res://scripts/deep_biome.gd").SPELL+"purple_swirl_orb.png")
		visual.region_enabled = false
		visual.scale = Vector2.ONE*0.9
		visual.modulate = Color("edc5ff")
	if wave:
		visual.texture = Assets.texture(Assets.MAGIC + ("orange_flame.png" if ember else "green_spirit_flame.png"))
		visual.region_enabled = false
		visual.scale = Vector2(2.2, 1.8)

func _physics_process(delta: float) -> void:
	if spent:
		return
	clock += delta
	lifetime -= delta
	var before: Vector2 = position
	position += velocity * delta
	if not wave:
		visual.rotation = velocity.angle()
		if witch_orb:
			visual.rotation = clock*2.4
		else:
			visual.region_rect.position.x = float(int(clock * 14) % 5) * 48
	else:
		visual.scale.y = 1.8 + sin(clock * 17) * 0.15
	var level: Node = get_parent()
	var width: float = float(level.get("stage_width")) if level.get("stage_width") != null else 6400.0
	if lifetime <= 0.0 or position.x < 0 or position.x > width:
		spent = true
		queue_free()
		return
	var terrain: Dictionary = {}
	if not wave:
		var query := PhysicsRayQueryParameters2D.create(before,position,1)
		terrain = get_world_2d().direct_space_state.intersect_ray(query)
	var blocking: float = before.distance_to(terrain.position)/maxf(0.001,before.distance_to(position)) if not terrain.is_empty() else INF
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null and player.locked:
		finish()
		return
	var target: Node2D
	var first: float = blocking
	if not friendly and player != null:
		var at: float = circle_entry(before,position,player.position+Vector2(0,-30),28 if wave else 24)
		if at < first:
			target = player
			first = at
	elif friendly:
		for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
			var at: float = circle_entry(before,position,enemy.position+Vector2(0,-32),40)
			if at < first:
				target = enemy
				first = at
	if target != null:
		position = before.lerp(position,first)
		spent = true
		if friendly:
			if target.strike(target.position+Vector2(0,-32),0,1,190):
				# Put the return cue above the struck silhouette and its health bar.
				collided.emit(target.position+Vector2(0,target.ui_top),"returned")
		else:
			var health_before: int = target.health
			target.take_damage(position)
			if target.health < health_before:
				collided.emit(position,"player")
		finish()
		return
	if not terrain.is_empty():
		position = terrain.position
		spent = true
		collided.emit(position,"terrain")
		finish()
		return
	queue_redraw()

func deflect(origin: Vector2, facing: float) -> bool:
	if friendly or wave or spent or position.distance_to(origin) > 95.0:
		return false
	if facing != 0 and (position.x - (origin.x - facing * 50)) * facing < -16:
		return false
	friendly = true
	visual.modulate = Color("9adfff")
	var aim: Vector2 = Vector2(facing,0) if facing != 0 else -velocity.normalized()
	if is_instance_valid(shooter) and not shooter.dead:
		aim = (shooter.position + Vector2(0, -35) - position).normalized()
	if aim.length_squared() < 0.001:
		aim = Vector2.RIGHT
	velocity = aim.normalized() * 480
	lifetime = 2.0
	return true

func finish() -> void:
	spent = true
	if not is_queued_for_deletion():
		queue_free()

static func circle_entry(from: Vector2, to: Vector2, center: Vector2, radius: float) -> float:
	var offset: Vector2 = from-center
	var ray: Vector2 = to-from
	var c: float = offset.length_squared()-radius*radius
	if c <= 0:
		return 0.0
	var a: float = ray.length_squared()
	if a < 0.0001:
		return INF
	var b: float = offset.dot(ray)
	var discriminant: float = b*b-a*c
	if discriminant < 0:
		return INF
	var at: float = (-b-sqrt(discriminant))/a
	return at if at >= 0 and at <= 1 else INF

func _draw() -> void:
	if wave:
		draw_line(Vector2(-14, 19), Vector2(14, 19), Color("e2c991"), 3)
	else:
		if (eye_orb or witch_orb) and not friendly:
			draw_circle(Vector2.ZERO, 15, Color("bb8de726"))
		draw_line(-velocity.normalized() * 26, Vector2.ZERO, (Color("d4aceb70") if eye_orb or witch_orb else Color("a1d7b550")) if not friendly else Color("a8e8ff70"), 5)
