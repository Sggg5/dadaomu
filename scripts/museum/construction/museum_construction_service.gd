class_name MuseumConstructionService
extends RefCounted
## Configuration, quoted atomic purchases and operating effects, independent from UI.
static var _rules:Dictionary={}
static func rules()->Dictionary:
	if _rules.is_empty():_rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/museum/facilities.json"))
	return _rules
static func definitions(state:MuseumState)->Dictionary[StringName,MuseumFacilityDefinition]:
	var result:Dictionary[StringName,MuseumFacilityDefinition]={}
	for unit_id in state.display_catalog.units:
		var unit:DisplayUnitDefinition=state.display_catalog.units[unit_id]
		for row:Dictionary in rules().unit_types:
			var definition:=_definition(row)
			definition.id=StringName(str(unit_id)+":"+row.kind)
			definition.unit_id=unit_id
			definition.hall_id=unit.hall_id
			definition.unlock_level=unit.unlock_level
			definition.display_name=unit.display_name+" ["+str(unit_id)+"] / "+row.name
			result[definition.id]=definition
	for row:Dictionary in rules().public:
		var definition:=_definition(row)
		definition.id=StringName(row.id)
		definition.hall_id=StringName(row.hall)
		definition.unlock_level=row.unlock
		result[definition.id]=definition
	return result
static func _definition(row:Dictionary)->MuseumFacilityDefinition:
	var definition:=MuseumFacilityDefinition.new()
	definition.kind=StringName(row.kind)
	definition.display_name=row.name
	definition.costs=row.costs
	definition.maintenance=row.maintenance
	definition.max_level=row.costs.size()
	definition.interest_per_level=row.get("interest_per_level",0.0)
	return definition
static func find(state:MuseumState,id:StringName)->MuseumFacilityDefinition:return definitions(state).get(id)
static func quote(state:MuseumState,id:StringName)->MuseumFacilityUpgrade:
	var definition:=find(state,id)
	if definition==null or state.facilities.level(id)>=definition.max_level:return null
	var request:=MuseumFacilityUpgrade.new()
	request.facility_id=id
	request.expected_level=state.facilities.level(id)
	request.target_level=request.expected_level+1
	request.price=int(definition.costs[request.expected_level])
	return request
static func rejection(state:MuseumState,request:MuseumFacilityUpgrade)->String:
	if request==null:return "已达最高等级或设施不存在"
	var definition:=find(state,request.facility_id)
	if definition==null:return "未知设施"
	if request.consumed or request.expected_level!=state.facilities.level(request.facility_id):return "请求已执行或等级已变化，请重新查看"
	if not state.can_edit():return "营业或远征期间不能建设"
	if definition.unlock_level>state.museum_level or state.display_catalog.halls[definition.hall_id].unlock_level>state.museum_level:return "馆舍 / 展厅尚未解锁"
	if request.target_level!=request.expected_level+1 or request.target_level>definition.max_level or request.price!=int(definition.costs[request.expected_level]):return "升级报价不一致"
	if state.cash<request.price:return "资金不足"
	return ""
static func purchase(state:MuseumState,request:MuseumFacilityUpgrade)->bool:
	if not rejection(state,request).is_empty():return false
	state.cash-=request.price
	state.facilities.levels[request.facility_id]=request.target_level
	state.facilities.record(state.day_number,"FACILITY_UPGRADE",str(request.facility_id),request.price,request.expected_level,request.target_level)
	request.consumed=true
	state.changed.emit()
	return true
static func unit_level(state:MuseumState,unit:StringName,kind:StringName)->int:return state.facilities.level(StringName(str(unit)+":"+str(kind)))
static func unit_bonus(state:MuseumState,unit:StringName)->float:
	var value:=0.0
	for row:Dictionary in rules().unit_types:value+=unit_level(state,unit,StringName(row.kind))*float(row.interest_per_level)
	return minf(float(rules().unit_bonus_cap),value)
static func unit_interest(state:MuseumState,unit:StringName)->int:return roundi(state.unit_appeal(unit)*(1.0+unit_bonus(state,unit)))
static func bonus_appeal(state:MuseumState)->int:
	var total:=0
	for id in state.display_catalog.unit_ids(state.museum_level):total+=unit_interest(state,id)-state.unit_appeal(id)
	return mini(floori(state.total_appeal()*float(rules().museum_bonus_cap)),total)
static func maintenance_due(state:MuseumState)->int:
	var total:=0
	var catalog:=definitions(state)
	for id in state.facilities.levels:
		var level:=state.facilities.level(id)
		if level>0 and catalog.has(id):total+=int(catalog[id].maintenance[level-1])
	return total
static func capital_today(state:MuseumState)->int:
	var total:=0
	for row in state.facilities.expenses:
		if row.day_number==state.day_number and row.kind in ["FACILITY_UPGRADE","HALL_EXPANSION"]:total+=int(row.amount)
	return total

static func public_id(kind:StringName)->StringName:
	for row:Dictionary in rules().public:
		if row.kind==str(kind):return StringName(row.id)
	return &""
static func public_position(kind:StringName)->Vector2:
	for row:Dictionary in rules().public:
		if row.kind==str(kind):return Vector2(row.position[0],row.position[1])
	return Vector2.ZERO
