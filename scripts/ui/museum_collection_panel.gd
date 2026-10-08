class_name MuseumCollectionPanel
extends CanvasLayer
## Current-unit slot manager plus searchable/paged storage. No research candidates enter this UI.
const PAGE_SIZE:=50
var state: MuseumState
var player: MuseumPlayer
var panel: Panel
var list: ItemList
var slot_list: ItemList
var heading: Label
var search_box: LineEdit
var category: OptionButton
var status_filter: OptionButton
var page_label: Label
var case_id: StringName=&""
var selected_slot: StringName=&""
var _ids: Array[StringName]=[]
var filtered_ids: Array[StringName]=[]
var page:=0
var _slot_ids: Array[StringName]=[]
var _controls_before:=true
var _mutations: Array[Button]=[]

func _ready()->void:
	layer=30
	panel=Panel.new()
	panel.position=Vector2(100,60)
	panel.size=Vector2(1080,610)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("192832")
	style.border_color=Color("a79565")
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	var box:=VBoxContainer.new()
	box.name="VBoxContainer"
	box.position=Vector2(20,18)
	box.size=Vector2(1040,570)
	panel.add_child(box)
	heading=Label.new()
	heading.add_theme_font_size_override("font_size",21)
	box.add_child(heading)
	search_box=LineEdit.new()
	search_box.placeholder_text="库房搜索：名称 / 实例ID · 按入藏实例排序"
	search_box.text_changed.connect(func(_text:String)->void:page=0;refresh_library())
	box.add_child(search_box)
	var filters:=HBoxContainer.new()
	box.add_child(filters)
	category=OptionButton.new()
	for title in ["全部类型","钱币","陶瓷","造像","玉器","青铜器","陶塑","首饰","残片"]:category.add_item(title)
	category.item_selected.connect(func(_index:int)->void:page=0;refresh_library())
	filters.add_child(category)
	status_filter=OptionButton.new()
	for title in ["全部状态","可陈列","未鉴定","已陈列","待拍"]:status_filter.add_item(title)
	status_filter.item_selected.connect(func(_index:int)->void:page=0;refresh_library())
	filters.add_child(status_filter)
	var body:=HBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(body)
	slot_list=ItemList.new()
	slot_list.custom_minimum_size.x=360
	slot_list.fixed_column_width=0
	slot_list.max_columns=1
	slot_list.max_text_lines=3
	slot_list.add_theme_font_size_override("font_size",16)
	slot_list.item_selected.connect(func(index:int)->void:selected_slot=_slot_ids[index])
	body.add_child(slot_list)
	list=ItemList.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size",16)
	body.add_child(list)
	var pages:=HBoxContainer.new()
	box.add_child(pages)
	button(pages,"上一页",func()->void:page=maxi(0,page-1);refresh_library())
	page_label=Label.new()
	page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	pages.add_child(page_label)
	button(pages,"下一页",func()->void:page=mini(maxi(0,ceili(filtered_ids.size()/float(PAGE_SIZE))-1),page+1);refresh_library())
	var choose:=Button.new()
	choose.name="Choose"
	choose.text="将选中馆藏放入选中位置"
	choose.pressed.connect(choose_selected)
	box.add_child(choose)
	var actions:=HBoxContainer.new()
	box.add_child(actions)
	button(actions,"撤下选中位置",func()->void:if state.unassign(selected_slot):refresh_slots();refresh_library())
	button(actions,"批量撤下此设施",func()->void:if state.withdraw_unit(case_id):refresh_slots();refresh_library())
	button(actions,"按筛选自动填空位",func()->void:
		var count:=state.fill_unit(case_id,filtered_ids)
		heading.text="本次放入%d件 · 容量/类型/尺寸/鉴定限制仍校验"%count
		refresh_slots();refresh_library())
	button(actions,"关闭 [Tab / E]",close)
	panel.hide()
	state.changed.connect(_on_state_changed)

func _on_state_changed()->void:
	if panel.visible:refresh_slots();refresh_library()

func button(parent:Node,title:String,callback:Callable)->void:
	var control:=Button.new()
	control.text=title
	control.pressed.connect(callback)
	parent.add_child(control)
	if title in ["撤下选中位置","批量撤下此设施","按筛选自动填空位"]:_mutations.append(control)

