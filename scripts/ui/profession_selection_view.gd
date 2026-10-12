extends VBoxContainer
## Ground UI chooses only a stable ID; confirmation captures the immutable value.
var selected_id: StringName = &"NONE"
var buttons: Dictionary = {}
var enabled: bool = true
func _ready() -> void:
	var title := Label.new()
	title.text = "门派信物 · DRAFT · 四派首版全部开放"
	title.add_theme_font_size_override("font_size", 16)
	add_child(title)
	var row := HBoxContainer.new()
	add_child(row)
	var names := {&"MOJIN":"摸金校尉", &"FAQIU":"发丘天官", &"BANSHAN":"搬山道人", &"XIELING":"卸岭力士", &"NONE":"无门派"}
	for id in names:
		var button := Button.new()
		button.text = names[id]
		button.custom_minimum_size = Vector2(114,32)
		button.toggle_mode = true
		button.pressed.connect(select.bind(id))
		buttons[id] = button
		row.add_child(button)
	select(&"NONE")
func select(id: StringName) -> bool:
	if not enabled or not ProfessionRunState.valid_id(id): return false
	selected_id = id
	for key in buttons: buttons[key].set_pressed_no_signal(key == id)
	return true
func reset() -> void:
	enabled = true
	select(&"NONE")
