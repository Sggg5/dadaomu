extends Control
## Only the isolated lab keeps its announced fixed seed; no production input edit.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.physical_keycode==KEY_N or event.keycode==KEY_N):
		get_viewport().set_input_as_handled()
