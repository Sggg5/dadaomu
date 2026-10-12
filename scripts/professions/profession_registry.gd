class_name ProfessionRegistry
extends RefCounted
## DRAFT tuning is independent of relic, antique and profile schemas.
static var _definitions: Dictionary = {}
static func definition(id: StringName) -> Dictionary:
	if _definitions.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/professions/draft_professions.json"))
		for row in data.definitions: _definitions[StringName(row.id)] = row
	return _definitions.get(id, {}).duplicate(true)
static func display_name(id: StringName) -> String:
	return str(definition(id).get("name", "无门派"))
static func token_name(id: StringName) -> String:
	return str(definition(id).get("token", "无信物"))
