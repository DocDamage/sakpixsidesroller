extends RefCounted

const Pocket = preload("res://scripts/pocket_ui.gd")
const Assets = preload("res://scripts/level_assets.gd")
const Journal = preload("res://scripts/journey_journal.gd")
const Campaign = preload("res://scripts/campaign_state.gd")
const PANEL := Color("383c4d")

static func paint(hud: Control) -> void:
	if hud.allow_exploration and not hud.paused and not hud.complete:
		compact_district(hud)
		caption(hud)
		announcements(hud)
		return
	hud.draw_rect(Rect2(0,0,1280,100),Color("0c0e1bf2"))
	for panel: Rect2 in [Rect2(24,8,394,86),Rect2(430,8,248,86),Rect2(690,8,348,86),Rect2(1050,8,206,86)]:
		hud.draw_style_box(Pocket.frame(PANEL),panel)
	hud.text_at(hud.profile.label,Vector2(52,29),12,Color("c4a377"))
	hud.text_at(hud.profile.title,Vector2(50,61),Pocket.fit(hud.font,hud.profile.title,27,350),Pocket.LIGHT)
	hud.text_at(hud.region,Vector2(52,82),11,Color("b2a7be"))
	var objective: String = Journal.task(hud)
	hud.text_at(objective,Vector2(458,30),Pocket.fit(hud.font,objective,12,192),Color("c3b9cd"))
	for i: int in range(3):
		var rect := Rect2(458+i*40,42,30,32)
		hud.draw_style_box(Pocket.button_box(Color("a89979") if i < hud.seals else Color("555462")),rect)
		Pocket.icon(hud,Assets.texture(hud.profile.seal_texture),rect.grow(-4),Color.WHITE if i < hud.seals else Color("64606f"))
	hud.text_at("%d / 3" % hud.seals,Vector2(594,66),19,Pocket.LIGHT)
	var key: String = hud.profile.key_label+"  "+(hud.profile.key_open if hud.key_found else hud.profile.key_locked)
	hud.text_at(key,Vector2(718,31),Pocket.fit(hud.font,key,12,298),Color("e3c78c") if hud.key_found else Color("b2a7be"))
	Pocket.icon(hud,Pocket.cropped("icons/9.png"),Rect2(718,43,16,16))
	hud.text_at(hud.profile.coin_label+"  %02d / %02d" % [hud.coins,hud.total_coins],Vector2(744,57),12)
	var direction: String = (hud.profile.destination_label+"  /  "+hud.profile.destination_state) if hud.complete else "NEXT "+hud.goal_name+"  /  "+hud.goal_direction
	hud.text_at(direction,Vector2(718,80),Pocket.fit(hud.font,direction,11,298),Color("d8b9f2"))
	hud.text_at("VITALITY",Vector2(1078,30),11,Color("c3b9cd"))
	for i: int in range(5):
		Pocket.icon(hud,Pocket.cropped("icons/7.png"),Rect2(1078+i*30,39,24,22),Color.WHITE if i < hud.health else Color("554855"))
	hud.text_at("DASH READY" if hud.dash_ready else "DASH",Vector2(1078,81),10,Color("b6e3d5") if hud.dash_ready else Color("a79eb3"))
	Pocket.bar(hud,Rect2(1153,70,85,12),hud.dash_charge)
	if hud.arrival_time > 0 and not hud.paused and not hud.complete:
		hud.draw_rect(Rect2(0,100,1280,570),Color(0.03,0.04,0.07,smoothstep(0,0.28,hud.arrival_time)))
	footer(hud)
	caption(hud)
	announcements(hud)
	if hud.damage_flash > 0.0:
		for rect: Rect2 in [Rect2(0,100,1280,8),Rect2(0,662,1280,8),Rect2(0,100,8,570),Rect2(1272,100,8,570)]:
			hud.draw_rect(rect,Color(0.9,0.4,0.4,hud.damage_flash*3))
	if hud.paused or hud.complete:
		Journal.paint(hud)

static func compact_district(hud: Control) -> void:
	# Keep health and objectives in the corners; the tower and landings need view.
	hud.draw_style_box(Pocket.frame(PANEL),Rect2(18,12,248,54))
	for i: int in 5:
		Pocket.icon(hud,Pocket.cropped("icons/7.png"),Rect2(32+i*29,23,23,22),Color.WHITE if i < hud.health else Color("554855"))
	Pocket.bar(hud,Rect2(187,28,60,10),hud.dash_charge)
	hud.text_at("DASH",Vector2(188,52),9,Color("b6e3d5"))
	hud.draw_style_box(Pocket.frame(PANEL),Rect2(910,12,352,66))
	var objective: String = Journal.task(hud)
	hud.text_at(objective,Vector2(930,35),Pocket.fit(hud.font,objective,12,310),Color("d8cba9"))
	for i: int in 3:
		Pocket.icon(hud,Assets.texture(hud.profile.seal_texture),Rect2(932+i*26,44,21,22),Color.WHITE if i < hud.seals else Color("64606f"))
	hud.text_at("%d / 3   COINS %02d" % [hud.seals,hud.coins],Vector2(1020,61),12)
	var hint: String = hud.controller.prompt("pause_level")+" JOURNAL / CONTROLS"
	hud.text_at(hint,Vector2(20,704),10,Color("b6abc6"))
	if hud.damage_flash > 0:
		hud.draw_rect(Rect2(0,0,1280,6),Color(0.9,0.4,0.4,hud.damage_flash*3))

