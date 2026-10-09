class_name MuseumOfficePanel
extends CanvasLayer
## Tabbed ledger UI; bounded hall/report lists. All decisions belong to services.
var state: MuseumState
var player: MuseumPlayer
var business: MuseumBusiness
var panel: PanelContainer
var tabs: TabContainer
var facility_view:MuseumFacilityView
var overview: RichTextLabel
var hall_list: ItemList
var hall_detail: RichTextLabel
var finance: RichTextLabel
var visitors: RichTextLabel
var history: RichTextLabel
var history_page:=0
var history_heading: Label
var _refresh_timer:=0.0
var topic_hall: OptionButton
var topic_select: OptionButton
var topic_detail: RichTextLabel
var topic_start: Button
var topic_stop: Button
var hall_ids: Array[StringName] = []
func _ready() -> void:
	layer=38
	panel=PanelContainer.new()
	panel.position=Vector2(130,90)
	panel.size=Vector2(1020,570)
	var paper:=StyleBoxFlat.new()
	paper.bg_color=Color("e9dec1")
	paper.border_color=Color("765a36")
	paper.set_border_width_all(5)
	paper.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel",paper)
	add_child(panel)
	var box:=VBoxContainer.new()
	panel.add_child(box)
	var title:=Label.new()
	title.text="馆长办公室  /  经营档案与台账"
	title.add_theme_color_override("font_color",Color("382d22"))
	title.add_theme_font_size_override("font_size",26)
	box.add_child(title)
	tabs=TabContainer.new()
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var ledger:=StyleBoxFlat.new()
	ledger.bg_color=Color("f4ecd4")
	ledger.border_color=Color("a58b5c")
	ledger.set_border_width_all(1)
	ledger.set_content_margin_all(14)
	tabs.add_theme_stylebox_override("panel",ledger)
	box.add_child(tabs)
	overview=_page("馆务总览")
	var hall_box:=HBoxContainer.new()
	hall_box.name="展厅管理"
	tabs.add_child(hall_box)
	hall_list=ItemList.new()
	hall_list.custom_minimum_size=Vector2(280,350)
	hall_box.add_child(hall_list)
	hall_detail=_text()
	hall_box.add_child(hall_detail)
	hall_list.item_selected.connect(_select_hall)
	finance=_page("财务台账")
	visitors=_page("参观反馈")
	var reports:=VBoxContainer.new()
	reports.name="营业日报"
	tabs.add_child(reports)
	var pages:=HBoxContainer.new()
	reports.add_child(pages)
	var previous:=Button.new()
	previous.text="较近日期"
	previous.pressed.connect(func()->void:history_page=maxi(0,history_page-1);_refresh_history())
	pages.add_child(previous)
	history_heading=Label.new()
	pages.add_child(history_heading)
	var next:=Button.new()
	next.text="较早日期"
	next.pressed.connect(func()->void:history_page=mini(maxi(0,ceili(state.daily_reports.size()/5.0)-1),history_page+1);_refresh_history())
	pages.add_child(next)
	history=_text()
	reports.add_child(history)
	var topic_box:=VBoxContainer.new()
	topic_box.name="专题策展"
	tabs.add_child(topic_box)
	var selectors:=HBoxContainer.new()
	topic_box.add_child(selectors)
	topic_hall=OptionButton.new()
	for id in [&"MAIN",&"EAST",&"WEST"]:topic_hall.add_item(state.display_catalog.halls[id].display_name)
	selectors.add_child(topic_hall)
	topic_select=OptionButton.new()
	for definition in ExhibitionService.definitions():topic_select.add_item(definition.display_name)
	selectors.add_child(topic_select)
	topic_hall.item_selected.connect(func(_index:int)->void:_refresh_topic())
	topic_select.item_selected.connect(func(_index:int)->void:_refresh_topic())
	topic_detail=_text()
	topic_box.add_child(topic_detail)
	var actions:=HBoxContainer.new()
	topic_box.add_child(actions)
	topic_start=Button.new()
	topic_start.text="举办 / 替换专题"
	topic_start.pressed.connect(func()->void:
		ExhibitionService.start(state,[&"MAIN",&"EAST",&"WEST"][topic_hall.selected],ExhibitionService.definitions()[topic_select.selected].id)
		refresh())
	actions.add_child(topic_start)
	topic_stop=Button.new()
	topic_stop.text="撤下专题"
	topic_stop.pressed.connect(func()->void:
		ExhibitionService.stop(state,[&"MAIN",&"EAST",&"WEST"][topic_hall.selected])
		refresh())
	actions.add_child(topic_stop)
	facility_view=MuseumFacilityView.new()
	facility_view.name="设施建设"
	facility_view.paper_style=true
	facility_view.state=state
	tabs.add_child(facility_view)
	var close_button:=Button.new()
	close_button.text="合上台账 [Tab / Esc]"
	close_button.pressed.connect(close)
	box.add_child(close_button)
	panel.hide()
