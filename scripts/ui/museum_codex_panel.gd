class_name MuseumCodexPanel
extends CanvasLayer
## One panel per Museum. Explicit player ownership prevents competing panels/input.
const PAGE_SIZE := 40
var state: MuseumState
var player: MuseumPlayer
var catalog := MuseumResearchCatalog.new()
var exhibitions := MuseumExhibitionCatalog.new()
var exhibition_choice: OptionButton
var exhibition_id := ""
var panel: PanelContainer
var backdrop: ColorRect
var list: ItemList
var detail: RichTextLabel
var search_box: LineEdit
var section: OptionButton
var page_label: Label
var image: TextureRect
var placeholder: Label
var image_note: Label
var mode := 0
var page := 0
var result_ids: Array = []
var visible_ids: Array = []
var _previous_controls := false
var dossier_id:StringName=&""
var history_page:=0
var dossier_actions:HBoxContainer
var employee_choice:OptionButton
var employee_ids:Array[StringName]=[]
var register_button:Button
var research_button:Button
var inspection_button:Button

func _ready() -> void:
	layer = 45
	catalog.load_file()
	exhibitions.load_file(catalog)
	backdrop = ColorRect.new()
	backdrop.color = Color("0d141b")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	backdrop.hide()
	panel = PanelContainer.new()
	var background := StyleBoxFlat.new()
	background.bg_color = Color("17232e")
	background.border_color = Color("8fadae")
	background.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel",background)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_top = 20
	panel.offset_right = -24
	panel.offset_bottom = -20
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	var title := Label.new()
	title.text = "馆藏档案与全球资料 · 玩家记录 / 外部资料只读"
	title.add_theme_font_size_override("font_size",24)
	box.add_child(title)
	section = OptionButton.new()
	for label in ["我的馆藏（实际拥有）","全球研究资料（不代表拥有）","自然历史（化石 / 矿物 / 陨石 / 岩石）","专题展览（策划草稿）","已离馆档案（不再持有）"]: section.add_item(label)
	section.item_selected.connect(set_mode)
	box.add_child(section)
	exhibition_choice = OptionButton.new()
	for id: String in exhibitions.ids(): exhibition_choice.add_item(exhibitions.plan(id).title_zh)
	exhibition_choice.item_selected.connect(func(index: int) -> void: exhibition_id = exhibitions.ids()[index]; refresh())
	box.add_child(exhibition_choice)
	exhibition_choice.hide()
	if not exhibitions.ids().is_empty(): exhibition_id = exhibitions.ids()[0]
	search_box = LineEdit.new()
	search_box.placeholder_text = "中文 / English 搜索 · 推荐中文名仍待审"
	search_box.text_changed.connect(func(_text: String) -> void: refresh())
	box.add_child(search_box)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(columns)
	list = ItemList.new()
	list.custom_minimum_size.x = 280
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_stretch_ratio = .7
	list.add_theme_font_size_override("font_size",17)
	list.item_selected.connect(select_entry)
	columns.add_child(list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	image = TextureRect.new()
	image.custom_minimum_size = Vector2(0,150)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right.add_child(image)
	placeholder = Label.new()
	placeholder.text = "暂无已核验照片"
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	placeholder.modulate = Color("a5b6bc")
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.add_child(placeholder)
	image_note = Label.new()
	image_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	image_note.add_theme_font_size_override("font_size",14)
	right.add_child(image_note)
	detail = RichTextLabel.new()
	detail.bbcode_enabled = false
	detail.selection_enabled = true
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("normal_font_size",18)
	right.add_child(detail)
	dossier_actions=HBoxContainer.new();box.add_child(dossier_actions)
	employee_choice=OptionButton.new();dossier_actions.add_child(employee_choice);employee_choice.item_selected.connect(func(_index:int)->void:_dossier())
	register_button=Button.new();register_button.text="基础登记";dossier_actions.add_child(register_button);register_button.pressed.connect(_register)
	research_button=Button.new();research_button.text="委托下一阶段研究";dossier_actions.add_child(research_button);research_button.pressed.connect(_research)
	inspection_button=Button.new();inspection_button.text="委托保护检查";dossier_actions.add_child(inspection_button);inspection_button.pressed.connect(_inspect)
	_button(dossier_actions,"较早履历",func()->void:history_page=mini(5,history_page+1);_dossier())
	_button(dossier_actions,"较近履历",func()->void:history_page=maxi(0,history_page-1);_dossier())
	var footer := HBoxContainer.new()
	box.add_child(footer)
	_button(footer,"上一页",func() -> void: page = maxi(0,page-1); render_page())
	page_label = Label.new()
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(page_label)
	_button(footer,"下一页",func() -> void: page = mini(maxi(0,ceili(result_ids.size()/float(PAGE_SIZE))-1),page+1); render_page())
	_button(footer,"关闭 [Tab / E]",close)
	panel.hide()

func _button(parent: Node, title: String, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.pressed.connect(action)
	parent.add_child(button)

func open() -> bool:
	if panel.visible or not is_instance_valid(player) or not player.controls_enabled: return false
	_previous_controls = player.controls_enabled
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	backdrop.show()
	panel.show()
	refresh()
	return true

func close() -> void:
	if not panel.visible: return
	section.get_popup().hide()
	exhibition_choice.get_popup().hide()
	search_box.release_focus()
	panel.hide()
	backdrop.hide()
	image.texture = null
	if is_instance_valid(player): player.controls_enabled = _previous_controls and state.phase != MuseumState.Phase.NIGHT

func set_mode(value: int) -> void:
	mode = value
	section.select(value)
	exhibition_choice.visible = mode == 3
	refresh()

func refresh() -> void:
	page = 0
	result_ids.clear()
	if mode == 0:
		for item in state.collection.all_items():
			var definition := MuseumState.POOL.find_by_id(item.definition_id)
			if search_box.text.is_empty() or (str(item.instance_id)+definition.display_name).to_lower().contains(search_box.text.to_lower()): result_ids.append(str(item.instance_id))
	elif mode==4:
		for id in state.collection.archives:
			if not state.collection.contains(id) and (search_box.text.is_empty() or search_box.text in str(id)):result_ids.append(str(id))
	elif mode == 3:
		var plan := exhibitions.plan(exhibition_id)
		for id: String in plan.get("reading_order",[]):
			var row := catalog.record(id)
			if search_box.text.is_empty() or (str(row.recommended_zh_name)+row.original_name).to_lower().contains(search_box.text.to_lower()): result_ids.append(id)
	else: result_ids = catalog.search(search_box.text,mode == 2)
	render_page()

func render_page() -> void:
	dossier_actions.visible=mode in [0,4]
	list.clear()
	visible_ids = result_ids.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)
	for id: String in visible_ids:
		if mode==4:list.add_item(id+" · "+MuseumState.POOL.find_by_id(state.collection.archives[StringName(id)].definition_id).display_name)
		elif mode == 0:
			var item := state.collection.find(StringName(id))
			list.add_item("%s · %s" % [id,MuseumState.POOL.find_by_id(item.definition_id).display_name])
		else:
			var row := catalog.record(id)
			list.add_item(str(row.recommended_zh_name) if row.recommended_zh_name != null else row.original_name)
	page_label.text = "%d 条 · 第%d / %d页" % [result_ids.size(),page+1,maxi(1,ceili(result_ids.size()/float(PAGE_SIZE)))]
	image.texture = null
	placeholder.show()
	placeholder.text = "暂无已核验照片"
	image_note.text = "暂无已核验本地照片 · 统一占位"
	detail.text = "馆藏为空" if mode == 0 else "选择资料查看详情"
	if not catalog.errors.is_empty(): detail.text = "研究数据不可用："+str(catalog.errors)
	if not visible_ids.is_empty(): list.select(0); select_entry(0)
	else:
		dossier_id=&"";register_button.disabled=true;research_button.disabled=true;inspection_button.disabled=true

func select_entry(index: int) -> void:
	if index < 0 or index >= visible_ids.size(): return
	image.texture = null
	placeholder.show()
	placeholder.text = "暂无已核验照片"
	image_note.text = "暂无已核验本地照片 · 统一占位"
	var id: String = visible_ids[index]
	dossier_actions.visible=mode in [0,4]
	image.visible=mode not in [0,4];image_note.visible=mode not in [0,4]
	if mode in [0,4]:
		dossier_id=StringName(id);history_page=0;_dossier()
	else:
		detail.text = MuseumCodexText.research(catalog,catalog.record(id))
		if mode == 3:
			var plan := exhibitions.plan(exhibition_id)
			placeholder.text = plan.title_zh + "\n专题策划封面（文字占位）"
			var intro: String = "%s · %s\n%s\n主题：%s\n研究策划预览；不代表拥有或正式展厅开放\n按阅读顺序浏览 %d 件实物资料\n\n" % [plan.title_zh,plan.curation_status,plan.description,MuseumCodexText.known(plan.theme_tags),plan.reading_order.size()]
			detail.text = intro + detail.text
			for article_id: String in plan.related_article_ids:
				var article := catalog.article(article_id)
				detail.text += "\n关联图鉴：%s · %s\n%s\n" % [article.zh_name,article.review_status,article.body]
			detail.text += "\n专题原始资料来源：\n"
			for source: Dictionary in plan.source_notes:
				detail.text += "%s · %s\n%s\n" % [source.get("source_id",""),source.get("license_id","未知"),source.get("record_url","")]
		image.texture = catalog.image_for(id)
		if image.texture != null:
			placeholder.hide()
			var media := catalog.media_for(id)
			image_note.text = "%s · %s\n%s" % [media.license_id,media.copyright_notice,media.attribution]

func _input(event: InputEvent) -> void:
	if not panel.visible or event.is_echo(): return
	# E belongs to text entry while the search field has focus; Tab always closes.
	if (event.is_action_pressed("interact") and not search_box.has_focus()) or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_TAB):
		close()
		get_viewport().set_input_as_handled()

