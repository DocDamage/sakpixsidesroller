extends "res://tests/living_world_checks.gd"

const Campaign = preload("res://scripts/campaign_state.gd")
const Assets = preload("res://scripts/level_assets.gd")

func run() -> void:
	hub = root.get_node("Controller")
	hub.settings_path = "res://artifacts/input-polish-controller.cfg"
	hub.defaults()
	Input.use_accumulated_input = false
	for chapter: int in range(1, 5):
		level = load(Campaign.SCENES[chapter - 1]).instantiate()
		root.add_child(level)
		current_scene = level
		await ticks(20)
		for enemy: Node2D in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
		await place()
		Pad.axis(JOY_AXIS_LEFT_Y, 1)
		Pad.button(JOY_BUTTON_A, true)
		await ticks(3)
		Pad.release()
		check(level.player.jumps == 1 and level.player.velocity.y < 0 and level.player.drop_time == 0, "Stage %d downward stick lean cannot swallow a solid-ground jump" % chapter)
		var ledge: Rect2 = level.profile.builder.LEDGES[0]
		level.player.respawn(Vector2(ledge.get_center().x, ledge.position.y - 2))
		level.player.invincible = 1000
		await ticks(10)
		check(level.player.standing_on_ledge(), "Stage %d recognizes its actual one-way collision surface" % chapter)
		level.player.hit_pause = 0.06
		Pad.axis(JOY_AXIS_LEFT_Y, 1)
		Pad.button(JOY_BUTTON_A, true)
		await ticks(2)
		Pad.release()
		await ticks(9)
		check(level.player.drop_time > 0 and level.player.position.y > ledge.position.y + 5 and level.player.jumps == 1, "Stage %d buffered down-jump retains drop intent through hit pause" % chapter)
		await tap(JOY_BUTTON_A)
		check(level.player.jumps == 2 and level.player.velocity.y < 0, "Stage %d dropping preserves one deliberate recovery jump" % chapter)
		Pad.release()
		level.player.respawn(Vector2(590, 598))
		level.player.invincible = 1000
		level.player.facing = 1
		await ticks(8)
		Pad.button(JOY_BUTTON_X, true)
		await ticks(15)
		Pad.release()
		var broken: Node2D
		for child: Node in level.get_children():
			if child.get_script() == preload("res://scripts/breakable_urn.gd") and child.position.x == 650:
				broken = child
		check(broken != null and broken.broken and get_nodes_in_group("healing_vials").size() == 1, "Stage %d destructible supply prop reacts to controller attacks and drops one heart" % chapter)
		check(absf(Assets.visible_rect(broken.visual).end.y - 600) < 0.1, "Stage %d broken debris rests on the visible floor" % chapter)
		level.queue_free()
		await ticks(2)
	hub.defaults()
	var mapping: Dictionary = hub.mapping.duplicate()
	check(not hub.rebind("attack", -1) and not hub.rebind("attack", JOY_BUTTON_MAX) and not hub.rebind("attack", JOY_BUTTON_BACK) and hub.mapping == mapping, "Invalid or reserved bindings cannot consume controller navigation")
	var config := ConfigFile.new()
	var malformed: Dictionary = mapping.duplicate()
	malformed["attack"] = JOY_BUTTON_DPAD_LEFT
	config.set_value("controller", "mapping", malformed)
	config.save(hub.settings_path)
	hub.load_settings()
	check(hub.mapping == mapping, "Loading a reserved-button mapping preserves the safe controller layout")
	hub.defaults()
	print("INPUT COMBAT POLISH RESULT: %d/%d checks passed" % [checks - failures, checks])
	OS.delay_msec(120)
	await ticks(6)
	quit(1 if failures else 0)