func _text() -> RichTextLabel:
	var text:=RichTextLabel.new()
	text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text.size_flags_vertical=Control.SIZE_EXPAND_FILL
	text.add_theme_color_override("default_color",Color("382d22"))
	text.add_theme_font_size_override("normal_font_size",20)
	return text
func _page(title:String) -> RichTextLabel:
	var text:=_text()
	text.name=title
	tabs.add_child(text)
	return text
func open() -> void:
	if not player.controls_enabled:return
	refresh()
	panel.show()
	player.controls_enabled=false
	player.velocity=Vector2.ZERO
func close() -> void:
	panel.hide()
	player.controls_enabled=state.phase!=MuseumState.Phase.NIGHT
func refresh() -> void:
	var data:=MuseumOverview.snapshot(state,business)
	overview.text="馆舍：%s     现金：%s\n\n馆藏 %d件  /  已鉴定 %d件\n展出 %d件  /  库房 %d件\n陈列位置利用率：%d / %d\n有展品设施：%d柜\n\n实际有效吸引力：%d\n预计游客：%d人（预测，不入账）" % [data.level,AntiqueDefinition.money(data.cash),data.owned,data.identified,data.displayed,data.stored,data.displayed,data.capacity,data.used_units,data.appeal,data.forecast_visitors]
	var selected_hall:int=hall_list.get_selected_items()[0] if not hall_list.get_selected_items().is_empty() else 0
	hall_list.clear()
	hall_ids.clear()
	for hall in data.halls:
		hall_ids.append(hall.id)
		hall_list.add_item("%s · %s · %d件" % [hall.name,"已解锁" if hall.unlocked else "未解锁",hall.displayed])
	var stats:=business.visits.snapshot()
	visitors.text="本日实际付费 %d人 / 完成观看 %d次\n独立观看游客 %d人 / 器物观看 %d件次（不同实物%d件）\n\n各厅：%s\n热门设施：%s\n专题访问：%s\n兴趣类别：%s\n\n近期真实反馈：\n%s" % [business.visitors_today,stats.view_count,stats.unique_viewers,stats.artifact_views,stats.unique_artifacts,_stat_lines(stats.hall_visits,"hall"),_stat_lines(stats.unit_visits,"unit"),_stat_lines(stats.topic_visits,"topic"),_stat_lines(stats.interests,"category"),"\n".join(stats.feedback)]
	hall_list.select(selected_hall)
	_select_hall(selected_hall)
	_refresh_topic()
	_refresh_history()
	if is_instance_valid(facility_view):facility_view.refresh()
	finance.text="现金（实际）：%s\n\n本日实时：%d位付费游客 / %s门票\n上次已结算：%d位游客 / %s门票\n\n预计游客：%d人；预测不记入现金。\n累计已记录：%d人 / %s门票；%d个营业日。" % [AntiqueDefinition.money(data.cash),data.live_visitors,AntiqueDefinition.money(data.live_income),data.last_visitors,AntiqueDefinition.money(data.last_income),data.forecast_visitors,MuseumDailyReport.totals(state).visitors,AntiqueDefinition.money(MuseumDailyReport.totals(state).income),MuseumDailyReport.totals(state).days]
	finance.text+="\n\n本日建设投资（实际流水）：%s\n预计每日维护：%s\n当日运营净收益：%s\n维护不足：当日可用现金支付，余款减免；无负债、不补扣。"%[AntiqueDefinition.money(MuseumConstructionService.capital_today(state)),AntiqueDefinition.money(MuseumConstructionService.maintenance_due(state)),AntiqueDefinition.money(MuseumOperatingFinance.net_for_day(state,state.day_number)) if state.daily_reports.has(state.day_number) else "尚未结算"]
func _select_hall(index:int) -> void:
	var data:=MuseumOverview.snapshot(state,business)
	if index<0 or index>=data.halls.size():return
	var hall:Dictionary=data.halls[index]
	var topic:=ExhibitionService.find(state.exhibition_plans.get(hall.id,&""))
	var evaluation:=ExhibitionService.active(state,hall.id)
	hall_detail.text="%s\n\n%s\n设施 %d / 展位 %d\n实际展品 %d\n有效吸引力 %d\n未利用设施 %d\n\n布展请到实体展柜按E；本台账不绕过展位规则。" % [hall.name,"已开放" if hall.unlocked else "需升级馆舍",hall.units,hall.slots,hall.displayed,hall.appeal,hall.empty_units]
	hall_detail.text+="\n\n经营专题：%s\n%s"%[topic.display_name if topic!=null else "无","有效 · 评分 %.1f"%evaluation.score if evaluation.qualified else "暂未合格"]
	hall_detail.text+="\n\n设施清单：\n"
	for unit_id in state.display_catalog.unit_ids(state.museum_level,hall.id):
		var unit:DisplayUnitDefinition=state.display_catalog.units[unit_id]
		var count:=state.unit_items(unit_id).size()
		hall_detail.text+="%s [%s] · %d/%d · %s\n"%[unit.display_name,unit_id,count,unit.capacity,"空置" if count==0 else "已布展"]
