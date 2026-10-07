class_name MuseumWorkPanel
extends CanvasLayer
signal work_completed(message: String)
## 鉴定/修复共用选择和确认生命周期，费用/合法性只由MuseumState决定。
var state: MuseumState
var player: MuseumPlayer
var restoration: bool = false
var panel: Panel
var list: ItemList
var label: Label
var confirm_button: Button
var _ids: Array[StringName] = []
var _confirmed: bool = false


func _ready() -> void:
	layer = 32
	panel = Panel.new()
	panel.position = Vector2(230,140)
	panel.size = Vector2(820,470)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("20262b")
	background.border_color = Color("bcb09a")
	background.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel",background)
	add_child(panel)
	var box := VBoxContainer.new()
	box.position = Vector2(24,20)
	box.size = Vector2(772,426)
	panel.add_child(box)
	label = Label.new()
	label.add_theme_font_size_override("font_size",20)
	box.add_child(label)
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size",18)
	box.add_child(list)
	confirm_button = Button.new()
	confirm_button.text = "[E] 修复选中古董" if restoration else "[E] 正式鉴定（免费）"
	confirm_button.pressed.connect(confirm)
	box.add_child(confirm_button)
	var close_button := Button.new()
	close_button.text = "[Tab] 关闭"
	close_button.pressed.connect(close)
	box.add_child(close_button)
	panel.hide()


func open() -> bool:
	if not state.can_edit(): return false
	_confirmed = false
	confirm_button.disabled = false
	_ids.clear()
	list.clear()
	label.text = "修复到品相100 · 现金 %s" % AntiqueDefinition.money(state.cash) if restoration else "正式馆藏鉴定 · 免费"
	for item in state.collection.all_items():
		if (restoration and not item.identified) or (not restoration and item.identified): continue
		if restoration and not state.can_repair(item.instance_id): continue
		_ids.append(item.instance_id)
		var definition := MuseumState.POOL.find_by_id(item.definition_id)
		list.add_item("%s · 品相%d → 100 · 费用%s" % [definition.display_name,item.condition,AntiqueDefinition.money(state.restoration_cost(item.instance_id))] if restoration else "%s · 待正式鉴定 · 第%d天入藏" % [definition.display_name,item.acquired_day])
	if _ids.is_empty(): label.text += "\n暂无待修复古董" if restoration else "\n暂无待鉴定古董"
	else: list.select(0)
	panel.show()
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	return true


func confirm() -> bool:
	if not panel.visible or _confirmed or list.get_selected_items().is_empty(): return false
	if not state.can_edit():
		label.text = "营业中无法进行馆藏作业"
		return false
	var id := _ids[list.get_selected_items()[0]]
	var item := state.collection.find(id)
	var cost := state.restoration_cost(id)
	var success := state.repair(id) if restoration else state.identify(id)
	if not success:
		label.text = "资金不足" if restoration and state.cash < cost else "该古董无需重复作业"
		return false
	_confirmed = true
	confirm_button.disabled = true
	list.clear()
	var definition := MuseumState.POOL.find_by_id(item.definition_id)
	label.text = "%s\n%s · 品相：%d\n基础估值：%s · 基础吸引力：%d · 当前吸引力：%d\n[Tab] 关闭后可处理下一件" % ["修复完成" if restoration else "鉴定完成",definition.display_name,item.condition,AntiqueDefinition.money(definition.base_value),definition.exhibit_appeal,state.appeal_for(id)]
	work_completed.emit("%s · %s · 品相%d · 当前现金%s" % ["修复完成" if restoration else "鉴定完成",definition.display_name,item.condition,AntiqueDefinition.money(state.cash)])
	return true


func close() -> void:
	panel.hide()
	player.controls_enabled = true


func _input(event: InputEvent) -> void:
	if not panel.visible or event.is_echo(): return
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_TAB:
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		confirm()
		get_viewport().set_input_as_handled()
