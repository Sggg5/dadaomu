class_name RelicDebugPanel
extends CanvasLayer
## 仅开发期展示与按键适配，不绘制正式拾取 UI，不决定效果行为。
const DEFINITIONS: Array[RelicDefinition] = [
	preload("res://data/relics/test_damage_relic.tres"),
	preload("res://data/relics/test_double_shot.tres"),
	preload("res://data/relics/test_kill_heal.tres")]
var runtime: RelicRuntime
var label: Label
var formal_panel: PanelContainer


func _ready() -> void:
	label = Label.new()
	label.position = Vector2(64, 610)
	label.add_theme_font_size_override("font_size", 16)
	label.size = Vector2(1152, 24)
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	formal_panel = PanelContainer.new()
	formal_panel.position = Vector2(864, 160)
	formal_panel.visible = false
	var list := VBoxContainer.new()
	formal_panel.add_child(list)
	for definition in RelicRewardService.DEFAULT_POOL.relics:
		var button := Button.new()
		button.text = "添加 " + definition.display_name
		button.tooltip_text = definition.description
		button.pressed.connect(_add_formal.bind(definition))
		list.add_child(button)
	add_child(formal_panel)
	runtime.inventory.changed.connect(refresh)
	refresh()


func _add_formal(definition: RelicDefinition) -> void:
	runtime.inventory.add(definition)


func refresh() -> void:
	var names := PackedStringArray()
	for id in runtime.inventory.ids():
		names.append(runtime.inventory.get_effect(id).definition.display_name)
	label.text = "工程遗物：%s   |   1/2/3 添加 · Backspace 全移除" % ("、".join(names) if not names.is_empty() else "无")
	label.text = label.text.replace("工程遗物", "遗物") + " · F2 正式遗物调试"
	label.tooltip_text = "、".join(names)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.is_echo() or not runtime.is_active():
		return
	var index := [KEY_1, KEY_2, KEY_3].find(event.physical_keycode)
	if index >= 0:
		runtime.inventory.add(DEFINITIONS[index])
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_BACKSPACE:
		runtime.inventory.clear()
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_F2:
		formal_panel.visible = not formal_panel.visible
		get_viewport().set_input_as_handled()
