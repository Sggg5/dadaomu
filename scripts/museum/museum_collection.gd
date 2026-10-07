class_name MuseumCollection
extends RefCounted
signal changed
var _items: Array[OwnedAntique] = []
var _next_id: int = 1


func add(definition_id: StringName, day: int, condition: int = 100, identified: bool = false) -> OwnedAntique:
	var item := OwnedAntique.new()
	item.instance_id = StringName("A%06d" % _next_id)
	_next_id += 1
	item.definition_id = definition_id
	item.acquired_day = day
	item.condition = clampi(condition,0,100)
	item.identified = identified
	_items.append(item)
	changed.emit()
	return item


func find(instance_id: StringName) -> OwnedAntique:
	for item in _items:
		if item.instance_id == instance_id: return item
	return null


func contains(instance_id: StringName) -> bool: return find(instance_id) != null


func remove(instance_id: StringName) -> bool:
	var item := find(instance_id)
	if item == null: return false
	_items.erase(item)
	changed.emit()
	return true


func all_items() -> Array[OwnedAntique]: return _items.duplicate()


func next_id() -> int: return _next_id


func restore(items: Array[OwnedAntique], next_owned_id: int) -> void:
	_items = items.duplicate()
	_next_id = next_owned_id
	for item in _items:
		_next_id = maxi(_next_id,str(item.instance_id).trim_prefix("A").to_int()+1)
	changed.emit()
