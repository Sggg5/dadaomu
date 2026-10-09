class_name MuseumResearchService
extends RefCounted
static func register(state:MuseumState,id:StringName)->bool:
	var item:=state.collection.find(id)
	if not state.can_edit() or item==null or not item.identified or state.is_auction_locked(id):return false
	var record:CollectionResearchRecord=state.collection.archives[id]
	if record.level!=0:return false
	record.level=1;record.snapshot(item);record.record(state.day_number,"REGISTER","MANUAL")
	state.changed.emit();return true
static func related(state:MuseumState,id:StringName,researched_only:bool=false)->Array[StringName]:
	var result:Array[StringName]=[]
	var record:CollectionResearchRecord=state.collection.archives.get(id)
	if record==null:return result
	var definition:=MuseumState.POOL.find_by_id(record.definition_id)
	var topic:=ResearchDefinition.topic(definition)
	for item in state.collection.all_items():
		if not item.identified:continue
		var other:=MuseumState.POOL.find_by_id(item.definition_id)
		if ResearchDefinition.topic(other)==topic and (not researched_only or state.collection.archives[item.instance_id].level>=2):result.append(item.instance_id)
	result.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b));return result
static func eligible(state:MuseumState,id:StringName,target:int)->bool:
	var item:=state.collection.find(id)
	if item==null or not item.identified or state.is_auction_locked(id) or not state.collection.archives.has(id):return false
	var record:CollectionResearchRecord=state.collection.archives[id]
	if target!=record.level+1 or target not in [2,3]:return false
	if target==2:return true
	var group:=related(state,id,true);var definitions:Dictionary={}
	for member in group:definitions[state.collection.find(member).definition_id]=true
	return ResearchDefinition.topic(MuseumState.POOL.find_by_id(item.definition_id))!="UNKNOWN" and group.size()>=int(ResearchDefinition.rules().topic_min_items) and definitions.size()>=int(ResearchDefinition.rules().topic_min_definitions)
static func complete(state:MuseumState,id:StringName,target:int,actor:String)->bool:
	if not eligible(state,id,target):return false
	var record:CollectionResearchRecord=state.collection.archives[id]
	record.level=target;record.record(state.day_number,"TYPE_RESEARCH" if target==2 else "TOPIC_RESEARCH",actor,{"related_ids":related(state,id,true)})
	return true
static func notes(state:MuseumState,id:StringName)->String:
	var record:CollectionResearchRecord=state.collection.archives.get(id)
	if record==null:return "资料待补充"
	var definition:=MuseumState.POOL.find_by_id(record.definition_id)
	if record.level<2:return "器物研究尚未完成；资料待补充。"
	var notes:Dictionary=ResearchDefinition.rules().type_notes
	var text:String=notes.get(str(definition.category),notes.DEFAULT)
	text+="\n本地游戏原型说明："+definition.description+"\n审核范围：游戏试玩待审，不是专家审定；引用仅作来源索引，无图片授权。"
	if definition.reference_urls.is_empty():text+="\n原始资料：待补充；材质及工艺：未知。"
	else:
		text+="\n原型参考链接（授权按原机构，不自动下载媒体）：\n"+"\n".join(definition.reference_urls)
	if record.level==3:text+="\n专题研究："+ResearchDefinition.topic(definition)+"\n关联真实持有实例："+", ".join(related(state,id,true))+"\n馆内研究记录，非学术批准。"
	return text
