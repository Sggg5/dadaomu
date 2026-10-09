class_name MuseumReputationCodec
extends RefCounted
## Bounded verified game progress; decoding never awards or changes cash.
static func encode(state:MuseumState)->Dictionary:
	return {"reputation_version":1,"collection_history":state.collection_history.duplicate(true),"museum_achievements":state.achievements.duplicate(true)}
static func integer(value:Variant,lo:int,hi:int)->bool:
	return (value is int or value is float) and is_finite(float(value)) and value==floor(float(value)) and value>=lo and value<=hi
static func decode(state:MuseumState,payload:Dictionary)->bool:
	if payload.get("reputation_version")!=1:return false
	var history:Variant=payload.get("collection_history");var honors:Variant=payload.get("museum_achievements")
	if not history is Dictionary or not honors is Dictionary or history.size()>50 or honors.size()>MuseumMilestoneDefinition.goals().size():return false
	var regions:Array=[]
	for region in SiteRegistry.load_default().regions:regions.append(str(region.region_id))
	var cleaned:Dictionary={}
	for key in history:
		if not key is String or MuseumState.POOL.find_by_id(StringName(key))==null:return false
		var row:Variant=history[key]
		if not row is Dictionary or row.size()!=6:return false
		for date in ["discovered_day","identified_day","researched_day"]:
			if not integer(row.get(date),0,state.day_number):return false
		if not integer(row.get("research_level"),0,3) or not row.get("identified") is bool or not row.get("regions") is Array:return false
		if row.research_level==1 or (row.research_level>=2 and not row.identified):return false
		if (not row.identified and row.identified_day!=0) or (row.research_level<2 and row.researched_day!=0):return false
		if row.discovered_day>0 and ((row.identified_day>0 and row.identified_day<row.discovered_day) or (row.researched_day>0 and row.researched_day<row.discovered_day)):return false
		if row.regions.size()>3:return false
		var unique:Dictionary={}
		for region in row.regions:
			if not region is String or region not in regions or unique.has(region):return false
			unique[region]=true
		cleaned[key]=row.duplicate(true)
		for date in ["discovered_day","identified_day","researched_day","research_level"]:cleaned[key][date]=int(row[date])
	# Existing archives are evidence, not ignorable orphan references.
	for record in state.collection.archives.values():
		var key:=str(record.definition_id)
		if not cleaned.has(key):return false
		var item:=state.collection.find(record.instance_id)
		if (item.identified if item!=null else record.last_identified) and not cleaned[key].identified:return false
		if record.level>=2 and cleaned[key].research_level<record.level:return false
		if not record.source.is_empty() and record.source.region_id not in cleaned[key].regions:return false
	var awards:Dictionary={}
	for id in honors:
		if not id is String:return false
		var goal:=MuseumMilestoneDefinition.find(id);var award:Variant=honors[id]
		if goal.is_empty() or not award is Dictionary or award.size()!=6:return false
		if award.get("id")!=id or award.get("metric")!=goal.metric or award.get("reward")!=goal.reward:return false
		if not integer(award.get("day_number"),1,state.day_number) or not integer(award.get("value"),int(goal.target),1000000000):return false
		if award.get("event") not in ["COLLECTION","MUSEUM","REPORT","RESEARCH"]:return false
		awards[id]=award.duplicate(true);awards[id].day_number=int(award.day_number);awards[id].value=int(award.value)
	state.collection_history=cleaned;state.achievements=awards;return true
