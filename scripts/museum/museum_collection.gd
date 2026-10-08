class_name MuseumCollection
extends RefCounted
const DEFINITIONS: AntiquePool = preload("res://data/antiques/playtest_catalog_50.tres")
signal changed
var _items: Array[OwnedAntique] = []
var _by_id: Dictionary[StringName,OwnedAntique] = {}
var _next_id: int = 1


func add(definition_id: StringName, day: int, condition: int = 100, identified: bool = false) -> OwnedAntique:
	if DEFINITIONS.find_by_id(definition_id)==null:return null
	var item := OwnedAntique.new()
	item.instance_id = StringName("A%06d" % _next_id)
	_next_id += 1
	item.definition_id = definition_id
	item.acquired_day = day
	item.condition = clampi(condition,0,100)
	item.identified = identified
	_items.append(item)
	_by_id[item.instance_id] = item
	changed.emit()
	return item


func find(instance_id: StringName) -> OwnedAntique:
	return _by_id.get(instance_id)


func contains(instance_id: StringName) -> bool: return find(instance_id) != null


func remove(instance_id: StringName) -> bool:
	var item := find(instance_id)
	if item == null: return false
	_items.erase(item)
	_by_id.erase(instance_id)
	changed.emit()
	return true


func all_items() -> Array[OwnedAntique]: return _items.duplicate()


func next_id() -> int: return _next_id


func restore(items: Array[OwnedAntique], next_owned_id: int) -> void:
	_items = items.duplicate()
	_by_id.clear()
	for item in _items: _by_id[item.instance_id] = item
	_next_id = next_owned_id
	for item in _items:
		_next_id = maxi(_next_id,str(item.instance_id).trim_prefix("A").to_int()+1)
	changed.emit()
