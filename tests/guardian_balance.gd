extends SceneTree

const Campaign = preload("res://scripts/campaign_state.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var controller_mode: bool = "--controller" in OS.get_cmdline_user_args()
	if controller_mode:
		var hub: Node = root.get_node("Controller")
		hub.settings_path = "res://artifacts/controller-balance.cfg"
		hub.defaults()
	var scene_path: String = "res://scenes/lantern_road.tscn" if "--chapter-two" in OS.get_cmdline_user_args() else "res://scenes/halloween_town.tscn"
	if "--chapter-three" in OS.get_cmdline_user_args():
		scene_path = "res://scenes/emberwick_market.tscn"
	elif "--chapter-four" in OS.get_cmdline_user_args():
		scene_path = "res://scenes/crownward_keep.tscn"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			var stage: int = clampi(int(argument.trim_prefix("--stage=")),1,Campaign.STAGES)
			scene_path = Campaign.SCENES[stage-1]
	var level: Node2D = load(scene_path).instantiate()
	root.add_child(level)
	current_scene = level
	for i: int in range(20):
		await physics_frame
	level.audio.toggle()
	for enemy: Node2D in get_nodes_in_group("enemies"):
		if enemy != level.combat.guardian:
			enemy.set_physics_process(false)
	level.player.position = level.combat.guardian.home + Vector2(-170, -2)
	level.player.health = 5
	level.player.invincible = 0
	var passed: bool = await preload("res://tests/guardian_driver.gd").fight(self, level, controller_mode)
	passed = passed and level.deaths == 0 and level.player.health > 0
	print("GUARDIAN BALANCE: %s / vitality %d / deaths %d" % ["PASS" if passed else "FAIL", level.player.health, level.deaths])
	level.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(120)
	quit(0 if passed else 1)
