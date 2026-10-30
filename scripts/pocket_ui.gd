extends RefCounted

# Original Mini Pocket sprites supply the frames, paper, icons and bar artwork.
const Assets = preload("res://scripts/level_assets.gd")
const ROOT: String = "res://UI/Super Asset Bundle #5 Mini Pocket Status 2.1/1 - Brown/"
const INK := Color("302d3c")
const MUTED := Color("635545")
const LIGHT := Color("f4e5c7")
static var crops: Dictionary = {}
static var panels: Dictionary = {}
static var buttons: Dictionary = {}
static var bars: Dictionary = {}
static var shared_theme: Theme

static func cropped(file: String) -> Texture2D:
	if not crops.has(file):
		var path: String = ROOT + "Content/" + file
		crops[file] = Assets.atlas(path, Assets.opaque_rect(path))
	return crops[file]

static func book() -> Texture2D:
	if not crops.has("book"):
		crops["book"] = Assets.atlas(ROOT + "Pixel Book/Sprites/Static/1.png", Rect2(144,160,488,312))
	return crops["book"]

static func frame(tint: Color = Color.WHITE) -> StyleBoxTexture:
	var key: String = tint.to_html()
	if not panels.has(key):
		var style := StyleBoxTexture.new()
		style.texture = Assets.atlas(ROOT + "Pixel Book/Sprites/Static/1.png", Rect2(144,160,244,312))
		for side: int in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
			style.set_texture_margin(side, 24)
		style.modulate_color = tint
		panels[key] = style
	return panels[key]

static func button_box(tint: Color) -> StyleBoxTexture:
	var key: String = tint.to_html()
	if buttons.has(key):
		return buttons[key]
	var style := StyleBoxTexture.new()
	style.texture = cropped("Buttons/3.png")
	style.modulate_color = tint
	for side: int in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		style.set_texture_margin(side, 4)
		style.set_content_margin(side, 12 if side in [SIDE_LEFT,SIDE_RIGHT] else 6)
	buttons[key] = style
	return style

static func focus_box() -> StyleBoxFlat:
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("614473")
	focus.set_border_width_all(3)
	focus.set_expand_margin_all(3)
	return focus

static func make_theme() -> Theme:
	if shared_theme != null:
		return shared_theme
	shared_theme = Theme.new()
	shared_theme.default_font_size = 16
	for kind: String in ["Button","OptionButton","CheckButton"]:
		shared_theme.set_stylebox("normal", kind, button_box(Color("d3c6a6")))
		shared_theme.set_stylebox("hover", kind, button_box(Color("fff1c5")))
		shared_theme.set_stylebox("pressed", kind, button_box(Color("a99b7e")))
		shared_theme.set_stylebox("focus", kind, focus_box())
		for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			shared_theme.set_color(state, kind, INK)
		shared_theme.set_color("font_disabled_color", kind, MUTED)
	for suffix: String in ["","_disabled","_mirrored","_disabled_mirrored"]:
		shared_theme.set_icon("checked"+suffix,"CheckButton",Assets.texture(ROOT+"Content/icons/15.png"))
		shared_theme.set_icon("unchecked"+suffix,"CheckButton",Assets.texture(ROOT+"Content/icons/18.png"))
	var rail := StyleBoxTexture.new()
	rail.texture = cropped("Progress Bars/17.png")
	for side: int in [SIDE_LEFT,SIDE_RIGHT]:
		rail.set_texture_margin(side, 3)
	rail.content_margin_top = 4
	rail.content_margin_bottom = 4
	shared_theme.set_stylebox("slider", "HSlider", rail)
	shared_theme.set_stylebox("grabber_area", "HSlider", StyleBoxEmpty.new())
	shared_theme.set_stylebox("grabber_area_highlight", "HSlider", StyleBoxEmpty.new())
	shared_theme.set_stylebox("focus", "HSlider", focus_box())
	shared_theme.set_icon("grabber", "HSlider", cropped("Buttons/5.png"))
	shared_theme.set_icon("grabber_highlight", "HSlider", cropped("Buttons/6.png"))
	shared_theme.set_stylebox("panel", "PopupMenu", frame())
	shared_theme.set_stylebox("hover", "PopupMenu", button_box(Color("fff1c5")))
	shared_theme.set_color("font_color", "PopupMenu", INK)
	shared_theme.set_color("font_hover_color", "PopupMenu", INK)
	return shared_theme

static func icon(canvas: CanvasItem, texture: Texture2D, rect: Rect2, tint: Color = Color.WHITE) -> void:
	var size: Vector2 = texture.get_size()
	var ratio: float = minf(rect.size.x / size.x, rect.size.y / size.y)
	var target := Rect2(rect.get_center() - size * ratio / 2.0, size * ratio)
	canvas.draw_texture_rect(texture, target, false, tint)

static func bar(canvas: CanvasItem, rect: Rect2, amount: float, file: String = "7", trail: float = -1.0) -> void:
	# Nine-slice the tiny end caps so a wide guardian bar keeps crisp edges.
	for id: String in ["17",file,"7"]:
		if not bars.has(id):
			var style := StyleBoxTexture.new()
			style.texture = cropped("Progress Bars/"+id+".png")
			for side: int in [SIDE_LEFT,SIDE_RIGHT]:
				style.set_texture_margin(side,3)
			for side: int in [SIDE_TOP,SIDE_BOTTOM]:
				style.set_texture_margin(side,2)
			bars[id] = style
	canvas.draw_style_box(bars["17"],rect)
	var fraction: float = clampf(amount,0,1)
	if trail > fraction:
		canvas.draw_style_box(bars["7"],Rect2(rect.position,Vector2(rect.size.x*clampf(trail,0,1),rect.size.y)))
	if fraction > 0.0:
		canvas.draw_style_box(bars[file],Rect2(rect.position,Vector2(maxf(6,rect.size.x*fraction),rect.size.y)))

static func lines(font: Font, value: String, size: int, width: float) -> PackedStringArray:
	var result: PackedStringArray = []
	for paragraph: String in value.split("\n"):
		var line: String = ""
		for word: String in paragraph.split(" ",false):
			var next: String = word if line.is_empty() else line + " " + word
			if not line.is_empty() and font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width:
				result.append(line)
				line = word
			else:
				line = next
		result.append(line)
	return result

static func paragraph(canvas: CanvasItem, value: String, at: Vector2, width: float, size: int, color: Color = INK) -> float:
	var font: Font = ThemeDB.fallback_font
	var rows: PackedStringArray = lines(font,value,size,width)
	for i: int in rows.size():
		canvas.draw_string(font,at+Vector2(0,i*(size+7)),rows[i],HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
	return rows.size()*(size+7)

static func fit(font: Font, value: String, size: int, width: float, minimum: int = 10) -> int:
	while size > minimum and font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width:
		size -= 1
	return size
