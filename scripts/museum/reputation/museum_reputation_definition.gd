class_name MuseumReputationDefinition
extends RefCounted
## Fictional operating titles, independent of building level and economic formulas.
static var _rules:Dictionary={}
static func rules()->Dictionary:
	if _rules.is_empty():_rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/museum/reputation.json"))
	return _rules
