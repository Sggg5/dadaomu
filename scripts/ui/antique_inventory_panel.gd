class_name AntiqueInventoryPanel
extends CanvasLayer
## 背包展示与按索引丢弃；不持拾取物、不暂停战斗、不改任何战斗属性。
var inventory: AntiqueInventory
var can_manage: Callable
var panel: PanelContainer
var header: Label
var list: ItemList
var footer: Label


func _ready() -> void:
	layer = 30
	panel = PanelContainer.new()
	panel.position = Vector2(320,155)
	panel.size = Vector2(640,435)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	header = Label.new()
	header.add_theme_font_size_override("font_size",23)
	box.add_child(header)
	var columns := Label.new()
	columns.text = "名称 · 占格 · 估值 · 价值/格"
	box.add_child(columns)
	list = ItemList.new()
	list.fixed_icon_size = Vector2i(28,28)
	list.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	list.custom_minimum_size = Vector2(600,280)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size",19)
	box.add_child(list)
	footer = Label.new()
	box.add_child(footer)
	var discard := Button.new()
	discard.text = "丢弃选中物品 [Delete] · 本局永久删除"
	discard.pressed.connect(discard_selected)
	box.add_child(discard)
	inventory.changed.connect(refresh)
	refresh()
	panel.hide()


func refresh() -> void:
	var selected := list.get_selected_items()
	list.clear()
	for item in inventory.items():
		list.add_item("%s    %d格    %s    %s/格" % [item.display_name,item.slots,AntiqueDefinition.money(item.base_value),AntiqueDefinition.money(floori(float(item.base_value)/item.slots))])
		list.set_item_icon(list.item_count-1,AntiqueVisual.icon(item.id))
	if not selected.is_empty() and selected[0] < list.item_count: list.select(selected[0])
	header.text = "随身背包 %d / %d · Tab关闭" % [inventory.used_slots(),inventory.capacity]
	footer.text = "总估值：%s · 背包打开时战斗继续" % AntiqueDefinition.money(inventory.total_value())


func discard_selected() -> void:
	if not can_manage.call(): return
	var selected := list.get_selected_items()
	if not selected.is_empty(): inventory.remove_at(selected[0])


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if not can_manage.call():
		panel.hide()
		return
	if event.physical_keycode == KEY_TAB:
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()
	elif panel.visible and event.physical_keycode == KEY_DELETE:
		discard_selected()
		get_viewport().set_input_as_handled()
