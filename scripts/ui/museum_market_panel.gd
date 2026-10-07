class_name MuseumMarketPanel
extends CanvasLayer
## 两种卖方操作共用选件/确认；可操作性由State、价格由MarketService决定。
signal transaction_completed(message: String)
var state: MuseumState
var player: MuseumPlayer
var consignment: bool = false
var panel: Panel
var list: ItemList
var heading: Label
var reserve: OptionButton
var confirm_button: Button
var cancel_button: Button
var _ids: Array[StringName] = []
var _confirmed: bool = false


func _ready() -> void:
	layer = 33
	panel = Panel.new()
	panel.position = Vector2(170,140)
	panel.size = Vector2(940,470)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("20262b")
	background.border_color = Color("bcb09a")
	background.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel",background)
	add_child(panel)
	var box := VBoxContainer.new()
	box.position = Vector2(24,20)
	box.size = Vector2(892,426)
	panel.add_child(box)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size",20)
	box.add_child(heading)
	list = ItemList.new()
	list.add_theme_font_size_override("font_size",17)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(list)
	reserve = OptionButton.new()
	for mode in range(3): reserve.add_item(AntiqueMarketService.reserve_name(mode),mode)
	reserve.select(AntiqueMarketService.Reserve.NORMAL)
	reserve.item_selected.connect(func(_index: int) -> void: _refresh_rows())
	box.add_child(reserve)
	confirm_button = Button.new()
	confirm_button.text = "[E] 委托选中古董" if consignment else "[E] 确认出售选中古董（永久失去该实例）"
	confirm_button.pressed.connect(confirm)
	box.add_child(confirm_button)
	cancel_button = Button.new()
	cancel_button.text = "取消委托（免费）"
	cancel_button.pressed.connect(cancel)
	box.add_child(cancel_button)
	var close_button := Button.new()
	close_button.text = "[Tab] 关闭"
	close_button.pressed.connect(close)
	box.add_child(close_button)
	panel.hide()


func open() -> bool:
	if not state.can_edit(): return false
	_confirmed = false
	confirm_button.disabled = false
	reserve.disabled = false
	reserve.visible = consignment
	cancel_button.visible = consignment and state.auction_lot_instance_id != &""
	cancel_button.disabled = false
	_ids.clear()
	list.clear()
	heading.text = "拍卖委托 · 今晚参加拍卖会会占用一个夜晚" if consignment else "古董商 · 未展出的已鉴定古董可出售 · 即时稳定现金"
	var pending := state.collection.find(state.auction_lot_instance_id)
	if consignment and pending != null:
		heading.text = "已有待拍品：%s · 品相%d\n%s · 等待参加夜间拍卖；可免费取消" % [MuseumState.POOL.find_by_id(pending.definition_id).display_name,pending.condition,AntiqueMarketService.reserve_name(state.auction_reserve_mode)]
	for item in state.collection.all_items():
		if (state.can_consign(item.instance_id) if consignment else state.can_sell(item.instance_id)): _ids.append(item.instance_id)
	_refresh_rows()
	if not _ids.is_empty(): list.select(0)
	elif pending == null or not consignment: heading.text += "\n暂无可交易古董（请先鉴定或撤展）"
	panel.show()
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	return true


func _refresh_rows() -> void:
	var selected := list.get_selected_items()
	list.clear()
	for id in _ids:
		var item := state.collection.find(id)
		if item == null: continue
		var definition := MuseumState.POOL.find_by_id(item.definition_id)
		var value := AntiqueMarketService.market_value(item,definition)
		var price := AntiqueMarketService.reserve_price(value,reserve.selected) if consignment else AntiqueMarketService.dealer_offer(value)
		list.add_item("%s · 品相%d · 市场估值%s · %s%s" % [definition.display_name,item.condition,AntiqueDefinition.money(value),"保留价" if consignment else "收购报价",AntiqueDefinition.money(price)])
	if not selected.is_empty() and selected[0] < list.item_count: list.select(selected[0])


func confirm() -> bool:
	if not panel.visible or _confirmed or list.get_selected_items().is_empty(): return false
	if not state.can_edit():
		heading.text = "营业中无法处理古董交易"
		return false
	var id := _ids[list.get_selected_items()[0]]
	var success := state.consign(id,reserve.selected) if consignment else state.sell_to_dealer(id)
	if not success:
		heading.text = "该古董未鉴定、正在展出或已锁定；无法交易"
		return false
	_confirmed = true
	confirm_button.disabled = true
	reserve.disabled = true
	list.clear()
	heading.text = "委托已保存 · 该件古董已锁定，去情报板选择拍卖会\n也可以选择下墓，委托会保留" if consignment else "出售完成 · 当前现金%s\n该实例已离开馆藏。[Tab] 关闭后可处理下一件" % AntiqueDefinition.money(state.cash)
	transaction_completed.emit(heading.text)
	return true


func cancel() -> bool:
	if not panel.visible or _confirmed or not state.cancel_consignment(): return false
	_confirmed = true
	cancel_button.disabled = true
	heading.text = "已免费取消委托 · 品相不变，古董恢复正常馆藏状态"
	transaction_completed.emit(heading.text)
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
