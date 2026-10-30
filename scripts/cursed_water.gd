extends Node2D

const Assets = preload("res://scripts/level_assets.gd")
const WATER_SHADER = preload("res://scripts/river_surface.gdshader")
var width: float = 320.0
var clock: float = 0.0
var clean: bool = false
var purity: float = -1.0
var surface: ColorRect
var water_material: ShaderMaterial
var heights := PackedFloat32Array()
var velocities := PackedFloat32Array()
var columns: int = 0
var spacing: float = 8.0
var previous_foot: float = 0.0
var splash_count: int = 0

func _ready() -> void:
	z_index = 2
	add_to_group("water_surfaces")
	if purity < 0:
		purity = 1.0 if clean else 0.0
	columns = mini(128, int(ceil(width / 8)) + 1)
	spacing = width / (columns - 1)
	heights.resize(128)
	velocities.resize(128)
	heights.fill(0)
	velocities.fill(0)
	water_material = ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	# The kit is a nested Godot project, so load its source texture directly.
	var noise: Image = Image.load_from_file(ProjectSettings.globalize_path("res://Shaders/Shader Kit/addons/water_kit/textures/noise_rgb.png"))
	noise.generate_mipmaps()
	water_material.set_shader_parameter("noise_texture", ImageTexture.create_from_image(noise))
	water_material.set_shader_parameter("surface_offset", 12.0)
	water_material.set_shader_parameter("spring_count", columns)
	water_material.set_shader_parameter("spring_spacing", spacing)
	water_material.set_shader_parameter("wave_height", 1.8)
	water_material.set_shader_parameter("wave_length", 180.0)
	water_material.set_shader_parameter("wave_speed", 0.65)
	water_material.set_shader_parameter("surface_color", Color("8fbea3").lerp(Color("c3d9da"), purity))
	water_material.set_shader_parameter("shallow_color", Color(0.10, 0.27, 0.23, 0.76).lerp(Color(0.20, 0.40, 0.49, 0.65), purity))
	water_material.set_shader_parameter("deep_color", Color("102b30").lerp(Color("23374e"), purity))
	water_material.set_shader_parameter("depth_falloff", 120.0)
	water_material.set_shader_parameter("refraction_strength", 1.2)
	water_material.set_shader_parameter("rays_strength", 0.06 + purity * 0.07)
	water_material.set_shader_parameter("pixel_size", 2.0)
	water_material.set_shader_parameter("color_steps", 5.0)
	water_material.set_shader_parameter("line_width", 2.0)
	water_material.set_shader_parameter("highlight_band", 10.0)
	surface = ColorRect.new()
	surface.position = Vector2(0, -12)
	surface.size = Vector2(width, 190)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.material = water_material
	add_child(surface)
	var reeds: String = Assets.SWAMP + "cattail_reeds.png" if purity < 0.55 else "res://Stages/Medievil Kingdom/9. Medieval Nature, Forest Edges & Farmland/cattail_grass.png"
	for x: float in [-21.0, width + 21.0]:
		Assets.sprite(self, reeds, Vector2(x, -55), 1.4, -3).modulate = Color("9ba995")

func splash(world_x: float, strength: float) -> void:
	var center: int = clampi(roundi((world_x - global_position.x) / spacing), 0, columns - 1)
	for i: int in range(maxi(0, center - 3), mini(columns, center + 4)):
		velocities[i] -= strength * (1.0 - absf(i - center) / 4.0)
	splash_count += 1
	var level: Node = get_parent()
	if level.get("effects") != null:
		level.effects.play("water_splash", Vector2(world_x, global_position.y - 16))
		level.audio.play("water")

func _physics_process(delta: float) -> void:
	clock += delta
	# Spring integration adapted from the supplied Water2DSide script.
	for i: int in range(columns):
		velocities[i] += -0.025 * heights[i] - 0.065 * velocities[i]
		heights[i] = clampf(heights[i] + velocities[i], -14, 14)
	for pass_index: int in range(4):
		for i: int in range(columns - 1):
			var spread: float = 0.18 * (heights[i] - heights[i + 1])
			velocities[i + 1] += spread
			heights[i + 1] += spread
			velocities[i] -= spread
			heights[i] -= spread
	water_material.set_shader_parameter("game_time", clock)
	water_material.set_shader_parameter("springs", heights)
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		var foot: float = player.global_position.y
		if not player.locked and previous_foot <= global_position.y and foot > global_position.y and player.global_position.x >= global_position.x and player.global_position.x <= global_position.x + width:
			splash(player.global_position.x, clampf(player.velocity.y * 0.012, 4, 12))
		previous_foot = foot
	queue_redraw()

func _draw() -> void:
	if purity > 0.6:
		return
	for i: int in range(6):
		var x: float = fposmod(i * 53.0 + clock * 8, width - 28)
		var y: float = fposmod(-clock * 15 - i * 23, 70)
		draw_texture_rect(Assets.texture(Assets.SWAMP + "toxic_bubbles.png"), Rect2(x, y - 8, 32, 32), false, Color(0.6, 0.85, 0.7, (1.0 - purity) * 0.5))
