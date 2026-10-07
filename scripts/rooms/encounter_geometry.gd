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
		if point.distance_to(room.to_local(room.combat_target.global_position))<min_player_distance:continue
		if room.obstacles().any(func(rect:Rect2)->bool:return rect.grow(clearance).has_point(point)):continue
		return point
	return Vector2.INF

## 候选和返回值均为Room局部坐标。只接受从origin直线可达的落点；
## 首选被挡时继续有限搜索同侧替代点，不通过瞬移越过实体墙/棺椁。
static func safe_reachable_point(room:Room,preferred:Vector2,origin:Vector2,clearance:float=24,min_player_distance:float=0,exclude_rid:RID=RID())->Vector2:
	var points:Array[Vector2]=[preferred]
	for y in range(208,552,32):
		for x in range(144,1152,32):points.append(Vector2(x,y))
	points.sort_custom(func(a:Vector2,b:Vector2)->bool:return a.distance_squared_to(preferred)<b.distance_squared_to(preferred))
	var excluded:Array[RID]=[]
	if exclude_rid.is_valid():excluded.append(exclude_rid)
	var from_global:=room.to_global(origin)
	var player_local:=room.to_local(room.combat_target.global_position)
	for point in points:
		if not Room.ROOM_RECT.grow(-clearance).has_point(point):continue
		if point.distance_to(player_local)<maxf(40,min_player_distance):continue
		if room.obstacles().any(func(rect:Rect2)->bool:return rect.grow(clearance).has_point(point)):continue
		var occupied:=false
		for actor in room.damage_targets():
			if not (actor is Enemy) or actor.health.is_dead or actor.get_rid()==exclude_rid:continue
			var reserved:=room.to_local(actor.reserved_world_position())
			if reserved.distance_to(point)<48:occupied=true;break
		if occupied:continue
		var ray:=PhysicsRayQueryParameters2D.create(from_global,room.to_global(point),1,excluded)
		if not room.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():continue
		return point
	return Vector2.INF
