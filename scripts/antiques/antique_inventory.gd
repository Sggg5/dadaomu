class_name AntiqueInventory
extends RefCounted
## 本Run独立背包；允许重复古董，只持定义引用，items返回数组副本。
signal changed
var capacity: int = 8
var _items: Array[AntiqueDefinition] = []


func _init(limit: int = 8) -> void: capacity = maxi(0,limit)


func used_slots() -> int:
	var total: int = 0
	for item in _items: total += item.slots
	return total


func free_slots() -> int: return capacity-used_slots()


func can_add(definition: AntiqueDefinition) -> bool:
	return definition != null and definition.is_valid() and definition.slots <= free_slots()


func add(definition: AntiqueDefinition) -> bool:
	if not can_add(definition): return false
	_items.append(definition)
	changed.emit()
	return true


func remove(id: StringName) -> bool:
	for index in range(_items.size()):
		if _items[index].id == id: return remove_at(index)
	return false


func remove_at(index: int) -> bool:
	if index < 0 or index >= _items.size(): return false
	_items.remove_at(index)
	changed.emit()
	return true


func total_value() -> int:
	var total: int = 0
	for item in _items: total += item.base_value
	return total


func clear() -> void:
	if _items.is_empty(): return
	_items.clear()
	changed.emit()


func items() -> Array[AntiqueDefinition]: return _items.duplicate()
