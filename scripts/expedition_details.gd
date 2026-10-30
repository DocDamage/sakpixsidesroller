extends "res://scripts/world_details.gd"

const DARK_PACK: String = "res://Stages/Dark Fantasy/"
const FOREST: String = "res://Stages/Abandonded Forest/"
var plants: Array[Sprite2D] = []

func place_prop(path: String, x: float, scale: float = 1.8) -> Sprite2D:
	var visual: Sprite2D = Assets.grounded(self,path,x,scale,-3)
	visual.set_meta("dense_prop",true)
	return visual

func setup(owner_level: Node2D) -> void:
	level = owner_level
	var woods: bool = level.chapter >= 7
	for x: float in [420.0,2580.0,3800.0]:
		var fire: Sprite2D = preload("res://scripts/upright_campfire.gd").place(self,x)
		fires.append(fire)
		level.lighting.add_glow(fire.position,Color("bcabd9") if level.chapter == 6 else Color("ffcc92"),115,fire)
	var guide: String = "Druid.png" if woods else ("Kneeling knight.png" if level.chapter == 5 else "Bishop.png")
	add_actor("Trail Guide" if woods else "Gate Watcher",guide,Vector2(320,600),5 if guide != "Kneeling knight.png" else 8,level.profile.objective.capitalize()+". The high ledges mark the way.")
	add_actor("Ranger" if woods else "Wounded Knight","Elf Archer.png" if woods else "Wounded knight.png",Vector2(2200,600),12,"Finish your combo to break a charge. Reflected orbs can clear the path.")
	add_actor("Root Keeper" if woods else "Archivist","Druid.png" if woods else "Evil Wizard.png",Vector2(5980,600),5 if woods else 12,"Claim the ward after the guardian falls. The gate lies just ahead.")
	var objects: Array = ["bedroll.png","firewood_bundle.png","cooking_pot.png","hiking_backpack.png","wooden_bench.png"] if woods else ["hooded_statue.png","stacked_books.png","spilled_barrel.png","rock_pile.png","candelabra_three.png"]
	var folder: String = FOREST+"9. Forgotten Campsites, Lost Objects & Woodland Props/" if woods else DARK_PACK+"4. Background Decorations/"
	for i: int in range(objects.size()):
		if i == 0:
			continue # The shared arrival gateway needs a clear threshold.
		place_prop(folder+str(objects[i]),[130.0,1270.0,2500.0,3900.0,5250.0][i],1.7)
	for x: float in [520.0,1370.0,2320.0,2850.0,3720.0,4180.0,5310.0,6340.0]:
		var path: String = FOREST+"5. Abandoned Trails, Wooden Bridges & Forest Traversal/lamp_post.png" if woods else DARK_PACK+"4. Background Decorations/candelabra_three.png"
		var lamp: Sprite2D = place_prop(path,x,2.0)
		level.lighting.add_glow(lamp.position,Color("d0d8a2") if woods else Color("ddb5d1"),88,lamp)
	for x: float in [1490.0,2660.0,4040.0,5290.0,6300.0]:
		var path: String = FOREST+"8. Dead Vegetation, Fungi & Forest Overgrowth/fern.png" if woods else DARK_PACK+"5. Trees & Nature/dry_grass_tuft.png"
		plants.append(Assets.grounded(self,path,x,1.6,-4))
	preload("res://scripts/world_motion.gd").install(level,self)
	for plant: Sprite2D in plants:
		plant.material = level.get_node("WorldMotion").breeze
