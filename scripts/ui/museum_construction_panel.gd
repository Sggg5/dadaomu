class_name MuseumConstructionPanel
extends CanvasLayer
## 单次确认绑定打开时等级；成功后必须关闭再打开才能购买下一等级。
var facility_panel:MuseumFacilityPanel
var state: MuseumState
var player: MuseumPlayer
var panel: Panel
var label: Label
var expected_level: int
var confirmed: bool = false


func _ready() -> void:
	layer = 35
	panel = Panel.new()
	panel.position = Vector2(300,155)
	panel.size = Vector2(680,460)
	add_child(panel)
	label = Label.new()
	label.position = Vector2(30,25)
	label.size = Vector2(620,315)
	label.add_theme_font_size_override("font_size",22)
	panel.add_child(label)
	var facilities:=Button.new()
	facilities.text="设施建设 / 查看各厅升级"
	facilities.position=Vector2(30,350)
	facilities.size=Vector2(620,36)
	facilities.pressed.connect(func()->void:close();facility_panel.open())
	panel.add_child(facilities)
	var close_button := Button.new()
	close_button.text = "关闭 [Tab]"
	close_button.position = Vector2(30,395)
	close_button.size = Vector2(620,40)
	close_button.pressed.connect(close)
	panel.add_child(close_button)
	panel.hide()


func open() -> void:
	expected_level = state.museum_level
	confirmed = false
	_refresh()
	panel.show()
	player.controls_enabled = false
	player.velocity = Vector2.ZERO


func _refresh() -> void:
	var current := state.level_definition()
	label.text = "%s\n当前：展柜%d · 游客容量%d\n现金：%s\n\n" % [current.display_name,state.display_catalog.unit_ids(state.museum_level).size(),current.visitor_capacity,AntiqueDefinition.money(state.cash)]
	if confirmed:
		label.text += "扩建完成，展区已开放。\n请先关闭建设牌，再查看下一次扩建。"
		return
	var next := MuseumState.LEVELS.at(state.museum_level+1)
	if next == null:
		label.text += "当前已达到本阶段最高馆舍等级"
		return
	label.text += "扩建：%s\n解锁：+%d展柜 · 游客容量%d → %d\n费用：%s\n\n%s" % [next.display_name,state.display_catalog.unit_ids(state.museum_level+1).size()-state.display_catalog.unit_ids(state.museum_level).size(),current.visitor_capacity,next.visitor_capacity,AntiqueDefinition.money(current.upgrade_cost),"资金不足" if state.cash < current.upgrade_cost else "[E] 扩建"]
	if not state.can_edit(): label.text += "\n营业中不能扩建"


func confirm() -> bool:
	if confirmed or not panel.visible or not state.upgrade(expected_level):
		_refresh()
		return false
	confirmed = true
	_refresh()
	return true


func close() -> void:
	panel.hide()
	player.controls_enabled = true


func _input(event: InputEvent) -> void:
	if not panel.visible or not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode == KEY_TAB:
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		confirm()
		get_viewport().set_input_as_handled()
