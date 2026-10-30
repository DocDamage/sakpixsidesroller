extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Profile = preload("res://scripts/chapter_profile.gd")
const Assets = preload("res://scripts/level_assets.gd")
const Bolt = preload("res://scripts/cursed_bolt.gd")

func orb(at: Vector2, velocity: Vector2, friendly: bool = false) -> Node2D:
	var bolt := Bolt.new()
	bolt.position = at
	bolt.velocity = velocity
	bolt.friendly = friendly
	level.add_child(bolt)
	bolt.set_physics_process(false)
	bolt.collided.connect(level.combat.projectile_collided)
	return bolt

func target(at: Vector2) -> Node2D:
	var enemy := Enemy.new()
	enemy.species = "plant"
	enemy.position = at
	level.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func run() -> void:
	hub = root.get_node("Controller")
	hub.focus_pause_enabled = false
	hub.settings_path = "res://artifacts/arrival-check-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	for chapter: int in range(1,Campaign.STAGES+1):
		level = load(Campaign.SCENES[chapter-1]).instantiate()
		root.add_child(level)
		current_scene = level
		check(level.hud.arrival_time > 0,"Stage %d starts with a short arrival fade" % chapter)
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		check(level.hud.arrival_time == 0,"Stage %d arrival fade clears before play settles" % chapter)
		var entries: Array[Node] = get_nodes_in_group("stage_entrances")
		if chapter == 1:
			check(entries.is_empty(),"Opening stage preserves its original arrival composition")
		else:
			var previous: RefCounted = Profile.new(chapter-1)
			check(entries.size() == 1 and entries[0].texture.resource_path == previous.open_exit_texture,"Stage %d begins at the exact open gateway used to leave stage %d" % [chapter,chapter-1])
			var rect: Rect2 = Assets.visible_rect(entries[0])
			check(absf(rect.end.y-600)<0.1 and rect.end.x < level.checkpoint.x+5,"Stage %d gateway meets the visible floor behind the arrival position" % chapter)
		Pad.release()
		level.player.respawn(Vector2(450,598))
		level.player.invincible = 1000
		await ticks(8)
		Pad.axis(JOY_AXIS_LEFT_X,-0.75)
		Pad.button(JOY_BUTTON_DPAD_RIGHT,true)
		var start: float = level.player.position.x
		await ticks(14)
		check(level.player.position.x > start+45 and hub.horizontal_direction() == 1 and level.player.facing > 0,"Stage %d D-pad right keeps full speed and facing against an opposing stick" % chapter)
		Pad.button(JOY_BUTTON_DPAD_LEFT,true)
		await ticks(10)
		check(hub.horizontal_direction() == 0 and absf(level.player.velocity.x)<1,"Stage %d opposite D-pad directions settle to neutral" % chapter)
		Pad.button(JOY_BUTTON_DPAD_RIGHT,false)
		Pad.axis(JOY_AXIS_LEFT_X,0.8)
		await ticks(12)
		check(hub.horizontal_direction() == -1 and level.player.velocity.x < -300,"Stage %d D-pad left takes priority over the opposite stick" % chapter)
		Pad.release()
		Pad.axis(JOY_AXIS_LEFT_X,0.8)
		var idle := InputEventJoypadMotion.new()
		idle.device = 88
		idle.axis = JOY_AXIS_LEFT_X
		idle.axis_value = 0
		Input.parse_input_event(idle)
		await ticks(3)
		check(hub.last_device == Pad.DEVICE and hub.horizontal_direction() > 0.7,"Stage %d an idle second controller cannot erase active stick movement" % chapter)
		Pad.release()
		var ledge: Rect2 = level.profile.builder.LEDGES[0]
		level.player.respawn(Vector2(ledge.get_center().x,ledge.position.y-2))
		await ticks(10)
		Pad.axis(JOY_AXIS_LEFT_X,0.8)
		Pad.axis(JOY_AXIS_LEFT_Y,0.35)
		await tap(JOY_BUTTON_A)
		check(level.player.drop_time == 0 and level.player.jumps == 1 and level.player.velocity.y < 0,"Stage %d a shallow diagonal tilt jumps from the ledge instead of accidentally dropping" % chapter)
		await tap(JOY_BUTTON_X)
		check(level.player.attack_mode == "air","Stage %d shallow downward drift preserves a normal aerial strike" % chapter)
		Pad.release()
		level.player.respawn(Vector2(ledge.get_center().x,ledge.position.y-2))
		await ticks(10)
		Pad.axis(JOY_AXIS_LEFT_Y,0.85)
		Pad.button(JOY_BUTTON_DPAD_UP,true)
		await tap(JOY_BUTTON_A)
		check(level.player.drop_time == 0 and level.player.jumps == 1,"Stage %d D-pad up overrides an unrelated downward stick lean" % chapter)
		Pad.release()
		level.player.respawn(Vector2(ledge.get_center().x,ledge.position.y-2))
		await ticks(10)
		Pad.axis(JOY_AXIS_LEFT_Y,0.85)
		await tap(JOY_BUTTON_A)
		check(level.player.drop_time > 0 and level.player.jumps == 1,"Stage %d deliberate stick down still drops through its one-way ledge" % chapter)
		Pad.release()
		level.player.set_physics_process(false)
		level.player.respawn(Vector2(450,600))
		var far: Node2D = target(Vector2(2500,282))
		var near: Node2D = target(Vector2(2250,282))
		var barrier := StaticBody2D.new()
		barrier.position = Vector2(2400,250)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(20,140)
		collision.shape = shape
		barrier.add_child(collision)
		level.add_child(barrier)
		await ticks(2)
		var returned: Node2D = orb(Vector2(2100,250),Vector2(1000,0),true)
		var pulses: int = hub.rumble_count
		hub.feedback.clear()
		returned._physics_process(0.5)
		check(near.health == 2 and far.health == 3 and returned.spent,"Stage %d a fast returned orb hits the enemy before the wall" % chapter)
		check(has_label("RETURN HIT") and hub.rumble_count > pulses,"Stage %d successful projectile returns receive clear text and controller feedback" % chapter)
		var hits: Dictionary = {"terrain":0}
		var blocked: Node2D = orb(Vector2(2350,250),Vector2(1000,0),true)
		blocked.collided.connect(func(_at: Vector2, kind: String) -> void: hits[kind] = int(hits.get(kind,0))+1)
		blocked._physics_process(0.3)
		blocked._physics_process(0.3)
		check(far.health == 3 and blocked.spent and hits.terrain == 1 and absf(blocked.position.x-2390)<0.1,"Stage %d stone blocks a return once at the actual impact point" % chapter)
		var small_effect: bool = false
		for node: Node in level.effects.get_children():
			if node is AnimatedSprite2D and node.scale.x < 1:
				small_effect = true
		check(small_effect,"Stage %d blocked projectiles use a restrained supplied impact animation" % chapter)
		level.player.respawn(Vector2(2300,282))
		level.player.invincible = 0
		var hostile: Node2D = orb(Vector2(2100,252),Vector2(1000,0))
		hostile._physics_process(0.5)
		check(level.player.health == 4 and hostile.spent,"Stage %d a hostile shot reaches the player before stone farther down its path" % chapter)
		barrier.queue_free()
		near.reset_encounter()
		await ticks(2)
		var sorted_return: Node2D = orb(Vector2(2100,250),Vector2(1000,0),true)
		sorted_return._physics_process(0.5)
		check(near.health == 2 and far.health == 3,"Stage %d returned shots hit the nearest target regardless of spawn order" % chapter)
		var origin := Vector2(500,250)
		var plunge: Node2D = orb(origin+Vector2(-35,20),Vector2(0,-230))
		level.player.attack_mode = "plunge"
		level.combat.resolve_attack(origin,1)
		check(plunge.friendly and is_equal_approx(plunge.velocity.length(),480),"Stage %d aerial plunges return an orb below either side of the player" % chapter)
		var still: Node2D = orb(origin,Vector2.ZERO)
		check(still.deflect(origin,0) and still.velocity.length() > 479,"Stage %d an orphaned stationary orb cannot become a stuck reflection" % chapter)
		Pad.release()
		level.queue_free()
		await ticks(2)
	print("ARRIVAL COMBAT RESULT: %d/%d checks passed" % [checks-failures,checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
