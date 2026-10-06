class_name CombatGeometry
extends RefCounted
## 当前房内瞬时范围/线段攻击；不发 projectile_hit，避免命中递归。
static func targets(room: Room) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if not is_instance_valid(room):
		return result
	for actor in room.enemy_spawner.get_children():
		var health := actor.get_node_or_null("Health") as Health
		if actor is Node2D and health != null and not health.is_dead:
			result.append(actor)
	return result


static func radius(room: Room, center: Vector2, radius_value: float, damage: float) -> int:
	var hits: int = 0
	for actor in targets(room):
		if actor.global_position.distance_to(center) <= radius_value and actor.take_damage(damage):
			hits += 1
	return hits


static func line(room: Room, origin: Vector2, end: Vector2, width: float, damage: float, excluded: Object) -> int:
	var hits: int = 0
	for actor in targets(room):
		if actor != excluded and actor.global_position.distance_to(Geometry2D.get_closest_point_to_segment(actor.global_position, origin, end)) <= width * 0.5:
			if actor.take_damage(damage):
				hits += 1
	return hits
