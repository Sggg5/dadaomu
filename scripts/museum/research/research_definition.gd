class_name ResearchDefinition
extends RefCounted
## Local game-content rules. Does not promote research database review status.
static var _rules:Dictionary={}
static func rules()->Dictionary:
	if _rules.is_empty():_rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/museum/collection_research.json"))
	return _rules
static func topic(definition:AntiqueDefinition)->String:
	if definition.category==&"COIN":return "COINS"
	if "唐" in definition.culture_period:return "TANG"
	if "汉" in definition.culture_period or "魏" in definition.culture_period:return "HAN_WEI"
	return "TYPE_"+str(definition.category) if definition.category!=&"" else "UNKNOWN"
