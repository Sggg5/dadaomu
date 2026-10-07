class_name HiddenRoomEntrance
extends Node2D
## 墙缝只通过近距主动交互发现；不给未发现暗室添加普通门或地图标记。
var player: Player
var can_enter: Callable
var enter: Callable
var is_return: bool = false
var label: Label
var inspected: bool = false

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-100, 18)
	if position.x > 1100: label.position.x = -185
	if position.x < 180: label.position.x = -15
	if position.y > 540: label.position.y = -58
	label.size = Vector2(200, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func in_range() -> bool:
	return player.controls_enabled and not player.health.is_dead and can_enter.call() and player.global_position.distance_to(global_position) <= 64

func _process(_delta: float) -> void:
	label.text = ("[E] 返回墓道" if is_return else ("发现暗门 · [E] 进入" if inspected else "[E] 检查墙缝")) if in_range() else ""

func _unhandled_input(input: InputEvent) -> void:
	if not input.is_action_pressed("interact") or input.is_echo() or not in_range(): return
	if not inspected and not is_return:
		inspected = true
	else:
		enter.call()
	get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_line(Vector2(-14, -6), Vector2(0, 0), Color("807669"), 3)
	draw_line(Vector2(0, 0), Vector2(-5, 13), Color("807669"), 3)
