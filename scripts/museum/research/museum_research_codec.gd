class_name MuseumResearchCodec
extends RefCounted
const MAX_ARCHIVES:=10000
static func encode(state:MuseumState)->Dictionary:
	var rows:Array=[];var ids:=state.collection.archives.keys()
	ids.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	for id in ids:
		var record:CollectionResearchRecord=state.collection.archives[id]
		var row:=record.values();var item:=state.collection.find(id)
		if item!=null:row.last_condition=item.condition;row.last_identified=item.identified
		rows.append(row)
	return {"collection_research_version":1,"collection_archives":rows}
static func decode(state:MuseumState,payload:Dictionary)->bool:
	if payload.get("collection_research_version")!=1 or not payload.get("collection_archives") is Array or payload.collection_archives.size()>MAX_ARCHIVES:return false
	var restored:Dictionary[StringName,CollectionResearchRecord]={}
	var sites:=SiteRegistry.load_default()
	for row:Variant in payload.collection_archives:
		if not row is Dictionary:return false
		for field in ["instance_id","definition_id"]:
			if not row.get(field) is String:return false
		var id:=StringName(row.instance_id);var suffix:String=row.instance_id.trim_prefix("A")
		if not row.instance_id.begins_with("A") or not suffix.is_valid_int() or suffix.to_int()<1 or suffix.to_int()>=state.collection.next_id() or restored.has(id):return false
		var definition:=MuseumState.POOL.find_by_id(StringName(row.definition_id))
		if definition==null:return false
		for field in ["acquired_day","inspection_anchor"]:
			if not MuseumManagementCodec.integer(row.get(field),0,state.day_number if field=="acquired_day" else state.daily_reports.size()):return false
		if not MuseumManagementCodec.integer(row.get("level"),0,3) or not MuseumManagementCodec.integer(row.get("last_condition"),0,100) or not row.get("last_identified") is bool:return false
		if row.level>0 and not row.last_identified:return false
		var item:=state.collection.find(id)
		if item!=null and (str(item.definition_id)!=row.definition_id or item.acquired_day!=row.acquired_day or item.condition!=row.last_condition or item.identified!=row.last_identified):return false
		if not row.get("source") is Dictionary:return false
		var source:Dictionary=row.source.duplicate(true)
		if not source.is_empty():
			if source.size()!=4 or not source.get("site_id") is String or not source.get("region_id") is String:return false
			var site:=sites.site(StringName(source.site_id))
			if site==null or str(site.region_id)!=source.region_id or not MuseumManagementCodec.integer(source.get("run_seed"),0,ExpeditionSeedService.MAX_SEED) or source.get("expedition_day")!=row.acquired_day:return false
			source.run_seed=int(source.run_seed);source.expedition_day=int(source.expedition_day)
		if not row.get("references") is Array or row.references.size()>32 or not row.get("exhibited_topics") is Array or row.exhibited_topics.size()>3:return false
		var references:Array[String]=[]
		for url:Variant in row.references:
			if not url is String or url not in definition.reference_urls or url in references:return false
			references.append(url)
		var topics:Array[StringName]=[]
		for topic:Variant in row.exhibited_topics:
			if not topic is String or ExhibitionService.find(StringName(topic))==null or StringName(topic) in topics:return false
			topics.append(StringName(topic))
		if not row.get("events") is Array or row.events.size()>CollectionResearchRecord.MAX_HISTORY or not MuseumManagementCodec.integer(row.get("next_event"),1,1000000000):return false
		var events:Array[Dictionary]=[];var expected:int=int(row.next_event)-row.events.size();var last_day:=0
		if expected<1:return false
		for event:Variant in row.events:
			if not event is Dictionary or event.get("event_id")!=expected or not MuseumManagementCodec.integer(event.get("day_number"),row.acquired_day,state.day_number) or event.day_number<last_day:return false
			if not event.get("actor") is String or event.actor.length()>64 or event.get("kind") not in ["REGISTER","TYPE_RESEARCH","TOPIC_RESEARCH","RESTORATION","INSPECTION","DISPOSED"] or not event.get("details") is Dictionary:return false
			var actor:=StringName(event.actor)
			if event.kind=="REGISTER" and event.actor!="MANUAL":return false
			if event.kind in ["TYPE_RESEARCH","TOPIC_RESEARCH"] and (not MuseumStaffService.catalog().has(actor) or MuseumStaffService.catalog()[actor].job!=&"APPRAISER"):return false
			if event.kind in ["INSPECTION","RESTORATION"] and not (event.kind=="RESTORATION" and event.actor=="MANUAL") and (not MuseumStaffService.catalog().has(actor) or MuseumStaffService.catalog()[actor].job!=&"CONSERVATOR"):return false
			if event.kind=="DISPOSED" and event.actor not in ["DEALER","AUCTION"]:return false
			var details:Dictionary=event.details.duplicate(true)
			if event.kind=="RESTORATION":
				if not MuseumManagementCodec.integer(details.get("before"),0,99) or details.get("after")!=100 or details.get("fee")!=ceili((100-float(details.before))/10.0)*[20,40,60,100][definition.rarity]:return false
				for field in ["before","after","fee"]:details[field]=int(details[field])
			elif event.kind=="INSPECTION":
				if not MuseumManagementCodec.integer(details.get("condition"),0,100) or not MuseumManagementCodec.integer(details.get("protect_level"),0,3) or not MuseumManagementCodec.integer(details.get("business_index"),1,state.daily_reports.size()) or details.get("repair_recommended")!=(details.condition<100):return false
				if not details.get("slot_id") is String or not details.get("unit_id") is String:return false
				if details.slot_id=="" and details.unit_id!="":return false
				if details.slot_id!="" and (not state.display_catalog.slots.has(StringName(details.slot_id)) or str(state.display_catalog.slots[StringName(details.slot_id)].unit_id)!=details.unit_id):return false
				if details.get("interval")!=ResearchDefinition.rules().inspection_intervals[int(details.protect_level)]:return false
				for field in ["condition","protect_level","business_index","interval"]:details[field]=int(details[field])
			elif event.kind in ["TYPE_RESEARCH","TOPIC_RESEARCH"]:
				if not details.get("related_ids") is Array or details.related_ids.size()>128:return false
				for related:Variant in details.related_ids:
					if not related is String or not related.begins_with("A") or not related.trim_prefix("A").is_valid_int() or related.trim_prefix("A").to_int()<1 or related.trim_prefix("A").to_int()>=state.collection.next_id():return false
			var normalized:Dictionary=event.duplicate(true);normalized.event_id=expected;normalized.day_number=int(event.day_number);normalized.details=details
			events.append(normalized);expected+=1;last_day=int(event.day_number)
		var record:=CollectionResearchRecord.new();record.instance_id=id;record.definition_id=StringName(row.definition_id);record.acquired_day=int(row.acquired_day);record.source=source
		record.level=int(row.level);record.inspection_anchor=int(row.inspection_anchor);record.last_condition=int(row.last_condition);record.last_identified=row.last_identified
		record.references=references;record.exhibited_topics=topics;record.events=events;record.next_event=int(row.next_event);restored[id]=record
	for item in state.collection.all_items():
		if not restored.has(item.instance_id):return false
	state.collection.archives=restored;return true
