extends RefCounted

static func configure(enemy: Node2D, level: Node2D) -> void:
	enemy.travel_limits = Vector2(enemy.home.x-enemy.patrol-70,enemy.home.x+enemy.patrol+70)
	if enemy.flying:
		return
	var supports: Array[Rect2] = []
	for span: Vector2 in level.profile.builder.FLOORS:
		supports.append(Rect2(span.x,600,span.y-span.x,220))
	for ledge: Rect2 in level.profile.builder.LEDGES:
		supports.append(ledge)
	for support: Rect2 in supports:
		if absf(support.position.y-enemy.home.y) < 2 and enemy.home.x >= support.position.x and enemy.home.x <= support.end.x:
			enemy.support_limits = Vector2(support.position.x+24,support.end.x-24)
			enemy.travel_limits.x = maxf(enemy.travel_limits.x,enemy.support_limits.x)
			enemy.travel_limits.y = minf(enemy.travel_limits.y,enemy.support_limits.y)
			return

static func limit(enemy: Node2D, x: float) -> float:
	return clampf(x,enemy.travel_limits.x,enemy.travel_limits.y)