func open(target_case:StringName=&"")->void:
	if panel.visible or not player.controls_enabled:return
	_controls_before=player.controls_enabled
	case_id=target_case
	page=0
	search_box.text=""
	category.select(0)
	status_filter.select(0)
	selected_slot=&""
	refresh_slots()
	refresh_library()
	panel.get_node("VBoxContainer/Choose").visible=case_id!=&""
	panel.get_node("VBoxContainer/Choose").disabled=not state.can_edit()
	for control in _mutations:control.disabled=not state.can_edit() or case_id==&""
	panel.show()
	player.controls_enabled=false
	player.velocity=Vector2.ZERO

func refresh_slots()->void:
	slot_list.visible=case_id!=&""
	slot_list.clear()
	_slot_ids.clear()
	if case_id==&"":
		heading.text="库房 · %d件（搜索 / 分类 / 状态筛选）"%state.collection.all_items().size()
		return
	var unit:=state.display_catalog.units[case_id]
	heading.text="%s · %s · %d/%d · %s"%[unit.display_name,case_id,state.unit_items(case_id).size(),unit.capacity,"营业中只读" if not state.can_edit() else "选择位置与馆藏"]
	for slot in unit.slots():
		_slot_ids.append(slot.id)
		var item:=state.collection.find(state.display_assignments.get(slot.id,&""))
		var text:="[%02d] 空闲"%(slot.index+1)
		if item!=null:text="[%02d] %s · %s"%[slot.index+1,MuseumState.POOL.find_by_id(item.definition_id).display_name,"已鉴定 · 品相%d"%item.condition if item.identified else "未鉴定 · 品相隐藏"]
		slot_list.add_item(text)
	if selected_slot not in _slot_ids:selected_slot=_slot_ids[0]
	slot_list.select(_slot_ids.find(selected_slot))

func refresh_library()->void:
	filtered_ids.clear()
	var categories:=["","COIN","CERAMIC","SCULPTURE","JADE","BRONZE","CERAMIC_SCULPTURE","JEWELRY","FRAGMENT"]
	for item in state.collection.all_items():
		var definition:=MuseumState.POOL.find_by_id(item.definition_id)
		var profile:Dictionary=state.display_catalog.profiles.get(str(item.definition_id),{})
		var location:=state.case_for(item.instance_id)
		if not search_box.text.is_empty() and not (str(item.instance_id)+definition.display_name).to_lower().contains(search_box.text.to_lower()):continue
		if category.selected>0 and profile.get("category")!=categories[category.selected]:continue
		match status_filter.selected:
			1:
				if not state.can_assign(item.instance_id) or location!=&"":continue
				if case_id!=&"" and not state.display_catalog.accepts(state.display_catalog.units[case_id],profile):continue
			2:
				if item.identified:continue
			3:
				if location==&"":continue
			4:
				if not state.is_auction_locked(item.instance_id):continue
		filtered_ids.append(item.instance_id)
	filtered_ids.sort_custom(func(a:StringName,b:StringName)->bool:return str(a)<str(b))
	page=mini(page,maxi(0,ceili(filtered_ids.size()/float(PAGE_SIZE))-1))
	_ids.assign(filtered_ids.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE))
	list.clear()
	for id in _ids:
		var item:=state.collection.find(id)
		var definition:=MuseumState.POOL.find_by_id(item.definition_id)
		var location:=state.case_for(id)
		list.add_item("%s · %s · %s · %s"%[id,definition.display_name,"品相%d"%item.condition if item.identified else "待正式鉴定", "待拍锁定" if state.is_auction_locked(id) else ("库房" if location==&"" else str(location))])
	page_label.text="筛选%d / 馆藏%d · 第%d/%d页 · 本页%d"%[filtered_ids.size(),state.collection.all_items().size(),page+1,maxi(1,ceili(filtered_ids.size()/float(PAGE_SIZE))),_ids.size()]
	if not _ids.is_empty():list.select(0)

func choose_selected()->bool:
	if case_id==&"" or selected_slot==&"" or list.get_selected_items().is_empty():return false
	var id:=_ids[list.get_selected_items()[0]]
	if not state.place(selected_slot,id):
		heading.text="该古董尚未鉴定" if not state.collection.find(id).identified else ("该古董已委托拍卖，暂时锁定" if state.is_auction_locked(id) else "不可陈列：已占用其它位置、营业只读或类型/尺寸不匹配")
		return false
	close()
	return true

func close()->void:
	panel.hide()
	search_box.release_focus()
	category.get_popup().hide()
	status_filter.get_popup().hide()
	player.controls_enabled=_controls_before and state.phase!=MuseumState.Phase.NIGHT

func _input(event:InputEvent)->void:
	if not panel.visible or event.is_echo():return
	if (event.is_action_pressed("interact") and not search_box.has_focus()) or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_TAB):
		close()
		get_viewport().set_input_as_handled()
