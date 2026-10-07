class_name WallMark
extends Node2D
## 真假共有的环境线索。生成由数据层完成；检查状态属于本层Plan，不存档。
const INTERACTION_DISTANCE: float = 30.0
const INITIAL_PROMPT: String = "[E] 检查墙面"
var player: Player
var definition: WallMarkDefinition
var plan: TombExplorationPlan
var can_inspect: Callable
var reveal_callback: Callable
var label: Label

func _ready() -> void:
	label = Label.new()
	label.position = Vector2(-150, 24)
	label.size = Vector2(300, 90)
	if definition.side == Door.Direction.EAST: label.position.x = -290
	if definition.side == Door.Direction.WEST: label.position.x = -10
	if definition.side == Door.Direction.SOUTH: label.position.y = -85
	if definition.side == Door.Direction.NORTH: label.position.y = 40
	label.z_index = 20
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func in_range() -> bool:
	return player.controls_enabled and not player.health.is_dead and can_inspect.call() and player.global_position.distance_to(global_position) <= INTERACTION_DISTANCE

func prompt_text() -> String:
	if not plan.checked_wall_marks.has(definition.id): return INITIAL_PROMPT
	if definition.is_secret:
		return "石砖后似乎另有空间。\n[E] 推开暗门" if plan.secret_discovered else "敲击声有些发空。\n[E] 继续检查"
	return definition.inspect_result # 假痕迹检查后只显示固定反馈，不再提示E。

func inspect() -> bool:
	if not in_range(): return false
	if plan.inspect_wall_mark(definition): return true
	if definition.is_secret:
		return reveal_callback.call()
	return false

func _process(_delta: float) -> void: label.text = prompt_text() if in_range() else ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and inspect(): get_viewport().set_input_as_handled()

func _draw() -> void:
	# 锚点用于靠近交互，痕迹实际画在墙体中线；真假共享此唯一绘制路径。
	var center := WallMarkGenerator.outward(definition.side) * 28
	var color := Color("676156")
	match definition.variant:
		0:
			draw_line(center + Vector2(-8, -4), center, color, 1.5)
			draw_line(center, center + Vector2(-3, 8), color, 1.5)
		1:
			draw_line(center + Vector2(-10, -3), center + Vector2(3, -3), color, 1.5)
			draw_line(center + Vector2(3, -3), center + Vector2(3, 5), color, 1.5)
		2:
			for offset in [Vector2(-5, 0), Vector2(3, 4), Vector2(-2, 7)]: draw_circle(center + offset, 1.7, color)
