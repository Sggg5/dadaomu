class_name MuseumCollectionCare
extends RefCounted
## Game management intervals, not a real conservation standard. No passive damage or fees.
static func environment(state:MuseumState,id:StringName)->Dictionary:
	var slot_id:=state.case_for(id)
	var unit_id:StringName=state.display_catalog.slots[slot_id].unit_id if slot_id!=&"" else &""
	var level:=state.facilities.level(StringName(str(unit_id)+":PROTECT")) if unit_id!=&"" else 0
	return {"slot_id":str(slot_id),"unit_id":str(unit_id),"protect_level":level,"interval":int(ResearchDefinition.rules().inspection_intervals[level])}
static func inspect(state:MuseumState,id:StringName,actor:String)->bool:
	var item:=state.collection.find(id)
	if item==null or not item.identified or state.is_auction_locked(id):return false
	var record:CollectionResearchRecord=state.collection.archives[id]
	var details:=environment(state,id)
	details.merge({"condition":item.condition,"repair_recommended":item.condition<100,"business_index":state.daily_reports.size()+1})
	record.inspection_anchor=state.daily_reports.size()+1
	record.record(state.day_number,"INSPECTION",actor,details)
	return true
static func due(state:MuseumState,id:StringName)->bool:
	if not state.collection.contains(id):return false
	return state.daily_reports.size()-state.collection.archives[id].inspection_anchor>=int(environment(state,id).interval)
static func restoration(state:MuseumState,id:StringName,before:int,fee:int,actor:String)->void:
	var record:CollectionResearchRecord=state.collection.archives[id]
	record.record(state.day_number,"RESTORATION",actor,{"before":before,"after":state.collection.find(id).condition,"fee":fee})
	record.snapshot(state.collection.find(id))
static func exhibition_history(state:MuseumState)->void:
	for hall in state.exhibition_plans:
		var evaluation:=ExhibitionService.active(state,hall)
		if not evaluation.qualified:continue
		for id in evaluation.matched_ids:
			var record:CollectionResearchRecord=state.collection.archives[id]
			var topic:StringName=state.exhibition_plans[hall]
			if topic not in record.exhibited_topics:record.exhibited_topics.append(topic)
