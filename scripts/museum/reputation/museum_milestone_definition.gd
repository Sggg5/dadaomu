class_name MuseumMilestoneDefinition
extends RefCounted
static var _data:Dictionary={}
static func rules()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/museum/milestones.json"))
	return _data
static func goals()->Array:return rules().goals
static func find(id:String)->Dictionary:
	for goal in goals():
		if goal.id==id:return goal
	return {}
