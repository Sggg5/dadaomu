class_name DungeonConfig
extends Resource
## 第一版的有限规模约束；相同 Seed、配置、模板顺序和生成版本才能完整复现。

@export_range(8, 12) var min_rooms: int = 8
@export_range(8, 12) var max_rooms: int = 12
@export_range(5, 11) var min_boss_distance: int = 5
@export_range(2, 10) var min_antique_distance: int = 2
@export var templates: Array[RoomDefinition] = []


func validation_error() -> String:
	if min_rooms < 8 or max_rooms > 12 or min_rooms > max_rooms:
		return "Room count must satisfy 8 <= min <= max <= 12"
	if min_boss_distance < 5 or min_boss_distance >= min_rooms:
		return "Boss depth must be >= 5 and smaller than minimum room count"
	if min_antique_distance < 2 or min_antique_distance >= min_boss_distance:
		return "Antique depth must be >= 2 and smaller than reserved spine depth"
	if templates.is_empty():
		return "At least one combat template is required"
	for template in templates:
		if template == null or template.room_type != RoomDefinition.Type.COMBAT:
			return "Templates must be valid combat definitions"
		for entry in template.spawns:
			if entry == null or entry.enemy_scene == null:
				return "Template requires valid spawn records"
	return ""
