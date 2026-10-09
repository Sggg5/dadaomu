class_name MuseumDossierText
extends RefCounted
static func format(state:MuseumState,id:StringName,page:int=0)->String:
	var record:CollectionResearchRecord=state.collection.archives.get(id)
	if record==null:return "档案不存在"
	var item:=state.collection.find(id);var definition:=MuseumState.POOL.find_by_id(record.definition_id)
	var location:=state.case_for(id) if item!=null else &""
	var environment:=MuseumCollectionCare.environment(state,id) if item!=null else {}
	var text:="%s\n独立馆藏档案 %s · %s\n定义 %s / 获取Day%d\n"%[definition.display_name,id,"实际持有" if item!=null else "不再持有，不能陈列或研究",record.definition_id,record.acquired_day]
	text+="发现来源：来源未记录\n" if record.source.is_empty() else "发现来源：%s / %s · Expedition Day%d · Seed%d\n"%[record.source.region_id,record.source.site_id,record.source.expedition_day,record.source.run_seed]
	if not record.source.is_empty():
		var registry:=SiteRegistry.load_default()
		text+="游戏远征（原创墓穴）："+registry.region(StringName(record.source.region_id)).display_name+" / "+registry.site(StringName(record.source.site_id)).display_name+"\n"
	text+="文化时期：%s · 分类：%s\n"%[definition.culture_period if definition.culture_period!="" else "未知",definition.category if definition.category!=&"" else &"未知"]
	text+="材质与制作工艺：未知 / 资料待补充；不能根据名称编造检测结果。\n"
	text+="鉴定：%s · 品相：%s\n"%["已鉴定" if (item.identified if item!=null else record.last_identified) else "未鉴定","%d"%(item.condition if item!=null else record.last_condition) if (item.identified if item!=null else record.last_identified) else "未知"]
	text+="位置：%s · 曾参与专题：%s\n研究等级 %d/3（登记 / 类型 / 专题）\n"%[location if location!=&"" else &"未陈列","、".join(record.exhibited_topics) if not record.exhibited_topics.is_empty() else "无记录",record.level]
	if item!=null:
		text+="保护%d级 · 建议每%d营业日检查 · %s\n"%[environment.protect_level,environment.interval,"建议安排检查" if MuseumCollectionCare.due(state,id) else "未到建议周期（可主动检查）"]
		text+="同类已持有："+", ".join(MuseumResearchService.same_type(state,id))+"\n"
	text+=MuseumResearchService.notes(state,id)+"\n\n履历（第%d页，最多保留64条）：\n"%[page+1]
	var reverse:=record.events.duplicate();reverse.reverse()
	for event in reverse.slice(page*12,(page+1)*12):
		var kind:String={"REGISTER":"基础登记","TYPE_RESEARCH":"器物类型研究","TOPIC_RESEARCH":"专题研究","RESTORATION":"修复","INSPECTION":"保护检查","DISPOSED":"移交离馆"}.get(event.kind,event.kind)
		var actor:String=MuseumStaffService.catalog()[StringName(event.actor)].display_name if MuseumStaffService.catalog().has(StringName(event.actor)) else {"MANUAL":"馆长手动","DEALER":"古董商","AUCTION":"拍卖"}.get(event.actor,event.actor)
		var result:String=""
		if event.kind=="RESTORATION":result="品相%d→%d / 费用%s"%[event.details.before,event.details.after,AntiqueDefinition.money(event.details.fee)]
		elif event.kind=="INSPECTION":result="品相%d / 保护%d级 / 每%d营业日 / %s / %s"%[event.details.condition,event.details.protect_level,event.details.interval,event.details.unit_id if event.details.unit_id!="" else "库房","建议修复" if event.details.repair_recommended else "无需修复"]
		elif event.kind in ["TYPE_RESEARCH","TOPIC_RESEARCH"]:result="关联实例："+", ".join(event.details.related_ids)
		text+="Day%d · %s · %s · %s\n"%[event.day_number,kind,actor,result]
	var completed:=0
	for other in state.collection.all_items():
		if state.collection.archives[other.instance_id].level>=2:completed+=1
	text+="\n本馆器物类型研究进度：%d / %d件；研究不提升市场价值。"%[completed,state.collection.all_items().size()]
	return text
