class_name ExhibitionService
extends RefCounted
## Pure re-evaluation of lawful owned displays; never creates collection or moves slots.
static var _data: Dictionary = {}
static func data()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://data/museum/exhibitions.json"))
	return _data
static func definitions()->Array[ExhibitionDefinition]:
	var result:Array[ExhibitionDefinition]=[]
	for row:Dictionary in data().topics:
		var topic:=ExhibitionDefinition.new()
		topic.id=StringName(row.id)
		topic.display_name=row.name
		topic.rules=row
		result.append(topic)
	return result
static func find(id:StringName)->ExhibitionDefinition:
	for topic in definitions():
		if topic.id==id:return topic
	return null
static func metadata(definition:AntiqueDefinition)->Dictionary:
	if data().legacy_metadata.has(str(definition.id)):return data().legacy_metadata[str(definition.id)]
	return {"category":str(definition.category),"year_min":definition.prototype_year_start,"year_max":definition.prototype_year_end}
static func matches(definition:AntiqueDefinition,topic:ExhibitionDefinition)->bool:
	var meta:=metadata(definition)
	return meta.year_min!=0 and meta.year_max!=0 and meta.year_min>=topic.rules.period_min and meta.year_max<=topic.rules.period_max and (topic.rules.categories.is_empty() or meta.category in topic.rules.categories)
static func evaluate(state:MuseumState,plan:ExhibitionPlan)->ExhibitionEvaluation:
	var result:=ExhibitionEvaluation.new()
	var topic:=find(plan.topic_id)
	if topic==null or not state.display_catalog.halls.has(plan.hall_id):
		result.missing.append("未知专题或展厅")
		return result
	if state.display_catalog.halls[plan.hall_id].unlock_level>state.museum_level:
		result.missing.append("展厅未解锁")
		return result
	var counts:Dictionary={}
	var categories:Dictionary={}
	var condition:=0.0
	for unit_id in state.display_catalog.unit_ids(state.museum_level,plan.hall_id):
		var unit:DisplayUnitDefinition=state.display_catalog.units[unit_id]
		for item in state.unit_items(unit_id):
			if not item.identified or state.is_auction_locked(item.instance_id) or item.instance_id in result.matched_ids:continue
			var definition:=MuseumState.POOL.find_by_id(item.definition_id)
			if definition==null or not state.display_catalog.accepts(unit,state.display_catalog.profiles.get(str(definition.id),{})) or not matches(definition,topic):continue
			result.matched_ids.append(item.instance_id)
			var repeats:int=counts.get(item.definition_id,0)
			result.score += (10.0+definition.rarity*3.0)*item.condition/100.0*pow(float(topic.rules.repeat_decay),repeats)
			counts[item.definition_id]=repeats+1
			categories[metadata(definition).category]=true
			condition+=item.condition
	result.unique_count=counts.size()
	result.category_count=categories.size()
	if not result.matched_ids.is_empty():result.average_condition=condition/result.matched_ids.size()
	if result.matched_ids.size()<topic.rules.min_items:result.missing.append("匹配展品至少%d件（当前%d）"%[topic.rules.min_items,result.matched_ids.size()])
	if result.unique_count<topic.rules.min_unique:result.missing.append("不同器物定义至少%d种（当前%d）"%[topic.rules.min_unique,result.unique_count])
	if result.category_count<topic.rules.min_categories:result.missing.append("器物类别至少%d类（当前%d）"%[topic.rules.min_categories,result.category_count])
	if result.average_condition<topic.rules.min_condition:result.missing.append("平均品相至少%d"%topic.rules.min_condition)
	result.score=minf(200.0,result.score)
	result.qualified=result.missing.is_empty()
	if result.qualified:result.heat=minf(float(topic.rules.max_heat),result.score/500.0)
	return result
static func start(state:MuseumState,hall:StringName,topic:StringName)->bool:
	if not state.can_edit():return false
	var plan:=ExhibitionPlan.new(hall,topic)
	if not evaluate(state,plan).qualified:return false
	state.exhibition_plans[hall]=topic
	state.changed.emit()
	return true
static func stop(state:MuseumState,hall:StringName)->bool:
	if not state.can_edit() or not state.exhibition_plans.has(hall):return false
	state.exhibition_plans.erase(hall)
	state.changed.emit()
	return true
static func active(state:MuseumState,hall:StringName)->ExhibitionEvaluation:
	return evaluate(state,ExhibitionPlan.new(hall,state.exhibition_plans.get(hall,&"")))
static func bonus_appeal(state:MuseumState)->int:
	var total:=0.0
	for hall in state.exhibition_plans:
		var base:=0
		for id in state.display_catalog.unit_ids(state.museum_level,hall):base+=state.unit_appeal(id)
		total+=base*active(state,hall).heat
	return mini(floori(state.total_appeal()*float(data().max_bonus_fraction)),floori(total))
