class_name HiddenRoomEntrance
extends Node2D
## 已进入暗室后的返回入口；外部发现统一由真假WallMark处理。
var player: Player
var can_enter: Callable
var enter: Callable
var label: Label
const INTERACTION_DISTANCE: float = 30.0

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
	return player.controls_enabled and not player.health.is_dead and can_enter.call() and player.global_position.distance_to(global_position) <= INTERACTION_DISTANCE

func _process(_delta: float) -> void:
	label.text = "[E] 返回墓道" if in_range() else ""

func _unhandled_input(input: InputEvent) -> void:
	if not input.is_action_pressed("interact") or input.is_echo() or not in_range(): return
	enter.call()
	get_viewport().set_input_as_handled()

func _draw() -> void:
	# 墙边小裂纹，尺寸约旧版60%，近似墙色；不发光、不标记位置。
	draw_line(Vector2(-8, -4), Vector2.ZERO, Color("5b5750"), 1.5)
	draw_line(Vector2.ZERO, Vector2(-3, 8), Color("5b5750"), 1.5)
