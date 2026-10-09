class_name MuseumMilestoneDefinition
extends RefCounted
static var _data:Dictionary={}
static func goals()->Array:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/museum/milestones.json"))
	return _data.goals
static func find(id:String)->Dictionary:
	for goal in goals():
		if goal.id==id:return goal
	return {}
