class_name EncounterDifficulty
extends RefCounted
## 房间深度解析成只读运行上下文；不修改共享 EnemyDefinition。
var depth: int = 0
var tier: int = 1
var hp_multiplier: float = 1.0
var damage_multiplier: float = 1.0


static func from_depth(value: int) -> EncounterDifficulty:
	var result := EncounterDifficulty.new()
	result.depth = value
	if value >= 5:
		result.tier = 3
		result.hp_multiplier = 1.30
		result.damage_multiplier = 1.20
	elif value >= 3:
		result.tier = 2
		result.hp_multiplier = 1.15
		result.damage_multiplier = 1.10
	return result
