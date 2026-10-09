class_name MuseumFacilityPanel
extends CanvasLayer
var state:MuseumState
var player:MuseumPlayer
var panel:PanelContainer
var view:MuseumFacilityView
func _ready()->void:
	layer=39
	panel=PanelContainer.new()
	panel.position=Vector2(110,80)
	panel.size=Vector2(1060,570)
	var blueprint:=StyleBoxFlat.new()
	blueprint.bg_color=Color("243746")
	blueprint.border_color=Color("c8ba91")
	blueprint.set_border_width_all(3)
	blueprint.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel",blueprint)
	add_child(panel)
	var box:=VBoxContainer.new()
	panel.add_child(box)
	var title:=Label.new()
	title.text="博物馆设施建设 / 升级规划"
	title.add_theme_font_size_override("font_size",25)
	box.add_child(title)
	view=MuseumFacilityView.new()
	view.state=state
	view.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(view)
	var back:=Button.new()
	back.text="返回 [Tab / Esc]"
	back.pressed.connect(close)
	box.add_child(back)
	panel.hide()
func open()->void:
	if not player.controls_enabled:return
	view.refresh()
	panel.show()
	player.controls_enabled=false
	player.velocity=Vector2.ZERO
func close()->void:
	panel.hide()
	player.controls_enabled=state.phase!=MuseumState.Phase.NIGHT
func _input(event:InputEvent)->void:
	if panel.visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_TAB,KEY_ESCAPE]:
		close()
		get_viewport().set_input_as_handled()
