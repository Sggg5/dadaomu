class_name NightActivityPanel
extends CanvasLayer
## 只发一种选择请求，GameFlow决定保存/场景切换。失败时玩家可重新选择。
signal dungeon_chosen
signal auction_chosen
var state: MuseumState
var player: MuseumPlayer
var panel: Panel
var label: Label
var dungeon_button: Button
var auction_button: Button
var _chosen: bool = false


func _ready() -> void:
	layer = 34
	panel = Panel.new()
	panel.position = Vector2(300,190)
	panel.size = Vector2(680,330)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("20262b")
	background.border_color = Color("bcb09a")
	background.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel",background)
	add_child(panel)
	var box := VBoxContainer.new()
	box.position = Vector2(24,20)
	box.size = Vector2(632,290)
	panel.add_child(box)
	label = Label.new()
	label.add_theme_font_size_override("font_size",20)
	box.add_child(label)
	dungeon_button = Button.new()
	dungeon_button.text = "下墓（待拍品保留）"
	dungeon_button.pressed.connect(func() -> void: choose(false))
	box.add_child(dungeon_button)
	auction_button = Button.new()
	auction_button.text = "参加拍卖会（本晚不下墓）"
	auction_button.pressed.connect(func() -> void: choose(true))
	box.add_child(auction_button)
	var back := Button.new()
	back.text = "[Tab] 暂不出发"
	back.pressed.connect(close)
	box.add_child(back)
	panel.hide()


func open() -> bool:
	var item := state.collection.find(state.auction_lot_instance_id)
	if not state.can_edit() or item == null: return false
	_chosen = false
	label.text = "今晚行动 · 一个夜晚只能选择一项\n待拍：%s · 品相%d\n%s\n拍卖波动收益 / 下墓探索新宝物" % [MuseumState.POOL.find_by_id(item.definition_id).display_name,item.condition,AntiqueMarketService.reserve_name(state.auction_reserve_mode)]
	panel.show()
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	return true


func choose(auction: bool) -> bool:
	if not panel.visible or _chosen or not state.can_edit(): return false
	_chosen = true
	close()
	if auction: auction_chosen.emit()
	else: dungeon_chosen.emit()
	return true


func close() -> void:
	panel.hide()
	player.controls_enabled = true


func _input(event: InputEvent) -> void:
	if panel.visible and event is InputEventKey and event.pressed and not event.is_echo() and event.physical_keycode == KEY_TAB:
		close()
		get_viewport().set_input_as_handled()
