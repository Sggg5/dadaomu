class_name BossArenaPool
extends RoomGeometryPool
func validation_error()->String:
	var error:=super.validation_error()
	if not error.is_empty():return error
	for geometry in geometries:
		if not (geometry is BossArenaDefinition):return "Boss pool requires Arena definitions"
		if &"CENTRAL_BIG" in geometry.tags or geometry.obstacles.any(func(rect:Rect2)->bool:return rect.intersects(Rect2(500,270,280,200))):return "Central Boss obstacle forbidden"
	return ""
func compatible(boss:BossDefinition)->Array[RoomGeometryDefinition]:
	var result:Array[RoomGeometryDefinition]=[]
	for geometry in geometries:
		if geometry is BossArenaDefinition and geometry.tags.any(func(tag:StringName)->bool:return tag in boss.compatible_arena_tags):result.append(geometry)
	return result
