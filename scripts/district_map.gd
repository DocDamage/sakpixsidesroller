extends Control

var district: Node2D
var just_opened: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func open_map() -> void:
	show()
	just_opened = true
	district.level.get_tree().paused = true
	district.level.get_node("/root/Controller").flush_gameplay()
	district.level.audio.play("map_open")
	district.map_cooldown = 0.25
	queue_redraw()

func close_map() -> void:
	hide()
	district.level.get_tree().paused = false
	district.map_cooldown = 0.25
	var controller: Node = district.level.get_node("/root/Controller")
	controller.flush_gameplay()
	controller.suppress_until_release = true
	district.level.audio.play("map_open")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if just_opened:
		just_opened = false
		return
	if event.is_action_pressed("district_map") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_level") or event.is_action_pressed("interact") and Input.is_action_pressed("move_down"):
		close_map()
		get_viewport().set_input_as_handled()

func point(at: Vector2) -> Vector2:
	return Vector2(54+at.x/19200*1172,160+(at.y+1100)/3200*410)

func room_label(font: Font, rect: Rect2, title: String) -> void:
	if rect.size.x < 42:
		return
	var rows: Array[String] = []
	var row: String = ""
	for word: String in title.trim_prefix("THE ").split(" "):
		var candidate: String = word if row.is_empty() else row+" "+word
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x > rect.size.x-8:
			if not row.is_empty():
				rows.append(row)
			row = word
		else:
			row = candidate
	if not row.is_empty():
		rows.append(row)
	for i: int in mini(2,rows.size()):
		if font.get_string_size(rows[i],HORIZONTAL_ALIGNMENT_LEFT,-1,9).x <= rect.size.x-8:
			draw_string(font,rect.position+Vector2(4,13+i*12),rows[i],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("d7d7c4"))

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("0c1119f5"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font,Vector2(54,66),"HAUNTED DISTRICT / ROUTES AND SHORTCUTS",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("dfd4b6"))
	draw_string(font,Vector2(54,98),"Explore connected streets, roofs and waterways. Lanterns preserve progress; opened routes remain open after a fall.",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("a4b1bd"))
	draw_string(font,Vector2(54,126),"CURRENT: "+district.region()+"     GOLD: YOU / CYAN: SANCTUARY / VIOLET: SEAL / GREEN: OPEN ROUTE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b2c8cb"))
	for i: int in district.spaces.size():
		var room: Dictionary = district.spaces[i]
		var a: Vector2 = point(room.rect.position)
		var b: Vector2 = point(room.rect.end)
		var discovered: bool = district.visited.has(i)
		var rect := Rect2(a,b-a).grow(-1)
		draw_rect(rect,Color("34505c") if discovered else Color("1b2632"))
		draw_rect(rect,Color("829a9c") if discovered else Color("3b4653"),false,1)
		if discovered:
			room_label(font,rect,room.name)
	for climb: Dictionary in district.climbs:
		draw_line(point(Vector2(climb.x,climb.top)),point(Vector2(climb.x,climb.bottom)),Color("b79867"),2)
	draw_line(point(Vector2(3780,1390)),point(Vector2(16380,1390)),Color("c9ae78") if district.ritual_ready else Color("566371"),1)
	for water: Node2D in district.waters:
		draw_rect(Rect2(point(water.position),point(Vector2(water.position.x+water.width,water.bottom))-point(water.position)),Color("407d9955"))
	if district.level.seals == 3 and not district.ritual_ready:
		draw_arc(point(Vector2(2920,600)),9,0,TAU,24,Color("fff2b2"),2)
	for lantern: Sprite2D in district.level.checkpoints:
		draw_circle(point(lantern.get_meta("feet")),4,Color("86dacb"))
	for item: Dictionary in district.level.items:
		if item.kind == "seal" and not item.taken:
			draw_circle(point(item.position),5,Color("c69be1"))
	for id: String in district.gates:
		var gate: Dictionary = district.gates[id]
		draw_circle(point(gate.rect.get_center()),4,Color("8ed9a6") if district.opened.has(id) else Color("e39e82"))
	draw_circle(point(district.level.player.position),6,Color("fff2b2"))
	draw_string(font,Vector2(54,626),"UP / DOWN: climb and swim    JUMP: dismount / swim stroke    UP + USE: moon hook    TAB / LB: map",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("d4c7a8"))
	var relic_names: PackedStringArray = []
	for id: String in district.upgrades:
		relic_names.append(id.replace("_"," ").capitalize())
	draw_string(font,Vector2(54,660),"RELICS: "+(", ".join(relic_names) if not relic_names.is_empty() else "undiscovered")+"     /     CLOSE: Tab, LB or Back",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("9aadb9"))
