extends Control

var controller: Node:
	get:
		return get_node("/root/Controller")

const Assets = preload("res://scripts/level_assets.gd")
const Campaign = preload("res://scripts/campaign_state.gd")
const Pocket = preload("res://scripts/pocket_ui.gd")

signal pause_requested
signal restart_requested
signal continue_requested
signal first_requested
var profile: RefCounted
var health: int = 5
var seals: int = 0
var coins: int = 0
var total_coins: int = 0
var stage_width: float = 6400
var checkpoint_total: int = 3
var key_found: bool = false
var progress: float = 0.0
var checkpoint_index: int = -1
var elapsed: float = 0.0
var arrival_time: float = 0.28
var dash_ready: bool = true
var deaths: int = 0
var region: String = "THE CROOKED QUARTER"
var prompt: String = ""
var notice: String = ""
var notice_time: float = 0.0
var intro_time: float = 7.0
var paused: bool = false
var complete: bool = false
var allow_exploration: bool = false
var muted: bool = false
var menu: VBoxContainer
var resume_button: Button
var restart_button: Button
var font: Font
var dash_charge: float = 1.0
var damage_flash: float = 0.0
var region_time: float = 0.0
var last_region: String = "THE CROOKED QUARTER"
var goal_name: String = "SEAL"
var goal_direction: String = "→ AHEAD"
var boss_visible: bool = false
var boss_health: int = 8
var boss_max_health: int = 8
var boss_damage_trail: float = 8.0
var boss_enraged: bool = false
var boss_staggered: bool = false
var kills: int = 0
var combo_hits: int = 0
var warden_alive: bool = true
var relics: int = 0
var talk_prompt: String = ""
var continue_button: Button
var first_button: Button
var last_complete: bool = false
var controls_button: Button
var mute_button: Button
var last_paused: bool = false
var quit_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font
	theme = Pocket.make_theme()
	menu = VBoxContainer.new()
	menu.position = Vector2(684, 284)
	menu.size = Vector2(380, 288)
	menu.add_theme_constant_override("separation", 12)
	add_child(menu)
	resume_button = make_button("RESUME", pause_requested.emit)
	continue_button = make_button("CONTINUE TO LEVEL 2", continue_requested.emit)
	restart_button = make_button("RESTART LEVEL", restart_requested.emit)
	first_button = make_button("BACK TO HALLOWEEN TOWN", first_requested.emit)
	controls_button = make_button("CONTROLS & CONTROLLER", controller.open_panel)
	mute_button = make_button("MUTE AUDIO", func() -> void:
		var level: Node = get_tree().current_scene
		level.audio.toggle()
		muted = level.audio.muted)
	quit_button = make_button("QUIT GAME (ENDS RUN)", get_tree().quit)
	menu.hide()

func make_button(caption: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(380, 48)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(func() -> void:
		controller.flush_gameplay()
		controller.suppress_until_release = true
		callback.call())
	menu.add_child(button)
	return button

func notify_player(value: String) -> void:
	notice = value
	notice_time = 4.5

func _process(delta: float) -> void:
	if not paused and not complete:
		arrival_time = maxf(0,arrival_time-delta)
		intro_time = maxf(0.0, intro_time - delta)
		notice_time = maxf(0.0, notice_time - delta)
		region_time = maxf(0.0, region_time - delta)
		if region != last_region:
			last_region = region
			region_time = 3.0
	menu.visible = (paused or complete) and not controller.panel.visible
	menu.position.y = 284
	controls_button.visible = paused or complete
	mute_button.visible = paused and not complete
	mute_button.text = "UNMUTE AUDIO" if muted else "MUTE AUDIO"
	resume_button.visible = paused and not complete or complete and allow_exploration
	resume_button.text = "KEEP EXPLORING" if complete else "RESUME"
	continue_button.visible = complete and profile.chapter < Campaign.STAGES
	continue_button.text = "CONTINUE TO LEVEL %d" % (profile.chapter + 1)
	first_button.visible = complete and profile.chapter == Campaign.STAGES
	restart_button.text = "REPLAY THIS LEVEL" if complete else "RESTART LEVEL"
	if complete and not last_complete:
		(resume_button if allow_exploration else (continue_button if profile.chapter < Campaign.STAGES else restart_button)).grab_focus()
		controller.rumble("success")
	if paused and not last_paused and not controller.panel.visible:
		resume_button.grab_focus()
	last_paused = paused
	last_complete = complete
	queue_redraw()

func text_at(value: String, at: Vector2, size: int, color: Color = Color("d4c9df")) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if font != null and profile != null:
		preload("res://scripts/pocket_hud_painter.gd").paint(self)
