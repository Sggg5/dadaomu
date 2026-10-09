class_name MuseumFacilityView
extends VBoxContainer
## Shared office/construction view. Quotes are consumed, never auto-buy the next level.
var paper_style:=false
var state:MuseumState
var hall_filter:OptionButton
var list:ItemList
var detail:RichTextLabel
var buy:Button
var next_quote:Button
var ids:Array[StringName]=[]
var request:MuseumFacilityUpgrade
var _confirmed:=false
var notice:String=""
func _ready()->void:
	hall_filter=OptionButton.new()
	for title in ["全部展厅","主厅","东厅","西厅"]:hall_filter.add_item(title)
	hall_filter.item_selected.connect(func(_index:int)->void:refresh())
	add_child(hall_filter)
	var columns:=HBoxContainer.new()
	columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_child(columns)
	list=ItemList.new()
	list.custom_minimum_size=Vector2(360,340)
	columns.add_child(list)
	list.item_selected.connect(func(_index:int)->void:_confirmed=false;notice="";_selected())
	detail=RichTextLabel.new()
	detail.add_theme_font_size_override("normal_font_size",19)
	detail.add_theme_color_override("default_color",Color("382d22") if paper_style else Color("e9dec1"))
	detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical=Control.SIZE_EXPAND_FILL
	columns.add_child(detail)
	var actions:=HBoxContainer.new()
	add_child(actions)
	buy=Button.new()
	buy.text="确认投资（按本次报价）"
	buy.pressed.connect(_purchase)
	actions.add_child(buy)
	next_quote=Button.new()
	next_quote.text="查看下一等级报价"
	next_quote.pressed.connect(func()->void:_confirmed=false;notice="";_selected())
	actions.add_child(next_quote)
	refresh()
func refresh()->void:
	var old:StringName=ids[list.get_selected_items()[0]] if not list.get_selected_items().is_empty() and list.get_selected_items()[0]<ids.size() else &""
	list.clear()
	ids.clear()
	var catalog:=MuseumConstructionService.definitions(state)
	var keys:=catalog.keys()
	keys.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	var hall:StringName=[&"",&"MAIN",&"EAST",&"WEST"][hall_filter.selected]
	for id:StringName in keys:
		var definition:MuseumFacilityDefinition=catalog[id]
		if hall!=&"" and definition.hall_id!=hall:continue
		ids.append(id)
		list.add_item("%s / %d级 %s"%[definition.display_name,state.facilities.level(id),"未解锁" if definition.unlock_level>state.museum_level else ""])
	if ids.is_empty():return
	list.select(maxi(0,ids.find(old)))
	_selected()
func _selected()->void:
	if list.get_selected_items().is_empty():return
	var id:=ids[list.get_selected_items()[0]]
	var definition:=MuseumConstructionService.find(state,id)
	var level:=state.facilities.level(id)
	request=MuseumConstructionService.quote(state,id)
	var current_cost:int=definition.maintenance[level-1] if level>0 else 0
	var after_cost:int=definition.maintenance[level] if level<definition.max_level else current_cost
	var next:int=mini(level+1,definition.max_level)
	detail.text="建设图纸 · %s\n稳定编号 %s / %s\n\n当前%d级 → %d级（最高%d）\n现金 %s / 本次投资 %s\n每日维护 %s → %s\n全馆预计维护 %s / 日\n馆舍解锁等级 %d（当前%d）\n\n%s\n\n%s"%[definition.display_name,id,definition.hall_id,level,next,definition.max_level,AntiqueDefinition.money(state.cash),AntiqueDefinition.money(request.price) if request!=null else "最高等级",AntiqueDefinition.money(current_cost),AntiqueDefinition.money(after_cost),AntiqueDefinition.money(MuseumConstructionService.maintenance_due(state)),definition.unlock_level,state.museum_level,_effects(definition,level,next),notice if not notice.is_empty() else MuseumConstructionService.rejection(state,request)]
	buy.disabled=_confirmed or not MuseumConstructionService.rejection(state,request).is_empty()
	next_quote.disabled=not _confirmed or level>=definition.max_level
func _effects(definition:MuseumFacilityDefinition,level:int,next:int)->String:
	if definition.interest_per_level>0:return "实际柜内兴趣 +%.1f%% → +%.1f%%\n单柜合计上限18%%，全馆设施额外吸引力上限15%%。\n画面对应灯带 / 底座 / 说明卡；没有展品不会凭空产生吸引力。"%[level*definition.interest_per_level*100,next*definition.interest_per_level*100]
	if definition.kind==&"PROTECT":return "玻璃框与锁护等级%d → %d。\n玻璃框与锁护会升级；当前不会自动改变藏品品相。"%[level,next]
	return "公共服务等级%d → %d：%s。\n需游客实际经过/停留后才记录使用，不能增加重复票款。"%[level,next,{&"GUIDE":"导览后至多加看一次",&"REST":"参观间隙短时休息",&"RECEPTION":"入馆接待说明"}.get(definition.kind,"")]
func _purchase()->void:
	if _confirmed:return
	if MuseumConstructionService.purchase(state,request):
		_confirmed=true
		notice="投资完成，已入建设流水。确认查看下一报价后才能继续。"
	else:notice=MuseumConstructionService.rejection(state,request)
	refresh()
