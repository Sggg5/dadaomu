class_name EncounterGeometry
extends RefCounted
## 本房几何合法点，有限候选，不生成拓扑/不读取全局随机状态。
static func safe_point(room:Room,preferred:Vector2,clearance:float=24,min_player_distance:float=0)->Vector2:
	var points:Array[Vector2]=[preferred]
	for y in range(208,552,32):
		for x in range(144,1152,32):points.append(Vector2(x,y))
	points.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.distance_squared_to(preferred)<b.distance_squared_to(preferred))
	for point in points:
		if not Room.ROOM_RECT.grow(-clearance).has_point(point):continue
		if point.distance_to(room.combat_target.position)<min_player_distance:continue
		if room.definition.obstacles.any(func(rect:Rect2)->bool:return rect.grow(clearance).has_point(point)):continue
		return point
	return Vector2.INF
