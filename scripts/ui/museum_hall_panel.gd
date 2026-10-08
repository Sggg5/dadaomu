class_name MuseumHallPanel
extends CanvasLayer
signal hall_selected(id: StringName)
var state: MuseumState
var player: MuseumPlayer
var panel: PanelContainer
var list: ItemList
var ids: Array[StringName] = []

func _ready() -> void:
	layer=35
	panel=PanelContainer.new()
	panel.position=Vector2(330,160)
	panel.size=Vector2(620,400)
	add_child(panel)
	var box:=VBoxContainer.new()
	panel.add_child(box)
	var heading:=Label.new()
	heading.text="展厅导览 · 仅载入当前展厅设施"
	box.add_child(heading)
	list=ItemList.new()
	list.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(list)
	var visit:=Button.new()
	visit.text="进入选中展厅"
	visit.pressed.connect(func()->void:
		if not list.get_selected_items().is_empty():
			var id:=ids[list.get_selected_items()[0]]
			close()
			hall_selected.emit(id))
	box.add_child(visit)
	var back:=Button.new()
	back.text="返回 [Tab/E]"
	back.pressed.connect(close)
	box.add_child(back)
	panel.hide()

func open() -> void:
	if not player.controls_enabled: return
	ids=state.display_catalog.hall_ids(state.museum_level)
	list.clear()
	for id in ids:
		var units:=state.display_catalog.unit_ids(state.museum_level,id)
		var capacity:=0
		for unit_id in units: capacity+=state.display_catalog.units[unit_id].capacity
		list.add_item("%s · %d设施 · %d陈列位置" % [state.display_catalog.halls[id].display_name,units.size(),capacity])
	list.select(0)
	panel.show()
	player.controls_enabled=false
	player.velocity=Vector2.ZERO
func close() -> void:
	panel.hide()
	player.controls_enabled=state.phase!=MuseumState.Phase.NIGHT
func _input(event: InputEvent) -> void:
	if panel.visible and not event.is_echo() and (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.physical_keycode==KEY_TAB)):
		close()
		get_viewport().set_input_as_handled()
