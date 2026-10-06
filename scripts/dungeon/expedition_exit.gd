class_name ExpeditionExit
extends Node2D
## 只负责64px内一次选择；先锁选择再发信号，E/F同帧也不能双结算。
signal descend_requested
signal extract_requested
var player: Player
var used: bool = false
var label: Label
var can_choose: Callable


func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-240,28)
	label.size.x = 480
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	_refresh()


func available() -> bool:
	return not used and is_instance_valid(player) and not player.health.is_dead and player.controls_enabled and (not can_choose.is_valid() or can_choose.call()) and player.global_position.distance_to(global_position) <= 64


func request() -> bool: return request_descend()


func request_descend() -> bool:
	if not available(): return false
	used = true
	descend_requested.emit()
	return true


func request_extract() -> bool:
	if not available(): return false
	used = true
	extract_requested.emit()
	return true


func _process(_delta: float) -> void: _refresh()


func _refresh() -> void:
	var value := AntiqueDefinition.money(player.antiques.total_value())
	label.text = "墓道更深处传来阴气……\n当前携带：%d / %d格\n估值：%s\n撤离可保住：%s\n[E] 继续深入第二层\n[F] 带着古董撤离" % [player.antiques.used_slots(),player.antiques.capacity,value,value]


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("interact") and request_descend(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("extract_run") and request_extract(): get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(-30,-22,60,44),Color("182126"))
	draw_rect(Rect2(-30,-22,60,44),Color("c4b77c"),false,4)
	draw_line(Vector2(-18,12),Vector2(0,-12),Color("9edab2"),4)
	draw_line(Vector2(0,-12),Vector2(18,12),Color("9edab2"),4)
