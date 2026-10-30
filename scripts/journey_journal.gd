extends RefCounted

const Pocket = preload("res://scripts/pocket_ui.gd")
const Assets = preload("res://scripts/level_assets.gd")
const Campaign = preload("res://scripts/campaign_state.gd")
const Ribbon = preload("res://scripts/stage_ribbon.gd")

static func task(hud: Control) -> String:
	if hud.complete:
		return hud.profile.completed_objective
	if hud.seals < 3:
		return hud.profile.objective
	return hud.profile.exit_objective if hud.key_found else (hud.profile.boss_objective if hud.warden_alive else hud.profile.key_objective)

static func paint(hud: Control) -> void:
	hud.draw_rect(Rect2(0,100,1280,570),Color("080b16df"))
	hud.draw_texture_rect(Pocket.book(),Rect2(152,48,976,624),false)
	hud.text_at(hud.profile.label,Vector2(212,120),Pocket.fit(hud.font,hud.profile.label,12,382),Pocket.MUTED)
	Pocket.paragraph(hud,hud.profile.title,Vector2(212,160),368,26)
	hud.draw_line(Vector2(212,206),Vector2(580,206),Color("9a8866"))
	hud.text_at("STAGE CLEARED" if hud.complete else "CURRENT TASK",Vector2(212,233),12,Pocket.MUTED)
	Pocket.paragraph(hud,task(hud),Vector2(212,263),368,17)
	var stats: Array[String] = ["%02d / %02d COINS" % [hud.coins,hud.total_coins],"%d FOES DEFEATED" % hud.kills,"%d / 2 LOST RELICS" % hud.relics,"%02d:%02d  /  %d RETURNS" % [int(hud.elapsed)/60,int(hud.elapsed)%60,hud.deaths]]
	for i: int in stats.size():
		hud.text_at(stats[i],Vector2(212,326+i*25),14,Pocket.INK)
	hud.text_at("THE ROAD SO FAR",Vector2(212,447),12,Pocket.MUTED)
	Ribbon.load_icons()
	for i: int in Campaign.STAGES:
		var x: float = 212+(i%6)*64
		var y: float = 458+(i/6)*32
		if i%6 < 5:
			hud.draw_line(Vector2(x+14,y+14),Vector2(x+78,y+14),Color("9a8866"),2)
		hud.draw_style_box(Pocket.button_box(Color.WHITE if i+1 == hud.profile.chapter else Color("b3a789")),Rect2(x,y,28,28))
		Pocket.icon(hud,Ribbon.icons[i],Rect2(x+5,y+5,18,18),Color.WHITE if i < hud.profile.chapter else Color("736c64"))
	hud.text_at("CHAPTER %d OF %d  /  %s" % [hud.profile.chapter,Campaign.STAGES,"CLEARED" if hud.complete else "%d%% TRAVELLED" % roundi(clampf(hud.progress,0,1)*100)],Vector2(212,536),13,Pocket.INK)
	if hud.complete and Campaign.results.size() > 1:
		var total: Dictionary = Campaign.totals()
		hud.text_at("JOURNEY  %d COINS / %d RELICS / %d FOES" % [total.coins,total.relics,total.kills],Vector2(212,561),12,Pocket.MUTED)
	else:
		hud.text_at("LANTERN %d / %d ACTIVE" % [hud.checkpoint_index+1,hud.checkpoint_total] if hud.checkpoint_index >= 0 else "Every ten coins restore one heart.",Vector2(212,561),14,Pocket.MUTED)
	Pocket.paragraph(hud,"Keep exploring to collect missed items. Your boss defeat and opened shortcuts stay saved." if hud.complete and hud.allow_exploration else "Checkpoints heal. Collected markers and relics survive a fall.",Vector2(212,584),368,13,Pocket.MUTED)
	var scene: Node = hud.get_tree().current_scene
	if scene != null and scene.get("audio") != null:
		var music: String = "MUSIC  " + scene.audio.now_playing()
		hud.text_at(music,Vector2(212,624),Pocket.fit(hud.font,music,11,380),Pocket.MUTED)
	hud.text_at("JOURNEY COMPLETE" if hud.complete and hud.profile.chapter == Campaign.STAGES else ("NEXT CHAPTER" if hud.complete else "FIELD JOURNAL"),Vector2(696,120),12,Pocket.MUTED)
	Pocket.paragraph(hud,hud.profile.victory if hud.complete else "PAUSED",Vector2(696,151),368,27)
	Pocket.paragraph(hud,hud.profile.victory_text if hud.complete else "Take a breath. The road can wait.",Vector2(696,220),368,16,Pocket.MUTED)
	var hub: Node = hud.controller
	var confirm: String = hub.Bindings.label(JOY_BUTTON_A,hub.style()) if hub.using_pad else "ENTER"
	var back: String = hub.Bindings.label(JOY_BUTTON_B,hub.style()) if hub.using_pad else "ESC"
	hud.text_at(confirm+"  SELECT",Vector2(696,605),13,Pocket.INK)
	var closing: String = "The forest is free. Your journey is complete." if hud.profile.chapter == Campaign.STAGES else "A new road waits beyond this page."
	hud.text_at(back+("  KEEP EXPLORING" if hud.complete and hud.allow_exploration else "  BACK") if not hud.complete or hud.allow_exploration else closing,Vector2(696,627),13,Pocket.MUTED)
