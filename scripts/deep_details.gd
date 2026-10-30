extends "res://scripts/world_details.gd"

const Biome = preload("res://scripts/deep_biome.gd")
var drifting: Array[Dictionary] = []
var wisps: Array[Dictionary] = []

func prop(path: String, x: float, size: float = 1.7) -> Sprite2D:
	var visual: Sprite2D = Assets.grounded(self,path,x,size,-3)
	visual.set_meta("dense_prop",true)
	return visual

func setup(owner_level: Node2D) -> void:
	level = owner_level
	var dungeon: bool = level.chapter <= 10
	for x: float in [420.0,2580.0,3800.0]:
		var fire: Sprite2D = preload("res://scripts/upright_campfire.gd").place(self,x)
		fires.append(fire)
		level.lighting.add_glow(fire.position,Color("b8c6ef") if dungeon else Color("b9e6d1"),110,fire)
	var portraits: Array = ["Kneeling knight.png","Evil Wizard.png","Elf Archer.png","Druid.png"]
	var frame_counts: Array = [8,12,12,5]
	add_actor("Gate Watcher" if dungeon else "Trail Guide",portraits[level.chapter-9],Vector2(320,600),frame_counts[level.chapter-9],level.profile.objective.capitalize()+". The high ledges mark the way.")
	add_actor("Archivist" if dungeon else "Grove Keeper","Wizard with a map.png" if dungeon else "Druid.png",Vector2(2200,600),6 if dungeon else 5,"The stone remembers your progress. Use a finisher to break the keeper's charge.")
	add_actor("Vault Keeper" if dungeon else "Star Keeper","Evil Wizard.png" if dungeon else "Elf Archer.png",Vector2(5980,600),12,"Claim the ward after the guardian falls. The open gateway lies ahead.")
	var files: Array = ["carved_stone_tablet.png","cracked_clay_jug.png","coiled_rope.png","stacked_books.png"] if dungeon else ["wooden_bench.png","broken_clay_jug.png","hollow_log.png","moss_covered_stones.png"]
	for i: int in 4:
		var folder: String = Biome.LOOT if dungeon else (Biome.HOMES if i == 0 else Biome.LIFE)
		prop(folder+str(files[i]),[1270.0,2500.0,3900.0,5250.0][i])
	for x: float in [520.0,1370.0,2320.0,2850.0,3720.0,4180.0,5310.0,6340.0]:
		var lamp: Sprite2D = prop(Biome.LOOT+"candelabra.png" if dungeon else Biome.HOMES+"double_lantern_post.png",x,2.0)
		level.lighting.add_glow(lamp.position,Color("a6c3ed") if dungeon else Color("a6e4d6"),80,lamp)
	for x: float in [1490.0,2660.0,4040.0,5290.0,6300.0]:
		var path: String = Biome.CAVE+"mossy_rock_flat.png" if dungeon else Biome.FLORA+("blue_flower_bush.png" if level.chapter == 11 else "pink_mushroom_cluster.png")
		var plant: Sprite2D = Assets.grounded(self,path,x,1.5,-4)
		if not dungeon:
			plant.add_to_group("wind_foliage")
	preload("res://scripts/world_motion.gd").install(level,self)
	if not dungeon:
		for x: float in [950.0,3690.0,6000.0]:
			var butterfly: Sprite2D = Assets.sprite(self,Biome.LIFE+"blue_butterfly.png",Vector2(x,520),0.55,-4)
			butterfly.modulate = Color("c1e8df")
			drifting.append({"visual":butterfly,"home":butterfly.position,"phase":x*0.01})
		for x: float in [1460.0,2870.0,4400.0]:
			var fireflies: Sprite2D = Assets.sprite(self,Biome.LIFE+"fireflies_a.png",Vector2(x,430),1.4,-5)
			fireflies.modulate = Color("b7e8d455")
			drifting.append({"visual":fireflies,"home":fireflies.position,"phase":x*0.01})
		for x: float in [1440.0,2800.0,4230.0]:
			var crystal: Sprite2D = Assets.grounded(self,Biome.SPELL+("cyan_crystal_cluster.png" if level.chapter == 11 else "gold_crystal_cluster.png"),x,1.6,-5)
			crystal.modulate = Color("9dcab9")
			crystal.set_meta("dense_prop",true)
			var wisp: Sprite2D = Assets.sprite(self,Biome.SPELL+"cyan_spirit_wisp.png",Vector2(x,510),0.8,-5)
			wisp.modulate = Color("b8e6d480") if level.chapter == 11 else Color("ffe3af80")
			wisps.append({"visual":wisp,"home":wisp.position,"phase":x*0.01})
			level.lighting.add_glow(wisp.position,Color("85d8c333") if level.chapter == 11 else Color("e9c88133"),70,wisp)

func _process(_delta: float) -> void:
	for entry: Dictionary in drifting:
		entry.visual.position = entry.home+Vector2(sin(clock*0.7+entry.phase)*20,sin(clock*1.2+entry.phase)*10)
	for entry: Dictionary in wisps:
		entry.visual.position = entry.home+Vector2(sin(clock*0.5+entry.phase)*7,sin(clock*1.1+entry.phase)*8)
