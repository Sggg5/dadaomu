class_name RoomGeometryPool
extends Resource
@export var id:StringName
@export var geometries:Array[RoomGeometryDefinition]=[]
func validation_error()->String:
	if id==&"" or geometries.is_empty():return "Geometry pool requires ID and entries"
	var seen:Dictionary={}
	for geometry in geometries:
		if geometry==null or geometry.id==&"" or seen.has(geometry.id) or geometry.selection_weight<1:return "Invalid/duplicate geometry"
		seen[geometry.id]=true
	return ""
