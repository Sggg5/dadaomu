class_name DisplayUnitDefinition
extends RefCounted
var id: StringName
var hall_id: StringName
var display_name: String
var kind: String
var capacity: int
var categories: Array = []
var max_size_cm: Vector3
var position: Vector2
var unlock_level: int
var legacy_first_slot: bool = false

func slots() -> Array[DisplaySlot]:
	var result: Array[DisplaySlot] = []
	for index in range(capacity):
		var slot := DisplaySlot.new()
		slot.id = id if index == 0 and legacy_first_slot else StringName("%s/%02d" % [id,index+1])
		slot.hall_id = hall_id
		slot.unit_id = id
		slot.index = index
		result.append(slot)
	return result
