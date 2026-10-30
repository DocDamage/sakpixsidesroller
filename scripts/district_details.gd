extends "res://scripts/world_details.gd"

func setup(owner_level: Node2D) -> void:
	level = owner_level
	for at: Vector2 in [Vector2(520,600),Vector2(3300,600),Vector2(4700,600),Vector2(7270,1100),Vector2(10600,600),Vector2(15400,600),Vector2(16700,600)]:
		var fire: Sprite2D = preload("res://scripts/upright_campfire.gd").place(self,at.x,at.y,at.x == 3300)
		fires.append(fire)
		level.lighting.add_glow(fire.position+fire.get_meta("emitter_offset"),Color("ffc484"),110,fire,fire.get_meta("emitter_offset"))
	add_actor("Lamplighter","Kneeling knight.png",Vector2(390,600),8,"The quarter has three ways out: the bells above, the water below, and the garden beyond the watchhouse. Tab or LB opens your map.")
	add_actor("Prisoner","Wizard with a map.png",Vector2(4300,1460),6,"The jailer took a moon hook. Defeat him and open the trapdoor back to town. Hold up and Use beneath a hook ring to grapple.")
	add_actor("Pump Keeper","Sitting Witch.png",Vector2(7080,1100),5,"The sluice drains the gallery. It also exposes the old return passage. Swim with the stick; jump gives a stronger upward stroke.")
	add_actor("Lantern Keeper","Sitting Witch.png",Vector2(16620,600),5,"Bring all three seals back to the quarter's ritual circle. The undercroft and prison trapdoor form a return loop; the lantern tram brings you back here.")
	preload("res://scripts/world_motion.gd").install(level,self)