static func footer(hud: Control) -> void:
	hud.draw_rect(Rect2(0,670,1280,50),Color("0c0e1bf5"))
	var controls: String = "SELECT REPLAY OR CONTINUE IN THE JOURNAL" if hud.complete else hud.controller.footer()
	if hud.complete and hud.allow_exploration:
		controls = "KEEP EXPLORING / CONTINUE TO THE NEXT STAGE IN THE JOURNAL"
	if hud.complete and hud.profile.chapter == Campaign.STAGES:
		controls = "JOURNEY COMPLETE / SELECT REPLAY OR RETURN IN THE JOURNAL"
	hud.text_at(controls,Vector2(32,689),Pocket.fit(hud.font,controls,11,754,9))
	if not hud.complete:
		var special: String = hud.controller.special_footer()
		hud.text_at(special,Vector2(32,710),Pocket.fit(hud.font,special,10,754,9),Color("b6abc6"))
	preload("res://scripts/stage_ribbon.gd").paint(hud)
	var help: String = hud.controller.Bindings.label(JOY_BUTTON_BACK,hud.controller.style()) if hud.controller.using_pad else "F1"
	var hint: String = hud.controller.prompt("pause_level")+" JOURNAL  "+help+" CONTROLS"
	hud.text_at(hint,Vector2(1010,710),Pocket.fit(hud.font,hint,10,238,9),Color("b6abc6"))
	hud.draw_rect(Rect2(32,657,1216,3),Color("463853"))
	hud.draw_rect(Rect2(32,657,1216*clampf(hud.progress,0,1),3),Color("d5a77d"))
	for i: int in hud.profile.checkpoints.size():
		var x: float = hud.profile.checkpoints[i]
		hud.draw_circle(Vector2(32+x/hud.stage_width*1216,658),4,Color("b6efcf") if i <= hud.checkpoint_index else Color("af9bbf"))

static func caption(hud: Control) -> void:
	var value: String = hud.prompt if not hud.prompt.is_empty() else (hud.notice if hud.notice_time > 0.0 else hud.talk_prompt)
	if value.is_empty() or hud.paused or hud.complete:
		return
	value = hud.controller.caption(value)
	var rows: PackedStringArray = Pocket.lines(hud.font,value,16,1000)
	var width: float = 0
	for row: String in rows:
		width = maxf(width,hud.font.get_string_size(row,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x)
	var height: float = rows.size()*23+20
	var top: float = (690 if hud.allow_exploration else 645)-height
	hud.draw_style_box(Pocket.frame(PANEL),Rect2(608-width/2,top,width+64,height))
	Pocket.paragraph(hud,value,Vector2(640-width/2,top+26),width+1,16,Pocket.LIGHT)

static func announcements(hud: Control) -> void:
	if hud.paused or hud.complete:
		return
	if hud.intro_time > 0:
		var alpha: float = minf(hud.intro_time,1)
		hud.draw_style_box(Pocket.frame(Color(0.22,0.24,0.30,alpha)),Rect2(32,132,476,130))
		hud.text_at(hud.profile.intro_tag,Vector2(64,162),Pocket.fit(hud.font,hud.profile.intro_tag,12,412),Color(0.8,0.65,0.92,alpha))
		hud.text_at(hud.profile.intro_title,Vector2(64,197),Pocket.fit(hud.font,hud.profile.intro_title,27,412),Color(0.96,0.9,0.8,alpha))
		hud.text_at(hud.profile.intro_text,Vector2(64,234),Pocket.fit(hud.font,hud.profile.intro_text,15,412),Color(0.82,0.79,0.87,alpha))
	elif hud.region_time > 0 and not hud.boss_visible:
		var alpha: float = minf(hud.region_time,1)
		var width: float = hud.font.get_string_size(hud.region,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
		hud.draw_style_box(Pocket.frame(Color(0.22,0.24,0.30,alpha)),Rect2(604-width/2,135,width+72,53))
		hud.text_at(hud.region,Vector2(640-width/2,169),22,Color(0.85,0.77,0.95,alpha))
	if hud.boss_visible:
		hud.draw_style_box(Pocket.frame(PANEL),Rect2(358,104,564,72))
		hud.text_at(hud.profile.boss_name+("  /  ENRAGED" if hud.boss_enraged else ""),Vector2(390,127),13,Color("edbb9b"))
		hud.text_at("%d / %d" % [hud.boss_health,hud.boss_max_health],Vector2(846,127),12,Pocket.LIGHT)
		Pocket.bar(hud,Rect2(390,135,500,12),float(hud.boss_health)/maxi(1,hud.boss_max_health),"13" if hud.boss_enraged else "1",hud.boss_damage_trail/maxi(1,hud.boss_max_health))
		for i: int in range(1,hud.boss_max_health):
			var x: float = 390+500.0*i/hud.boss_max_health
			hud.draw_line(Vector2(x,137),Vector2(x,145),Color("2b273e70"),1)
		var hint: String = "GUARD BROKEN  /  "+hud.controller.prompt("attack")+" KEEP THE COMBO GOING" if hud.boss_staggered else hud.profile.boss_hint
		hud.text_at(hint,Vector2(390,163),Pocket.fit(hud.font,hint,12,500),Color("b8e8d1") if hud.boss_staggered else Color("d4c9df"))
	if hud.combo_hits >= 2:
		hud.text_at("%d HITS" % hud.combo_hits,Vector2(32,125),17,Color("e0bd91"))
	if hud.relics > 0:
		hud.text_at("LOST RELICS  %d / 2" % hud.relics,Vector2(32,149),12,Color("d9b47c"))