func open_at(id:StringName)->void:
	open();set_mode(0);search_box.text=str(id);refresh()
func _dossier()->void:
	if not state.collection.archives.has(dossier_id):return
	var original:=MuseumCodexText.owned(state,state.collection.find(dossier_id)) if state.collection.contains(dossier_id) else "历史馆藏"
	detail.text=MuseumDossierText.format(state,dossier_id,history_page)+"\n\n原始游戏原型说明\n"+original
	var selected:=employee_choice.selected
	employee_ids.clear();employee_choice.clear()
	for id in MuseumStaffService.active_ids(state):
		if MuseumStaffService.catalog()[id].job!=&"GUIDE":employee_ids.append(id);employee_choice.add_item(MuseumStaffService.catalog()[id].display_name+" · "+str(MuseumStaffService.catalog()[id].job))
	if employee_ids.is_empty():employee_choice.add_item("无工作员工，请到办公室招聘")
	else:employee_choice.select(clampi(selected,0,employee_ids.size()-1))
	var item:=state.collection.find(dossier_id);var record:CollectionResearchRecord=state.collection.archives[dossier_id]
	register_button.disabled=not state.can_edit() or item==null or not item.identified or state.is_auction_locked(dossier_id) or record.level!=0
	research_button.disabled=not state.can_edit() or employee_ids.is_empty() or not MuseumResearchService.eligible(state,dossier_id,record.level+1)
	inspection_button.disabled=not state.can_edit() or employee_ids.is_empty() or item==null or not item.identified
	if not employee_ids.is_empty():
		research_button.disabled=research_button.disabled or MuseumStaffService.catalog()[employee_ids[employee_choice.selected]].job!=&"APPRAISER"
		inspection_button.disabled=inspection_button.disabled or MuseumStaffService.catalog()[employee_ids[employee_choice.selected]].job!=&"CONSERVATOR"
	for task in state.staff.tasks:
		if task.instance_id==dossier_id:detail.text+="
任务#%d %s / %s · %s"%[task.task_id,task.action(),task.staff_id,task.status]
func _register()->void:MuseumResearchService.register(state,dossier_id);_dossier()
func _research()->void:
	if not employee_ids.is_empty():MuseumStaffTasks.enqueue(state,employee_ids[employee_choice.selected],dossier_id,&"RESEARCH",state.collection.archives[dossier_id].level+1)
	_dossier()
func _inspect()->void:
	if not employee_ids.is_empty():MuseumStaffTasks.enqueue(state,employee_ids[employee_choice.selected],dossier_id,&"INSPECT")
	_dossier()
