class_name MuseumOfficePanel
extends CanvasLayer
## Tabbed ledger UI; bounded hall/report lists. All decisions belong to services.
var state: MuseumState
var player: MuseumPlayer
var business: MuseumBusiness
var panel: PanelContainer
var tabs: TabContainer
var overview: RichTextLabel
var hall_list: ItemList
var hall_detail: RichTextLabel
var finance: RichTextLabel
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
	var close_button:=Button.new()
	close_button.text="合上台账 [Tab / Esc]"
	close_button.pressed.connect(close)
	box.add_child(close_button)
	panel.hide()
func _text() -> RichTextLabel:
	var text:=RichTextLabel.new()
	text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	text.size_flags_vertical=Control.SIZE_EXPAND_FILL
	text.add_theme_color_override("default_color",Color("e9dec1"))
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
	hall_list.clear()
	hall_ids.clear()
	for hall in data.halls:
		hall_ids.append(hall.id)
		hall_list.add_item("%s · %s · %d件" % [hall.name,"已解锁" if hall.unlocked else "未解锁",hall.displayed])
	_select_hall(0)
	finance.text="现金（实际）：%s\n\n本日实时：%d位付费游客 / %s门票\n上次已结算：%d位游客 / %s门票\n\n预计游客：%d人；预测不记入现金。\n历史营业记录将在日报页查询。" % [AntiqueDefinition.money(data.cash),data.live_visitors,AntiqueDefinition.money(data.live_income),data.last_visitors,AntiqueDefinition.money(data.last_income),data.forecast_visitors]
func _select_hall(index:int) -> void:
	var data:=MuseumOverview.snapshot(state,business)
	if index<0 or index>=data.halls.size():return
	var hall:Dictionary=data.halls[index]
	hall_detail.text="%s\n\n%s\n设施 %d / 展位 %d\n实际展品 %d\n有效吸引力 %d\n未利用设施 %d\n\n布展请到实体展柜按E；本台账不绕过展位规则。" % [hall.name,"已开放" if hall.unlocked else "需升级馆舍",hall.units,hall.slots,hall.displayed,hall.appeal,hall.empty_units]
func _input(event:InputEvent) -> void:
	if panel.visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_TAB,KEY_ESCAPE]:
		close()
		get_viewport().set_input_as_handled()
