class_name VisitorViewResult
extends RefCounted
## Completed-view snapshot. Pure IDs/value fields; no DisplayCase or visitor nodes.
static func snapshot(state:MuseumState,unit_id:StringName,seen_categories:Dictionary)->Dictionary:
	var unit:DisplayUnitDefinition=state.display_catalog.units[unit_id]
	var ids:Array[String]=[]
	var categories:Array[String]=[]
	var condition:=0.0
	var repeated:=false
	var topic_id:StringName=state.exhibition_plans.get(unit.hall_id,&"")
	var theme:=ExhibitionService.active(state,unit.hall_id)
	var watched_theme:=false
	for item in state.unit_items(unit_id):
		if not item.identified:continue
		ids.append(str(item.instance_id))
		var definition:=MuseumState.POOL.find_by_id(item.definition_id)
		var category:String=str(state.display_catalog.profiles.get(str(definition.id),{}).get("category","UNKNOWN"))
		categories.append(category)
		if seen_categories.has(category):repeated=true
		condition+=item.condition
		if theme.qualified and item.instance_id in theme.matched_ids:watched_theme=true
	var text:="这一柜的%d件器物摆在一起很有意思。"%ids.size()
	if repeated:text="这些展品看起来有些相似。"
	elif watched_theme and topic_id==&"HAN_WEI":text="这批汉魏墓葬器物很有意思。"
	elif watched_theme and topic_id==&"TANG_SILK":text="这一组唐代器物摆在一起挺好看。"
	elif watched_theme and topic_id==&"COINS":text="这些钱币让人看到了流通的变化。"
	elif not ids.is_empty() and condition/ids.size()>=90:text="这些器物保存得不错。"
	if MuseumConstructionService.unit_level(state,unit_id,&"LABEL")>0:text="说明牌把器物背景交代得很清楚。"+text
	elif MuseumConstructionService.unit_level(state,unit_id,&"LIGHT")>0:text="柜内照明让细节更清楚。"+text
	return {"hall_id":str(unit.hall_id),"unit_id":str(unit_id),"instance_ids":ids,"categories":categories,"effective_appeal":MuseumConstructionService.unit_interest(state,unit_id),"topic_id":str(topic_id) if watched_theme else "","repeat_category":repeated,"feedback":text}
