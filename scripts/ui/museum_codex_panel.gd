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
	title.text = "全球博物馆图鉴 · 只读研究 / 策划预览"
	title.add_theme_font_size_override("font_size",24)
	box.add_child(title)
	section = OptionButton.new()
	for label in ["我的馆藏（实际拥有）","全球研究资料（不代表拥有）","自然历史（化石 / 矿物 / 陨石 / 岩石）","专题展览（策划草稿）"]: section.add_item(label)
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
	elif mode == 3:
		var plan := exhibitions.plan(exhibition_id)
		for id: String in plan.get("reading_order",[]):
			var row := catalog.record(id)
			if search_box.text.is_empty() or (str(row.recommended_zh_name)+row.original_name).to_lower().contains(search_box.text.to_lower()): result_ids.append(id)
	else: result_ids = catalog.search(search_box.text,mode == 2)
	render_page()

func render_page() -> void:
	list.clear()
	visible_ids = result_ids.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)
	for id: String in visible_ids:
		if mode == 0:
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

func select_entry(index: int) -> void:
	if index < 0 or index >= visible_ids.size(): return
	image.texture = null
	placeholder.show()
	placeholder.text = "暂无已核验照片"
	image_note.text = "暂无已核验本地照片 · 统一占位"
	var id: String = visible_ids[index]
	if mode == 0: detail.text = MuseumCodexText.owned(state,state.collection.find(StringName(id)))
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
