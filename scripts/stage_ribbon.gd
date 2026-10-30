extends RefCounted

const Assets = preload("res://scripts/level_assets.gd")
const Campaign = preload("res://scripts/campaign_state.gd")
const ROOT: String = "res://UI/Super Asset Bundle #5 Mini Pocket Status 2.1/0 - Sprites/Tab icons/Style 1/"
static var icons: Array[Texture2D] = []

static func load_icons() -> void:
	if icons.is_empty():
		for file: String in ["1.png", "4.png", "3.png", "2.png", "5.png", "10.png", "6.png", "9.png", "5.png", "10.png", "7.png", "8.png"]:
			icons.append(Assets.texture(ROOT + file))

static func paint(hud: Control) -> void:
	load_icons()
	for i: int in range(Campaign.STAGES):
		var at := Vector2(812+(i%6)*26,674+(i/6)*22)
		var active: bool = hud.profile.chapter == i + 1
		hud.draw_rect(Rect2(at-Vector2.ONE*2,Vector2(22,22)),Color("c9b48b") if active else Color("292538"),false,1)
		hud.draw_texture_rect(icons[i],Rect2(at,Vector2(18,18)),false,Color.WHITE if i < hud.profile.chapter else Color("62616e"))
	hud.text_at("%d / %d" % [hud.profile.chapter,Campaign.STAGES],Vector2(984,691),12,Color("d4c4ac"))
