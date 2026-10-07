class_name MuseumCollectionPanel
extends CanvasLayer
## 按馆藏instance_id选择展品；没有删除/出售入口。开放期间数据层再次拒绝修改。
var state: MuseumState
var player: MuseumPlayer
var panel: Panel
var list: ItemList
var heading: Label
var case_id: StringName = &""
var _ids: Array[StringName] = []


func _ready() -> void:
	layer = 30
	panel = Panel.new()
	panel.position = Vector2(230,140)
	panel.size = Vector2(820,470)
	add_child(panel)
	var box := VBoxContainer.new()
	box.name = "VBoxContainer"
	box.position = Vector2(24,20)
	box.size = Vector2(772,426)
	panel.add_child(box)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size",22)
	box.add_child(heading)
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_font_size_override("font_size",18)
	box.add_child(list)
	var choose := Button.new()
	choose.text = "将选中藏品放入此展柜"
	choose.pressed.connect(choose_selected)
	choose.name = "Choose"
	box.add_child(choose)
	var close_button := Button.new()
	close_button.text = "关闭 [Tab / E]"
	close_button.pressed.connect(close)
	box.add_child(close_button)
	panel.hide()


func open(target_case: StringName = &"") -> void:
	case_id = target_case
	_ids.clear()
	list.clear()
	heading.text = "馆藏 · %d件 · %s" % [state.collection.all_items().size(),"选择展品" if case_id != &"" else "库房（包含已展出藏品）"]
	for item in state.collection.all_items():
		_ids.append(item.instance_id)
		var definition := MuseumState.POOL.find_by_id(item.definition_id)
		var location := state.case_for(item.instance_id)
		list.add_item("%s · %s · 吸引力%d · %s · %s" % [item.instance_id,definition.display_name,definition.exhibit_appeal,AntiqueDefinition.money(definition.base_value),"库房" if location == &"" else str(location).replace("CASE_","展柜")])
	panel.get_node("VBoxContainer/Choose").visible = case_id != &""
	panel.show()
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	if not _ids.is_empty(): list.select(0)


func choose_selected() -> bool:
	if case_id == &"" or list.get_selected_items().is_empty(): return false
	var id := _ids[list.get_selected_items()[0]]
	if not state.assign(case_id,id):
		heading.text = "这件藏品已在其他展柜，或营业中不能调整展品"
		return false
	close()
	return true


func close() -> void:
	panel.hide()
	player.controls_enabled = true


func _input(event: InputEvent) -> void:
	if not panel.visible or event.is_echo(): return
	if (event is InputEventKey and event.pressed and event.physical_keycode == KEY_TAB) or event.is_action_pressed("interact"):
		close()
		get_viewport().set_input_as_handled()
