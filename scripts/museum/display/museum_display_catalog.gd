class_name MuseumDisplayCatalog
extends RefCounted
## Read-only configurable layout and game-prototype footprints. Never reads research IDs.
var halls: Dictionary[StringName, ExhibitionHallDefinition] = {}
var units: Dictionary[StringName, DisplayUnitDefinition] = {}
var slots: Dictionary[StringName, DisplaySlot] = {}
var profiles: Dictionary = {}
var repeat_decay: float = .65
var minimum_repeat_factor: float = .15
var visitor_appeal_scale: float = .35
var additional_hall_visitors: int = 2

func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/museum/display_layout.json"))
	profiles = data.profiles
	repeat_decay = data.repeat_decay
	minimum_repeat_factor = data.minimum_repeat_factor
	visitor_appeal_scale = data.visitor_appeal_scale
	additional_hall_visitors = data.additional_hall_visitors
	for row: Dictionary in data.halls:
		var hall := ExhibitionHallDefinition.new()
		hall.id = StringName(row.id)
		hall.display_name = row.name
		hall.unlock_level = row.unlock_level
		halls[hall.id] = hall
	for row: Dictionary in data.units:
		var unit := DisplayUnitDefinition.new()
		unit.id = StringName(row.id)
		unit.hall_id = StringName(row.hall_id)
		unit.display_name = row.name
		unit.kind = row.kind
		unit.capacity = row.capacity
		unit.categories = row.categories
		unit.max_size_cm = Vector3(row.max_size_cm[0],row.max_size_cm[1],row.max_size_cm[2])
		unit.position = Vector2(row.position[0],row.position[1])
		unit.unlock_level = row.unlock_level
		unit.legacy_first_slot = row.get("legacy_first_slot",false)
		assert(unit.capacity > 0 and unit.capacity <= 64 and halls.has(unit.hall_id))
		units[unit.id] = unit
		halls[unit.hall_id].unit_ids.append(unit.id)
		for slot in unit.slots():
			assert(not slots.has(slot.id))
			slots[slot.id] = slot

func unit_ids(level: int, hall: StringName = &"") -> Array[StringName]:
	var result: Array[StringName] = []
	for id in units:
		if units[id].unlock_level <= level and (hall == &"" or units[id].hall_id == hall): result.append(id)
	result.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	return result

func hall_ids(level: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for id in halls:
		if halls[id].unlock_level <= level: result.append(id)
	result.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	return result

func accepts(unit: DisplayUnitDefinition, profile: Dictionary) -> bool:
	# Unknown size is NOT an estimate derived from inventory slots or specimen name.
	if profile.is_empty() or profile.get("category") not in unit.categories or not profile.get("size_cm") is Array or profile.size_cm.size() != 3: return false
	if profile.get("category")=="LARGE_FOSSIL": return false # no specimen transport entitlement
	if profile.get("transport") != "HAND_CARRY": return false # no large transport system yet
	for index in range(3):
		var size: Variant = profile.size_cm[index]
		if not (size is int or size is float) or not is_finite(size) or size <= 0 or size > unit.max_size_cm[index]: return false
	return true
