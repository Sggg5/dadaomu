class_name DungeonConfig
extends Resource
## 第一版的有限规模约束；相同 Seed、配置、模板顺序和生成版本才能完整复现。

@export_range(4, 12) var min_rooms: int = 8
@export_range(4, 12) var max_rooms: int = 12
@export_range(2, 11) var min_terminal_distance: int = 5
# 旧测试读写接口兼容；生成器只使用terminal语义。
var min_boss_distance: int:
	get: return min_terminal_distance
	set(value): min_terminal_distance = value
@export var terminal_is_boss: bool = true
@export_range(1, 10) var min_antique_distance: int = 2
@export var templates: Array[RoomDefinition] = []


func validation_error() -> String:
	if min_rooms < 4 or max_rooms > 12 or min_rooms > max_rooms:
		return "Room count must satisfy 4 <= min <= max <= 12"
	if min_terminal_distance < 2 or min_terminal_distance >= min_rooms:
		return "Terminal depth must be >= 2 and smaller than minimum room count"
	if min_antique_distance < 1 or min_antique_distance >= min_terminal_distance:
		return "Antique depth must be >= 1 and smaller than reserved spine depth"
	if templates.is_empty():
		return "At least one combat template is required"
	for template in templates:
		if template == null or template.room_type != RoomDefinition.Type.COMBAT:
			return "Templates must be valid combat definitions"
		for entry in template.spawns:
			if entry == null or entry.enemy_scene == null:
				return "Template requires valid spawn records"
	return ""
