class_name TombDefinition
extends Resource
## 只负责多层顺序，Session消费此资源；不生成地图或持有运行节点。
@export var id: StringName
@export var display_name: String
@export var floors: Array[TombFloorDefinition] = []

func validation_error() -> String:
	if id == &"" or floors.is_empty(): return "Tomb needs ID and at least one floor"
	for floor in floors:
		if floor == null or not floor.validation_error().is_empty(): return "Invalid tomb floor"
	return ""

func floor_at(number: int) -> TombFloorDefinition:
	return floors[number - 1] if number >= 1 and number <= floors.size() else null
