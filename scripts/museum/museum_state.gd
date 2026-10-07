class_name MuseumState
extends RefCounted
## 只在本程序周期内存活。展柜按馆藏实例ID归属，收入只来自一次售票。
enum Phase { MORNING, OPEN, EVENING, NIGHT }
const CASE_IDS: Array[StringName] = [&"CASE_1", &"CASE_2", &"CASE_3"]
const POOL: AntiquePool = preload("res://data/antiques/formal_pool.tres")
signal changed
var day_number: int = 1
var cash: int = 0
var phase: Phase = Phase.MORNING
var collection := MuseumCollection.new()
var display_assignments: Dictionary[StringName, StringName] = {}
var last_day_visitors: int = 0
var last_day_ticket_income: int = 0


func case_for(instance_id: StringName) -> StringName:
	for id in display_assignments:
		if display_assignments[id] == instance_id: return id
	return &""


func can_edit() -> bool: return phase in [Phase.MORNING, Phase.EVENING]


func assign(case_id: StringName, instance_id: StringName) -> bool:
	if not can_edit() or case_id not in CASE_IDS or not collection.contains(instance_id): return false
	if case_for(instance_id) != &"" and case_for(instance_id) != case_id: return false
	display_assignments[case_id] = instance_id
	changed.emit()
	return true


func unassign(case_id: StringName) -> bool:
	if not can_edit() or not display_assignments.has(case_id): return false
	display_assignments.erase(case_id)
	changed.emit()
	return true


func definition_for(case_id: StringName) -> AntiqueDefinition:
	var item := collection.find(display_assignments.get(case_id, &""))
	return POOL.find_by_id(item.definition_id) if item != null else null


func total_appeal() -> int:
	var appeal: int = 0
	for id in CASE_IDS:
		var definition := definition_for(id)
		if definition != null: appeal += definition.exhibit_appeal
	return appeal
