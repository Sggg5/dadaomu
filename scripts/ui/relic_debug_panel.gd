class_name RelicDebugPanel
extends CanvasLayer
## 仅开发期展示与按键适配，不绘制正式拾取 UI，不决定效果行为。
const DEFINITIONS: Array[RelicDefinition] = [
	preload("res://data/relics/test_damage_relic.tres"),
	preload("res://data/relics/test_double_shot.tres"),
	preload("res://data/relics/test_kill_heal.tres")]
var runtime: RelicRuntime
var label: Label


func _ready() -> void:
	label = Label.new()
	label.position = Vector2(64, 610)
	label.add_theme_font_size_override("font_size", 16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	runtime.inventory.changed.connect(refresh)
	refresh()


func refresh() -> void:
	var names := PackedStringArray()
	for id in runtime.inventory.ids():
		names.append(runtime.inventory.get_effect(id).definition.display_name)
	label.text = "工程遗物：%s   |   1/2/3 添加 · Backspace 全移除" % ("、".join(names) if not names.is_empty() else "无")


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
