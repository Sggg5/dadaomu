class_name RunExit
extends Node2D
## 一次性交互，不决定Seed或生成地图。
signal run_complete_requested
var player: Player
var used: bool = false


func _ready() -> void:
	var label := Label.new()
	label.position = Vector2(-150, 28)
	label.text = "墓穴深处已肃清\n[E] 返回地面"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func request() -> bool:
	if used or not is_instance_valid(player) or player.health.is_dead or not player.controls_enabled or player.global_position.distance_to(global_position) > 64: return false
	used = true
	run_complete_requested.emit()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and request(): get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(-28,-22,56,44), Color("131d24"))
	draw_rect(Rect2(-28,-22,56,44), Color("87c4a3"),false,4)
	draw_line(Vector2(-12,0),Vector2(0,13),Color("d2efd1"),4)
	draw_line(Vector2(0,13),Vector2(12,0),Color("d2efd1"),4)