func _input(event:InputEvent) -> void:
	if panel.visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_TAB,KEY_ESCAPE]:
		close()
		get_viewport().set_input_as_handled()

func _refresh_topic()->void:
	var hall:StringName=[&"MAIN",&"EAST",&"WEST"][topic_hall.selected]
	var topic:=ExhibitionService.definitions()[topic_select.selected]
	var evaluation:=ExhibitionService.evaluate(state,ExhibitionPlan.new(hall,topic.id))
	var current:=ExhibitionService.find(state.exhibition_plans.get(hall,&""))
	topic_detail.text="游戏经营专题 · 非学术审核结论\n\n当前配置：%s\n%s：%s\n匹配 %d件 / 不同器物 %d种 / 类别 %d类\n平均品相 %.1f / 评分 %.1f\n展厅兴趣加成 %.1f%%（最高20%%）\n\n%s\n\n只采用本厅合法、已鉴定实物；布展请到实体展柜。" % [current.display_name if current!=null else "无",topic.display_name,"条件合格" if evaluation.qualified else "条件不足",evaluation.matched_ids.size(),evaluation.unique_count,evaluation.category_count,evaluation.average_condition,evaluation.score,evaluation.heat*100.0,"缺少："+"；".join(evaluation.missing) if not evaluation.qualified else "可以举办。移走展品后自动重新评估。"]
	topic_start.disabled=not state.can_edit() or not evaluation.qualified
	topic_stop.disabled=not state.can_edit() or not state.exhibition_plans.has(hall)

func _refresh_history()->void:
	history_heading.text="第%d页 / %d个已结算日（每页5日）"%[history_page+1,state.daily_reports.size()]
	var text:="日报只记录实际营业；读取不重复结算。\n\n"
	for report in MuseumDailyReport.recent(state,history_page):
		text+="Day %d · %d人 · 门票%s · 展品%d件 / 吸引力%d\n参观次数%s · 专题%s\n\n"%[report.day_number,report.visitor_count,AntiqueDefinition.money(report.ticket_income),report.total_exhibit_count,report.exhibit_appeal,_stat_lines(report.hall_visit_statistics,"hall"),_topic_names(report.active_exhibitions)]
		text+="维护应付%s / 已付%s / 减免%s / 净收益%s\n建设（截至闭馆）%s\n"%[AntiqueDefinition.money(int(report.get("maintenance_due",0))),AntiqueDefinition.money(int(report.get("maintenance_paid",0))),AntiqueDefinition.money(int(report.get("maintenance_waived",0))),AntiqueDefinition.money(int(report.get("operating_net_income",report.ticket_income))),AntiqueDefinition.money(int(report.get("construction_at_close",0)))]
		text+="设施观看：%s\n专题评分：%s / 访问：%s\n器物观看%d件次 / 独立观看%d人\n兴趣：%s\n\n"%[_stat_lines(report.popular_units,"unit"),_stat_lines(report.exhibition_scores,"hall"),_stat_lines(report.exhibition_visits,"topic"),report.artifact_views,report.unique_viewers,_stat_lines(report.interest_distribution,"category")]
	history.text=text

func _process(delta:float)->void:
	if not is_instance_valid(panel) or not panel.visible:return
	_refresh_timer+=delta
	if _refresh_timer>=.5:
		_refresh_timer=0.0
		refresh()

func _stat_lines(values:Dictionary,kind:String)->String:
	if values.is_empty():return "暂无记录"
	var keys:=values.keys()
	keys.sort_custom(func(a:Variant,b:Variant)->bool:return float(values[a])>float(values[b]) if values[a]!=values[b] else str(a)<str(b))
	var lines:Array[String]=[]
	var categories:={"COIN":"钱币","CERAMIC":"陶瓷","CERAMIC_SCULPTURE":"陶俑","BRONZE":"青铜器","JADE":"玉器","JEWELRY":"饰品","FRAGMENT":"残片","SCULPTURE":"造像"}
	for key in keys:
		var title:=str(key)
		if kind=="hall" and state.display_catalog.halls.has(StringName(key)):title=state.display_catalog.halls[StringName(key)].display_name
		elif kind=="unit" and state.display_catalog.units.has(StringName(key)):title=state.display_catalog.units[StringName(key)].display_name+" ["+str(key)+"]"
		elif kind=="topic" and ExhibitionService.find(StringName(key))!=null:title=ExhibitionService.find(StringName(key)).display_name
		elif kind=="category":title=categories.get(str(key),str(key))
		lines.append("%s：%s"%[title,str(values[key])])
	return "；".join(lines)
func _topic_names(values:Dictionary)->String:
	var result:Array[String]=[]
	for hall in values:
		var topic:=ExhibitionService.find(StringName(values[hall]))
		result.append(state.display_catalog.halls[StringName(hall)].display_name+" / "+topic.display_name)
	return "；".join(result) if not result.is_empty() else "无有效专题"
