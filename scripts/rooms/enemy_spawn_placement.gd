class_name EnemySpawnPlacement
extends RefCounted
## 纯空间查询；先解析整波位置，失败不生成部分波次或把怪放入墙内。
var positions:Array[Vector2]=[]
var error:String=""
static func point(obstacles:Array[Rect2],preferred:Vector2,reserved:Array[Vector2],clearance:float=24,spacing:float=48,target:Vector2=Vector2.INF,min_target_distance:float=0)->Vector2:
	var candidates:Array[Vector2]=[preferred]
	for y in range(224,528,24):
		for x in range(160,1160,24):candidates.append(Vector2(x,y))
	candidates.sort_custom(func(a:Vector2,b:Vector2)->bool:
		var da:=a.distance_squared_to(preferred)
		var db:=b.distance_squared_to(preferred)
		return da<db if da!=db else (a.y<b.y if a.y!=b.y else a.x<b.x))
	var entries:Array[Vector2]=[Vector2(640,208),Vector2(1152,368),Vector2(640,528),Vector2(128,368)]
	for candidate in candidates:
		if not Room.ROOM_RECT.grow(-clearance).has_point(candidate):continue
		if obstacles.any(func(rect:Rect2)->bool:return rect.grow(clearance).has_point(candidate)):continue
		if entries.any(func(entry:Vector2)->bool:return entry.distance_to(candidate)<180):continue
		if reserved.any(func(other:Vector2)->bool:return other.distance_to(candidate)<spacing):continue
		if min_target_distance>0 and candidate.distance_to(target)<min_target_distance:continue
		return candidate
	return Vector2.INF
static func build(definition:RoomDefinition,geometry:RoomGeometryDefinition,target:Vector2=Vector2.INF,min_target_distance:float=0)->EnemySpawnPlacement:
	var result:=EnemySpawnPlacement.new()
	for spawn in definition.spawns:
		if spawn==null:result.error="Null enemy spawn";return result
		var candidate:=point(geometry.obstacles,spawn.position,result.positions,24,48,target,min_target_distance)
		if not candidate.is_finite():result.error="No legal spawn for %s #%d"%[definition.room_id,result.positions.size()];return result
		result.positions.append(candidate)
	return result
