class_name MuseumState
extends RefCounted
## 纯地面状态；展柜按馆藏实例ID归属。存档编解码由ProfileStore承担。
enum Phase { MORNING, OPEN, EVENING, NIGHT }
const LEVELS: MuseumLevels = preload("res://data/museum/levels.tres")
const POOL: AntiquePool = preload("res://data/antiques/formal_pool.tres")
signal changed
var day_number: int = 1
var cash: int = 0
var museum_level: int = 0
var phase: Phase = Phase.MORNING
var collection := MuseumCollection.new()
var display_assignments: Dictionary[StringName, StringName] = {}
var last_day_visitors: int = 0
var last_day_ticket_income: int = 0


func level_definition() -> MuseumLevelDefinition: return LEVELS.at(museum_level)


func case_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for index in range(level_definition().case_count): ids.append(StringName("CASE_%d" % (index+1)))
	return ids


func upgrade(expected_level: int) -> bool:
	# 调用携带打开建设牌时的等级：同一旧请求重复执行不可能再次扣款。
	if expected_level != museum_level or not can_edit() or museum_level >= LEVELS.highest_level(): return false
	var cost := level_definition().upgrade_cost
	if cash < cost: return false
	cash -= cost
	museum_level += 1
	changed.emit()
	return true


func case_for(instance_id: StringName) -> StringName:
	for id in display_assignments:
		if display_assignments[id] == instance_id: return id
	return &""


func can_edit() -> bool: return phase in [Phase.MORNING, Phase.EVENING]


func assign(case_id: StringName, instance_id: StringName) -> bool:
	if not can_edit() or case_id not in case_ids() or not collection.contains(instance_id): return false
	if not collection.find(instance_id).identified: return false
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
	for id in case_ids():
		appeal += appeal_for(display_assignments.get(id,&""))
	return appeal


func appeal_for(instance_id: StringName) -> int:
	var item := collection.find(instance_id)
	if item == null or not item.identified: return 0
	var definition := POOL.find_by_id(item.definition_id)
	return maxi(1,roundi(definition.exhibit_appeal*item.condition/100.0)) if definition != null else 0


func identify(instance_id: StringName) -> bool:
	var item := collection.find(instance_id)
	if not can_edit() or item == null or item.identified: return false
	item.identified = true
	changed.emit()
	return true


func restoration_cost(instance_id: StringName) -> int:
	var item := collection.find(instance_id)
	if item == null or not item.identified or item.condition >= 100: return 0
	var definition := POOL.find_by_id(item.definition_id)
	if definition == null: return 0
	var unit_cost: int = [20,40,60,100][definition.rarity]
	return ceili((100-item.condition)/10.0)*unit_cost


func repair(instance_id: StringName) -> bool:
	var cost := restoration_cost(instance_id)
	if not can_edit() or cost <= 0 or cash < cost: return false
	# 原子事务后通知存档/UI；满品相再次调用拒绝，不产生半完成状态。
	cash -= cost
	collection.find(instance_id).condition = 100
	changed.emit()
	return true
