class_name MuseumCollectionCodex
extends RefCounted
## Fifty playable definitions only. Research indexes/candidates never enter this catalog.
static func capture(state:MuseumState,legacy:bool=false)->void:
	for record:CollectionResearchRecord in state.collection.archives.values():
		var key:=str(record.definition_id)
		var row:Dictionary=state.collection_history.get(key,{"discovered_day":0,"identified_day":0,"researched_day":0,"research_level":0,"regions":[]})
		if not state.collection_history.has(key) and not legacy:row.discovered_day=record.acquired_day
		var item:=state.collection.find(record.instance_id)
		var identified:bool=item.identified if item!=null else record.last_identified
		if identified and not bool(row.get("identified",false)) and not legacy:row.identified_day=state.day_number
		if record.level>=2:
			if row.researched_day==0 and int(row.research_level)<2 and not legacy:row.researched_day=state.day_number
			row.research_level=maxi(int(row.research_level),record.level)
		if not record.source.is_empty() and record.source.region_id not in row.regions:row.regions.append(str(record.source.region_id));row.regions.sort()
		# Evidence flags survive selling and bounded archive pruning, but dates may be unknown.
		row["identified"]=bool(row.get("identified",false)) or identified
		state.collection_history[key]=row
static func rows(state:MuseumState,region:String="",category:String="",period:String="",rarity:int=-1,query:String="")->Array[Dictionary]:
	var result:Array[Dictionary]=[];var counts:Dictionary={}
	for item in state.collection.all_items():counts[str(item.definition_id)]=int(counts.get(str(item.definition_id),0))+1
	var pool:AntiquePool=load("res://data/antiques/playtest_catalog_50.tres")
	for definition in pool.antiques:
		var meta:=ExhibitionService.metadata(definition)
		var category_id:String=str(meta.category)
		var year:int=definition.prototype_year_end if definition.prototype_year_end!=0 else int(meta.year_max)
		var period_id:String="未知" if year==0 else ("先秦" if year< -206 else ("汉魏" if year<=420 else ("唐以前" if year<618 else ("唐" if year<=907 else ("民国" if year>=1912 else "宋元明清")))))
		var evidence:Dictionary=state.collection_history.get(str(definition.id),{})
		var recorded:Array=evidence.get("regions",[])
		if region!="" and region not in recorded:continue
		if category!="" and category_id!=category:continue
		if period!="" and period_id!=period:continue
		if rarity>=0 and definition.rarity!=rarity:continue
		if query!="" and query.to_lower() not in (definition.display_name+str(definition.id)).to_lower():continue
		var owned:int=counts.get(str(definition.id),0)
		var discovered:bool=not evidence.is_empty()
		var identified:bool=evidence.get("identified",false)
		var researched:bool=int(evidence.get("research_level",0))>=2
		var instances:Array[StringName]=[]
		for item in state.collection.all_items():
			if item.definition_id==definition.id:instances.append(item.instance_id)
		result.append({"id":str(definition.id),"name":definition.display_name,"category":category_id,"period":period_id,"rarity":definition.rarity,"regions":recorded.duplicate(),"discovered":discovered,"identified":identified,"researched":researched,"owned":owned,"instances":instances,"status":" / ".join((["DISCOVERED"] if discovered else ["UNKNOWN"])+(["IDENTIFIED"] if identified else [])+(["RESEARCHED"] if researched else [])+(["OWNED"] if owned>0 else []))})
	return result
static func counts(state:MuseumState)->Dictionary:
	var result:Dictionary={"discovered":0,"identified":0,"researched":0,"owned":0,"total":MuseumState.POOL.antiques.size()}
	for row in rows(state):
		for key in ["discovered","identified","researched"]:
			if row[key]:result[key]+=1
		if row.owned>0:result.owned+=1
	return result


static func category_name(id:String)->String:
	return {"COIN":"钱币","CERAMIC":"陶瓷","CERAMIC_SCULPTURE":"陶俑与明器","BRONZE":"青铜器","JADE":"玉器","JEWELRY":"金银饰件","FOSSIL":"化石","FRAGMENT":"器物残片","SCULPTURE":"雕塑"}.get(id,id if id!="" else "未知")
