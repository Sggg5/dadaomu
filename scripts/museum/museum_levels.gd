class_name MuseumLevels
extends Resource
@export var levels: Array[MuseumLevelDefinition] = []


func at(level: int) -> MuseumLevelDefinition:
	return levels[level] if level >= 0 and level < levels.size() else null


func highest_level() -> int: return levels.size()-1
